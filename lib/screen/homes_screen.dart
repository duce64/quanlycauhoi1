import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/model/categories.dart';
import 'package:flutterquiz/model/question_package.dart';
import 'package:flutterquiz/screen/widgets/empty.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:http/http.dart' as http;

class HomesScreen extends StatefulWidget {
  const HomesScreen({Key? key}) : super(key: key);

  @override
  State<HomesScreen> createState() => _ManageQuestionScreenState();
}

class _ManageQuestionScreenState extends State<HomesScreen> {
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
    // Filter categories and question packages based on search keyword
    return _categories.where((category) {
      final isCategoryMatch =
          category.name.toLowerCase().contains(_searchKeyword.toLowerCase());

      // Filter question packages based on the search keyword
      final questionPackages = _questionPackagesByCategory[category.id] ?? [];
      final filteredPackages = questionPackages.where((pkg) {
        return pkg.name.toLowerCase().contains(_searchKeyword.toLowerCase());
      }).toList();

      // Show category if it matches or if it has matching question packages
      return isCategoryMatch || filteredPackages.isNotEmpty;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories().length==0?
                EmptyStateWidget(
                    svgPath: 'assets/empty.svg',
                    message: 'Không có gói câu hỏi nào ',
                  )
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

                      // Filtered packages based on the search keyword
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
                                  title: _highlightText(
                                      'Gói câu hỏi ${pkg.name}',
                                      _searchKeyword),
                                  // subtitle: Text("ID gói: ${pkg.}"),
                                  leading: const Icon(
                                      Icons.folder_open_outlined,
                                      color: Colors.grey),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      QuizScreenH,
                                      arguments: {
                                        'categoryId': category.id,
                                        'questionId': pkg.idQuestion,
                                        'idTest': 'null',
                                        'isTest': false,
                                        'timeLimitMinutes':
                                            (999 ?? 0), // phút x 60 thành giây
                                      },
                                    );
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

String formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$day/$month/$year $hour:$minute";
  } catch (e) {
    return isoDate; // fallback nếu lỗi
  }
}