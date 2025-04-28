import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/screen/quiz_screens.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class OngoingTestScreen extends StatefulWidget {
  const OngoingTestScreen({Key? key}) : super(key: key);

  @override
  State<OngoingTestScreen> createState() => _OngoingTestScreenState();
}

class _OngoingTestScreenState extends State<OngoingTestScreen> {
  bool isLoadingOngoing = true;
  bool isLoadingExpired = true;

  List<Map<String, dynamic>> ongoingTests = [];
  List<Map<String, dynamic>> expiredTests = [];

  @override
  void initState() {
    super.initState();
    fetchTests();
  }

  Future<void> fetchTests() async {
    try {
      final ongoingRes = await http
          .get(Uri.parse('${AppConstants.baseUrl}/api/exams/ongoing'));
      final expiredRes = await http
          .get(Uri.parse('${AppConstants.baseUrl}/api/exams/expired'));

      if (ongoingRes.statusCode == 200) {
        List data = jsonDecode(ongoingRes.body);
        setState(() {
          ongoingTests =
              data.map<Map<String, dynamic>>((test) => _mapTest(test)).toList();
          isLoadingOngoing = false;
          print('ongoingTests: $ongoingTests');
        });
      }

      if (expiredRes.statusCode == 200) {
        List data = jsonDecode(expiredRes.body);
        setState(() {
          expiredTests =
              data.map<Map<String, dynamic>>((test) => _mapTest(test)).toList();
          isLoadingExpired = false;
        });
      }
    } catch (e) {
      print('❌ Lỗi khi load tests: $e');
      setState(() {
        isLoadingOngoing = false;
        isLoadingExpired = false;
      });
    }
  }

  Map<String, dynamic> _mapTest(dynamic test) {
    return {
      '_id': test['_id'],
      'title': test['title'] ?? '',
      'start': 'N/A',
      'end': 'Hạn: ${test['deadline'] ?? ''}',
      'duration': '${test['timeLimit'] ?? ''} phút',
      'questions': '${test['questionCount']} câu',
      'numberQuestion': test['questionCount'] ?? 0,
      'isPublic': true,
      'categoryId': test['categoryId'],
      'questionPackageId': test['questionPackageId'],
      'timeLimit': test['timeLimit'],
    };
  }

  void _onTestTap(Map<String, dynamic> test, bool isExpired) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final payload = base64Url.normalize(token.split('.')[1]);
    final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
    final userId = decoded['userId'] ?? '';
    final checkRes = await http.get(
      Uri.parse(
          '${AppConstants.baseUrl}/api/results/check?userId=$userId&testId=${test['_id']}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final checkData = jsonDecode(checkRes.body);
    print('checkData: $checkData');

    if (checkRes.statusCode == 200 &&
        checkData['hasTaken'] == false &&
        !isExpired) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_fill,
                    color: Colors.blue, size: 48),
                const SizedBox(height: 12),
                const Text(
                  "Bạn có muốn bắt đầu bài kiểm tra này ngay bây giờ không?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Huỷ"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check),
                      label: const Text("Bắt đầu"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirm == true) {
        print('check questionCount${test['numberQuestion']}');

        Navigator.pushNamed(
          context,
          'QuizScreenH',
          arguments: {
            'categoryId': test['categoryId'],
            'questionId': test['questionPackageId'],
            'idTest': test['_id'],
            'isTest': true,
            'timeLimitMinutes':
                (test['timeLimit'] ?? 0), // phút x 60 thành giây
            'numberQuestion': test['numberQuestion']
          },
        );
      }
    } else if (isExpired) {
      _showSimpleDialog(
          icon: Icons.timer_off,
          color: Colors.redAccent,
          text: "Bài kiểm tra này đã hết hạn.");
    } else {
      _showSimpleDialog(
          icon: Icons.info_outline,
          color: Colors.orange,
          text: "Bạn đã hoàn thành bài kiểm tra này.");
    }
  }

  void _showSimpleDialog(
      {required IconData icon, required Color color, required String text}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 12),
              Text(text, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(''),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreateButton(),
            const SizedBox(height: 16),
            _buildSectionTitle("Đang diễn ra"),
            _buildTestList(isLoadingOngoing, ongoingTests, false),
            const SizedBox(height: 24),
            _buildSectionTitle("Đã hết hạn"),
            _buildTestList(isLoadingExpired, expiredTests, true),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3E3D9D),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          // TODO: điều hướng sang trang Tạo bài kiểm tra
          Navigator.pushNamed(context, CreateExamScreens).then(
            (value) {
              if (value == true) {
                fetchTests();
              }
            },
          );
        },
        icon: const Icon(Icons.add, size: 16, color: Colors.white),
        label: const Text("Tạo bài kiểm tra",
            style: TextStyle(fontSize: 14, color: Colors.white)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTestList(
      bool isLoading, List<Map<String, dynamic>> tests, bool isExpired) {
    return SizedBox(
      height: 260,
      child: isLoading
          ? _buildSkeleton()
          : tests.isEmpty
              ? const Center(child: Text('Không có bài kiểm tra nào'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tests.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final test = tests[index];
                    return GestureDetector(
                      onTap: () => _onTestTap(test, isExpired),
                      child: _TestCard(test: test, isExpired: isExpired),
                    );
                  },
                ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      separatorBuilder: (context, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}

class _TestCard extends StatelessWidget {
  final Map<String, dynamic> test;
  final bool isExpired;

  const _TestCard({Key? key, required this.test, required this.isExpired})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isExpired ? 0.6 : 1.0,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              test['title'],
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.access_time, test['start']),
            _infoRow(Icons.access_time_outlined, test['end']),
            _infoRow(Icons.timer_outlined, "Thời gian: ${test['duration']}"),
            _infoRow(Icons.list_alt, "Câu hỏi: ${test['questions']}"),
            _infoRow(Icons.groups_outlined,
                test['isPublic'] ? "Công khai" : "Riêng tư"),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isExpired ? "Đã hết hạn" : "Đang diễn ra",
                  style: TextStyle(
                    color: isExpired ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
