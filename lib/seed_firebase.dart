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
        appBar: AppBar(title: const Text('Tạo dữ liệu mẫu Firebase')),
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
                    Text('Đang tạo dữ liệu mẫu...'),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Lỗi khi tạo dữ liệu mẫu:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return const Text('Đã tạo dữ liệu mẫu Firebase thành công.');
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
    'restaurantName': 'Nhà hàng QLMA',
    'pointRate': 10000,
    'pointValue': 1000,
    'orderCurrentNumber': 2,
    'invoiceCurrentNumber': 2,
  });

  setDoc('users', 'user01', {
    'fullName': 'Quản trị viên',
    'email': 'admin@gmail.com',
    'phone': '0909000000',
    'role': 'admin',
    'isActive': true,
    'createdAt': now,
  });

  setDoc('users', 'user02', {
    'fullName': 'Trần Thị Nhân',
    'email': 'staff@gmail.com',
    'phone': '0912345678',
    'role': 'staff',
    'isActive': true,
    'createdAt': now,
  });

  setDoc('customers', 'customer01', {
    'fullName': 'Nguyễn Văn An',
    'phone': '0987654321',
    'points': 112,
    'createdAt': now,
  });

  setDoc('customers', 'customer02', {
    'fullName': 'Lê Thị Bình',
    'phone': '0977000000',
    'points': 45,
    'createdAt': now,
  });

  setDoc('categories', 'category01', {'name': 'Nước uống', 'isActive': true});

  setDoc('categories', 'category02', {'name': 'Món chính', 'isActive': true});

  setDoc('categories', 'category03', {'name': 'Lẩu', 'isActive': true});

  setDoc('foods', 'food01', {
    'name': 'Trà sữa truyền thống',
    'categoryId': 'category01',
    'description': 'Trà sữa vị truyền thống',
    'imageUrl': 'https://example.com/tra-sua.jpg',
    'status': 'Còn bán',
    'minPrice': 25000,
  });

  setDoc('foods', 'food02', {
    'name': 'Cơm chiên hải sản',
    'categoryId': 'category02',
    'description': 'Cơm chiên với tôm, mực và rau củ',
    'imageUrl': 'https://example.com/com-chien.jpg',
    'status': 'Còn bán',
    'minPrice': 50000,
  });

  setDoc('foods', 'food03', {
    'name': 'Lẩu thái',
    'categoryId': 'category03',
    'description': 'Lẩu thái chua cay',
    'imageUrl': 'https://example.com/lau-thai.jpg',
    'status': 'Còn bán',
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
    'name': 'Thường',
    'price': 50000,
    'unit': 'Phần',
    'isActive': true,
  });

  setDoc('food_variants', 'variant05', {
    'foodId': 'food02',
    'name': 'Lớn',
    'price': 65000,
    'unit': 'Phần',
    'isActive': true,
  });

  setDoc('food_variants', 'variant06', {
    'foodId': 'food03',
    'name': 'Nhỏ',
    'price': 199000,
    'unit': 'Nồi',
    'isActive': true,
  });

  setDoc('food_variants', 'variant07', {
    'foodId': 'food03',
    'name': 'Lớn',
    'price': 299000,
    'unit': 'Nồi',
    'isActive': true,
  });

  setDoc('tables', 'table01', {
    'name': 'Bàn 01',
    'status': 'Đang phục vụ',
    'currentOrderId': 'order01',
    'mergedWith': <String>[],
  });

  setDoc('tables', 'table02', {
    'name': 'Bàn 02',
    'status': 'Trống',
    'currentOrderId': null,
    'mergedWith': <String>[],
  });

  setDoc('tables', 'table03', {
    'name': 'Bàn 03',
    'status': 'Đã đặt',
    'currentOrderId': null,
    'mergedWith': <String>[],
  });

  setDoc('orders', 'order01', {
    'tableId': 'table01',
    'tableIds': ['table01'],
    'status': 'Đang mở',
    'subtotal': 424000,
    'createdBy': 'user02',
    'createdAt': now,
  });

  setDoc('orders', 'order02', {
    'tableId': 'table02',
    'tableIds': ['table02'],
    'status': 'Đã thanh toán',
    'subtotal': 125000,
    'createdBy': 'user02',
    'createdAt': now,
  });

  setDoc('order_details', 'detail01', {
    'orderId': 'order01',
    'foodId': 'food01',
    'variantId': 'variant02',
    'foodName': 'Trà sữa truyền thống',
    'variantName': 'Size M',
    'unitPrice': 30000,
    'quantity': 2,
    'note': 'Ít đá',
    'lineTotal': 60000,
    'status': 'Đã xác nhận',
  });

  setDoc('order_details', 'detail02', {
    'orderId': 'order01',
    'foodId': 'food02',
    'variantId': 'variant05',
    'foodName': 'Cơm chiên hải sản',
    'variantName': 'Lớn',
    'unitPrice': 65000,
    'quantity': 1,
    'note': 'Không hành',
    'lineTotal': 65000,
    'status': 'Đã xác nhận',
  });

  setDoc('order_details', 'detail03', {
    'orderId': 'order01',
    'foodId': 'food03',
    'variantId': 'variant07',
    'foodName': 'Lẩu thái',
    'variantName': 'Lớn',
    'unitPrice': 299000,
    'quantity': 1,
    'note': 'Ít cay',
    'lineTotal': 299000,
    'status': 'Đã xác nhận',
  });

  setDoc('order_details', 'detail04', {
    'orderId': 'order02',
    'foodId': 'food01',
    'variantId': 'variant03',
    'foodName': 'Trà sữa truyền thống',
    'variantName': 'Size L',
    'unitPrice': 35000,
    'quantity': 1,
    'note': 'Không đá',
    'lineTotal': 35000,
    'status': 'Đã xác nhận',
  });

  setDoc('order_details', 'detail05', {
    'orderId': 'order02',
    'foodId': 'food02',
    'variantId': 'variant04',
    'foodName': 'Cơm chiên hải sản',
    'variantName': 'Thường',
    'unitPrice': 50000,
    'quantity': 1,
    'note': '',
    'lineTotal': 50000,
    'status': 'Đã xác nhận',
  });

  setDoc('order_details', 'detail06', {
    'orderId': 'order02',
    'foodId': 'food01',
    'variantId': 'variant02',
    'foodName': 'Trà sữa truyền thống',
    'variantName': 'Size M',
    'unitPrice': 30000,
    'quantity': 1,
    'note': 'Ít đường',
    'lineTotal': 30000,
    'status': 'Đã xác nhận',
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
