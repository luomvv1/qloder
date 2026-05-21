import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  const Customer({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.points,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final int points;
  final Timestamp? createdAt;

  factory Customer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Customer(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      points: (data['points'] as num? ?? 0).toInt(),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
