import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/model/categories.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ManageCategoryScreen extends StatefulWidget {
  const ManageCategoryScreen({Key? key}) : super(key: key);

  @override
  State<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;

  // ✅ Thêm biến tìm kiếm
  TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/categories'),
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        setState(() {
          _categories = data.map((e) => Category.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Lỗi khi tải category: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc chắn muốn xoá danh mục này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/categories/$id'),
      );

      if (response.statusCode == 200) {
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xoá danh mục")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xoá thất bại")),
        );
      }
    }
  }

  void _navigateToEdit(Category category) {
    Navigator.pushNamed(
      context,
      EditCategoryScreens,
      arguments: category,
    ).then((_) => _loadCategories());
  }

  // ✅ Hàm lọc danh mục theo từ khóa
  List<Category> _filteredCategories() {
    if (_searchKeyword.isEmpty) return _categories;
    return _categories
        .where((cat) =>
            cat.name.toLowerCase().contains(_searchKeyword.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: kItemSelectBottomNav),
        title: const Text(
          "Danh mục",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Ô tìm kiếm + nút tạo danh mục
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nhập từ khoá',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchKeyword = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      border: const UnderlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchKeyword = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AddCategoryScreens).then((_) {
                      _loadCategories();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Tạo danh mục"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCategories().length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final category = _filteredCategories()[index];
                      return ListTile(
                        leading: const Icon(Icons.list_alt,
                            color: Colors.deepPurple),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_open_outlined,
                                color: Colors.grey),
                            const SizedBox(width: 4),
                            const Text("0"), // hoặc số câu hỏi nếu có
                            const SizedBox(width: 16),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditDialog(category);
                                } else if (value == 'delete') {
                                  _deleteCategory(category.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text("Chỉnh sửa"),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text("Xoá"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Category category) {
    final TextEditingController nameController =
        TextEditingController(text: category.name);
    String imageBase64 = category.image;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cập nhật danh mục',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Tên danh mục',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.list_alt),
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final picked = await ImagePicker()
                    .pickImage(source: ImageSource.gallery, imageQuality: 60);
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() {
                    imageBase64 = base64Encode(bytes);
                  });
                }
              },
              child: Column(
                children: [
                  const Text(
                    'Ảnh đại diện',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: imageBase64.isNotEmpty
                        ? Image.memory(base64Decode(imageBase64),
                            fit: BoxFit.cover)
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            onPressed: () async {
              final updatedCategory = {
                'name': nameController.text.trim(),
                'image': imageBase64,
              };

              final response = await http.put(
                Uri.parse(
                    '${AppConstants.baseUrl}/api/categories/${category.id}'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(updatedCategory),
              );

              if (response.statusCode == 200) {
                Navigator.pop(context);
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cập nhật thành công")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cập nhật thất bại")),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
