import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.minPrice,
  });

  final String id;
  final String name;
  final String categoryId;
  final String description;
  final String imageUrl;
  final String status;
  final num minPrice;

  bool get isAvailable => status == 'Còn bán' || status == 'available';

  factory Food.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    return Food(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
      categoryId: data['categoryId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      status: data['status'] as String? ?? 'Còn bán',
      minPrice: data['minPrice'] as num? ?? 0,
    );
  }
}
