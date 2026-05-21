import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer.dart';
import '../models/restaurant_order.dart';
import '../models/restaurant_table.dart';
import 'auth_service.dart';

class PaymentService {
  PaymentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AuthService? authService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuthService _authService;

  Future<PaymentSettings> getPaymentSettings() async {
    final snapshot = await _firestore
        .collection('settings')
        .doc('setting01')
        .get();
    final data = snapshot.data() ?? <String, dynamic>{};

    return PaymentSettings(
      pointRate: (data['pointRate'] as num? ?? 10000).toInt(),
      pointValue: (data['pointValue'] as num? ?? 1000).toInt(),
    );
  }

  Future<Customer?> findCustomerByPhone(String phone) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) return null;

    final snapshot = await _firestore
        .collection('customers')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Customer.fromFirestore(snapshot.docs.first);
  }

  Future<Customer> createCustomer({
    required String fullName,
    required String phone,
  }) async {
    final normalizedName = fullName.trim();
    final normalizedPhone = phone.trim();

    if (normalizedName.isEmpty) {
      throw Exception('Vui lòng nhập tên khách hàng.');
    }

    if (normalizedPhone.isEmpty) {
      throw Exception('Vui lòng nhập số điện thoại.');
    }

    final existingCustomer = await findCustomerByPhone(normalizedPhone);
    if (existingCustomer != null) {
      return existingCustomer;
    }

    final nextNumber = await _latestCustomerNumber() + 1;
    final customerId = 'customer${nextNumber.toString().padLeft(2, '0')}';
    final customerRef = _firestore.collection('customers').doc(customerId);

    await customerRef.set({
      'fullName': normalizedName,
      'phone': normalizedPhone,
      'points': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await customerRef.get();
    return Customer.fromFirestore(snapshot);
  }

  Future<String> payOrder({
    required RestaurantOrder order,
    required RestaurantTable table,
    required Customer? customer,
    required num discountAmount,
    required int pointsUsed,
    required String paymentMethod,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('Bạn cần đăng nhập để thanh toán.');
    }

    final appUser = await _authService.currentUserProfile();
    if (appUser == null) {
      throw Exception('Không lấy được thông tin nhân viên.');
    }

    final detailsSnapshot = await _firestore
        .collection('order_details')
        .where('orderId', isEqualTo: order.id)
        .get();

    if (detailsSnapshot.docs.isEmpty) {
      throw Exception('Order chưa có món nên không thể thanh toán.');
    }

    final hasPendingItem = detailsSnapshot.docs.any((doc) {
      final status = doc.data()['status'] as String? ?? 'Chưa xác nhận';
      return status == 'Chưa xác nhận' || status == 'pending';
    });
    if (hasPendingItem) {
      throw Exception('Còn món chưa xác nhận. Hãy xác nhận gọi món trước.');
    }

    final settingsRef = _firestore.collection('settings').doc('setting01');
    final orderRef = _firestore.collection('orders').doc(order.id);
    final customerRef = customer == null
        ? null
        : _firestore.collection('customers').doc(customer.id);

    late final String invoiceId;

    await _firestore.runTransaction((transaction) async {
      final settingsSnapshot = await transaction.get(settingsRef);
      final orderSnapshot = await transaction.get(orderRef);
      final customerSnapshot = customerRef == null
          ? null
          : await transaction.get(customerRef);

      final orderData = orderSnapshot.data();
      if (!orderSnapshot.exists || orderData == null) {
        throw Exception('Không tìm thấy order ${order.id}.');
      }

      final status = orderData['status'] as String? ?? 'Đang mở';
      if (status != 'Đang mở' && status != 'open') {
        throw Exception('Order này đã thanh toán hoặc đã hủy.');
      }

      final tableIds = _tableIdsFromOrder(orderData, table.id);
      final subtotal = orderData['subtotal'] as num? ?? order.subtotal;
      final settings = settingsSnapshot.data() ?? <String, dynamic>{};
      final currentInvoiceNumber =
          (settings['invoiceCurrentNumber'] as num? ?? 0).toInt();
      final pointRate = (settings['pointRate'] as num? ?? 10000).toInt();
      final pointValue = (settings['pointValue'] as num? ?? 1000).toInt();
      final nextInvoiceNumber = currentInvoiceNumber + 1;

      invoiceId = 'invoice${nextInvoiceNumber.toString().padLeft(2, '0')}';
      final invoiceRef = _firestore.collection('invoices').doc(invoiceId);

      var customerPoints = customer?.points ?? 0;
      if (customerSnapshot != null && customerSnapshot.exists) {
        customerPoints =
            (customerSnapshot.data()?['points'] as num? ?? customerPoints)
                .toInt();
      }

      final validDiscount = discountAmount < 0 ? 0 : discountAmount;
      final amountCanUsePoints = subtotal - validDiscount;
      final maxPointsByAmount = pointValue <= 0 || amountCanUsePoints <= 0
          ? 0
          : (amountCanUsePoints / pointValue).floor();
      final maxPoints = customerPoints < maxPointsByAmount
          ? customerPoints
          : maxPointsByAmount;
      final validPointsUsed = customer == null
          ? 0
          : pointsUsed.clamp(0, maxPoints);
      final pointsValue = validPointsUsed * pointValue;
      final rawTotal = subtotal - validDiscount - pointsValue;
      final totalAmount = rawTotal < 0 ? 0 : rawTotal;
      final pointsEarned = customer == null || pointRate <= 0
          ? 0
          : (subtotal / pointRate).floor();

      transaction.set(invoiceRef, {
        'invoiceNo': 'HD${nextInvoiceNumber.toString().padLeft(6, '0')}',
        'orderId': order.id,
        'tableId': table.id,
        'tableIds': tableIds,
        'customerId': customer?.id,
        'subtotal': subtotal,
        'discountAmount': validDiscount,
        'pointsUsed': validPointsUsed,
        'pointsEarned': pointsEarned,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'paidBy': appUser.id,
        'paidAt': FieldValue.serverTimestamp(),
      });

      transaction.update(orderRef, {
        'status': 'Đã thanh toán',
        'paidAt': FieldValue.serverTimestamp(),
      });

      for (final tableId in tableIds) {
        transaction.update(_firestore.collection('tables').doc(tableId), {
          'status': 'Trống',
          'currentOrderId': null,
          'mergedWith': <String>[],
        });
      }

      if (customerRef != null) {
        transaction.update(customerRef, {
          'points': customerPoints - validPointsUsed + pointsEarned,
        });
      }

      transaction.set(settingsRef, {
        'invoiceCurrentNumber': nextInvoiceNumber,
      }, SetOptions(merge: true));
    });

    return invoiceId;
  }

  List<String> _tableIdsFromOrder(
    Map<String, dynamic> orderData,
    String fallbackTableId,
  ) {
    final rawTableIds = orderData['tableIds'] as List<dynamic>?;
    final tableIds =
        rawTableIds
            ?.whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList() ??
        <String>[];

    if (tableIds.isEmpty && fallbackTableId.isNotEmpty) {
      return [fallbackTableId];
    }

    return tableIds;
  }

  Future<int> _latestCustomerNumber() async {
    final snapshot = await _firestore.collection('customers').get();

    var latestNumber = 0;
    for (final doc in snapshot.docs) {
      final match = RegExp(r'^customer(\d+)$').firstMatch(doc.id);
      if (match == null) continue;

      final number = int.tryParse(match.group(1) ?? '') ?? 0;
      if (number > latestNumber) {
        latestNumber = number;
      }
    }

    return latestNumber;
  }
}

class PaymentSettings {
  const PaymentSettings({required this.pointRate, required this.pointValue});

  final int pointRate;
  final int pointValue;
}
