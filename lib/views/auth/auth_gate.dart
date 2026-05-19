import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../home/home_view.dart';
import 'login_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (!snapshot.hasData) {
          return const LoginView();
        }

        return FutureBuilder<AppUser?>(
          future: authService.currentUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const _LoadingView();
            }

            if (profileSnapshot.hasError) {
              return _AuthErrorView(error: profileSnapshot.error.toString());
            }

            final appUser = profileSnapshot.data;
            if (appUser == null || !appUser.isActive) {
              return const LoginView();
            }

            return HomeView(user: appUser);
          },
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AuthErrorView extends StatelessWidget {
  const _AuthErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Khong doc duoc thong tin tai khoan',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => AuthService().signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Dang xuat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
