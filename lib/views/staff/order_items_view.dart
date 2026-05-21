library order_items_view;

import 'package:flutter/material.dart';

import '../../controllers/order_items_controller.dart';
import '../../models/category.dart';
import '../../models/food.dart';
import '../../models/food_variant.dart';
import '../../models/order_detail.dart';
import '../../models/restaurant_order.dart';
import '../../models/restaurant_table.dart';

part 'widgets/order_items_widgets.dart';

class OrderItemsView extends StatefulWidget {
  const OrderItemsView({super.key, required this.order, required this.table});

  final RestaurantOrder order;
  final RestaurantTable table;

  @override
  State<OrderItemsView> createState() => _OrderItemsViewState();
}

class _OrderItemsViewState extends State<OrderItemsView> {
  late final OrderItemsController _controller = OrderItemsController();
  final _quantityController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  bool _isOrderDetailsExpanded = true;

  Food? _selectedFood;
  FoodVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    _controller.searchController.addListener(_controller.onSearchChanged);
  }

  @override
  void dispose() {
    _controller.searchController.removeListener(_controller.onSearchChanged);
    _quantityController.dispose();
    _noteController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gọi món')),
      body: StreamBuilder<RestaurantOrder>(
        stream: _controller.watchOrder(widget.order.id),
        builder: (context, orderSnapshot) {
          final order = orderSnapshot.data ?? widget.order;

          return StreamBuilder<List<OrderDetail>>(
            stream: _controller.watchOrderDetails(widget.order.id),
            builder: (context, detailSnapshot) {
              final details = detailSnapshot.data ?? const <OrderDetail>[];

              return StreamBuilder<List<FoodCategory>>(
                stream: _controller.watchCategories(),
                builder: (context, categorySnapshot) {
                  final categories =
                      categorySnapshot.data ?? const <FoodCategory>[];

                  return StreamBuilder<List<Food>>(
                    stream: _controller.watchFoods(),
                    builder: (context, foodSnapshot) {
                      final foods = foodSnapshot.data ?? const <Food>[];

                      return StreamBuilder<List<FoodVariant>>(
                        stream: _controller.watchVariants(),
                        builder: (context, variantSnapshot) {
                          final variants =
                              variantSnapshot.data ?? const <FoodVariant>[];

                          if (orderSnapshot.hasError ||
                              detailSnapshot.hasError ||
                              categorySnapshot.hasError ||
                              foodSnapshot.hasError ||
                              variantSnapshot.hasError) {
                            return const _ErrorState();
                          }

                          final isLoading =
                              categorySnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              foodSnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              variantSnapshot.connectionState ==
                                  ConnectionState.waiting;

                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              final filteredFoods = _controller.filterFoods(
                                foods,
                              );

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 980;
                                  final pagePadding = constraints.maxWidth < 480
                                      ? 10.0
                                      : 16.0;
                                  final orderPanelWidth =
                                      constraints.maxWidth < 1180
                                      ? 360.0
                                      : 420.0;

                                  final orderPanel = Column(
                                    children: [
                                      _OrderHeader(
                                        order: order,
                                        table: widget.table,
                                      ),
                                      const SizedBox(height: 12),
                                      if (_isOrderDetailsExpanded)
                                        _OrderDetailsPanel(
                                          details: details,
                                          variants: variants,
                                          controller: _controller,
                                          onConfirm: _confirmPendingItems,
                                          onQuantityChanged: _changeQuantity,
                                          onVariantChanged: _changeVariant,
                                          onNoteChanged: _editNote,
                                          onDelete: _deleteDetail,
                                        )
                                      else
                                        Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.playlist_add_check,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Order hiện tại',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                            ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${details.length} món',
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _isOrderDetailsExpanded =
                                                  !_isOrderDetailsExpanded;
                                            });
                                          },
                                          icon: Icon(
                                            _isOrderDetailsExpanded
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                          ),
                                          label: Text(
                                            _isOrderDetailsExpanded
                                                ? 'Thu gọn'
                                                : 'Xem order',
                                          ),
                                        ),
                                      ),
                                      if (_selectedFood != null &&
                                          _selectedVariant != null) ...[
                                        const SizedBox(height: 12),
                                        _AddItemPanel(
                                          food: _selectedFood!,
                                          variant: _selectedVariant!,
                                          quantityController:
                                              _quantityController,
                                          noteController: _noteController,
                                          isAdding: _controller.isAdding,
                                          errorMessage:
                                              _controller.errorMessage,
                                          onCancel: _clearSelection,
                                          onAdd: _addSelectedItem,
                                        ),
                                      ],
                                    ],
                                  );

                                  final menuPanel = _MenuPanel(
                                    categories: categories,
                                    foods: filteredFoods,
                                    variants: variants,
                                    controller: _controller,
                                    isLoading: isLoading,
                                    onVariantTap: _selectVariant,
                                  );

                                  return ListView(
                                    padding: EdgeInsets.all(pagePadding),
                                    children: [
                                      if (wide)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: orderPanelWidth,
                                              child: orderPanel,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(child: menuPanel),
                                          ],
                                        )
                                      else ...[
                                        orderPanel,
                                        const SizedBox(height: 16),
                                        menuPanel,
                                      ],
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Chọn món và biến thể từ menu để mở form thêm vào order.
  void _selectVariant(Food food, FoodVariant variant) {
    setState(() {
      _selectedFood = food;
      _selectedVariant = variant;
      _quantityController.text = '1';
      _noteController.clear();
    });
    _controller.clearError();
  }

  // Xóa món đang chọn khỏi form thêm món.
  void _clearSelection() {
    setState(() {
      _selectedFood = null;
      _selectedVariant = null;
      _quantityController.text = '1';
      _noteController.clear();
    });
    _controller.clearError();
  }

  // Thêm món mới vào order với số lượng và ghi chú hiện tại.
  Future<void> _addSelectedItem() async {
    final food = _selectedFood;
    final variant = _selectedVariant;
    if (food == null || variant == null) return;

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final added = await _controller.addItem(
      orderId: widget.order.id,
      food: food,
      variant: variant,
      quantity: quantity,
      note: _noteController.text,
    );

    if (!mounted || !added) return;

    _showMessage('Đã thêm ${food.name} vào order.');
    _clearSelection();
  }

  // Khóa các món mới gọi để nhân viên không sửa lại số lượng/size/ghi chú.
  Future<void> _confirmPendingItems() async {
    final confirmed = await _controller.confirmPendingItems(widget.order.id);
    if (!mounted) return;

    if (confirmed) {
      _showMessage('Đã xác nhận các món mới gọi.');
    } else {
      _showMessage(_controller.errorMessage ?? 'Không thể xác nhận gọi món.');
    }
  }

  // Tăng hoặc giảm số lượng món chưa xác nhận.
  Future<void> _changeQuantity(OrderDetail detail, int quantity) async {
    final updated = await _controller.updateQuantity(
      detail: detail,
      quantity: quantity,
    );
    if (!mounted || updated) return;

    _showMessage(_controller.errorMessage ?? 'Không thể sửa số lượng.');
  }

  // Đổi size/biến thể của món chưa xác nhận.
  Future<void> _changeVariant(OrderDetail detail, FoodVariant variant) async {
    final updated = await _controller.updateVariant(
      detail: detail,
      variant: variant,
    );
    if (!mounted || updated) return;

    _showMessage(_controller.errorMessage ?? 'Không thể đổi size món.');
  }

  // Sửa ghi chú cho món chưa xác nhận.
  Future<void> _editNote(OrderDetail detail) async {
    var draftNote = detail.note;
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sửa ghi chú'),
          content: TextFormField(
            initialValue: detail.note,
            autofocus: true,
            onChanged: (value) => draftNote = value,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              hintText: 'Ví dụ: ít cay, không đá, không hành',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(draftNote.trim()),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
    if (!mounted || note == null) return;

    final updated = await _controller.updateNote(detail: detail, note: note);
    if (!mounted || updated) return;

    _showMessage(_controller.errorMessage ?? 'Không thể sửa ghi chú.');
  }

  // Xóa món chưa xác nhận khỏi order.
  Future<void> _deleteDetail(OrderDetail detail) async {
    final deleted = await _controller.deleteItem(detail);
    if (!mounted) return;

    if (deleted) {
      _showMessage('Đã xóa món khỏi order.');
    } else {
      _showMessage(_controller.errorMessage ?? 'Không thể xóa món.');
    }
  }

  // Hiển thị thông báo ngắn sau thao tác gọi món.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
