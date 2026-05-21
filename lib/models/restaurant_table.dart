import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantTable {
  const RestaurantTable({
    required this.id,
    required this.name,
    required this.status,
    required this.mergedWith,
    this.currentOrderId,
  });

  final String id;
  final String name;
  final String status;
  final String? currentOrderId;
  final List<String> mergedWith;

  bool get isEmpty => statusLabel == '\u0054r\u1ed1ng';
  bool get isServing => statusLabel == '\u0110ang ph\u1ee5c v\u1ee5';
  bool get isReserved => statusLabel == '\u0110\u00e3 \u0111\u1eb7t';

  String get statusLabel {
    return switch (status) {
      'empty' || 'Tr\u00e1\u00bb\u2018ng' => '\u0054r\u1ed1ng',
      'serving' ||
      '\u00c4\u0090ang ph\u00c3\u00a1\u00c2\u00bb\u00c2\u00a5c v\u00c3\u00a1\u00c2\u00bb\u00c2\u00a5' =>
        '\u0110ang ph\u1ee5c v\u1ee5',
      'reserved' ||
      '\u00c4\u0090\u00c3\u00a3 \u00c4\u0091\u00e1\u00ba\u00b7t' =>
        '\u0110\u00e3 \u0111\u1eb7t',
      _ => status,
    };
  }

  factory RestaurantTable.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawMergedWith = data['mergedWith'] as List<dynamic>?;

    return RestaurantTable(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
      status: data['status'] as String? ?? '\u0054r\u1ed1ng',
      currentOrderId: data['currentOrderId'] as String?,
      mergedWith:
          rawMergedWith?.whereType<String>().toList() ?? const <String>[],
    );
  }
}
