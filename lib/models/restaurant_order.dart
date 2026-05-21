import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantOrder {
  const RestaurantOrder({
    required this.id,
    required this.tableId,
    required this.tableIds,
    required this.status,
    required this.subtotal,
    required this.createdBy,
    this.createdAt,
  });

  final String id;
  final String tableId;
  final List<String> tableIds;
  final String status;
  final num subtotal;
  final String createdBy;
  final Timestamp? createdAt;

  factory RestaurantOrder.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final tableId = data['tableId'] as String? ?? '';
    final rawTableIds = data['tableIds'] as List<dynamic>?;
    final tableIds =
        rawTableIds
            ?.whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList() ??
        <String>[];

    return RestaurantOrder(
      id: doc.id,
      tableId: tableId,
      tableIds: tableIds.isEmpty && tableId.isNotEmpty ? [tableId] : tableIds,
      status: data['status'] as String? ?? 'Đang mở',
      subtotal: data['subtotal'] as num? ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
