import 'package:flutter/material.dart';

import '../../controllers/theme_controller.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../invoices/invoice_list_view.dart';
import '../staff/staff_tables_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    if (user.isAdmin) {
      return AdminDashboardView(user: user);
    }
    return StaffWorkspaceView(user: user);
  }
}

void _openInvoices(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const InvoiceListView()));
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nhà hàng'),
        actions: [
          _ThemeToggleButton(),
          IconButton(
            tooltip: 'Thông tin cá nhân',
            onPressed: () => _showProfileDialog(context, user),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomePanel(
            title: 'Xin chào, ${user.fullName}',
            subtitle: 'Theo dõi nhanh hoạt động order theo bàn',
            icon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      StaffWorkspaceView(user: user, showBackButton: true),
                ),
              );
            },
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Mở giao diện nhân viên'),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Khu vực quản lý'),
          const SizedBox(height: 12),
          _ActionGrid(
            actions: [
              _ActionData(
                icon: Icons.restaurant_menu,
                title: 'Món ăn',
                subtitle: 'Thêm, sửa, trạng thái món',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.category_outlined,
                title: 'Danh mục',
                subtitle: 'Món chính, nước uống, lẩu',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.table_bar,
                title: 'Bàn ăn',
                subtitle: 'Sơ đồ và trạng thái bàn',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.badge_outlined,
                title: 'Nhân viên',
                subtitle: 'Tài khoản và phân quyền',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.payments_outlined,
                title: 'Hóa đơn',
                subtitle: 'Tra cứu hóa đơn đã thanh toán',
                onTap: () => _openInvoices(context),
              ),
              _ActionData(
                icon: Icons.bar_chart,
                title: 'Thống kê',
                subtitle: 'Doanh thu và món bán chạy',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StaffWorkspaceView extends StatelessWidget {
  const StaffWorkspaceView({
    super.key,
    required this.user,
    this.showBackButton = false,
  });

  final AppUser user;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: showBackButton ? const BackButton() : null,
        title: const Text('Nhân viên phục vụ'),
        actions: [
          _ThemeToggleButton(),
          IconButton(
            tooltip: 'Thông tin cá nhân',
            onPressed: () => _showProfileDialog(context, user),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          if (!showBackButton)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () => AuthService().signOut(),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomePanel(
            title: 'Xin chào, ${user.fullName}',
            subtitle: 'Quản lý order theo bàn trong ca làm',
            icon: Icons.room_service_outlined,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openStaffTables(context),
            icon: const Icon(Icons.table_restaurant),
            label: const Text('Mở sơ đồ bàn'),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Chức năng phục vụ hiện có'),
          const SizedBox(height: 12),
          _ActionGrid(
            actions: [
              _ActionData(
                icon: Icons.add_shopping_cart,
                title: 'Tạo order',
                subtitle: 'Chọn bàn, mở order mới',
                onTap: () =>
                    _openStaffTables(context, StaffTableMode.createOrder),
              ),
              _ActionData(
                icon: Icons.playlist_add,
                title: 'Thêm món',
                subtitle: 'Chọn món, size, số lượng',
                onTap: () => _openStaffTables(context, StaffTableMode.addFood),
              ),
              _ActionData(
                icon: Icons.check_circle_outline,
                title: 'Xác nhận món',
                subtitle: 'Khóa món đã gửi bếp',
                onTap: () =>
                    _openStaffTables(context, StaffTableMode.confirmFood),
              ),
              _ActionData(
                icon: Icons.swap_horiz,
                title: 'Chuyển bàn',
                subtitle: 'Chuyển order sang bàn khác',
                onTap: () => _openStaffTables(context, StaffTableMode.transfer),
              ),
              _ActionData(
                icon: Icons.call_merge,
                title: 'Gộp bàn',
                subtitle: 'Nhiều bàn dùng chung một order',
                onTap: () => _openStaffTables(context, StaffTableMode.merge),
              ),
              _ActionData(
                icon: Icons.payments_outlined,
                title: 'Thanh toán',
                subtitle: 'Giảm giá, điểm, xuất hóa đơn',
                onTap: () => _openStaffTables(context, StaffTableMode.payment),
              ),
              _ActionData(
                icon: Icons.person_search_outlined,
                title: 'Thành viên',
                subtitle: 'Tìm hoặc thêm nhanh theo SĐT',
                onTap: () => _openStaffTables(context, StaffTableMode.payment),
              ),
              _ActionData(
                icon: Icons.receipt_long,
                title: 'Order hiện tại',
                subtitle: 'Xem chi tiết món theo bàn',
                onTap: () =>
                    _openStaffTables(context, StaffTableMode.currentOrders),
              ),
              _ActionData(
                icon: Icons.manage_search,
                title: 'Hóa đơn',
                subtitle: 'Xem hóa đơn đã thanh toán',
                onTap: () => _openInvoices(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openStaffTables(
    BuildContext context, [
    StaffTableMode mode = StaffTableMode.normal,
  ]) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => StaffTablesView(mode: mode)));
  }

}

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;
        return IconButton(
          tooltip: isDark
              ? 'Đổi sang giao diện sáng'
              : 'Đổi sang giao diện tối',
          onPressed: ThemeController.instance.toggleTheme,
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        );
      },
    );
  }
}

Future<void> _showProfileDialog(BuildContext context, AppUser user) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Thông tin cá nhân'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileRow(label: 'Họ tên', value: user.fullName),
            _ProfileRow(label: 'Email', value: user.email),
            _ProfileRow(label: 'Số điện thoại', value: user.phone),
            _ProfileRow(
              label: 'Vai trò',
              value: user.isAdmin ? 'Quản lý' : 'Nhân viên',
            ),
            _ProfileRow(label: 'Mã tài khoản', value: user.id),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
        ],
      );
    },
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

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
            radius: 24,
            backgroundColor: colorScheme.primary,
            child: Icon(icon, color: colorScheme.onPrimary, size: 24),
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
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_ActionData> actions;

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
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 150,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: action.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(action.icon),
                      const SizedBox(height: 12),
                      Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActionData {
  const _ActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
