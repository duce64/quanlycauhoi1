import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/model/categories.dart';
import 'package:flutterquiz/model/question_package.dart';
import 'package:flutterquiz/screen/admin/ViewQuestionsByCategoryScreen.dart';
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
  Map<int, List<QuestionPackage>> _questionPackagesByCategory = {};
  Set<int> _expandedCategoryIds = {};

  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response =
          await http.get(Uri.parse('${AppConstants.baseUrl}/api/categories'));
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

  Future<void> _fetchQuestionPackages(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConstants.baseUrl}/api/questions/by-category/$categoryId'),
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        setState(() {
          _questionPackagesByCategory[categoryId] =
              data.map((e) => QuestionPackage.fromJson(e)).toList();
        });
      } else {
        print('Lỗi khi load gói câu hỏi');
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
    }
  }

  List<Category> _filteredCategories() {
    return _categories;
  }

  Widget _highlightText(String text, String keyword) {
    if (keyword.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();

    if (!lowerText.contains(lowerKeyword)) {
      return Text(text);
    }

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerKeyword, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + keyword.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + keyword.length;
    }

    return RichText(
        text: TextSpan(
            style: const TextStyle(color: Colors.black), children: spans));
  }

  // Nút Thêm câu hỏi
  Widget _buildAddQuestionButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3E3D9D),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          _showAddQuestionDialog();
        },
        icon: const Icon(Icons.add, size: 16, color: Colors.white),
        label: const Text(
          "Thêm câu hỏi",
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  // trong ManageQuestionScreen
  void _showAddQuestionDialog() {
    TextEditingController _questionNameController = TextEditingController();
    int? _selectedCategoryId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thêm câu hỏi mới'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown chọn category
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Chọn danh mục',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategoryId,
                    items: _categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // TextField nhập tên câu hỏi
                  TextField(
                    controller: _questionNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên câu hỏi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String questionName = _questionNameController.text.trim();

                    if (_selectedCategoryId != null &&
                        questionName.isNotEmpty) {
                      try {
                        final response = await http.post(
                          Uri.parse(
                              '${AppConstants.baseUrl}/api/questions/add'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'name': questionName,
                            'idCategory': _selectedCategoryId,
                          }),
                        );

                        if (response.statusCode == 201) {
                          Navigator.of(context).pop(); // Đóng dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Thêm câu hỏi thành công!')),
                          );

                          // 🆕 Nếu đang mở Category đó, reload lại câu hỏi
                          if (_expandedCategoryIds
                              .contains(_selectedCategoryId)) {
                            await _fetchQuestionPackages(_selectedCategoryId!);
                          }
                          setState(() {}); // cập nhật giao diện sau khi reload
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Lỗi khi thêm câu hỏi: ${response.body}')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi kết nối server: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Vui lòng chọn danh mục và nhập tên câu hỏi')),
                      );
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
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
          "Quản lý câu hỏi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          // Nút Thêm câu hỏi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildAddQuestionButton(),
          ),
          const SizedBox(height: 8),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên gói câu hỏi',
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
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCategories().length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final category = _filteredCategories()[index];
                      final isExpanded =
                          _expandedCategoryIds.contains(category.id);
                      final allPackages =
                          _questionPackagesByCategory[category.id] ?? [];

                      // lọc gói theo từ khóa tìm kiếm
                      final filteredPackages = allPackages
                          .where((pkg) => pkg.name
                              .toLowerCase()
                              .contains(_searchKeyword.toLowerCase()))
                          .toList();

                      return ExpansionTile(
                        initiallyExpanded: isExpanded,
                        leading: const Icon(Icons.help_outline_rounded,
                            color: Colors.deepPurple),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedCategoryIds.add(category.id);
                              if (!_questionPackagesByCategory
                                  .containsKey(category.id)) {
                                _fetchQuestionPackages(category.id);
                              }
                            } else {
                              _expandedCategoryIds.remove(category.id);
                            }
                          });
                        },
                        children: filteredPackages.isEmpty
                            ? const [
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    "Không có gói phù hợp.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              ]
                            : filteredPackages.map((pkg) {
                                return ListTile(
                                  title:
                                      _highlightText(pkg.name, _searchKeyword),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'view') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ViewQuestionsByCategoryScreen(
                                              categoryId: pkg.idQuestion,
                                            ),
                                          ),
                                        );
                                      } else if (value == 'add') {
                                        Navigator.pushNamed(
                                          context,
                                          AddQuestionScreens,
                                          arguments: {
                                            'categoryId': category.id,
                                            'idQuestionPackage': pkg.idQuestion,
                                          },
                                        );
                                      }
                                      if (value == 'remove') {
                                        final shouldDelete =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Xác nhận xóa'),
                                            content: Text(
                                                'Bạn có chắc chắn muốn xóa gói câu hỏi này không?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: Text('Hủy'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: Text('Xóa'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (shouldDelete == true) {
                                          try {
                                            print(
                                                'Xóa gói câu hỏi: ${pkg.idQuestion}');
                                            final id = pkg.idQuestion;

                                            // Xóa gói câu hỏi
                                            final response1 = await http.delete(
                                              Uri.parse(
                                                  '${AppConstants.baseUrl}/api/questions/package/$id'),
                                            );

                                            // Xóa câu hỏi trong gói
                                            final response2 = await http.delete(
                                              Uri.parse(
                                                  '${AppConstants.baseUrl}/api/questions/delete/$id'),
                                            );

                                            if (response1.statusCode == 200 ||
                                                response2.statusCode == 200) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content:
                                                        Text('Xóa thành công')),
                                              );
                                              _loadCategories();
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content:
                                                        Text('Xóa thất bại')),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text('Lỗi: $e')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: Text('Xem toàn bộ câu hỏi'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'add',
                                        child: Text('Thêm câu hỏi'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'remove',
                                        child: Text('Xóa bộ câu hỏi'),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text("ID gói: ${pkg.idQuestion}"),
                                  leading: const Icon(
                                      Icons.folder_open_outlined,
                                      color: Colors.grey),
                                  onTap: () {
                                    // Navigator.pushNamed(
                                    //   context,
                                    //   AddQuestionScreens,
                                    //   arguments: {
                                    //     'categoryId': category.id,
                                    //     'idQuestionPackage': pkg.idQuestion,
                                    //   },
                                    // );
                                    // Navigator.pushNamed(
                                    //   context,
                                    //   QuestionPackageListScreens,
                                    //   arguments: {
                                    //     'categoryId': category.id,
                                    //     'idQuestionPackage': pkg.idQuestion,
                                    //   },
                                    // );
                                  },
                                );
                              }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
