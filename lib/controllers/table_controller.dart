import 'package:flutter/material.dart';

import '../models/restaurant_table.dart';
import '../services/table_service.dart';

class TableController extends ChangeNotifier {
  TableController({TableService? tableService})
    : _tableService = tableService ?? TableService();

  final TableService _tableService;
  final searchController = TextEditingController();

  String selectedStatus = 'all';
  bool isTransferring = false;
  String? transferErrorMessage;

  Stream<List<RestaurantTable>> get tablesStream => _tableService.watchTables();

  void onSearchChanged() {
    notifyListeners();
  }

  void setStatus(String status) {
    selectedStatus = status;
    notifyListeners();
  }

  List<RestaurantTable> filterTables(List<RestaurantTable> tables) {
    final keyword = searchController.text.trim().toLowerCase();

    return tables.where((table) {
      final matchesStatus =
          selectedStatus == 'all' || table.statusLabel == selectedStatus;
      final matchesKeyword =
          keyword.isEmpty || table.name.toLowerCase().contains(keyword);

      return matchesStatus && matchesKeyword;
    }).toList();
  }

  int countByStatus(List<RestaurantTable> tables, String status) {
    return tables.where((table) => table.statusLabel == status).length;
  }

  List<RestaurantTable> transferTargets(
    List<RestaurantTable> tables,
    RestaurantTable currentTable,
  ) {
    return tables
        .where(
          (table) =>
              table.id != currentTable.id &&
              (table.isEmpty || table.isReserved) &&
              (table.currentOrderId == null || table.currentOrderId!.isEmpty),
        )
        .toList();
  }

  Future<bool> transferOrder({
    required RestaurantTable fromTable,
    required RestaurantTable toTable,
  }) async {
    transferErrorMessage = null;
    isTransferring = true;
    notifyListeners();

    try {
      await _tableService.transferOrder(fromTable: fromTable, toTable: toTable);
      return true;
    } catch (error) {
      transferErrorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isTransferring = false;
      notifyListeners();
    }
  }

  List<RestaurantTable> mergeTargets(
    List<RestaurantTable> tables,
    RestaurantTable currentTable,
  ) {
    return tables
        .where(
          (table) =>
              table.id != currentTable.id &&
              ((table.isEmpty || table.isReserved) ||
                  (table.isServing &&
                      table.currentOrderId != null &&
                      table.currentOrderId!.isNotEmpty &&
                      table.currentOrderId != currentTable.currentOrderId)),
        )
        .toList();
  }

  Future<bool> mergeTables({
    required RestaurantTable keepTable,
    required RestaurantTable mergedTable,
  }) async {
    transferErrorMessage = null;
    isTransferring = true;
    notifyListeners();

    try {
      await _tableService.mergeTables(
        keepTable: keepTable,
        mergedTable: mergedTable,
      );
      return true;
    } catch (error) {
      transferErrorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isTransferring = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
