import 'package:cloud_firestore/cloud_firestore.dart';

class FoodVariant {
  const FoodVariant({
    required this.id,
    required this.foodId,
    required this.name,
    required this.price,
    required this.unit,
    required this.isActive,
  });

  final String id;
  final String foodId;
  final String name;
  final num price;
  final String unit;
  final bool isActive;

  factory FoodVariant.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return FoodVariant(
      id: doc.id,
      foodId: data['foodId'] as String? ?? '',
      name: data['name'] as String? ?? doc.id,
      price: data['price'] as num? ?? 0,
      unit: data['unit'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}
