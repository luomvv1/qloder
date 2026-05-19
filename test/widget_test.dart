import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qloder/models/app_user.dart';
import 'package:qloder/views/home/home_view.dart';

void main() {
  testWidgets('Admin dashboard shows staff workspace button', (tester) async {
    const user = AppUser(
      id: 'user01',
      fullName: 'Quan tri vien',
      email: 'admin@gmail.com',
      phone: '0909000000',
      role: 'admin',
      isActive: true,
    );

    await tester.pumpWidget(const MaterialApp(home: HomeView(user: user)));

    expect(find.text('Vao giao dien nhan vien'), findsOneWidget);
    expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
  });
}
