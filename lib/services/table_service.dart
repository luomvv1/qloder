import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant_table.dart';

class TableService {
  TableService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RestaurantTable>> watchTables() {
    return _firestore.collection('tables').snapshots().map((snapshot) {
      final tables = snapshot.docs.map(RestaurantTable.fromFirestore).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return tables;
    });
  }

  Future<void> transferOrder({
    required RestaurantTable fromTable,
    required RestaurantTable toTable,
  }) async {
    final orderId = fromTable.currentOrderId;
    if (orderId == null || orderId.isEmpty) {
      throw Exception('Bàn nguồn chưa có order để chuyển.');
    }

    if (fromTable.id == toTable.id) {
      throw Exception('Bàn chuyển đến phải khác bàn hiện tại.');
    }

    final fromTableRef = _firestore.collection('tables').doc(fromTable.id);
    final toTableRef = _firestore.collection('tables').doc(toTable.id);
    final orderRef = _firestore.collection('orders').doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final fromSnapshot = await transaction.get(fromTableRef);
      final toSnapshot = await transaction.get(toTableRef);
      final orderSnapshot = await transaction.get(orderRef);

      final fromData = fromSnapshot.data();
      final toData = toSnapshot.data();
      final orderData = orderSnapshot.data();

      if (!fromSnapshot.exists || fromData == null) {
        throw Exception('Không tìm thấy bàn nguồn.');
      }

      if (!toSnapshot.exists || toData == null) {
        throw Exception('Không tìm thấy bàn chuyển đến.');
      }

      if (!orderSnapshot.exists || orderData == null) {
        throw Exception('Không tìm thấy order hiện tại.');
      }

      final currentOrderId = fromData['currentOrderId'] as String?;
      if (currentOrderId != orderId) {
        throw Exception('Order của bàn nguồn đã thay đổi. Vui lòng thử lại.');
      }

      final toStatus = toData['status'] as String? ?? 'Trống';
      final toCurrentOrderId = toData['currentOrderId'] as String?;
      final toTableCanReceive =
          (toStatus == 'Trống' || toStatus == 'empty') ||
          (toStatus == 'Đã đặt' || toStatus == 'reserved');

      if (!toTableCanReceive ||
          (toCurrentOrderId != null && toCurrentOrderId.isNotEmpty)) {
        throw Exception('Bàn chuyển đến đang có order, không thể chuyển.');
      }

      final orderStatus = orderData['status'] as String? ?? 'Đang mở';
      if (orderStatus != 'Đang mở' && orderStatus != 'open') {
        throw Exception('Order này không còn mở để chuyển bàn.');
      }

      transaction.update(fromTableRef, {
        'status': 'Trống',
        'currentOrderId': null,
        'mergedWith': <String>[],
      });
      transaction.update(toTableRef, {
        'status': 'Đang phục vụ',
        'currentOrderId': orderId,
        'mergedWith': <String>[],
      });
      transaction.update(orderRef, {
        'tableId': toTable.id,
        'tableIds': [toTable.id],
      });
    });
  }

  Future<void> mergeTables({
    required RestaurantTable keepTable,
    required RestaurantTable mergedTable,
  }) async {
    final keepOrderId = keepTable.currentOrderId;
    final mergedOrderId = mergedTable.currentOrderId;

    if (keepOrderId == null || keepOrderId.isEmpty) {
      throw Exception('Bàn giữ lại chưa có order.');
    }

    if (keepTable.id == mergedTable.id) {
      throw Exception('Không thể gộp cùng một bàn.');
    }

    final keepTableRef = _firestore.collection('tables').doc(keepTable.id);
    final mergedTableRef = _firestore.collection('tables').doc(mergedTable.id);
    final keepOrderRef = _firestore.collection('orders').doc(keepOrderId);
    final mergedOrderRef = mergedOrderId == null || mergedOrderId.isEmpty
        ? null
        : _firestore.collection('orders').doc(mergedOrderId);

    final mergedDetailsSnapshot =
        mergedOrderId == null ||
            mergedOrderId.isEmpty ||
            mergedOrderId == keepOrderId
        ? null
        : await _firestore
              .collection('order_details')
              .where('orderId', isEqualTo: mergedOrderId)
              .get();

    await _firestore.runTransaction((transaction) async {
      final keepTableSnapshot = await transaction.get(keepTableRef);
      final mergedTableSnapshot = await transaction.get(mergedTableRef);
      final keepOrderSnapshot = await transaction.get(keepOrderRef);
      final mergedOrderSnapshot = mergedOrderRef == null
          ? null
          : await transaction.get(mergedOrderRef);

      final keepTableData = keepTableSnapshot.data();
      final mergedTableData = mergedTableSnapshot.data();
      final keepOrderData = keepOrderSnapshot.data();
      final mergedOrderData = mergedOrderSnapshot?.data();

      if (!keepTableSnapshot.exists || keepTableData == null) {
        throw Exception('Không tìm thấy bàn giữ lại.');
      }

      if (!mergedTableSnapshot.exists || mergedTableData == null) {
        throw Exception('Không tìm thấy bàn cần gộp.');
      }

      if (!keepOrderSnapshot.exists || keepOrderData == null) {
        throw Exception('Không tìm thấy order bàn giữ lại.');
      }

      if (mergedOrderRef != null &&
          (mergedOrderSnapshot == null ||
              !mergedOrderSnapshot.exists ||
              mergedOrderData == null)) {
        throw Exception('Không tìm thấy order bàn cần gộp.');
      }

      final keepCurrentOrderId = keepTableData['currentOrderId'] as String?;
      final mergedCurrentOrderId = mergedTableData['currentOrderId'] as String?;
      if (keepCurrentOrderId != keepOrderId ||
          mergedCurrentOrderId != mergedOrderId) {
        throw Exception('Order của một trong hai bàn đã thay đổi.');
      }

      final keepStatus = keepOrderData['status'] as String? ?? 'Đang mở';
      if (keepStatus != 'Đang mở' && keepStatus != 'open') {
        throw Exception('Order bàn giữ lại không còn mở.');
      }

      var mergedSubtotal = 0;
      if (mergedOrderData != null && mergedOrderId != keepOrderId) {
        final mergedStatus = mergedOrderData['status'] as String? ?? 'Đang mở';
        if (mergedStatus != 'Đang mở' && mergedStatus != 'open') {
          throw Exception('Order bàn cần gộp không còn mở.');
        }
        mergedSubtotal = (mergedOrderData['subtotal'] as num? ?? 0).toInt();
      }

      if (mergedDetailsSnapshot != null) {
        for (final detailDoc in mergedDetailsSnapshot.docs) {
          transaction.update(detailDoc.reference, {'orderId': keepOrderId});
        }
      }

      transaction.update(keepOrderRef, {
        'tableIds': FieldValue.arrayUnion([keepTable.id, mergedTable.id]),
        if (mergedSubtotal > 0)
          'subtotal': FieldValue.increment(mergedSubtotal),
        if (mergedOrderId != null &&
            mergedOrderId.isNotEmpty &&
            mergedOrderId != keepOrderId)
          'mergedOrderIds': FieldValue.arrayUnion([mergedOrderId]),
      });

      if (mergedOrderRef != null && mergedOrderId != keepOrderId) {
        transaction.update(mergedOrderRef, {
          'status': 'Đã gộp',
          'mergedIntoOrderId': keepOrderId,
          'mergedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(keepTableRef, {
        'status': 'Đang phục vụ',
        'currentOrderId': keepOrderId,
        'mergedWith': FieldValue.arrayUnion([mergedTable.id]),
      });
      transaction.update(mergedTableRef, {
        'status': 'Đang phục vụ',
        'currentOrderId': keepOrderId,
        'mergedWith': FieldValue.arrayUnion([keepTable.id]),
      });
    });
  }
}
