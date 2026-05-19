import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final Timestamp? createdAt;

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';

  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? 'staff',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
