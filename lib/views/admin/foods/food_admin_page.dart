import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/cloudinary_config.dart';
import '../../../services/cloudinary_service.dart';

class FoodAdminPage extends StatefulWidget {
  const FoodAdminPage({super.key});

  @override
  State<FoodAdminPage> createState() => _FoodAdminPageState();
}

class _FoodAdminPageState extends State<FoodAdminPage> {
  final _searchController = TextEditingController();
  String _searchText = '';
  String _selectedCategoryId = 'all';

  CollectionReference<Map<String, dynamic>> get _foods =>
      FirebaseFirestore.instance.collection('foods');
  CollectionReference<Map<String, dynamic>> get _categories =>
      FirebaseFirestore.instance.collection('categories');
  CollectionReference<Map<String, dynamic>> get _variants =>
      FirebaseFirestore.instance.collection('food_variants');

  ButtonStyle get _compactButtonStyle => FilledButton.styleFrom(
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 14),
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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

  // Tab món ăn: thêm/sửa/xóa món và mở nhanh danh sách biến thể.
  Widget _foodTab(BuildContext context) {
    return Column(
      children: [
        _FoodAdminHeader(
          title: 'Món ăn và biến thể',
          subtitle: 'Quản lý ảnh, trạng thái và nhiều size cho từng món',
          buttonText: 'Thêm món',
          icon: Icons.restaurant_menu,
          onPressed: () => _showFoodForm(context),
          style: _compactButtonStyle,
        ),
        _FoodAdminFilterBar(
          searchController: _searchController,
          selectedCategoryId: _selectedCategoryId,
          categoriesStream: _categories.snapshots(),
          onCategoryChanged: (value) {
            setState(() => _selectedCategoryId = value);
          },
          onClear: () {
            _searchController.clear();
            setState(() => _selectedCategoryId = 'all');
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _foods.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Không tải được món ăn'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs =
                  snapshot.data!.docs.where(_matchesFoodFilter).toList()
                    ..sort((a, b) {
                      final nameA = a.data()['name'] as String? ?? a.id;
                      final nameB = b.data()['name'] as String? ?? b.id;
                      return nameA.compareTo(nameB);
                    });
              if (docs.isEmpty) {
                return const Center(child: Text('Không có món ăn phù hợp'));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                itemCount: docs.length,
                itemBuilder: (_, index) => _foodCard(context, docs[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matchesFoodFilter(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] as String? ?? doc.id).toLowerCase();
    final description = (data['description'] as String? ?? '').toLowerCase();
    final categoryName = (data['categoryName'] as String? ?? '').toLowerCase();
    final categoryId = data['categoryId'] as String? ?? '';

    final matchesSearch =
        _searchText.isEmpty ||
        name.contains(_searchText) ||
        description.contains(_searchText) ||
        categoryName.contains(_searchText) ||
        doc.id.toLowerCase().contains(_searchText);
    final matchesCategory =
        _selectedCategoryId == 'all' || categoryId == _selectedCategoryId;

    return matchesSearch && matchesCategory;
  }

  // Card món ăn: hiển thị thông tin món, ảnh, trạng thái và các biến thể.
  Widget _foodCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = data['name'] as String? ?? doc.id;
    final description = data['description'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final price = data['minPrice'] as num? ?? 0;
    final status = data['status'] as String? ?? 'Còn bán';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _foodImage(imageUrl, width: 68, height: 68),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            _StatusBadge(status: status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${_formatVnd(price)}'
            '${description.isEmpty ? '' : '\n$description'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showFoodForm(context, doc: doc);
            } else if (value == 'variants') {
              _showVariantsSheet(context, foodId: doc.id, foodName: name);
            } else if (value == 'status') {
              await doc.reference.update({
                'status': status == 'Còn bán' ? 'Hết món' : 'Còn bán',
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else if (value == 'delete') {
              await _deleteFoodWithVariants(doc.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Sửa món ăn')),
            PopupMenuItem(value: 'variants', child: Text('Quản lý biến thể')),
            PopupMenuItem(value: 'status', child: Text('Đổi trạng thái')),
            PopupMenuItem(value: 'delete', child: Text('Xóa món ăn')),
          ],
        ),
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _variants.where('foodId', isEqualTo: doc.id).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }

              final variants = snapshot.data!.docs;
              variants.sort((a, b) {
                final priceA = a.data()['price'] as num? ?? 0;
                final priceB = b.data()['price'] as num? ?? 0;
                return priceA.compareTo(priceB);
              });

              if (variants.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Món này chưa có biến thể')),
                      TextButton.icon(
                        onPressed: () => _showVariantForm(
                          context,
                          foodId: doc.id,
                          foodName: name,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm biến thể'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final variant in variants)
                    _variantTile(context, variant, foodName: name),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _showVariantForm(
                          context,
                          foodId: doc.id,
                          foodName: name,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm biến thể'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Dòng biến thể: sửa giá, đổi trạng thái hoặc xóa biến thể.
  Widget _variantTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String foodName,
  }) {
    final data = doc.data();
    final name = data['name'] as String? ?? doc.id;
    final price = data['price'] as num? ?? 0;
    final unit = data['unit'] as String? ?? '';
    final isActive = data['isActive'] as bool? ?? true;
    final foodId = data['foodId'] as String? ?? '';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(name),
      subtitle: Text('${_formatVnd(price)} / $unit'),
      leading: Icon(
        isActive ? Icons.check_circle_outline : Icons.block_outlined,
        color: isActive ? Colors.teal : Colors.redAccent,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'edit') {
            _showVariantForm(
              context,
              foodId: foodId,
              foodName: foodName,
              doc: doc,
            );
          } else if (value == 'toggle') {
            await doc.reference.update({
              'isActive': !isActive,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            await _syncMinPrice(foodId);
          } else if (value == 'delete') {
            await doc.reference.delete();
            await _syncMinPrice(foodId);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Sửa biến thể')),
          PopupMenuItem(
            value: 'toggle',
            child: Text(isActive ? 'Tạm ẩn biến thể' : 'Mở lại biến thể'),
          ),
          const PopupMenuItem(value: 'delete', child: Text('Xóa biến thể')),
        ],
      ),
    );
  }

  // Tab danh mục: quản lý nhóm món như nước uống, món chính, lẩu.
  Widget _categoryTab(BuildContext context) {
    return Column(
      children: [
        _FoodAdminHeader(
          title: 'Danh mục món ăn',
          subtitle: 'Nhóm món giúp nhân viên lọc menu nhanh hơn',
          buttonText: 'Thêm danh mục',
          icon: Icons.category_outlined,
          onPressed: () => _showCategoryForm(context),
          style: _compactButtonStyle,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _categories.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs
                ..sort((a, b) {
                  final nameA = a.data()['name'] as String? ?? a.id;
                  final nameB = b.data()['name'] as String? ?? b.id;
                  return nameA.compareTo(nameB);
                });
              if (docs.isEmpty) {
                return const Center(child: Text('Chưa có danh mục'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      subtitle: Text(isActive ? 'Đang hoạt động' : 'Đang ẩn'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showCategoryForm(context, doc: doc);
                          } else if (value == 'toggle') {
                            await doc.reference.update({'isActive': !isActive});
                          } else if (value == 'delete') {
                            await doc.reference.delete();
                          }
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

  // Form thêm/sửa món: ảnh có thể upload Cloudinary hoặc nhập URL trực tiếp.
  Future<void> _showFoodForm(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final name = TextEditingController(
      text: doc?.data()['name'] as String? ?? '',
    );
    final desc = TextEditingController(
      text: doc?.data()['description'] as String? ?? '',
    );
    final imageUrl = TextEditingController(
      text: doc?.data()['imageUrl'] as String? ?? '',
    );
    final parentContext = context;
    String selectedCategoryId = (doc?.data()['categoryId'] as String?) ?? '';
    String status = (doc?.data()['status'] as String?) ?? 'Còn bán';
    var isUploading = false;
    final variantDrafts = <_VariantDraft>[
      if (doc == null) _VariantDraft(unit: 'Ly'),
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(18, 16, 8, 0),
          contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFCCFBF1),
                foregroundColor: const Color(0xFF0F766E),
                child: Icon(doc == null ? Icons.restaurant_menu : Icons.edit),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  doc == null ? 'Thêm món ăn' : 'Sửa món ăn',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: isUploading
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: name,
                    textInputAction: TextInputAction.next,
                    decoration: _adminFieldDecoration('Tên món').copyWith(
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: const Icon(Icons.fastfood_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: _categories.get(),
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
                        decoration: _adminFieldDecoration('Danh mục').copyWith(
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          prefixIcon: const Icon(Icons.category),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: _adminFieldDecoration('Trạng thái').copyWith(
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: const Icon(Icons.sell_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Còn bán',
                        child: Text('Còn bán'),
                      ),
                      DropdownMenuItem(
                        value: 'Hết món',
                        child: Text('Hết món'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => status = value ?? 'Còn bán'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: desc,
                    minLines: 2,
                    maxLines: 3,
                    decoration: _adminFieldDecoration('Mô tả').copyWith(
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FoodImagePickerPanel(
                    imageUrl: imageUrl,
                    isUploading: isUploading,
                    preview: _foodImage(
                      imageUrl.text,
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.contain,
                    ),
                    onUrlChanged: () => setState(() {}),
                    onPickImage: isUploading
                        ? null
                        : () async {
                            await _pickAndUploadImage(
                              dialogContext,
                              imageUrl,
                              setState,
                              setUploading: (value) => isUploading = value,
                            );
                          },
                  ),
                  if (doc == null) ...[
                    const SizedBox(height: 14),
                    _VariantDraftList(
                      variants: variantDrafts,
                      onAdd: () => setState(() {
                        variantDrafts.add(_VariantDraft());
                      }),
                      onRemove: (index) => setState(() {
                        variantDrafts[index].dispose();
                        variantDrafts.removeAt(index);
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              onPressed: isUploading
                  ? null
                  : () async {
                      final safeName = name.text.trim();
                      final safeImageUrl = imageUrl.text.trim();

                      if (safeName.isEmpty || selectedCategoryId.isEmpty) {
                        _showSnack(
                          dialogContext,
                          'Vui lòng nhập tên món và chọn danh mục.',
                        );
                        return;
                      }
                      if (safeImageUrl.isEmpty) {
                        _showSnack(
                          dialogContext,
                          'Vui lòng upload hoặc nhập URL ảnh món ăn.',
                        );
                        return;
                      }
                      if (doc == null && variantDrafts.isEmpty) {
                        _showSnack(
                          dialogContext,
                          'Vui lòng thêm ít nhất một biến thể cho món.',
                        );
                        return;
                      }

                      final parsedVariants = <_ParsedVariant>[];
                      if (doc == null) {
                        for (var i = 0; i < variantDrafts.length; i++) {
                          final draft = variantDrafts[i];
                          final variantName = draft.name.text.trim();
                          final variantUnit = draft.unit.text.trim();
                          final variantPrice =
                              int.tryParse(draft.price.text.trim()) ?? 0;

                          if (variantName.isEmpty ||
                              variantUnit.isEmpty ||
                              variantPrice <= 0) {
                            _showSnack(
                              dialogContext,
                              'Biến thể dòng ${i + 1} phải có tên, đơn vị và giá lớn hơn 0.',
                            );
                            return;
                          }

                          parsedVariants.add(
                            _ParsedVariant(
                              name: variantName,
                              price: variantPrice,
                              unit: variantUnit,
                            ),
                          );
                        }
                      }

                      final payload = <String, dynamic>{
                        'name': safeName,
                        'categoryId': selectedCategoryId,
                        'description': desc.text.trim(),
                        'imageUrl': safeImageUrl,
                        'status': status,
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      String? createdFoodId;
                      if (doc == null) {
                        createdFoodId = await _nextSequentialDocId(
                          _foods,
                          'food',
                        );
                        payload['minPrice'] = parsedVariants
                            .map((variant) => variant.price)
                            .reduce((a, b) => a < b ? a : b);
                        payload['createdAt'] = FieldValue.serverTimestamp();
                        await _foods.doc(createdFoodId).set(payload);
                        await _createVariantsForFood(
                          createdFoodId,
                          parsedVariants,
                        );
                      } else {
                        await doc.reference.update(payload);
                      }

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (createdFoodId != null && parentContext.mounted) {
                        _showSnack(
                          parentContext,
                          'Đã thêm món và các biến thể.',
                        );
                      }
                    },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    TextEditingController imageUrl,
    StateSetter setState, {
    required ValueChanged<bool> setUploading,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      _showSnack(
        context,
        'Bạn chưa cấu hình Cloudinary cloudName và uploadPreset.',
      );
      return;
    }

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1400,
      );
    } catch (error) {
      if (context.mounted) {
        _showSnack(
          context,
          'Không mở được bộ chọn ảnh. Hãy stop app, chạy flutter pub get rồi flutter run lại. Lỗi: $error',
        );
      }
      return;
    }

    if (picked == null) return;

    setState(() {
      setUploading(true);
    });

    try {
      final url = await CloudinaryService().uploadFoodImage(picked);
      imageUrl.text = url;
      if (context.mounted) {
        _showSnack(context, 'Upload ảnh thành công.');
      }
    } catch (error) {
      if (context.mounted) {
        _showSnack(context, 'Upload ảnh thất bại: $error');
      }
    } finally {
      setState(() {
        setUploading(false);
      });
    }
  }

  // Màn hình phụ để quản lý toàn bộ biến thể của một món.
  Future<void> _showVariantsSheet(
    BuildContext context, {
    required String foodId,
    required String foodName,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Biến thể của $foodName',
                      style: Theme.of(sheetContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  FilledButton.icon(
                    style: _compactButtonStyle,
                    onPressed: () => _showVariantForm(
                      context,
                      foodId: foodId,
                      foodName: foodName,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _variants
                      .where('foodId', isEqualTo: foodId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    docs.sort((a, b) {
                      final priceA = a.data()['price'] as num? ?? 0;
                      final priceB = b.data()['price'] as num? ?? 0;
                      return priceA.compareTo(priceB);
                    });

                    if (docs.isEmpty) {
                      return const Center(child: Text('Chưa có biến thể'));
                    }

                    return ListView(
                      children: [
                        for (final doc in docs)
                          _variantTile(context, doc, foodName: foodName),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Form thêm/sửa biến thể: giá biến thể sẽ đồng bộ thành minPrice của món.
  Future<void> _showVariantForm(
    BuildContext context, {
    required String foodId,
    required String foodName,
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final name = TextEditingController(
      text: doc?.data()['name'] as String? ?? '',
    );
    final price = TextEditingController(
      text: ((doc?.data()['price'] as num?) ?? 0).toString(),
    );
    final unit = TextEditingController(
      text: doc?.data()['unit'] as String? ?? '',
    );
    var isActive = (doc?.data()['isActive'] as bool?) ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            doc == null
                ? 'Thêm biến thể cho $foodName'
                : 'Sửa biến thể của $foodName',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: _adminFieldDecoration('Tên biến thể / size'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: _adminFieldDecoration(
                    'Giá bán',
                  ).copyWith(suffixText: 'VND'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: unit,
                  decoration: _adminFieldDecoration('Đơn vị tính'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang bán biến thể này'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
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
                final safeName = name.text.trim();
                final safeUnit = unit.text.trim();
                final safePrice = int.tryParse(price.text.trim()) ?? 0;

                if (safeName.isEmpty || safeUnit.isEmpty || safePrice <= 0) {
                  _showSnack(
                    dialogContext,
                    'Vui lòng nhập tên biến thể, đơn vị và giá lớn hơn 0.',
                  );
                  return;
                }

                final payload = <String, dynamic>{
                  'foodId': foodId,
                  'name': safeName,
                  'price': safePrice,
                  'unit': safeUnit,
                  'isActive': isActive,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (doc == null) {
                  final variantId = await _nextSequentialDocId(
                    _variants,
                    'variant',
                  );
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await _variants.doc(variantId).set(payload);
                } else {
                  await doc.reference.update(payload);
                }

                await _syncMinPrice(foodId);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createVariantsForFood(
    String foodId,
    List<_ParsedVariant> variants,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    final firstVariantId = await _nextSequentialDocId(_variants, 'variant');
    final firstNumber =
        int.tryParse(firstVariantId.replaceFirst('variant', '')) ?? 1;

    for (var i = 0; i < variants.length; i++) {
      final variant = variants[i];
      final variantId =
          'variant${(firstNumber + i).toString().padLeft(2, '0')}';
      batch.set(_variants.doc(variantId), {
        'foodId': foodId,
        'name': variant.name,
        'price': variant.price,
        'unit': variant.unit,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
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
              final safeName = name.text.trim();
              if (safeName.isEmpty) return;

              final payload = {
                'name': safeName,
                'isActive': true,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (doc == null) {
                final categoryId = await _nextSequentialDocId(
                  _categories,
                  'category',
                );
                payload['createdAt'] = FieldValue.serverTimestamp();
                await _categories.doc(categoryId).set(payload);
              } else {
                await doc.reference.update(payload);
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncMinPrice(String foodId) async {
    final snapshot = await _variants.where('foodId', isEqualTo: foodId).get();
    final prices = snapshot.docs
        .where((doc) => doc.data()['isActive'] as bool? ?? true)
        .map((doc) => doc.data()['price'] as num? ?? 0)
        .where((price) => price > 0)
        .toList();
    prices.sort();

    await _foods.doc(foodId).set({
      'minPrice': prices.isEmpty ? 0 : prices.first,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteFoodWithVariants(String foodId) async {
    final variantSnapshot = await _variants
        .where('foodId', isEqualTo: foodId)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final variant in variantSnapshot.docs) {
      batch.delete(variant.reference);
    }
    batch.delete(_foods.doc(foodId));
    await batch.commit();
  }

  Widget _foodImage(
    String path, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    final trimmedPath = path.trim();
    if (trimmedPath.startsWith('lib/images/')) {
      return Image.asset(
        trimmedPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _emptyImage(width: width, height: height),
      );
    }
    if (trimmedPath.startsWith('http')) {
      return Image.network(
        trimmedPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _emptyImage(width: width, height: height),
      );
    }
    return _emptyImage(width: width, height: height);
  }

  Widget _emptyImage({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _VariantDraft {
  _VariantDraft({String name = '', String price = '', String unit = ''})
    : name = TextEditingController(text: name),
      price = TextEditingController(text: price),
      unit = TextEditingController(text: unit);

  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController unit;

  void dispose() {
    name.dispose();
    price.dispose();
    unit.dispose();
  }
}

class _ParsedVariant {
  const _ParsedVariant({
    required this.name,
    required this.price,
    required this.unit,
  });

  final String name;
  final int price;
  final String unit;
}

class _FoodImagePickerPanel extends StatelessWidget {
  const _FoodImagePickerPanel({
    required this.imageUrl,
    required this.isUploading,
    required this.preview,
    required this.onUrlChanged,
    required this.onPickImage,
  });

  final TextEditingController imageUrl;
  final bool isUploading;
  final Widget preview;
  final VoidCallback onUrlChanged;
  final VoidCallback? onPickImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, color: Color(0xFF0F766E)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ảnh món ăn',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: onPickImage,
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(isUploading ? 'Đang upload' : 'Chọn ảnh'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: imageUrl,
            decoration: _adminFieldDecoration('URL ảnh').copyWith(
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              prefixIcon: const Icon(Icons.link),
              hintText: 'Dán URL ảnh hoặc chọn ảnh từ máy',
            ),
            onChanged: (_) => onUrlChanged(),
          ),
          const SizedBox(height: 10),
          Container(
            height: 190,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: preview,
            ),
          ),
        ],
      ),
    );
  }
}

// Thanh tìm kiếm và lọc món ăn cho admin.
class _FoodAdminFilterBar extends StatelessWidget {
  const _FoodAdminFilterBar({
    required this.searchController,
    required this.selectedCategoryId,
    required this.categoriesStream,
    required this.onCategoryChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String selectedCategoryId;
  final Stream<QuerySnapshot<Map<String, dynamic>>> categoriesStream;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: categoriesStream,
      builder: (context, snapshot) {
        final categories = [...?snapshot.data?.docs]
          ..sort((a, b) {
            final nameA = a.data()['name'] as String? ?? a.id;
            final nameB = b.data()['name'] as String? ?? b.id;
            return nameA.compareTo(nameB);
          });
        final hasSelectedCategory =
            selectedCategoryId == 'all' ||
            categories.any((doc) => doc.id == selectedCategoryId);
        final safeCategoryId = hasSelectedCategory ? selectedCategoryId : 'all';
        final selectedCategoryName = safeCategoryId == 'all'
            ? 'Tất cả'
            : _categoryNameById(categories, safeCategoryId);
        final hasFilter =
            searchController.text.trim().isNotEmpty ||
            selectedCategoryId != 'all';

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Tìm món',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa tìm kiếm',
                              onPressed: searchController.clear,
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: Color(0xFF0F766E),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 134,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showCategoryPicker(context, categories, safeCategoryId),
                  icon: const Icon(Icons.menu, size: 20),
                  label: Text(
                    selectedCategoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasFilter) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Xóa lọc',
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> categories,
    String currentCategoryId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'Chọn danh mục',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            _CategoryChoiceTile(
              title: 'Tất cả món',
              selected: currentCategoryId == 'all',
              onTap: () {
                onCategoryChanged('all');
                Navigator.of(sheetContext).pop();
              },
            ),
            for (final doc in categories)
              _CategoryChoiceTile(
                title: doc.data()['name'] as String? ?? doc.id,
                selected: currentCategoryId == doc.id,
                onTap: () {
                  onCategoryChanged(doc.id);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _categoryNameById(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> categories,
    String categoryId,
  ) {
    for (final doc in categories) {
      if (doc.id == categoryId) {
        return doc.data()['name'] as String? ?? doc.id;
      }
    }
    return 'Tất cả';
  }
}

class _CategoryChoiceTile extends StatelessWidget {
  const _CategoryChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedTileColor: const Color(0xFFCCFBF1),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? const Color(0xFF0F766E) : null,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      onTap: onTap,
    );
  }
}

class _FoodAdminHeader extends StatelessWidget {
  const _FoodAdminHeader({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.icon,
    required this.onPressed,
    required this.style,
  });

  final String title;
  final String subtitle;
  final String buttonText;
  final IconData icon;
  final VoidCallback onPressed;
  final ButtonStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFCCFBF1),
            foregroundColor: const Color(0xFF0F766E),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'Còn bán' || status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAvailable ? 'Còn bán' : 'Hết món',
        style: TextStyle(
          color: isAvailable
              ? const Color(0xFF166534)
              : const Color(0xFF991B1B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VariantDraftList extends StatelessWidget {
  const _VariantDraftList({
    required this.variants,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_VariantDraft> variants;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Biến thể / size',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Thêm biến thể'),
              ),
            ],
          ),
          const Text(
            'Nhập ít nhất một biến thể. Có thể thêm nhiều size hoặc xóa dòng dư.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < variants.length; i++) ...[
            _VariantDraftRow(
              index: i,
              draft: variants[i],
              canRemove: variants.length > 1,
              onRemove: () => onRemove(i),
            ),
            if (i != variants.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _VariantDraftRow extends StatelessWidget {
  const _VariantDraftRow({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _VariantDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Biến thể ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Xóa biến thể',
                    onPressed: canRemove ? onRemove : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              TextField(
                controller: draft.name,
                decoration: _adminFieldDecoration('Tên size / biến thể'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: draft.price,
                      keyboardType: TextInputType.number,
                      decoration: _adminFieldDecoration(
                        'Giá',
                      ).copyWith(suffixText: 'VND'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: draft.unit,
                      decoration: _adminFieldDecoration('Đơn vị'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
