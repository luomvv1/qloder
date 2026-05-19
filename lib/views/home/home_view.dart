import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';

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

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quan ly nha hang'),
        actions: [
          IconButton(
            tooltip: 'Dang xuat',
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomePanel(
            title: 'Xin chao, ${user.fullName}',
            subtitle: 'Dashboard quan ly he thong order theo ban',
            icon: Icons.admin_panel_settings_outlined,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
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
            icon: const Icon(Icons.storefront),
            label: const Text('Vao giao dien nhan vien'),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Tong quan nhanh'),
          const SizedBox(height: 12),
          const _MetricGrid(
            metrics: [
              _MetricData(
                title: 'Ban dang phuc vu',
                value: '1',
                icon: Icons.table_restaurant,
                color: Color(0xFF0F766E),
              ),
              _MetricData(
                title: 'Hoa don hom nay',
                value: '1',
                icon: Icons.receipt_long,
                color: Color(0xFFB45309),
              ),
              _MetricData(
                title: 'Mon dang ban',
                value: '3',
                icon: Icons.restaurant,
                color: Color(0xFF7C3AED),
              ),
              _MetricData(
                title: 'Thanh vien',
                value: '2',
                icon: Icons.people_alt_outlined,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Quan ly du lieu'),
          const SizedBox(height: 12),
          _ActionGrid(
            actions: [
              _ActionData(
                icon: Icons.restaurant_menu,
                title: 'Mon an',
                subtitle: 'Them, sua, an/hien mon',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.category_outlined,
                title: 'Danh muc',
                subtitle: 'Mon chinh, nuoc uong, lau',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.tune,
                title: 'Bien the',
                subtitle: 'Size, gia va don vi tinh',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.table_bar,
                title: 'Ban an',
                subtitle: 'Trang thai va order hien tai',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.badge_outlined,
                title: 'Nhan vien',
                subtitle: 'Tai khoan va phan quyen',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.person_search,
                title: 'Khach hang',
                subtitle: 'Thanh vien va diem tich luy',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.payments_outlined,
                title: 'Hoa don',
                subtitle: 'Tra cuu va xem chi tiet',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.bar_chart,
                title: 'Thong ke',
                subtitle: 'Doanh thu va mon ban chay',
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: showBackButton ? const BackButton() : null,
        title: const Text('Phuc vu'),
        actions: [
          if (!showBackButton)
            IconButton(
              tooltip: 'Dang xuat',
              onPressed: () => AuthService().signOut(),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomePanel(
            title: 'Ca lam cua ${user.fullName}',
            subtitle: 'Chon ban, tao order va thanh toan cho khach',
            icon: Icons.storefront,
            backgroundColor: const Color(0xFFFFF7ED),
            foregroundColor: const Color(0xFF9A3412),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Trang thai ban'),
          const SizedBox(height: 12),
          _TableStatusGrid(
            tables: [
              _TableData(
                name: 'Ban 01',
                status: 'Dang phuc vu',
                color: colorScheme.primary,
                icon: Icons.room_service_outlined,
              ),
              const _TableData(
                name: 'Ban 02',
                status: 'Trong',
                color: Color(0xFF16A34A),
                icon: Icons.check_circle_outline,
              ),
              const _TableData(
                name: 'Ban 03',
                status: 'Da dat',
                color: Color(0xFFB45309),
                icon: Icons.event_available_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Thao tac nhanh'),
          const SizedBox(height: 12),
          _ActionGrid(
            actions: [
              _ActionData(
                icon: Icons.add_shopping_cart,
                title: 'Tao order',
                subtitle: 'Chon ban va them mon',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.playlist_add,
                title: 'Them mon',
                subtitle: 'Them mon vao order dang mo',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.swap_horiz,
                title: 'Chuyen ban',
                subtitle: 'Doi ban cho order hien tai',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.call_merge,
                title: 'Gop ban',
                subtitle: 'Gop order cua nhieu ban',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.person_search,
                title: 'Tim thanh vien',
                subtitle: 'Tra cuu bang so dien thoai',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.person_add_alt,
                title: 'Them thanh vien',
                subtitle: 'Tao khach moi khi thanh toan',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.payments_outlined,
                title: 'Thanh toan',
                subtitle: 'Giam gia, diem va hoa don',
                onTap: () {},
              ),
              _ActionData(
                icon: Icons.receipt_long,
                title: 'Hoa don gan day',
                subtitle: 'Xem cac bill vua thanh toan',
                onTap: () {},
              ),
            ],
          ),
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
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: foregroundColor.withValues(alpha: 0.12),
            child: Icon(icon, color: foregroundColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor.withValues(alpha: 0.78),
                  ),
                ),
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
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;

        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(metric.icon, color: metric.color),
                    const Spacer(),
                    Text(
                      metric.value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      metric.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            mainAxisExtent: 148,
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
                      const Spacer(),
                      Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
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

class _TableStatusGrid extends StatelessWidget {
  const _TableStatusGrid({required this.tables});

  final List<_TableData> tables;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 1;

        return GridView.builder(
          itemCount: tables.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) {
            final table = tables[index];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: table.color.withValues(alpha: 0.12),
                  child: Icon(table.icon, color: table.color),
                ),
                title: Text(table.name),
                subtitle: Text(table.status),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
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

class _TableData {
  const _TableData({
    required this.name,
    required this.status,
    required this.color,
    required this.icon,
  });

  final String name;
  final String status;
  final Color color;
  final IconData icon;
}
