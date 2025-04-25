import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/screen/admin/EditTestScreen.dart';
import 'package:http/http.dart' as http;

// Constants
const kPrimaryColor = Color(0xFF1976D2);
const kLightBackground = Color(0xFFE9F1FB);
const kCardBackground = Colors.white;
const kTitleColor = Color(0xFF002856);

class CreatedTestListScreen extends StatefulWidget {
  const CreatedTestListScreen({Key? key}) : super(key: key);

  @override
  State<CreatedTestListScreen> createState() => _CreatedTestListScreenState();
}

class _CreatedTestListScreenState extends State<CreatedTestListScreen> {
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCreatedTests();
  }

  Future<void> _fetchCreatedTests() async {
    try {
      final response =
          await http.get(Uri.parse("http://192.168.52.91:3000/api/exams"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _tests = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception("Không thể tải dữ liệu (${response.statusCode})");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTest(String id) async {
    final response =
        await http.delete(Uri.parse("http://192.168.52.91:3000/api/exams/$id"));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xoá bài kiểm tra")),
      );
      _fetchCreatedTests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xoá thất bại")),
      );
    }
  }

  void _editTest(Map<String, dynamic> test) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTestScreen(testData: test),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTitleColor),
        title: const Text(
          "📝 Danh sách bài kiểm tra đã tạo",
          style: TextStyle(
            color: kTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text("❌ $_error",
                      style: const TextStyle(color: Colors.red)))
              : _tests.isEmpty
                  ? const Center(child: Text("Không có bài kiểm tra nào"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tests.length,
                      itemBuilder: (context, index) {
                        final item = _tests[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kCardBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title'] ?? 'Không có tiêu đề',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: kTitleColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.orange),
                                    onPressed: () => _editTest(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteTest(item['_id']),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("Phòng: ${item['department'] ?? 'Chưa rõ'}",
                                  style: TextStyle(color: Colors.grey[700])),
                              Text("Hạn: ${formatDate(item['deadline'] ?? '')}",
                                  style: TextStyle(color: Colors.grey[600])),
                              Text(
                                  "Số người kiểm tra: ${item['users']?.length ?? 0}",
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Không xác định";
    }
  }
}
