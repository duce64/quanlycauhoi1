import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/model/categories.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:http/http.dart' as http;
import '../../model/question_package.dart';

const kPrimaryColor = Color(0xFF1976D2);
const kLightBackground = Color(0xFFE9F1FB);
const kCardBackground = Colors.white;
const kTitleColor = Color(0xFF002856);

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
          'http://192.168.52.91:3000/api/questions/by-category/${widget.category.id}',
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
      backgroundColor: kLightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTitleColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "📦 Gói câu hỏi - ${widget.category.name}",
          style: const TextStyle(
            color: kTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: kPrimaryColor),
            onPressed: () {},
          )
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryColor,
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(
        child: Text(
          "Đã xảy ra lỗi: $_errorMessage",
          style: const TextStyle(color: Colors.red),
        ),
      );
    } else if (_questionPackages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Chưa có gói câu hỏi nào.\nNhấn ➕ để thêm mới.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: kTitleColor),
          ),
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _questionPackages.length,
        itemBuilder: (context, index) {
          final pkg = _questionPackages[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              leading: CircleAvatar(
                backgroundColor: kPrimaryColor.withOpacity(0.1),
                child: Text(
                  pkg.idQuestion.toString(),
                  style: const TextStyle(
                    color: kPrimaryColor,
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
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.grey),
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
            ),
          );
        },
      );
    }
  }
}
