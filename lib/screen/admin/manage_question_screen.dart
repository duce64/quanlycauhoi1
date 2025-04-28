import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/model/categories.dart';
import 'package:flutterquiz/model/question_package.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:http/http.dart' as http;

class ManageQuestionPackageScreen extends StatefulWidget {
  final Category category;

  const ManageQuestionPackageScreen({Key? key, required this.category})
      : super(key: key);

  @override
  State<ManageQuestionPackageScreen> createState() =>
      _ManageQuestionPackageScreenState();
}

class _ManageQuestionPackageScreenState
    extends State<ManageQuestionPackageScreen> {
  List<QuestionPackage> _questionPackages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQuestionPackages();
  }

  Future<void> _fetchQuestionPackages() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/api/questions/by-category/${widget.category.id}',
        ),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _questionPackages =
              data.map((e) => QuestionPackage.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Lỗi khi tải dữ liệu từ server");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTitleColor),
        title: Text(
          "Gói câu hỏi - ${widget.category.name}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: kTitleColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    "Đã xảy ra lỗi: $_errorMessage",
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _questionPackages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          "Chưa có gói câu hỏi nào.\nNhấn ➕ để thêm mới.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _questionPackages.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final pkg = _questionPackages[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          tileColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          leading: CircleAvatar(
                            backgroundColor:
                                kItemSelectBottomNav.withOpacity(0.1),
                            child: Text(
                              pkg.idQuestion.toString(),
                              style: TextStyle(
                                color: kItemSelectBottomNav,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            pkg.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTitleColor,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              size: 20, color: Colors.grey),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AddQuestionScreens,
                              arguments: {
                                'categoryId': widget.category.id,
                                'idQuestionPackage': pkg.idQuestion,
                              },
                            ).then((_) => _fetchQuestionPackages());
                          },
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add),
        label: const Text("Thêm gói"),
        onPressed: () {
          Navigator.pushNamed(
            context,
            AddQuestionPackageScreens,
            arguments: {
              'categoryId': widget.category.id,
              'idQuestionPackage': null,
            },
          ).then((_) => _fetchQuestionPackages());
        },
      ),
    );
  }
}
