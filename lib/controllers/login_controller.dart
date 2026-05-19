import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class LoginController extends ChangeNotifier {
  LoginController({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<AppUser?> signIn() async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      return await _authService.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      errorMessage = _messageFromAuthError(error.code);
      return null;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _messageFromAuthError(String code) {
    return switch (code) {
      'invalid-email' => 'Email khong hop le.',
      'user-disabled' => 'Tai khoan da bi khoa.',
      'user-not-found' => 'Khong tim thay tai khoan.',
      'wrong-password' => 'Mat khau khong dung.',
      'invalid-credential' => 'Email hoac mat khau khong dung.',
      _ => 'Dang nhap that bai. Vui long thu lai.',
    };
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
