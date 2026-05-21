import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food.dart';
import '../models/food_variant.dart';
import '../models/order_detail.dart';
import '../models/restaurant_order.dart';
import '../models/restaurant_table.dart';
import 'auth_service.dart';

class OrderService {
  OrderService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AuthService? authService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuthService _authService;

  Stream<RestaurantOrder> watchOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map(RestaurantOrder.fromFirestore);
  }

  Stream<List<OrderDetail>> watchOrderDetails(String orderId) {
    return _firestore
        .collection('order_details')
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) {
          final details = snapshot.docs.map(OrderDetail.fromFirestore).toList()
            ..sort((a, b) => a.id.compareTo(b.id));

          return details;
        });
  }

  Future<RestaurantOrder> getOrder(String orderId) async {
    final orderSnapshot = await _firestore
        .collection('orders')
        .doc(orderId)
        .get();
    if (!orderSnapshot.exists) {
      throw Exception('Không tìm thấy order $orderId.');
    }

    return RestaurantOrder.fromFirestore(orderSnapshot);
  }

  Future<RestaurantOrder> createOrderForTable(RestaurantTable table) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để tạo order.');
    }

    final appUser = await _authService.currentUserProfile();
    if (appUser == null) {
      throw Exception('Không lấy được thông tin nhân viên.');
    }

    final tableRef = _firestore.collection('tables').doc(table.id);
    final settingsRef = _firestore.collection('settings').doc('setting01');
    final currentNumber = await _latestOrderNumber();
    late final DocumentReference<Map<String, dynamic>> orderRef;

    await _firestore.runTransaction((transaction) async {
      final tableSnapshot = await transaction.get(tableRef);
      final tableData = tableSnapshot.data();

      if (!tableSnapshot.exists || tableData == null) {
        throw Exception('Không tìm thấy bàn ${table.name}.');
      }

      final currentStatus = tableData['status'] as String? ?? 'Trống';
      if (currentStatus == 'Đang phục vụ' || currentStatus == 'serving') {
        throw Exception('Bàn này đang phục vụ, không thể tạo order mới.');
      }

      final nextNumber = currentNumber + 1;
      final orderId = 'order${nextNumber.toString().padLeft(2, '0')}';
      orderRef = _firestore.collection('orders').doc(orderId);

      final orderSnapshot = await transaction.get(orderRef);
      if (orderSnapshot.exists) {
        throw Exception('Mã order $orderId đã tồn tại. Vui lòng thử lại.');
      }

      transaction.set(orderRef, {
        'tableId': table.id,
        'tableIds': [table.id],
        'status': 'Đang mở',
        'subtotal': 0,
        'createdBy': appUser.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(tableRef, {
        'status': 'Đang phục vụ',
        'currentOrderId': orderRef.id,
        'mergedWith': <String>[],
      });

      transaction.set(settingsRef, {
        'orderCurrentNumber': nextNumber,
      }, SetOptions(merge: true));
    });

    final orderSnapshot = await orderRef.get();
    return RestaurantOrder.fromFirestore(orderSnapshot);
  }

  Future<void> addItemToOrder({
    required String orderId,
    required Food food,
    required FoodVariant variant,
    required int quantity,
    required String note,
  }) async {
    if (quantity <= 0) {
      throw Exception('Số lượng món phải lớn hơn 0.');
    }

    final lineTotal = variant.price * quantity;
    final currentNumber = await _latestDetailNumber();
    final detailId = 'detail${(currentNumber + 1).toString().padLeft(2, '0')}';
    final detailRef = _firestore.collection('order_details').doc(detailId);
    final orderRef = _firestore.collection('orders').doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final orderData = orderSnapshot.data();

      if (!orderSnapshot.exists || orderData == null) {
        throw Exception('Không tìm thấy order $orderId.');
      }

      final status = orderData['status'] as String? ?? 'Đang mở';
      if (status != 'Đang mở' && status != 'open') {
        throw Exception('Order này không còn mở để thêm món.');
      }

      final detailSnapshot = await transaction.get(detailRef);
      if (detailSnapshot.exists) {
        throw Exception('Mã chi tiết $detailId đã tồn tại. Vui lòng thử lại.');
      }

      transaction.set(detailRef, {
        'orderId': orderId,
        'foodId': food.id,
        'variantId': variant.id,
        'foodName': food.name,
        'variantName': variant.name,
        'unitPrice': variant.price,
        'quantity': quantity,
        'note': note.trim(),
        'lineTotal': lineTotal,
        'status': 'Chưa xác nhận',
      });

      transaction.update(orderRef, {
        'subtotal': FieldValue.increment(lineTotal),
      });
    });
  }

  Future<void> updateDetailQuantity({
    required OrderDetail detail,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await deleteDetail(detail);
      return;
    }

    final detailRef = _firestore.collection('order_details').doc(detail.id);
    final orderRef = _firestore.collection('orders').doc(detail.orderId);

    await _firestore.runTransaction((transaction) async {
      final detailSnapshot = await transaction.get(detailRef);
      final detailData = detailSnapshot.data();

      if (!detailSnapshot.exists || detailData == null) {
        throw Exception('Không tìm thấy món trong order.');
      }

      _ensurePendingDetail(detailData);

      final oldTotal = detailData['lineTotal'] as num? ?? 0;
      final unitPrice = detailData['unitPrice'] as num? ?? 0;
      final newTotal = unitPrice * quantity;

      transaction.update(detailRef, {
        'quantity': quantity,
        'lineTotal': newTotal,
      });
      transaction.update(orderRef, {
        'subtotal': FieldValue.increment(newTotal - oldTotal),
      });
    });
  }

  Future<void> updateDetailVariant({
    required OrderDetail detail,
    required FoodVariant variant,
  }) async {
    final detailRef = _firestore.collection('order_details').doc(detail.id);
    final orderRef = _firestore.collection('orders').doc(detail.orderId);

    await _firestore.runTransaction((transaction) async {
      final detailSnapshot = await transaction.get(detailRef);
      final detailData = detailSnapshot.data();

      if (!detailSnapshot.exists || detailData == null) {
        throw Exception('Không tìm thấy món trong order.');
      }

      _ensurePendingDetail(detailData);

      final quantity = (detailData['quantity'] as num? ?? 0).toInt();
      final oldTotal = detailData['lineTotal'] as num? ?? 0;
      final newTotal = variant.price * quantity;

      transaction.update(detailRef, {
        'variantId': variant.id,
        'variantName': variant.name,
        'unitPrice': variant.price,
        'lineTotal': newTotal,
      });
      transaction.update(orderRef, {
        'subtotal': FieldValue.increment(newTotal - oldTotal),
      });
    });
  }

  Future<void> updateDetailNote({
    required OrderDetail detail,
    required String note,
  }) async {
    final detailRef = _firestore.collection('order_details').doc(detail.id);

    await _firestore.runTransaction((transaction) async {
      final detailSnapshot = await transaction.get(detailRef);
      final detailData = detailSnapshot.data();

      if (!detailSnapshot.exists || detailData == null) {
        throw Exception('Không tìm thấy món trong order.');
      }

      _ensurePendingDetail(detailData);

      transaction.update(detailRef, {'note': note.trim()});
    });
  }

  Future<void> deleteDetail(OrderDetail detail) async {
    final detailRef = _firestore.collection('order_details').doc(detail.id);
    final orderRef = _firestore.collection('orders').doc(detail.orderId);

    await _firestore.runTransaction((transaction) async {
      final detailSnapshot = await transaction.get(detailRef);
      final detailData = detailSnapshot.data();

      if (!detailSnapshot.exists || detailData == null) {
        throw Exception('Không tìm thấy món trong order.');
      }

      _ensurePendingDetail(detailData);

      final lineTotal = detailData['lineTotal'] as num? ?? 0;
      transaction.delete(detailRef);
      transaction.update(orderRef, {
        'subtotal': FieldValue.increment(-lineTotal),
      });
    });
  }

  // Hủy order đang mở và trả tất cả bàn trong order về trạng thái trống.
  Future<void> cancelOrder({
    required RestaurantOrder order,
    required RestaurantTable table,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để hủy order.');
    }

    final appUser = await _authService.currentUserProfile();
    final orderRef = _firestore.collection('orders').doc(order.id);

    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final orderData = orderSnapshot.data();

      if (!orderSnapshot.exists || orderData == null) {
        throw Exception('Không tìm thấy order ${order.id}.');
      }

      final status = orderData['status'] as String? ?? 'Đang mở';
      if (status != 'Đang mở' && status != 'open') {
        throw Exception('Chỉ có thể hủy order đang mở.');
      }

      final rawTableIds = orderData['tableIds'] as List<dynamic>?;
      final tableIds =
          rawTableIds
              ?.whereType<String>()
              .where((id) => id.isNotEmpty)
              .toList() ??
          <String>[];
      if (tableIds.isEmpty && table.id.isNotEmpty) {
        tableIds.add(table.id);
      }

      transaction.update(orderRef, {
        'status': 'Đã hủy',
        'canceledAt': FieldValue.serverTimestamp(),
        'canceledBy': appUser?.id ?? user.uid,
      });

      for (final tableId in tableIds) {
        transaction.update(_firestore.collection('tables').doc(tableId), {
          'status': 'Trống',
          'currentOrderId': null,
          'mergedWith': <String>[],
        });
      }
    });
  }

  Future<void> confirmPendingItems(String orderId) async {
    final detailSnapshot = await _firestore
        .collection('order_details')
        .where('orderId', isEqualTo: orderId)
        .get();
    final pendingDocs = detailSnapshot.docs.where((doc) {
      final status = doc.data()['status'] as String? ?? 'Chưa xác nhận';
      return status == 'Chưa xác nhận' || status == 'pending';
    }).toList();

    if (pendingDocs.isEmpty) {
      throw Exception('Không có món mới cần xác nhận.');
    }

    final batch = _firestore.batch();
    for (final doc in pendingDocs) {
      batch.update(doc.reference, {
        'status': 'Đã xác nhận',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.update(_firestore.collection('orders').doc(orderId), {
      'lastConfirmedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<int> _latestOrderNumber() async {
    final orderSnapshot = await _firestore.collection('orders').get();

    var latestNumber = 0;
    for (final doc in orderSnapshot.docs) {
      final match = RegExp(r'^order(\d+)$').firstMatch(doc.id);
      if (match == null) continue;

      final number = int.tryParse(match.group(1) ?? '') ?? 0;
      if (number > latestNumber) {
        latestNumber = number;
      }
    }

    return latestNumber;
  }

  Future<int> _latestDetailNumber() async {
    final detailSnapshot = await _firestore.collection('order_details').get();

    var latestNumber = 0;
    for (final doc in detailSnapshot.docs) {
      final match = RegExp(r'^detail(\d+)$').firstMatch(doc.id);
      if (match == null) continue;

      final number = int.tryParse(match.group(1) ?? '') ?? 0;
      if (number > latestNumber) {
        latestNumber = number;
      }
    }

    return latestNumber;
  }

  void _ensurePendingDetail(Map<String, dynamic> detailData) {
    final status = detailData['status'] as String? ?? 'Chưa xác nhận';
    if (status != 'Chưa xác nhận' && status != 'pending' && status.isNotEmpty) {
      throw Exception('Món này đã xác nhận nên không thể sửa.');
    }
  }
}
