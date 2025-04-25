import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/model/question.dart';
import 'package:flutterquiz/screen/quiz_screen.dart';
import 'package:flutterquiz/screen/quiz_screens.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:http/http.dart' as http;

class QuestionPackageListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const QuestionPackageListScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<QuestionPackageListScreen> createState() =>
      _QuestionPackageListScreenState();
}

class _QuestionPackageListScreenState extends State<QuestionPackageListScreen> {
  bool _isLoading = true;
  List<dynamic> _packages = [];

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    try {
      final res = await http.get(
        Uri.parse(
            'http://192.168.52.91:3000/api/questions/by-category/${widget.categoryId}'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _packages = data;
          _isLoading = false;
        });
      } else {
        throw Exception("Lỗi tải gói câu hỏi");
      }
    } catch (e) {
      print("Lỗi: $e");
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStyledItem(Map<String, dynamic> pkg) {
    final themeColor = Color(0xFF002856);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: kItemSelectBottomNav.withOpacity(0.1),
            child: Icon(Icons.folder, color: kItemSelectBottomNav),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg['name'] ?? 'Không tên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Mã gói: ${pkg['idQuestion']}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(0xFF002856);
    final bgColor = Color(0xFFE9F1FB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: themeColor),
        title: Text(
          "📦 Gói câu hỏi - ${widget.categoryName}",
          style: TextStyle(color: themeColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kItemSelectBottomNav),
                  SizedBox(height: 16),
                  Text("Đang tải dữ liệu...",
                      style: TextStyle(color: Colors.grey[700]))
                ],
              ),
            )
          : _packages.isEmpty
              ? const Center(child: Text("Không có gói câu hỏi nào"))
              : ListView.builder(
                  itemCount: _packages.length,
                  itemBuilder: (context, index) {
                    final pkg = _packages[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          QuizScreenH,
                          arguments: {
                            'categoryId': widget.categoryId,
                            'questionId': pkg['idQuestion'],
                            'idTest': 'null',
                            'isTest': false,
                          },
                        ).then((_) => _fetchPackages());
                      },
                      child: _buildStyledItem(pkg),
                    );
                  },
                ),
    );
  }
}
