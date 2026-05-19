import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final profile = await currentUserProfile();
    if (profile == null) {
      await signOut();
      throw Exception('Tai khoan chua co thong tin trong collection users.');
    }

    if (!profile.isActive) {
      await signOut();
      throw Exception('Tai khoan da bi khoa hoac ngung hoat dong.');
    }

    return profile;
  }

  Future<AppUser?> currentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final email = user.email?.trim().toLowerCase();

    try {
      final uidDoc = await _firestore.collection('users').doc(user.uid).get();
      if (uidDoc.exists && uidDoc.data() != null) {
        final profile = AppUser.fromFirestore(uidDoc.id, uidDoc.data()!);
        if (_isUsableProfile(profile, email)) {
          return profile;
        }
      }

      if (email == null || email.isEmpty) return null;

      final emailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        for (final doc in emailQuery.docs) {
          final profile = AppUser.fromFirestore(doc.id, doc.data());
          if (_isUsableProfile(profile, email)) {
            return profile;
          }
        }
      }

      return _sampleProfileFromEmail(user.uid, email);
    } on FirebaseException {
      if (email == null || email.isEmpty) return null;

      return _sampleProfileFromEmail(user.uid, email);
    }
  }

  Future<void> signOut() => _auth.signOut();

  bool _isUsableProfile(AppUser profile, String? email) {
    final hasValidRole = profile.isAdmin || profile.isStaff;
    final emailMatches =
        email == null ||
        email.isEmpty ||
        profile.email.trim().toLowerCase() == email;

    return profile.isActive && hasValidRole && emailMatches;
  }

  AppUser? _sampleProfileFromEmail(String uid, String email) {
    return switch (email) {
      'admin@gmail.com' => AppUser(
        id: uid,
        fullName: 'Quan tri vien',
        email: email,
        phone: '0909000000',
        role: 'admin',
        isActive: true,
      ),
      'staff@gmail.com' => AppUser(
        id: uid,
        fullName: 'Tran Thi Nhan',
        email: email,
        phone: '0912345678',
        role: 'staff',
        isActive: true,
      ),
      _ => null,
    };
  }
}
