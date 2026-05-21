import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/food.dart';
import '../models/food_variant.dart';
import '../models/order_detail.dart';
import '../models/restaurant_order.dart';
import '../services/food_service.dart';
import '../services/order_service.dart';

class OrderItemsController extends ChangeNotifier {
  OrderItemsController({FoodService? foodService, OrderService? orderService})
    : _foodService = foodService ?? FoodService(),
      _orderService = orderService ?? OrderService();

  final FoodService _foodService;
  final OrderService _orderService;
  final searchController = TextEditingController();

  bool isAdding = false;
  bool isUpdating = false;
  bool isConfirming = false;
  String? errorMessage;
  String selectedCategoryId = 'all';

  Stream<RestaurantOrder> watchOrder(String orderId) {
    return _orderService.watchOrder(orderId);
  }

  Stream<List<OrderDetail>> watchOrderDetails(String orderId) {
    return _orderService.watchOrderDetails(orderId);
  }

  Stream<List<FoodCategory>> watchCategories() {
    return _foodService.watchCategories();
  }

  Stream<List<Food>> watchFoods() {
    return _foodService.watchFoods();
  }

  Stream<List<FoodVariant>> watchVariants() {
    return _foodService.watchVariants();
  }

  void onSearchChanged() {
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void selectCategory(String categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  List<Food> filterFoods(List<Food> foods) {
    final keyword = searchController.text.trim().toLowerCase();

    return foods.where((food) {
      final matchesCategory =
          selectedCategoryId == 'all' || food.categoryId == selectedCategoryId;
      final matchesKeyword =
          keyword.isEmpty ||
          food.name.toLowerCase().contains(keyword) ||
          food.description.toLowerCase().contains(keyword);

      return food.isAvailable && matchesCategory && matchesKeyword;
    }).toList();
  }

  List<FoodVariant> variantsForFood(String foodId, List<FoodVariant> variants) {
    return variants.where((variant) => variant.foodId == foodId).toList();
  }

  Future<bool> addItem({
    required String orderId,
    required Food food,
    required FoodVariant variant,
    required int quantity,
    required String note,
  }) async {
    errorMessage = null;
    isAdding = true;
    notifyListeners();

    try {
      await _orderService.addItemToOrder(
        orderId: orderId,
        food: food,
        variant: variant,
        quantity: quantity,
        note: note,
      );
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isAdding = false;
      notifyListeners();
    }
  }

  Future<bool> updateQuantity({
    required OrderDetail detail,
    required int quantity,
  }) async {
    return _runUpdate(() {
      return _orderService.updateDetailQuantity(
        detail: detail,
        quantity: quantity,
      );
    });
  }

  Future<bool> updateVariant({
    required OrderDetail detail,
    required FoodVariant variant,
  }) async {
    return _runUpdate(() {
      return _orderService.updateDetailVariant(
        detail: detail,
        variant: variant,
      );
    });
  }

  Future<bool> updateNote({
    required OrderDetail detail,
    required String note,
  }) async {
    return _runUpdate(() {
      return _orderService.updateDetailNote(detail: detail, note: note);
    });
  }

  Future<bool> deleteItem(OrderDetail detail) async {
    return _runUpdate(() {
      return _orderService.deleteDetail(detail);
    });
  }

  Future<bool> confirmPendingItems(String orderId) async {
    errorMessage = null;
    isConfirming = true;
    notifyListeners();

    try {
      await _orderService.confirmPendingItems(orderId);
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isConfirming = false;
      notifyListeners();
    }
  }

  Future<bool> _runUpdate(Future<void> Function() action) async {
    errorMessage = null;
    isUpdating = true;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
