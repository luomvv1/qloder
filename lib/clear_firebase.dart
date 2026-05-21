import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ClearFirebaseApp());
}

class ClearFirebaseApp extends StatefulWidget {
  const ClearFirebaseApp({super.key});

  @override
  State<ClearFirebaseApp> createState() => _ClearFirebaseAppState();
}

class _ClearFirebaseAppState extends State<ClearFirebaseApp> {
  late final Future<int> _clearFuture = clearSampleData();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Xóa dữ liệu mẫu')),
        body: Center(
          child: FutureBuilder<int>(
            future: _clearFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang xóa dữ liệu mẫu...'),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Lỗi khi xóa dữ liệu:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return Text(
                'Đã xóa ${snapshot.data ?? 0} document.\n'
                'Bây giờ hãy chạy lại seed_firebase.dart.',
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<int> clearSampleData() async {
  final db = FirebaseFirestore.instance;
  var deletedCount = 0;

  const collections = [
    'order_details',
    'orders',
    'invoices',
    'tables',
    'food_variants',
    'foods',
    'categories',
    'customers',
    'users',
    'settings',
  ];

  for (final collection in collections) {
    deletedCount += await deleteCollection(db, collection);
  }

  return deletedCount;
}

Future<int> deleteCollection(
  FirebaseFirestore db,
  String collectionPath,
) async {
  var deletedCount = 0;

  while (true) {
    final snapshot = await db.collection(collectionPath).limit(250).get();
    if (snapshot.docs.isEmpty) break;

    final batch = db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      deletedCount++;
    }

    await batch.commit();
  }

  return deletedCount;
}
