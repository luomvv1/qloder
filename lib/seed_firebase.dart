import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SeedApp());
}

class SeedApp extends StatefulWidget {
  const SeedApp({super.key});

  @override
  State<SeedApp> createState() => _SeedAppState();
}

class _SeedAppState extends State<SeedApp> {
  late final Future<void> _seedFuture = seedSampleData();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Seed Firebase')),
        body: Center(
          child: FutureBuilder<void>(
            future: _seedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Dang tao du lieu mau...'),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Loi khi tao du lieu mau:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return const Text('Da tao du lieu mau Firebase thanh cong.');
            },
          ),
        ),
      ),
    );
  }
}

Future<void> seedSampleData() async {
  await ensureSampleAuthAccounts();

  final db = FirebaseFirestore.instance;
  final batch = db.batch();
  final now = Timestamp.now();

  void setDoc(String collection, String id, Map<String, dynamic> data) {
    batch.set(db.collection(collection).doc(id), data);
  }

  setDoc('settings', 'setting01', {
    'restaurantName': 'Nha hang QLMA',
    'pointRate': 10000,
    'pointValue': 1000,
    'invoiceCurrentNumber': 2,
  });

  setDoc('users', 'user01', {
    'fullName': 'Quan tri vien',
    'email': 'admin@gmail.com',
    'phone': '0909000000',
    'role': 'admin',
    'isActive': true,
    'createdAt': now,
  });

  setDoc('users', 'user02', {
    'fullName': 'Tran Thi Nhan',
    'email': 'staff@gmail.com',
    'phone': '0912345678',
    'role': 'staff',
    'isActive': true,
    'createdAt': now,
  });

  setDoc('customers', 'customer01', {
    'fullName': 'Nguyen Van An',
    'phone': '0987654321',
    'points': 112,
    'createdAt': now,
  });

  setDoc('customers', 'customer02', {
    'fullName': 'Le Thi Binh',
    'phone': '0977000000',
    'points': 45,
    'createdAt': now,
  });

  setDoc('categories', 'category01', {'name': 'Nuoc uong', 'isActive': true});

  setDoc('categories', 'category02', {'name': 'Mon chinh', 'isActive': true});

  setDoc('categories', 'category03', {'name': 'Lau', 'isActive': true});

  setDoc('foods', 'food01', {
    'name': 'Tra sua truyen thong',
    'categoryId': 'category01',
    'description': 'Tra sua vi truyen thong',
    'imageUrl': 'https://example.com/tra-sua.jpg',
    'status': 'available',
    'minPrice': 25000,
  });

  setDoc('foods', 'food02', {
    'name': 'Com chien hai san',
    'categoryId': 'category02',
    'description': 'Com chien voi tom, muc va rau cu',
    'imageUrl': 'https://example.com/com-chien.jpg',
    'status': 'available',
    'minPrice': 50000,
  });

  setDoc('foods', 'food03', {
    'name': 'Lau thai',
    'categoryId': 'category03',
    'description': 'Lau thai chua cay',
    'imageUrl': 'https://example.com/lau-thai.jpg',
    'status': 'available',
    'minPrice': 199000,
  });

  setDoc('food_variants', 'variant01', {
    'foodId': 'food01',
    'name': 'Size S',
    'price': 25000,
    'unit': 'Ly',
    'isActive': true,
  });

  setDoc('food_variants', 'variant02', {
    'foodId': 'food01',
    'name': 'Size M',
    'price': 30000,
    'unit': 'Ly',
    'isActive': true,
  });

  setDoc('food_variants', 'variant03', {
    'foodId': 'food01',
    'name': 'Size L',
    'price': 35000,
    'unit': 'Ly',
    'isActive': true,
  });

  setDoc('food_variants', 'variant04', {
    'foodId': 'food02',
    'name': 'Thuong',
    'price': 50000,
    'unit': 'Phan',
    'isActive': true,
  });

  setDoc('food_variants', 'variant05', {
    'foodId': 'food02',
    'name': 'Lon',
    'price': 65000,
    'unit': 'Phan',
    'isActive': true,
  });

  setDoc('food_variants', 'variant06', {
    'foodId': 'food03',
    'name': 'Nho',
    'price': 199000,
    'unit': 'Noi',
    'isActive': true,
  });

  setDoc('food_variants', 'variant07', {
    'foodId': 'food03',
    'name': 'Lon',
    'price': 299000,
    'unit': 'Noi',
    'isActive': true,
  });

  setDoc('tables', 'table01', {
    'name': 'Ban 01',
    'status': 'serving',
    'currentOrderId': 'order01',
  });

  setDoc('tables', 'table02', {
    'name': 'Ban 02',
    'status': 'empty',
    'currentOrderId': null,
  });

  setDoc('tables', 'table03', {
    'name': 'Ban 03',
    'status': 'reserved',
    'currentOrderId': null,
  });

  setDoc('orders', 'order01', {
    'tableId': 'table01',
    'status': 'open',
    'subtotal': 424000,
    'createdBy': 'user02',
    'createdAt': now,
  });

  setDoc('orders', 'order02', {
    'tableId': 'table02',
    'status': 'paid',
    'subtotal': 125000,
    'createdBy': 'user02',
    'createdAt': now,
  });

  setDoc('order_details', 'detail01', {
    'orderId': 'order01',
    'foodId': 'food01',
    'variantId': 'variant02',
    'foodName': 'Tra sua truyen thong',
    'variantName': 'Size M',
    'unitPrice': 30000,
    'quantity': 2,
    'note': 'It da',
    'lineTotal': 60000,
  });

  setDoc('order_details', 'detail02', {
    'orderId': 'order01',
    'foodId': 'food02',
    'variantId': 'variant05',
    'foodName': 'Com chien hai san',
    'variantName': 'Lon',
    'unitPrice': 65000,
    'quantity': 1,
    'note': 'Khong hanh',
    'lineTotal': 65000,
  });

  setDoc('order_details', 'detail03', {
    'orderId': 'order01',
    'foodId': 'food03',
    'variantId': 'variant07',
    'foodName': 'Lau thai',
    'variantName': 'Lon',
    'unitPrice': 299000,
    'quantity': 1,
    'note': 'It cay',
    'lineTotal': 299000,
  });

  setDoc('order_details', 'detail04', {
    'orderId': 'order02',
    'foodId': 'food01',
    'variantId': 'variant03',
    'foodName': 'Tra sua truyen thong',
    'variantName': 'Size L',
    'unitPrice': 35000,
    'quantity': 1,
    'note': 'Khong da',
    'lineTotal': 35000,
  });

  setDoc('order_details', 'detail05', {
    'orderId': 'order02',
    'foodId': 'food02',
    'variantId': 'variant04',
    'foodName': 'Com chien hai san',
    'variantName': 'Thuong',
    'unitPrice': 50000,
    'quantity': 1,
    'note': '',
    'lineTotal': 50000,
  });

  setDoc('order_details', 'detail06', {
    'orderId': 'order02',
    'foodId': 'food01',
    'variantId': 'variant02',
    'foodName': 'Tra sua truyen thong',
    'variantName': 'Size M',
    'unitPrice': 30000,
    'quantity': 1,
    'note': 'It duong',
    'lineTotal': 30000,
  });

  setDoc('invoices', 'invoice01', {
    'invoiceNo': 'HD000001',
    'orderId': 'order02',
    'tableId': 'table02',
    'customerId': 'customer01',
    'subtotal': 125000,
    'discountAmount': 10000,
    'pointsUsed': 20,
    'pointsEarned': 12,
    'totalAmount': 95000,
    'paymentMethod': 'cash',
    'paidBy': 'user02',
    'paidAt': now,
  });

  await batch.commit();
}

Future<void> ensureSampleAuthAccounts() async {
  final auth = FirebaseAuth.instance;

  await createOrSignInSampleUser(
    auth: auth,
    email: 'admin@gmail.com',
    password: '123456',
  );

  await createOrSignInSampleUser(
    auth: auth,
    email: 'staff@gmail.com',
    password: '123456',
  );
}

Future<void> createOrSignInSampleUser({
  required FirebaseAuth auth,
  required String email,
  required String password,
}) async {
  try {
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  } on FirebaseAuthException catch (error) {
    if (error.code == 'email-already-in-use') {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      return;
    }

    rethrow;
  }
}
