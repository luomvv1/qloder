import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'invoices/invoice_list_view.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Quản trị hệ thống',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chao, ${user.fullName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quản lý toàn bộ hệ thống nhà hàng',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Danh mục chức năng',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            title: 'Quản lý tài khoản nhân viên',
            subtitle: 'Thêm, sửa, xóa, phân quyền phục vụ/bếp',
            icon: Icons.badge_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EmployeeAdminPage()),
            ),
          ),
          _FeatureCard(
            title: 'Quản lý món ăn',
            subtitle: 'Thêm/sửa/xóa món, giá, trạng thái, danh mục',
            icon: Icons.restaurant_menu,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FoodAdminPage())),
          ),
          _FeatureCard(
            title: 'Quản lý bàn',
            subtitle: 'Thêm/sửa/xóa bàn, cập nhật trạng thái',
            icon: Icons.table_bar,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TableAdminPage())),
          ),
          _FeatureCard(
            title: 'Quản lý hóa đơn',
            subtitle:
                'Xem hóa đơn, thống kê doanh thu, lịch sử order',
            icon: Icons.receipt_long,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const InvoiceAdminPage())),
          ),
          _FeatureCard(
            title: 'Quản lý khách hàng thành viên',
            subtitle: 'Danh sách, điểm thưởng, khóa/mở tài khoản',
            icon: Icons.groups_outlined,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MemberAdminPage())),
          ),
          _FeatureCard(
            title: 'Quản lý ưu đãi',
            subtitle:
                'Tạo/sửa/xóa chương trình ưu đãi theo thời gian',
            icon: Icons.local_offer_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PromotionAdminPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class EmployeeAdminPage extends StatelessWidget {
  const EmployeeAdminPage({super.key});

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  Future<String> _createAuthUserForStaff({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final appName = 'staff-create-${DateTime.now().millisecondsSinceEpoch}';
    final tempApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(fullName);
      final uid = credential.user?.uid;
      if (uid == null || uid.isEmpty) {
        throw Exception('Khong tao duoc UID tai khoan nhan vien.');
      }
      await tempAuth.signOut();
      return uid;
    } finally {
      await tempApp.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý nhân viên')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmployeeForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhân viên'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _users.orderBy('fullName').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có nhân viên'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = data['fullName'] as String? ?? doc.id;
              final email = data['email'] as String? ?? '';
              final role =
                  data['position'] as String? ??
                  data['role'] as String? ??
                  'phuc-vu';
              final isActive = data['isActive'] as bool? ?? true;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('$email\nVai tro: $role'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showEmployeeForm(context, doc: doc);
                      } else if (value == 'toggle') {
                        await doc.reference.update({'isActive': !isActive});
                      } else if (value == 'delete') {
                        await doc.reference.delete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Sửa thông tin'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          isActive ? 'Khóa tài khoản' : 'Mở tài khoản',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa tài khoản'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEmployeeForm(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final fullName = TextEditingController(
      text: doc?.data()['fullName'] as String? ?? '',
    );
    final email = TextEditingController(
      text: doc?.data()['email'] as String? ?? '',
    );
    final phone = TextEditingController(
      text: doc?.data()['phone'] as String? ?? '',
    );
    final password = TextEditingController(text: '');
    var position = (doc?.data()['position'] as String?) ?? 'phuc-vu';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              doc == null ? 'Thêm nhân viên' : 'Sửa nhân viên',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fullName,
                    decoration: _adminFieldDecoration('Họ tên'),
                  ),
                  TextField(
                    controller: email,
                    decoration: _adminFieldDecoration('Email'),
                  ),
                  TextField(
                    controller: phone,
                    decoration: _adminFieldDecoration('Số điện thoại'),
                  ),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: _adminFieldDecoration(
                      doc == null
                          ? 'Mật khẩu'
                          : 'Mật khẩu mới (để trống nếu không đổi)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: position,
                    items: const [
                      DropdownMenuItem(
                        value: 'phuc-vu',
                        child: Text('Phục vụ'),
                      ),
                      DropdownMenuItem(value: 'bep', child: Text('Bếp')),
                    ],
                    onChanged: (value) =>
                        setState(() => position = value ?? 'phuc-vu'),
                    decoration: _adminFieldDecoration('Phân quyền'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () async {
                  final safeName = fullName.text.trim();
                  final safePhone = phone.text.trim();
                  final safeEmail = email.text.trim().toLowerCase();
                  if (safeName.isEmpty ||
                      safePhone.isEmpty ||
                      safeEmail.isEmpty) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bắt buộc nhập đầy đủ Tên, Gmail và Số điện thoại.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  final isValidEmail = RegExp(
                    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                  ).hasMatch(safeEmail);
                  if (!isValidEmail) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gmail không hợp lệ. Vui lòng nhập đúng định dạng email.',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  final normalizedPhone = safePhone.replaceAll(
                    RegExp(r'\s+'),
                    '',
                  );
                  final isValidPhone = RegExp(
                    r'^\d{10}$',
                  ).hasMatch(normalizedPhone);
                  if (!isValidPhone) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Số điện thoại phải đúng 10 chữ số.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  final safePassword = password.text.trim();
                  if (doc == null && safePassword.isEmpty) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bắt buộc nhập mật khẩu để tạo tài khoản.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  if (safePassword.isNotEmpty && safePassword.length < 6) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mật khẩu phải có ít nhất 6 ký tự.',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  if (doc == null) {
                    final existingSnapshot = await _users.get();
                    final normalizedNewName = safeName.toLowerCase();
                    final duplicatedName = existingSnapshot.docs.any((userDoc) {
                      final existingName =
                          (userDoc.data()['fullName'] as String? ?? '')
                              .trim()
                              .toLowerCase();
                      return existingName == normalizedNewName;
                    });
                    if (duplicatedName) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tên phục vụ đã tồn tại, không thể tạo trùng.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                  }

                  try {
                    final payload = <String, dynamic>{
                      'fullName': safeName,
                      'email': safeEmail,
                      'phone': safePhone,
                      'position': position,
                      'role': 'staff',
                      'loginByPhone': false,
                      'loginId': safeEmail,
                      'isActive': true,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    if (doc == null) {
                      final userId = await _nextSequentialDocId(_users, 'user');
                      final uid = await _createAuthUserForStaff(
                        email: safeEmail,
                        password: safePassword,
                        fullName: safeName,
                      );
                      payload['authUid'] = uid;
                      payload['createdAt'] = FieldValue.serverTimestamp();
                      await _users.doc(userId).set(payload);
                    } else {
                      await doc.reference.update(payload);
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  } on FirebaseAuthException catch (e) {
                    var message = 'Khong tao duoc tai khoan nhan vien.';
                    if (e.code == 'email-already-in-use') {
                      message = 'Gmail da ton tai trong he thong.';
                    } else if (e.code == 'invalid-email') {
                      message = 'Gmail khong hop le.';
                    } else if (e.code == 'weak-password') {
                      message = 'Mat khau qua yeu. Hay dat it nhat 6 ky tu.';
                    }
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                  } catch (_) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Co loi xay ra khi tao tai khoan nhan vien.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FoodAdminPage extends StatelessWidget {
  const FoodAdminPage({super.key});

  CollectionReference<Map<String, dynamic>> get _foods =>
      FirebaseFirestore.instance.collection('foods');
  CollectionReference<Map<String, dynamic>> get _categories =>
      FirebaseFirestore.instance.collection('categories');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý món ăn'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Món ăn'),
              Tab(text: 'Danh mục'),
            ],
          ),
        ),
        body: TabBarView(children: [_foodTab(context), _categoryTab(context)]),
      ),
    );
  }

  Widget _foodTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _showFoodForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm món'),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _foods.orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final name = data['name'] as String? ?? doc.id;
                  final price = (data['minPrice'] as num? ?? 0).toInt();
                  final status = data['status'] as String? ?? 'Con ban';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(
                        'Giá: ${_formatVnd(price)} - Trạng thái: $status',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') _showFoodForm(context, doc: doc);
                          if (value == 'status') {
                            await doc.reference.update({
                              'status': status == 'Con ban'
                                  ? 'Het mon'
                                  : 'Con ban',
                            });
                          }
                          if (value == 'delete') await doc.reference.delete();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Sửa món ăn'),
                          ),
                          PopupMenuItem(
                            value: 'status',
                            child: Text('Cập nhật trạng thái'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Xóa món ăn'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _showCategoryForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm danh mục'),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _categories.orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final name = data['name'] as String? ?? doc.id;
                  final isActive = data['isActive'] as bool? ?? true;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(
                        isActive ? 'Đang hoạt động' : 'Đang ẩn',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showCategoryForm(context, doc: doc);
                          }
                          if (value == 'toggle') {
                            await doc.reference.update({'isActive': !isActive});
                          }
                          if (value == 'delete') await doc.reference.delete();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Sửa danh mục'),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(
                              isActive ? 'Ẩn danh mục' : 'Mở danh mục',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Xóa danh mục'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showFoodForm(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final name = TextEditingController(
      text: doc?.data()['name'] as String? ?? '',
    );
    final price = TextEditingController(
      text: ((doc?.data()['minPrice'] as num?) ?? 0).toString(),
    );
    final desc = TextEditingController(
      text: doc?.data()['description'] as String? ?? '',
    );
    String selectedCategoryId = (doc?.data()['categoryId'] as String?) ?? '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(doc == null ? 'Thêm món ăn' : 'Sửa món ăn'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: _adminFieldDecoration('Tên món'),
                ),
                FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: _categories.orderBy('name').get(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? const [];
                    final validSelected = docs.any(
                      (e) => e.id == selectedCategoryId,
                    );
                    final value = validSelected ? selectedCategoryId : null;
                    return DropdownButtonFormField<String>(
                      initialValue: value,
                      isExpanded: true,
                      items: docs
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.id,
                              child: Text(
                                (e.data()['name'] as String?) ?? e.id,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedCategoryId = v ?? ''),
                      decoration: _adminFieldDecoration('Danh mục'),
                    );
                  },
                ),
                TextField(
                  controller: price,
                  decoration: _adminFieldDecoration(
                    'Giá',
                  ).copyWith(suffixText: 'VND'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: desc,
                  decoration: _adminFieldDecoration('Mô tả'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (selectedCategoryId.isEmpty) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng chọn danh mục món ăn.'),
                      ),
                    );
                  }
                  return;
                }
                final payload = <String, dynamic>{
                  'name': name.text.trim(),
                  'categoryId': selectedCategoryId,
                  'minPrice': int.tryParse(price.text.trim()) ?? 0,
                  'description': desc.text.trim(),
                  'imageUrl': doc?.data()['imageUrl'] ?? '',
                  'status': doc?.data()['status'] ?? 'Còn bán',
                };
                if (doc == null) {
                  final foodId = await _nextSequentialDocId(_foods, 'food');
                  await _foods.doc(foodId).set(payload);
                } else {
                  await doc.reference.update(payload);
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryForm(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final name = TextEditingController(
      text: doc?.data()['name'] as String? ?? '',
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(doc == null ? 'Thêm danh mục' : 'Sửa danh mục'),
        content: TextField(
          controller: name,
          decoration: _adminFieldDecoration('Tên danh mục'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final payload = {'name': name.text.trim(), 'isActive': true};
              if (doc == null) {
                final categoryId = await _nextSequentialDocId(
                  _categories,
                  'category',
                );
                await _categories.doc(categoryId).set(payload);
              } else {
                await doc.reference.update(payload);
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class TableAdminPage extends StatefulWidget {
  const TableAdminPage({super.key});

  @override
  State<TableAdminPage> createState() => _TableAdminPageState();
}

class _TableAdminPageState extends State<TableAdminPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  CollectionReference<Map<String, dynamic>> get _tables =>
      FirebaseFirestore.instance.collection('tables');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý bàn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTableForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm bàn'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _tables.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final query = _searchText.trim().toLowerCase();
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final name = (data['name'] as String? ?? doc.id).toLowerCase();
            final status = (data['status'] as String? ?? '').toLowerCase();
            return query.isEmpty ||
                name.contains(query) ||
                status.contains(query);
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: _adminFieldDecoration('Tìm kiếm bàn').copyWith(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchText.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchText = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: (value) => setState(() => _searchText = value),
                ),
              ),
              if (docs.isEmpty)
                const Expanded(
                  child: Center(child: Text('Không tìm thấy bàn phù hợp')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final name = data['name'] as String? ?? doc.id;
                      final status = data['status'] as String? ?? 'Trong';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('Trạng thái: $status'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showTableForm(context, doc: doc);
                              }
                              if (value == 'status') {
                                await _showStatusPicker(context, doc);
                              }
                              if (value == 'delete') {
                                await doc.reference.delete();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Sửa bàn'),
                              ),
                              PopupMenuItem(
                                value: 'status',
                                child: Text('Cập nhật trạng thái'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Xóa bàn'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showTableForm(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final name = TextEditingController(
      text: doc?.data()['name'] as String? ?? '',
    );
    final quantity = TextEditingController(text: '1');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (statefulContext, setState) => AlertDialog(
            title: Text(doc == null ? 'Thêm bàn' : 'Sửa bàn'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: _adminFieldDecoration(
                    doc == null
                        ? 'Tên bàn (có thể bỏ trống)'
                        : 'Tên bàn',
                  ),
                ),
                if (doc == null) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: quantity,
                    keyboardType: TextInputType.number,
                    decoration: _adminFieldDecoration(
                      'Số lượng bàn cần thêm',
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        try {
                          if (doc == null) {
                            final qty = int.tryParse(quantity.text.trim()) ?? 1;
                            final safeQty = qty < 1 ? 1 : qty;
                            final inputName = name.text.trim();
                            final existingSnapshot = await _tables.get();
                            final existingNames = existingSnapshot.docs
                                .map(
                                  (e) => (e.data()['name'] as String? ?? '')
                                      .trim()
                                      .toLowerCase(),
                                )
                                .where((e) => e.isNotEmpty)
                                .toSet();

                            if (inputName.isEmpty) {
                              final usedNumbers = <int>{};
                              for (final tableDoc in existingSnapshot.docs) {
                                final tableName =
                                    (tableDoc.data()['name'] as String? ?? '')
                                        .trim();
                                final match = RegExp(
                                  r'^Bàn\s+(\d+)$',
                                  caseSensitive: false,
                                ).firstMatch(tableName);
                                if (match != null) {
                                  final number = int.tryParse(match.group(1)!);
                                  if (number != null) usedNumbers.add(number);
                                }
                              }

                              var createdCount = 0;
                              var candidate = 1;
                              while (createdCount < safeQty) {
                                if (!usedNumbers.contains(candidate)) {
                                  final generatedName =
                                      'Bàn ${candidate.toString().padLeft(2, '0')}';
                                  final tableId = await _nextSequentialDocId(
                                    _tables,
                                    'table',
                                  );
                                  await _tables.doc(tableId).set({
                                    'name': generatedName,
                                    'status': 'Trống',
                                    'currentOrderId': null,
                                    'mergedWith': <String>[],
                                  });
                                  usedNumbers.add(candidate);
                                  createdCount++;
                                }
                                candidate++;
                              }
                            } else {
                              for (var i = 1; i <= safeQty; i++) {
                                final generatedName = safeQty == 1
                                    ? inputName
                                    : '$inputName $i';
                                final key = generatedName.trim().toLowerCase();
                                if (existingNames.contains(key)) {
                                  continue;
                                }
                                final tableId = await _nextSequentialDocId(
                                  _tables,
                                  'table',
                                );
                                await _tables.doc(tableId).set({
                                  'name': generatedName,
                                  'status': 'Trống',
                                  'currentOrderId': null,
                                  'mergedWith': <String>[],
                                });
                                existingNames.add(key);
                              }
                            }
                          } else {
                            final payload = {
                              'name': name.text.trim(),
                              'status': doc.data()['status'] ?? 'Trống',
                            };
                            await doc.reference.update(payload);
                          }
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } finally {
                          if (statefulContext.mounted) {
                            setState(() => isSaving = false);
                          }
                        }
                      },
                child: Text(isSaving ? 'Đang lưu...' : 'Lưu'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStatusPicker(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final statusList = ['Trống', 'Đang phục vụ', 'Đã đặt'];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cập nhật trạng thái bàn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusList
              .map(
                (status) => ListTile(
                  title: Text(status),
                  onTap: () async {
                    await doc.reference.update({'status': status});
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class InvoiceAdminPage extends StatelessWidget {
  const InvoiceAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý hóa đơn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore.collection('invoices').snapshots(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const Card(
                  child: ListTile(title: Text('Đang tải thống kê...')),
                );
              }
              final invoices = snapshot.data!.docs;
              final revenue = invoices.fold<num>(
                0,
                (total, e) => total + ((e.data()['totalAmount'] as num?) ?? 0),
              );
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Thống kê doanh thu'),
                  subtitle: Text(
                    'Tổng hóa đơn: ${invoices.length}\nTổng doanh thu: ${_formatVnd(revenue)}',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const InvoiceListView())),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Xem hóa đơn'),
          ),
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              title: const Text('Xem lịch sử order'),
              children: [
                SizedBox(
                  height: 300,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: firestore
                        .collection('orders')
                        .orderBy('createdAt', descending: true)
                        .limit(30)
                        .snapshots(),
                    builder: (_, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text('Chưa có order'));
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (_, index) {
                          final data = docs[index].data();
                          return ListTile(
                            dense: true,
                            title: Text('Order ${docs[index].id}'),
                            subtitle: Text(
                              'Bàn: ${data['tableId'] ?? '-'} | Trạng thái: ${data['status'] ?? '-'} | Tạm tính: ${_formatVnd((data['subtotal'] as num?) ?? 0)}',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MemberAdminPage extends StatelessWidget {
  const MemberAdminPage({super.key});

  CollectionReference<Map<String, dynamic>> get _customers =>
      FirebaseFirestore.instance.collection('customers');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý thành viên')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _customers.orderBy('fullName').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có thành viên'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = data['fullName'] as String? ?? doc.id;
              final phone = data['phone'] as String? ?? '';
              final points = (data['points'] as num? ?? 0).toInt();
              final isActive = data['isActive'] as bool? ?? true;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                    'SĐT: $phone\nĐiểm: $points | ${isActive ? 'Hoạt động' : 'Đã khóa'}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'points') {
                        _showUpdatePoints(context, doc);
                      } else if (value == 'toggle') {
                        await doc.reference.set({
                          'isActive': !isActive,
                        }, SetOptions(merge: true));
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'points',
                        child: Text('Cập nhật điểm thưởng'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          isActive ? 'Khóa tài khoản' : 'Mở tài khoản',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showUpdatePoints(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final current = (doc.data()['points'] as num? ?? 0).toInt();
    final controller = TextEditingController(text: current.toString());
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cập nhật điểm thưởng'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: _adminFieldDecoration('Điểm mới'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final points = int.tryParse(controller.text.trim()) ?? current;
              await doc.reference.update({'points': points});
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class PromotionAdminPage extends StatelessWidget {
  const PromotionAdminPage({super.key});

  CollectionReference<Map<String, dynamic>> get _promotions =>
      FirebaseFirestore.instance.collection('promotions');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý ưu đãi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromotionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ưu đãi'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _promotions.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('Chưa có chương trình ưu đãi'),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = data['title'] as String? ?? doc.id;
              final code = data['code'] as String? ?? '';
              final type = data['discountType'] as String? ?? 'percent';
              final value = (data['discountValue'] as num? ?? 0).toDouble();
              final minOrder = (data['minOrderAmount'] as num? ?? 0).toDouble();
              final maxDiscount = (data['maxDiscountAmount'] as num? ?? 0)
                  .toDouble();
              final active = data['isActive'] as bool? ?? true;
              final startAt = data['startAt'] as Timestamp?;
              final endAt = data['endAt'] as Timestamp?;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(
                    'Mã: $code\n'
                    'Loại: ${type == 'percent' ? 'Phần trăm' : 'Tiền mặt'} - Giá trị: ${type == 'percent' ? '${value.toStringAsFixed(0)}%' : _formatVnd(value)}\n'
                    'Đơn tối thiểu: ${_formatVnd(minOrder)} - Giảm tối đa: ${_formatVnd(maxDiscount)}\n'
                    'Thời gian: ${_fmtDate(startAt)} đến ${_fmtDate(endAt)}\n'
                    'Trạng thái: ${active ? 'Đang áp dụng' : 'Tạm tắt'}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showPromotionForm(context, doc: doc);
                      } else if (value == 'toggle') {
                        await doc.reference.update({'isActive': !active});
                      } else if (value == 'delete') {
                        await doc.reference.delete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Sửa ưu đãi'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          active ? 'Tạm tắt ưu đãi' : 'Bật ưu đãi',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa ưu đãi'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPromotionForm(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final title = TextEditingController(
      text: doc?.data()['title'] as String? ?? '',
    );
    final code = TextEditingController(
      text: doc?.data()['code'] as String? ?? '',
    );
    final description = TextEditingController(
      text: doc?.data()['description'] as String? ?? '',
    );
    final discountValue = TextEditingController(
      text: ((doc?.data()['discountValue'] as num?) ?? 0).toString(),
    );
    final minOrderAmount = TextEditingController(
      text: ((doc?.data()['minOrderAmount'] as num?) ?? 0).toString(),
    );
    final maxDiscountAmount = TextEditingController(
      text: ((doc?.data()['maxDiscountAmount'] as num?) ?? 0).toString(),
    );
    final usageLimit = TextEditingController(
      text: ((doc?.data()['usageLimit'] as num?) ?? 0).toString(),
    );
    final usedCount = TextEditingController(
      text: ((doc?.data()['usedCount'] as num?) ?? 0).toString(),
    );
    var discountType = (doc?.data()['discountType'] as String?) ?? 'percent';
    var startAt =
        (doc?.data()['startAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    var endAt =
        (doc?.data()['endAt'] as Timestamp?)?.toDate().add(
          const Duration(days: 7),
        ) ??
        DateTime.now().add(const Duration(days: 7));
    var isActive = (doc?.data()['isActive'] as bool?) ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            doc == null
                ? 'Thêm chương trình ưu đãi'
                : 'Sửa chương trình ưu đãi',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: _adminFieldDecoration('Tên chương trình'),
                ),
                TextField(
                  controller: code,
                  decoration: _adminFieldDecoration('Mã ưu đãi'),
                ),
                TextField(
                  controller: description,
                  decoration: _adminFieldDecoration('Mô tả'),
                ),
                _PickerField(
                  label: 'Loại giảm giá',
                  valueText: discountType == 'percent'
                      ? 'Giảm theo phần trăm'
                      : 'Giảm theo tiền mặt',
                  onTap: () async {
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Giảm theo phần trăm'),
                              onTap: () => Navigator.of(context).pop('percent'),
                            ),
                            ListTile(
                              title: const Text('Giảm theo tiền mặt'),
                              onTap: () => Navigator.of(context).pop('fixed'),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (selected != null) {
                      setState(() => discountType = selected);
                    }
                  },
                ),
                TextField(
                  controller: discountValue,
                  keyboardType: TextInputType.number,
                  decoration: _adminFieldDecoration('Giá trị giảm')
                      .copyWith(
                        suffixText: discountType == 'percent' ? '%' : 'VND',
                      ),
                ),
                TextField(
                  controller: minOrderAmount,
                  keyboardType: TextInputType.number,
                  decoration: _adminFieldDecoration(
                    'Đơn hàng tối thiểu',
                  ).copyWith(suffixText: 'VND'),
                ),
                TextField(
                  controller: maxDiscountAmount,
                  keyboardType: TextInputType.number,
                  decoration: _adminFieldDecoration(
                    'Mức giảm tối đa',
                  ).copyWith(suffixText: 'VND'),
                ),
                TextField(
                  controller: usageLimit,
                  keyboardType: TextInputType.number,
                  decoration: _adminFieldDecoration(
                    'Giới hạn lượt dùng',
                  ),
                ),
                TextField(
                  controller: usedCount,
                  keyboardType: TextInputType.number,
                  decoration: _adminFieldDecoration('Số lượt đã dùng'),
                ),
                const SizedBox(height: 8),
                _PickerField(
                  label: 'Ngày bắt đầu',
                  valueText: _fmtDate(Timestamp.fromDate(startAt)),
                  icon: Icons.calendar_today_outlined,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startAt,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => startAt = picked);
                  },
                ),
                _PickerField(
                  label: 'Ngày kết thúc',
                  valueText: _fmtDate(Timestamp.fromDate(endAt)),
                  icon: Icons.calendar_today_outlined,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endAt,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => endAt = picked);
                  },
                ),
                _PickerField(
                  label: 'Trạng thái',
                  valueText: isActive ? 'Đang áp dụng' : 'Tạm tắt',
                  onTap: () async {
                    final selected = await showModalBottomSheet<bool>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Đang áp dụng'),
                              onTap: () => Navigator.of(context).pop(true),
                            ),
                            ListTile(
                              title: const Text('Tạm tắt'),
                              onTap: () => Navigator.of(context).pop(false),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (selected != null) {
                      setState(() => isActive = selected);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final payload = <String, dynamic>{
                  'title': title.text.trim(),
                  'code': code.text.trim().toUpperCase(),
                  'description': description.text.trim(),
                  'discountType': discountType,
                  'discountValue':
                      double.tryParse(discountValue.text.trim()) ?? 0,
                  'minOrderAmount':
                      double.tryParse(minOrderAmount.text.trim()) ?? 0,
                  'maxDiscountAmount':
                      double.tryParse(maxDiscountAmount.text.trim()) ?? 0,
                  'usageLimit': int.tryParse(usageLimit.text.trim()) ?? 0,
                  'usedCount': int.tryParse(usedCount.text.trim()) ?? 0,
                  'startAt': Timestamp.fromDate(startAt),
                  'endAt': Timestamp.fromDate(endAt),
                  'isActive': isActive,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (doc == null) {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await _promotions.add(payload);
                } else {
                  await doc.reference.update(payload);
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.icon = Icons.expand_more_rounded,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _adminFieldDecoration(
            label,
          ).copyWith(suffixIcon: Icon(icon)),
          child: Text(valueText),
        ),
      ),
    );
  }
}

InputDecoration _adminFieldDecoration(String hint) {
  return InputDecoration(
    labelText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: const Color(0xFFF1F5F9),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.4),
    ),
  );
}

String _formatVnd(num value) {
  final number = value.toInt();
  final text = number.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()} VND';
}

Future<String> _nextSequentialDocId(
  CollectionReference<Map<String, dynamic>> collection,
  String prefix,
) async {
  final snapshot = await collection.get();
  var maxNumber = 0;

  final pattern = RegExp('^${RegExp.escape(prefix)}(\\d+)\$');
  for (final doc in snapshot.docs) {
    final match = pattern.firstMatch(doc.id);
    if (match == null) continue;
    final parsed = int.tryParse(match.group(1)!);
    if (parsed != null && parsed > maxNumber) {
      maxNumber = parsed;
    }
  }

  final next = maxNumber + 1;
  return '$prefix${next.toString().padLeft(2, '0')}';
}
