import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.orderId,
    required this.foodId,
    required this.variantId,
    required this.foodName,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
    required this.note,
    required this.lineTotal,
    required this.status,
  });

  final String id;
  final String orderId;
  final String foodId;
  final String variantId;
  final String foodName;
  final String variantName;
  final num unitPrice;
  final int quantity;
  final String note;
  final num lineTotal;
  final String status;

  bool get isPending =>
      status.isEmpty || status == 'Chưa xác nhận' || status == 'pending';

  bool get isConfirmed => status == 'Đã xác nhận' || status == 'confirmed';

  String get statusLabel {
    if (isConfirmed) return 'Đã xác nhận';
    return 'Chưa xác nhận';
  }

  factory OrderDetail.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return OrderDetail(
      id: doc.id,
      orderId: data['orderId'] as String? ?? '',
      foodId: data['foodId'] as String? ?? '',
      variantId: data['variantId'] as String? ?? '',
      foodName: data['foodName'] as String? ?? '',
      variantName: data['variantName'] as String? ?? '',
      unitPrice: data['unitPrice'] as num? ?? 0,
      quantity: (data['quantity'] as num? ?? 0).toInt(),
      note: data['note'] as String? ?? '',
      lineTotal: data['lineTotal'] as num? ?? 0,
      status: data['status'] as String? ?? 'Chưa xác nhận',
    );
  }
}
