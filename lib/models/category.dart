import 'package:cloud_firestore/cloud_firestore.dart';

class FoodCategory {
  const FoodCategory({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;

  factory FoodCategory.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return FoodCategory(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}
