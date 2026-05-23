part of order_items_view;

// Header hiển thị mã order, bàn đang phục vụ và tạm tính.
class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order, required this.table});

  final RestaurantOrder order;
  final RestaurantTable table;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            child: const Icon(Icons.receipt_long, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text('${table.name} - Đang phục vụ'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Tạm tính'),
              Text(
                formatMoney(order.subtotal),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Khung danh sách món trong order và nút xác nhận món mới gọi.
class _OrderDetailsPanel extends StatelessWidget {
  const _OrderDetailsPanel({
    required this.details,
    required this.variants,
    required this.controller,
    required this.onConfirm,
    required this.onQuantityChanged,
    required this.onVariantChanged,
    required this.onNoteChanged,
    required this.onDelete,
  });

  final List<OrderDetail> details;
  final List<FoodVariant> variants;
  final OrderItemsController controller;
  final VoidCallback onConfirm;
  final void Function(OrderDetail detail, int quantity) onQuantityChanged;
  final void Function(OrderDetail detail, FoodVariant variant) onVariantChanged;
  final ValueChanged<OrderDetail> onNoteChanged;
  final ValueChanged<OrderDetail> onDelete;

  @override
  Widget build(BuildContext context) {
    final pendingCount = details.where((detail) => detail.isPending).length;
    final isBusy = controller.isUpdating || controller.isConfirming;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.playlist_add_check),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order hiện tại',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text('${details.length} món'),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: pendingCount > 0 && !isBusy ? onConfirm : null,
              icon: controller.isConfirming
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(
                pendingCount > 0
                    ? 'Xác nhận $pendingCount món mới'
                    : 'Chưa có món mới cần xác nhận',
              ),
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                controller.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (details.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Khách chưa gọi món.')),
              )
            else
              for (final detail in details)
                _OrderDetailTile(
                  detail: detail,
                  variants: variants
                      .where((variant) => variant.foodId == detail.foodId)
                      .toList(),
                  isBusy: isBusy,
                  onQuantityChanged: onQuantityChanged,
                  onVariantChanged: onVariantChanged,
                  onNoteChanged: onNoteChanged,
                  onDelete: onDelete,
                ),
          ],
        ),
      ),
    );
  }
}

// Một dòng món trong order: tên món, size, số lượng, ghi chú và thao tác sửa/xóa.
class _OrderDetailTile extends StatelessWidget {
  const _OrderDetailTile({
    required this.detail,
    required this.variants,
    required this.isBusy,
    required this.onQuantityChanged,
    required this.onVariantChanged,
    required this.onNoteChanged,
    required this.onDelete,
  });

  final OrderDetail detail;
  final List<FoodVariant> variants;
  final bool isBusy;
  final void Function(OrderDetail detail, int quantity) onQuantityChanged;
  final void Function(OrderDetail detail, FoodVariant variant) onVariantChanged;
  final ValueChanged<OrderDetail> onNoteChanged;
  final ValueChanged<OrderDetail> onDelete;

  @override
  Widget build(BuildContext context) {
    final canEdit = detail.isPending && !isBusy;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: detail.isPending
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text('${detail.quantity}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.foodName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${detail.variantName} - ${formatMoney(detail.unitPrice)}',
                    ),
                    if (detail.note.isNotEmpty)
                      Text(
                        'Ghi chú: ${detail.note}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(detail.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  _StatusChip(detail: detail),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (detail.isPending)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Giảm số lượng',
                  onPressed: canEdit
                      ? () => onQuantityChanged(detail, detail.quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                IconButton.filledTonal(
                  tooltip: 'Tăng số lượng',
                  onPressed: canEdit
                      ? () => onQuantityChanged(detail, detail.quantity + 1)
                      : null,
                  icon: const Icon(Icons.add),
                ),
                PopupMenuButton<FoodVariant>(
                  tooltip: 'Đổi size',
                  enabled: canEdit && variants.isNotEmpty,
                  onSelected: (variant) => onVariantChanged(detail, variant),
                  itemBuilder: (context) {
                    return [
                      for (final variant in variants)
                        PopupMenuItem(
                          value: variant,
                          child: Row(
                            children: [
                              Icon(
                                variant.id == detail.variantId
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${variant.name} - ${formatMoney(variant.price)}',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ];
                  },
                  child: const _SmallActionChip(
                    icon: Icons.tune,
                    label: 'Đổi size',
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.note_alt_outlined),
                  label: const Text('Ghi chú'),
                  onPressed: canEdit ? () => onNoteChanged(detail) : null,
                ),
                ActionChip(
                  avatar: const Icon(Icons.delete_outline),
                  label: const Text('Xóa'),
                  onPressed: canEdit ? () => onDelete(detail) : null,
                ),
              ],
            )
          else
            const Align(
              alignment: Alignment.centerRight,
              // child: _SmallActionChip(
              //   icon: Icons.lock,
              //   label: 'Đã khóa, chỉ có thể gọi thêm món mới',
              // ),
            ),
        ],
      ),
    );
  }
}

// Chip hiển thị trạng thái món: chưa xác nhận hoặc đã xác nhận.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final color = detail.isPending
        ? Theme.of(context).colorScheme.secondaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: color,
      label: Text(detail.statusLabel),
    );
  }
}

// Chip nhỏ dùng cho các trạng thái phụ như đã khóa, đổi size.
class _SmallActionChip extends StatelessWidget {
  const _SmallActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// Form thêm món đã chọn vào order: số lượng, ghi chú và nút thêm.
class _AddItemPanel extends StatelessWidget {
  const _AddItemPanel({
    required this.food,
    required this.variant,
    required this.quantityController,
    required this.noteController,
    required this.isAdding,
    required this.errorMessage,
    required this.onCancel,
    required this.onAdd,
  });

  final Food food;
  final FoodVariant variant;
  final TextEditingController quantityController;
  final TextEditingController noteController;
  final bool isAdding;
  final String? errorMessage;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.primary,
                  child: const Icon(Icons.add_shopping_cart),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thêm món mới',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bỏ chọn',
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: _FoodImage(imageUrl: food.imageUrl, height: 84),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(icon: Icons.tune, label: variant.name),
                          _InfoPill(
                            icon: Icons.payments_outlined,
                            label: formatMoney(variant.price),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Ví dụ: ít cay, không đá, không hành',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: isAdding ? null : onAdd,
              icon: isAdding
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Thêm vào order'),
            ),
          ],
        ),
      ),
    );
  }
}

// Khung menu gọi món gồm ô tìm kiếm, lọc danh mục và lưới món ăn.
class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.categories,
    required this.foods,
    required this.variants,
    required this.controller,
    required this.isLoading,
    required this.onVariantTap,
  });

  final List<FoodCategory> categories;
  final List<Food> foods;
  final List<FoodVariant> variants;
  final OrderItemsController controller;
  final bool isLoading;
  final void Function(Food food, FoodVariant variant) onVariantTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Menu gọi món',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text('${foods.length} món'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm món',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CategoryFilter(categories: categories, controller: controller),
              ],
            ),
            if (controller.selectedCategoryId != 'all') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text(_selectedCategoryName(categories, controller)),
                  onDeleted: () => controller.selectCategory('all'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (foods.isEmpty)
              const _EmptyMenuPanel()
            else
              _FoodGrid(
                foods: foods,
                variants: variants,
                controller: controller,
                onVariantTap: onVariantTap,
              ),
          ],
        ),
      ),
    );
  }
}

// Thanh lọc món ăn theo danh mục.
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.categories, required this.controller});

  final List<FoodCategory> categories;
  final OrderItemsController controller;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Lọc danh mục',
      child: SizedBox(
        width: 54,
        height: 56,
        child: OutlinedButton(
          onPressed: () => _showCategorySheet(context),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(Icons.menu),
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                'Chọn danh mục',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              _CategoryOptionTile(
                title: 'Tất cả món',
                selected: controller.selectedCategoryId == 'all',
                onTap: () {
                  controller.selectCategory('all');
                  Navigator.of(sheetContext).pop();
                },
              ),
              for (final category in categories)
                _CategoryOptionTile(
                  title: category.name,
                  selected: controller.selectedCategoryId == category.id,
                  onTap: () {
                    controller.selectCategory(category.id);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

String _selectedCategoryName(
  List<FoodCategory> categories,
  OrderItemsController controller,
) {
  if (controller.selectedCategoryId == 'all') return 'Tất cả';
  for (final category in categories) {
    if (category.id == controller.selectedCategoryId) return category.name;
  }
  return 'Tất cả';
}

class _CategoryOptionTile extends StatelessWidget {
  const _CategoryOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? colorScheme.primary : null,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// Lưới hiển thị các món ăn sau khi tìm kiếm/lọc danh mục.
class _FoodGrid extends StatelessWidget {
  const _FoodGrid({
    required this.foods,
    required this.variants,
    required this.controller,
    required this.onVariantTap,
  });

  final List<Food> foods;
  final List<FoodVariant> variants;
  final OrderItemsController controller;
  final void Function(Food food, FoodVariant variant) onVariantTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 340
            ? 2
            : 1;
        final compactCards = columns == 2 && constraints.maxWidth < 560;
        final itemExtent = columns == 1
            ? 390.0
            : compactCards
            ? 286.0
            : 370.0;

        return GridView.builder(
          itemCount: foods.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: itemExtent,
          ),
          itemBuilder: (context, index) {
            final food = foods[index];
            return _FoodCard(
              food: food,
              variants: controller.variantsForFood(food.id, variants),
              compact: compactCards,
              onVariantTap: (variant) => onVariantTap(food, variant),
            );
          },
        );
      },
    );
  }
}

// Ảnh món ăn lấy từ URL; nếu lỗi sẽ hiện ảnh mặc định.
class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.imageUrl, required this.height});

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl.trim();

    if (trimmedUrl.isEmpty) {
      return _FoodImageFallback(height: height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: trimmedUrl.startsWith('lib/images/')
            ? Image.asset(
                trimmedUrl,
                height: height,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _FoodImageFallback(height: height);
                },
              )
            : Image.network(
                trimmedUrl,
                height: height,
                width: double.infinity,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return _FoodImageLoading(height: height);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _FoodImageFallback(height: height);
                },
              ),
      ),
    );
  }
}

// Trạng thái loading khi ảnh món ăn đang tải.
class _FoodImageLoading extends StatelessWidget {
  const _FoodImageLoading({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

// Ảnh mặc định khi món chưa có ảnh hoặc URL ảnh lỗi.
class _FoodImageFallback extends StatelessWidget {
  const _FoodImageFallback({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.restaurant_menu,
        color: colorScheme.onPrimaryContainer,
        size: 34,
      ),
    );
  }
}

// Card món ăn trong menu, bấm để chọn size/biến thể.
class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.food,
    required this.variants,
    required this.compact,
    required this.onVariantTap,
  });

  final Food food;
  final List<FoodVariant> variants;
  final bool compact;
  final ValueChanged<FoodVariant> onVariantTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageHeight = compact ? 96.0 : 122.0;
    final variantHeight = compact ? 52.0 : 112.0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: variants.isEmpty ? null : () => _showFoodOptions(context),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _FoodImage(imageUrl: food.imageUrl, height: imageHeight),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Từ ${formatMoney(food.minPrice)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                food.description,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (variants.isEmpty)
                const Text('Chưa có biến thể giá.')
              else if (compact)
                SizedBox(
                  height: variantHeight,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showFoodOptions(context),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text('Chọn(${variants.length})'),
                  ),
                )
              else
                SizedBox(
                  height: variantHeight,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: compact ? 0 : 8,
                      runSpacing: 8,
                      children: [
                        for (final variant in variants)
                          _VariantButton(
                            variant: variant,
                            fullWidth: compact,
                            onTap: () => onVariantTap(variant),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFoodOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FoodImage(imageUrl: food.imageUrl, height: 180),
                  const SizedBox(height: 14),
                  Text(
                    food.name,
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (food.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      food.description,
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Chọn',
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  for (final variant in variants)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.58,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          leading: Icon(
                            Icons.add_circle_outline,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            variant.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          trailing: Text(
                            formatMoney(variant.price),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            onVariantTap(variant);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Nút chọn từng biến thể/size của món ăn.
class _VariantButton extends StatelessWidget {
  const _VariantButton({
    required this.variant,
    required this.fullWidth,
    required this.onTap,
  });

  final FoodVariant variant;
  final bool fullWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width - 72;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: fullWidth ? double.infinity : 0,
        maxWidth: fullWidth
            ? double.infinity
            : maxWidth.clamp(180.0, 260.0).toDouble(),
      ),
      child: Material(
        color: colorScheme.primaryContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    variant.name,
                    maxLines: fullWidth ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (fullWidth) const Spacer(),
                Text(
                  formatMoney(variant.price),
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.72,
                    ),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Trạng thái khi không có món nào phù hợp với tìm kiếm/lọc.
class _EmptyMenuPanel extends StatelessWidget {
  const _EmptyMenuPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: Text('Không có món phù hợp.')),
    );
  }
}

// Trạng thái lỗi khi không đọc được dữ liệu order/menu từ Firebase.
class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Không đọc được dữ liệu order hoặc món ăn.'),
      ),
    );
  }
}

// Định dạng tiền Việt: 25000 -> 25.000đ.
String formatMoney(num value) {
  final text = value.round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    final indexFromEnd = text.length - i;
    buffer.write(text[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return '$bufferđ';
}
