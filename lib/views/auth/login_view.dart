import 'package:flutter/material.dart';

import '../../controllers/login_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginController _controller = LoginController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(
                              child: _BrandPanel(colorScheme: colorScheme),
                            ),
                            const SizedBox(width: 28),
                            SizedBox(
                              width: 420,
                              child: _LoginForm(controller: _controller),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MobileHeader(),
                            const SizedBox(height: 24),
                            _LoginForm(controller: _controller),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7E5E4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dang nhap',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Su dung tai khoan admin hoac nhan vien',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(context),
                  decoration: InputDecoration(
                    labelText: 'Mat khau',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: controller.obscurePassword
                          ? 'Hien mat khau'
                          : 'An mat khau',
                      onPressed: controller.togglePasswordVisibility,
                      icon: Icon(
                        controller.obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _ErrorText(message: controller.errorMessage!),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: controller.isLoading
                      ? null
                      : () => _submit(context),
                  icon: controller.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Dang nhap'),
                ),
                const SizedBox(height: 18),
                const _SampleAccounts(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await controller.signIn();
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 500),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: colorScheme.primary,
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 180),
          Text(
            'QLMA',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Quan ly order mon an theo ban cho nha hang',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureChip(icon: Icons.table_bar, label: 'Ban an'),
              _FeatureChip(icon: Icons.receipt_long, label: 'Hoa don'),
              _FeatureChip(
                icon: Icons.people_alt_outlined,
                label: 'Thanh vien',
              ),
              _FeatureChip(icon: Icons.bar_chart, label: 'Thong ke'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: colorScheme.primary,
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'QLMA',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text('Quan ly order mon an theo ban'),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _SampleAccounts extends StatelessWidget {
  const _SampleAccounts();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Tai khoan mau:\nadmin@gmail.com / 123456\nstaff@gmail.com / 123456',
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
