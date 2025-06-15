import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/screen/admin/ExamDetailScreen.dart';
import 'package:flutterquiz/screen/widgets/empty.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../util/constant.dart';

class AdminExamResultScreen extends StatefulWidget {
  const AdminExamResultScreen({Key? key}) : super(key: key);

  @override
  State<AdminExamResultScreen> createState() => _AdminExamResultScreenState();
}

class _AdminExamResultScreenState extends State<AdminExamResultScreen> {
  late Future<List<Exam>> futureExams;
  String _userName = '';
  String _department = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadUserFromToken();
    futureExams = fetchExams();
  }

  Future<void> _loadUserFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      final payload = token.split('.')[1];
      final decoded = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(payload))));
      setState(() {
        _userName = decoded['fullname'] ?? '';
        _department = decoded['department'] ?? '';
        _role = decoded['role'] ?? '';
      });
    }
  }

  Future<List<Exam>> fetchExams() async {
    final response =
        await http.get(Uri.parse('${AppConstants.baseUrl}/api/exams'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Exam.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải bài kiểm tra');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFE9F1FB),
        child: Column(
          children: [
            // Body
            Expanded(
              child: FutureBuilder<List<Exam>>(
                future: futureExams,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return EmptyStateWidget(
                    svgPath: 'assets/empty.svg',
                    message: 'Không có bài kiểm tra nào',
                  );
                  }

                  final exams = snapshot.data!;
                  return exams.length==0?
                  EmptyStateWidget(
                    svgPath: 'assets/empty.svg',
                    message: 'Không có bài kiểm tra nào',
                  )
                  :ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: exams.length,
                    itemBuilder: (context, index) {
                      final exam = exams[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExamDetailScreen(
                                examId: '${exam.id}',
                                title: '${exam.title}',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exam.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF002856),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Phòng ban: ${exam.department}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hạn: ${formatDate(exam.deadline)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.schedule,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tạo: ${formatDate(exam.createdAt)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}

class Exam {
  final String id;
  final String title;
  final int questionPackageId;
  final String userId;
  final String department;
  final DateTime deadline;
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.title,
    required this.questionPackageId,
    required this.userId,
    required this.department,
    required this.deadline,
    required this.createdAt,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['_id'],
      title: json['title'],
      questionPackageId: json['questionPackageId'],
      userId: json['userId'],
      department: json['department'],
      deadline: DateTime.parse(json['deadline']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
