import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/model/question.dart';
import 'package:flutterquiz/screen/quiz_screen.dart';
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
            '${AppConstants.baseUrl}/api/questions/by-category/${widget.categoryId}'),
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

  Future<void> _showAddPackageDialog() async {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _idController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thêm gói câu hỏi'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên gói câu hỏi',
                  ),
                ),
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Mã gói câu hỏi',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Thêm'),
              onPressed: () async {
                // Gửi yêu cầu API thêm gói câu hỏi
                final name = _nameController.text.trim();
                final idQuestion = _idController.text.trim();

                if (name.isNotEmpty && idQuestion.isNotEmpty) {
                  try {
                    final response = await http.post(
                      Uri.parse('${AppConstants.baseUrl}/api/questions'),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                      },
                      body: jsonEncode({
                        'categoryId': widget.categoryId,
                        'name': name,
                        'idQuestion': idQuestion,
                      }),
                    );

                    if (response.statusCode == 201) {
                      // Thêm thành công, load lại gói câu hỏi
                      _fetchPackages();
                      Navigator.of(context).pop();
                    } else {
                      throw Exception('Lỗi thêm gói câu hỏi');
                    }
                  } catch (e) {
                    print('Lỗi khi thêm gói câu hỏi: $e');
                  }
                }
              },
            ),
          ],
        );
      },
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
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: themeColor),
            onPressed:
                _showAddPackageDialog, // Hiển thị dialog khi bấm nút thêm
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kItemSelectBottomNav),
                  SizedBox(height: 16),
                  Text("Đang tải dữ liệu...",
                      style: TextStyle(color: Colors.grey[700])),
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
