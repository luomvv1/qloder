import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNo,
    required this.orderId,
    required this.tableId,
    required this.tableIds,
    required this.customerId,
    required this.subtotal,
    required this.discountAmount,
    required this.pointsUsed,
    required this.pointsEarned,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paidBy,
    this.paidAt,
  });

  final String id;
  final String invoiceNo;
  final String orderId;
  final String tableId;
  final List<String> tableIds;
  final String? customerId;
  final num subtotal;
  final num discountAmount;
  final int pointsUsed;
  final int pointsEarned;
  final num totalAmount;
  final String paymentMethod;
  final String paidBy;
  final Timestamp? paidAt;

  factory Invoice.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawTableIds = data['tableIds'] as List<dynamic>?;
    final tableId = data['tableId'] as String? ?? '';
    final tableIds =
        rawTableIds
            ?.whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList() ??
        <String>[];

    return Invoice(
      id: doc.id,
      invoiceNo: data['invoiceNo'] as String? ?? doc.id,
      orderId: data['orderId'] as String? ?? '',
      tableId: tableId,
      tableIds: tableIds.isEmpty && tableId.isNotEmpty ? [tableId] : tableIds,
      customerId: data['customerId'] as String?,
      subtotal: data['subtotal'] as num? ?? 0,
      discountAmount: data['discountAmount'] as num? ?? 0,
      pointsUsed: (data['pointsUsed'] as num? ?? 0).toInt(),
      pointsEarned: (data['pointsEarned'] as num? ?? 0).toInt(),
      totalAmount: data['totalAmount'] as num? ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? '',
      paidBy: data['paidBy'] as String? ?? '',
      paidAt: data['paidAt'] as Timestamp?,
    );
  }
}

class InvoiceReferenceInfo {
  const InvoiceReferenceInfo({
    required this.tableNames,
    required this.customerName,
    required this.paidByName,
  });

  final List<String> tableNames;
  final String customerName;
  final String paidByName;
}
