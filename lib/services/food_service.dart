import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/food.dart';
import '../models/food_variant.dart';

class FoodService {
  FoodService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<FoodCategory>> watchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      final categories =
          snapshot.docs
              .map(FoodCategory.fromFirestore)
              .where((category) => category.isActive)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      return categories;
    });
  }

  Stream<List<Food>> watchFoods() {
    return _firestore.collection('foods').snapshots().map((snapshot) {
      final foods = snapshot.docs.map(Food.fromFirestore).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return foods;
    });
  }

  Stream<List<FoodVariant>> watchVariants() {
    return _firestore.collection('food_variants').snapshots().map((snapshot) {
      final variants =
          snapshot.docs
              .map(FoodVariant.fromFirestore)
              .where((variant) => variant.isActive)
              .toList()
            ..sort((a, b) => a.price.compareTo(b.price));

      return variants;
    });
  }
}
