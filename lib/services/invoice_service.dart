import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invoice.dart';
import '../models/order_detail.dart';

class InvoiceService {
  InvoiceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Invoice>> watchInvoices() {
    return _firestore
        .collection('invoices')
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Invoice.fromFirestore).toList());
  }

  Stream<Invoice> watchInvoice(String invoiceId) {
    return _firestore
        .collection('invoices')
        .doc(invoiceId)
        .snapshots()
        .map(Invoice.fromFirestore);
  }

  Stream<List<OrderDetail>> watchInvoiceDetails(String orderId) {
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

  Future<InvoiceReferenceInfo> getReferenceInfo(Invoice invoice) async {
    final tableNames = <String>[];
    for (final tableId in invoice.tableIds) {
      final tableSnapshot = await _firestore
          .collection('tables')
          .doc(tableId)
          .get();
      final tableName = tableSnapshot.data()?['name'] as String?;
      tableNames.add(tableName == null || tableName.isEmpty ? tableId : tableName);
    }

    var customerName = 'Không có';
    final customerId = invoice.customerId;
    if (customerId != null && customerId.isNotEmpty) {
      final customerSnapshot = await _firestore
          .collection('customers')
          .doc(customerId)
          .get();
      final fullName = customerSnapshot.data()?['fullName'] as String?;
      customerName = fullName == null || fullName.isEmpty ? customerId : fullName;
    }

    var paidByName = invoice.paidBy;
    if (invoice.paidBy.isNotEmpty) {
      final userSnapshot = await _firestore
          .collection('users')
          .doc(invoice.paidBy)
          .get();
      final fullName = userSnapshot.data()?['fullName'] as String?;
      paidByName = fullName == null || fullName.isEmpty
          ? invoice.paidBy
          : fullName;
    }

    return InvoiceReferenceInfo(
      tableNames: tableNames,
      customerName: customerName,
      paidByName: paidByName,
    );
  }
}
