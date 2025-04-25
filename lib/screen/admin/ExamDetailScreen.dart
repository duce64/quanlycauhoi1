import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class ExamDetailScreen extends StatefulWidget {
  final String examId;
  final String title;
  final String department;

  const ExamDetailScreen({
    Key? key,
    required this.examId,
    required this.title,
    required this.department,
  }) : super(key: key);

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  int totalUsers = 10; // Số người giả định (hoặc lấy từ API users nếu có)
  List<Result> results = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    try {
      final res = await http.get(Uri.parse(
          'http://192.168.52.91:3000/api/results/by-test/${widget.examId}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        // Lọc kết quả theo testId
        final filtered = data
            .where((e) =>
                e['testId'] != null && e['testId'].toString() == widget.examId)
            .toList();

        setState(() {
          results = filtered.map((e) => Result.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Lỗi tải dữ liệu');
      }
    } catch (e) {
      print("Lỗi: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int completed = results.length;
    final int remaining = totalUsers - completed;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết: ${widget.title}'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Biểu đồ
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: completed.toDouble(),
                            title: '$completed đã thi',
                            color: Colors.green,
                            radius: 60,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: remaining.toDouble(),
                            title: '$remaining chưa thi',
                            color: Colors.grey,
                            radius: 60,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tổng số người (giả định): $totalUsers',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Danh sách kết quả:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Danh sách kết quả
                  Expanded(
                    child: results.isEmpty
                        ? const Center(
                            child: Text('Chưa có ai làm bài kiểm tra này.'))
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final r = results[index];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(r.username),
                                subtitle:
                                    Text('Điểm: ${r.score} - ${r.status}'),
                                trailing: Text(
                                  formatDate(r.date),
                                  style: const TextStyle(fontSize: 12),
                                ),
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class Result {
  final String username;
  final double score;
  final String status;
  final DateTime date;

  Result({
    required this.username,
    required this.score,
    required this.status,
    required this.date,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      username: json['userId']['username'],
      score: (json['score'] as num).toDouble(),
      status: json['status'],
      date: DateTime.parse(json['date']),
    );
  }
}
