import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/model/categories.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:http/http.dart' as http;

class ManageQuestionScreen extends StatefulWidget {
  const ManageQuestionScreen({Key? key}) : super(key: key);

  @override
  State<ManageQuestionScreen> createState() => _ManageQuestionScreenState();
}

class _ManageQuestionScreenState extends State<ManageQuestionScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;

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

  void _navigateToEdit(Category category) {
    Navigator.pushNamed(
      context,
      ManageQuestionPackageScreens,
      arguments: category,
    ).then((_) => _loadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F1FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: kItemSelectBottomNav),
        title: Text(
          "Quản lý câu hỏi",
          style: TextStyle(
            color: kItemSelectBottomNav,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () => _navigateToEdit(category),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              kItemSelectBottomNav.withOpacity(0.1),
                          backgroundImage:
                              MemoryImage(base64Decode(category.image)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF002856),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "ID: ${category.id}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey)
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
