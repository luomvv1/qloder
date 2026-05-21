import 'package:flutter/material.dart';

import '../../controllers/order_controller.dart';
import '../../controllers/table_controller.dart';
import '../../models/restaurant_table.dart';
import 'order_items_view.dart';
import 'payment_view.dart';
import 'widgets/serving_table_actions.dart';

enum StaffTableMode {
  normal,
  createOrder,
  addFood,
  confirmFood,
  transfer,
  merge,
  payment,
  currentOrders,
}

extension StaffTableModeText on StaffTableMode {
  String get title {
    return switch (this) {
      StaffTableMode.normal => 'Sơ đồ bàn',
      StaffTableMode.createOrder => 'Tạo order',
      StaffTableMode.addFood => 'Thêm món',
      StaffTableMode.confirmFood => 'Xác nhận món',
      StaffTableMode.transfer => 'Chuyển bàn',
      StaffTableMode.merge => 'Gộp bàn',
      StaffTableMode.payment => 'Thanh toán',
      StaffTableMode.currentOrders => 'Order hiện tại',
    };
  }

  String get description {
    return switch (this) {
      StaffTableMode.normal => 'Chọn bàn để thao tác order',
      StaffTableMode.createOrder => 'Chọn bàn trống hoặc đã đặt để tạo order',
      StaffTableMode.addFood => 'Chọn bàn đang phục vụ để thêm món',
      StaffTableMode.confirmFood => 'Chọn bàn đang phục vụ để kiểm tra món mới',
      StaffTableMode.transfer => 'Chọn bàn đang phục vụ cần chuyển order',
      StaffTableMode.merge => 'Chọn bàn chính đang phục vụ để gộp bàn',
      StaffTableMode.payment => 'Chọn bàn đang phục vụ để thanh toán',
      StaffTableMode.currentOrders => 'Chọn bàn đang phục vụ để xem order',
    };
  }
}

class StaffTablesView extends StatefulWidget {
  const StaffTablesView({super.key, this.mode = StaffTableMode.normal});

  final StaffTableMode mode;

  @override
  State<StaffTablesView> createState() => _StaffTablesViewState();
}

class _StaffTablesViewState extends State<StaffTablesView> {
  late final TableController _controller = TableController();
  late final OrderController _orderController = OrderController();

  @override
  void initState() {
    super.initState();
    _controller.searchController.addListener(_controller.onSearchChanged);
  }

  @override
  void dispose() {
    _controller.searchController.removeListener(_controller.onSearchChanged);
    _orderController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Xây dựng màn hình sơ đồ bàn theo chế độ được chọn từ nút nhanh.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.title)),
      body: StreamBuilder<List<RestaurantTable>>(
        stream: _controller.tablesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          final tables = snapshot.data ?? const <RestaurantTable>[];

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final filteredTables = _modeFilteredTables(
                _controller.filterTables(tables),
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _TableHeader(
                    total: filteredTables.length,
                    title: widget.mode.title,
                    subtitle: widget.mode.description,
                  ),
                  const SizedBox(height: 16),
                  _StatusSummary(controller: _controller, tables: tables),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller.searchController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm bàn',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusFilter(controller: _controller),
                  const SizedBox(height: 16),
                  if (filteredTables.isEmpty)
                    const _EmptyState()
                  else
                    _TableGrid(
                      tables: filteredTables,
                      onTableTap: (table) => _handleTableTap(table, tables),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Lọc danh sách bàn theo chức năng nhanh: tạo order, thêm món, thanh toán...
  List<RestaurantTable> _modeFilteredTables(List<RestaurantTable> tables) {
    return switch (widget.mode) {
      StaffTableMode.createOrder =>
        tables.where((table) => table.isEmpty || table.isReserved).toList(),
      StaffTableMode.addFood ||
      StaffTableMode.confirmFood ||
      StaffTableMode.transfer ||
      StaffTableMode.merge ||
      StaffTableMode.payment ||
      StaffTableMode.currentOrders =>
        tables.where((table) => table.isServing).toList(),
      StaffTableMode.normal => tables,
    };
  }

  // Quyết định thao tác khi nhân viên bấm vào một bàn.
  void _handleTableTap(RestaurantTable table, List<RestaurantTable> tables) {
    switch (widget.mode) {
      case StaffTableMode.createOrder:
        _createOrder(table);
      case StaffTableMode.addFood:
      case StaffTableMode.confirmFood:
      case StaffTableMode.currentOrders:
        _openExistingOrder(table);
      case StaffTableMode.payment:
        _openPayment(table);
      case StaffTableMode.transfer:
        _openTransferTable(table, tables);
      case StaffTableMode.merge:
        _openMergeTable(table, tables);
      case StaffTableMode.normal:
        _showTableDetail(table, tables);
    }
  }

  // Hiển thị bảng thao tác đầy đủ khi mở sơ đồ bàn bình thường.
  void _showTableDetail(RestaurantTable table, List<RestaurantTable> tables) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final color = _statusColor(table.statusLabel);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(_statusIcon(table.statusLabel), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(table.statusLabel),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Mã bàn', value: table.id),
              _InfoRow(
                label: 'Order hiện tại',
                value: table.currentOrderId ?? 'Chưa có',
              ),
              const SizedBox(height: 18),
              if (_orderController.errorMessage != null) ...[
                Text(
                  _orderController.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (table.isEmpty || table.isReserved)
                FilledButton.icon(
                  onPressed: () => _createOrder(table, sheetContext),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(
                    table.isReserved
                        ? 'Nhận bàn và tạo order'
                        : 'Tạo order cho bàn này',
                  ),
                )
              else if (table.isServing)
                ServingTableActions(
                  onOpenOrder: () => _openExistingOrder(table, sheetContext),
                  onTransfer: () =>
                      _openTransferTable(table, tables, sheetContext),
                  onMerge: () => _openMergeTable(table, tables, sheetContext),
                  onPayment: () => _openPayment(table, sheetContext),
                  onCancel: () => _cancelOrder(table, sheetContext),
                ),
            ],
          ),
        );
      },
    );
  }

  // Tạo order mới cho bàn trống/đã đặt, sau đó mở ngay màn hình gọi món.
  Future<void> _createOrder(
    RestaurantTable table, [
    BuildContext? sheetContext,
  ]) async {
    final order = await _orderController.createOrderForTable(table);
    if (!mounted || order == null) return;

    if (sheetContext != null) {
      Navigator.of(sheetContext).pop();
      await Future<void>.delayed(Duration.zero);
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderItemsView(order: order, table: table),
      ),
    );
  }

  // Mở chi tiết order hiện tại để thêm món, sửa món chưa xác nhận hoặc xem món.
  Future<void> _openExistingOrder(
    RestaurantTable table, [
    BuildContext? sheetContext,
  ]) async {
    final orderId = table.currentOrderId;
    if (orderId == null || orderId.isEmpty) {
      if (sheetContext != null) {
        Navigator.of(sheetContext).pop();
        await Future<void>.delayed(Duration.zero);
      }

      if (!mounted) return;
      _showMessage('Bàn này chưa có order hiện tại.');
      return;
    }

    final order = await _orderController.getOrder(orderId);
    if (!mounted || order == null) return;

    if (sheetContext != null) {
      Navigator.of(sheetContext).pop();
      await Future<void>.delayed(Duration.zero);
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderItemsView(order: order, table: table),
      ),
    );
  }

  // Mở màn hình thanh toán cho order hiện tại của bàn.
  Future<void> _openPayment(
    RestaurantTable table, [
    BuildContext? sheetContext,
  ]) async {
    final orderId = table.currentOrderId;
    if (orderId == null || orderId.isEmpty) {
      if (sheetContext != null) {
        Navigator.of(sheetContext).pop();
        await Future<void>.delayed(Duration.zero);
      }

      if (!mounted) return;
      _showMessage('Bàn này chưa có order hiện tại.');
      return;
    }

    final order = await _orderController.getOrder(orderId);
    if (!mounted || order == null) return;

    if (sheetContext != null) {
      Navigator.of(sheetContext).pop();
      await Future<void>.delayed(Duration.zero);
    }

    if (!mounted) return;
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentView(order: order, table: table),
      ),
    );

    if (!mounted || paid != true) return;
    _showMessage('Thanh toán thành công. Bàn đã về trống.');
  }

  // Hủy order đang mở và trả bàn về trạng thái trống sau khi nhân viên xác nhận.
  Future<void> _cancelOrder(
    RestaurantTable table, [
    BuildContext? sheetContext,
  ]) async {
    final orderId = table.currentOrderId;
    if (orderId == null || orderId.isEmpty) {
      if (sheetContext != null) {
        Navigator.of(sheetContext).pop();
        await Future<void>.delayed(Duration.zero);
      }

      if (!mounted) return;
      _showMessage('Bàn này chưa có order hiện tại.');
      return;
    }

    if (sheetContext != null) {
      Navigator.of(sheetContext).pop();
      await Future<void>.delayed(Duration.zero);
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hủy order?'),
          content: Text(
            'Order $orderId của ${table.name} sẽ bị hủy và bàn sẽ chuyển về trạng thái trống.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hủy order'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final order = await _orderController.getOrder(orderId);
    if (!mounted || order == null) return;

    final canceled = await _orderController.cancelOrder(
      order: order,
      table: table,
    );

    if (!mounted) return;
    _showMessage(
      canceled
          ? 'Đã hủy $orderId. Bàn đã về trống.'
          : _orderController.errorMessage ?? 'Không thể hủy order.',
    );
  }

  // Chuyển order hiện tại sang một bàn trống/đã đặt.
  Future<void> _openTransferTable(
    RestaurantTable table,
    List<RestaurantTable> tables, [
    BuildContext? sheetContext,
  ]) async {
    final targets = _controller.transferTargets(tables, table);

    if (sheetContext != null) {
      Navigator.of(sheetContext).pop();
      await Future<void>.delayed(Duration.zero);
    }

    if (!mounted) return;

    if (targets.isEmpty) {
      _showMessage('Không có bàn trống để chuyển.');
      return;
    }

    final targetTable = await _pickTableDialog(
      title: 'Chuyển ${table.name} sang bàn',
      description: 'Chọn bàn trống hoặc bàn đã đặt để nhận order hiện tại.',
      tables: targets,
      icon: Icons.swap_horiz,
    );

    if (!mounted || targetTable == null) return;

    final transferred = await _controller.transferOrder(
      fromTable: table,
      toTable: targetTable,
    );

    if (!mounted) return;
    _showMessage(
      transferred
          ? 'Đã chuyển order từ ${table.name} sang ${targetTable.name}.'
          : _controller.transferErrorMessage ?? 'Không thể chuyển bàn.',
    );
  }

  // Gộp thêm bàn vào order đang phục vụ.
  Future<void> _openMergeTable(
    RestaurantTable table,
    List<RestaurantTable> tables, [
    BuildContext? sheetContext,
  ]) async {
    final targets = _controller.mergeTargets(tables, table);

    if (sheetContext != null) {
      Navigator.of(sheetContext).pop();
      await Future<void>.delayed(Duration.zero);
    }

    if (!mounted) return;

    if (targets.isEmpty) {
      _showMessage('Không có bàn phù hợp để gộp.');
      return;
    }

    final targetTable = await _pickTableDialog(
      title: 'Gộp bàn vào ${table.name}',
      description:
          'Chọn bàn trống/đã đặt để ghép thêm chỗ, hoặc bàn đang phục vụ để nhập order vào ${table.name}. Sau khi gộp, các bàn dùng chung một order.',
      tables: targets,
      icon: Icons.call_merge,
    );

    if (!mounted || targetTable == null) return;

    final merged = await _controller.mergeTables(
      keepTable: table,
      mergedTable: targetTable,
    );

    if (!mounted) return;
    _showMessage(
      merged
          ? 'Đã gộp ${targetTable.name} vào ${table.name}.'
          : _controller.transferErrorMessage ?? 'Không thể gộp bàn.',
    );
  }

  // Dialog chọn bàn đích cho chức năng chuyển bàn hoặc gộp bàn.
  Future<RestaurantTable?> _pickTableDialog({
    required String title,
    required String description,
    required List<RestaurantTable> tables,
    required IconData icon,
  }) {
    return showDialog<RestaurantTable>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(title),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Text(description),
            ),
            for (final table in tables)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(table),
                child: Row(
                  children: [
                    Icon(icon, color: _statusColor(table.statusLabel)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            table.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            table.currentOrderId == null
                                ? table.statusLabel
                                : '${table.statusLabel} - ${table.currentOrderId}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // Hiển thị thông báo ngắn cho nhân viên sau mỗi thao tác.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.total,
    required this.title,
    required this.subtitle,
  });

  final int total;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.table_bar, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text('$subtitle - $total bàn phù hợp'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.controller, required this.tables});

  final TableController controller;
  final List<RestaurantTable> tables;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Trống',
            value: controller.countByStatus(tables, 'Trống').toString(),
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Phục vụ',
            value: controller.countByStatus(tables, 'Đang phục vụ').toString(),
            color: const Color(0xFF0F766E),
            icon: Icons.room_service_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Đã đặt',
            value: controller.countByStatus(tables, 'Đã đặt').toString(),
            color: const Color(0xFFB45309),
            icon: Icons.event_available_outlined,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.controller});

  final TableController controller;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'Tất cả'),
      ('Trống', 'Trống'),
      ('Đang phục vụ', 'Đang phục vụ'),
      ('Đã đặt', 'Đã đặt'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            ChoiceChip(
              label: Text(filter.$2),
              selected: controller.selectedStatus == filter.$1,
              onSelected: (_) => controller.setStatus(filter.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TableGrid extends StatelessWidget {
  const _TableGrid({required this.tables, required this.onTableTap});

  final List<RestaurantTable> tables;
  final ValueChanged<RestaurantTable> onTableTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : 2;

        return GridView.builder(
          itemCount: tables.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 142,
          ),
          itemBuilder: (context, index) {
            final table = tables[index];
            return _TableCard(table: table, onTap: () => onTableTap(table));
          },
        );
      },
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table, required this.onTap});

  final RestaurantTable table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(table.statusLabel);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(_statusIcon(table.statusLabel), color: color),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey.shade500),
                ],
              ),
              const Spacer(),
              Text(
                table.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                table.statusLabel,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Không có bàn phù hợp.')),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Không đọc được danh sách bàn:\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'Trống' => const Color(0xFF16A34A),
    'Đang phục vụ' => const Color(0xFF0F766E),
    'Đã đặt' => const Color(0xFFB45309),
    _ => const Color(0xFF78716C),
  };
}

IconData _statusIcon(String status) {
  return switch (status) {
    'Trống' => Icons.check_circle_outline,
    'Đang phục vụ' => Icons.room_service_outlined,
    'Đã đặt' => Icons.event_available_outlined,
    _ => Icons.table_bar,
  };
}
