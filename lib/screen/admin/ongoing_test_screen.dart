import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/screen/admin/CreateExamScreen.dart';
import 'package:flutterquiz/screen/quiz_screens.dart';
import 'package:flutterquiz/screen/widgets/empty.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final payload = base64Url.normalize(token.split('.')[1]);
    final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
    final userId = decoded['userId'];
    try {
      final ongoingRes = await http.get(Uri.parse(
          '${AppConstants.baseUrl}/api/exams/ongoing?userId=$userId'));
      final expiredRes = await http.get(Uri.parse(
          '${AppConstants.baseUrl}/api/exams/expired?userId=$userId'));

      if (ongoingRes.statusCode == 200) {
        List data = jsonDecode(ongoingRes.body);
        setState(() {
          ongoingTests =
              data.map<Map<String, dynamic>>((test) => _mapTest(test)).toList();
          isLoadingOngoing = false;
          print('ongoingTests: $ongoingTests');
        });
      }else{
        print('❌ Lỗi khi load ongoing tests: ${ongoingRes.statusCode}');
        setState(() {
          isLoadingOngoing = false;
        });
      }

      if (expiredRes.statusCode == 200) {
        List data = jsonDecode(expiredRes.body);
        setState(() {
          expiredTests =
              data.map<Map<String, dynamic>>((test) => _mapTest(test)).toList();
          isLoadingExpired = false;
        });
      }else{
        print('❌ Lỗi khi load expired tests: ${expiredRes.statusCode}');
        setState(() {
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
    final deadline = test['deadline'];
    String formattedDeadline = 'N/A';
    if (deadline != null) {
      try {
        final date = DateTime.parse(deadline);
        formattedDeadline =
            'Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}';
      } catch (e) {
        formattedDeadline = 'Hạn: ${test['deadline']}'; // fallback nếu lỗi
      }
    }

    return {
      '_id': test['_id'],
      'title': test['title'] ?? '',
      'start': 'N/A',
      'end': formattedDeadline,
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
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   title: const Text(''),
      // ),
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

  Future<bool> _checkAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = base64.normalize(parts[1]);
        final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
        final role = decoded['role'] ?? '';
        return role == 'admin';
      }
    }
    return false;
  }

  Widget _buildCreateButton() {
    return FutureBuilder<bool>(
      future: _checkAdminRole(), // Gọi hàm kiểm tra admin
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(); // hoặc có thể để loading nhỏ
        }

        bool isAdmin = snapshot.data ?? false;
        if (!isAdmin) return const SizedBox(); // Không phải admin thì ẩn luôn

        return Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E3D9D),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, CreateExamScreens).then((value) {
                print('value: $value');
                fetchTests(); // Gọi lại hàm load bài kiểm tra sau khi tạo mới
                setState(() {});
              });
            },
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text("Tạo bài kiểm tra",
                style: TextStyle(fontSize: 14, color: Colors.white)),
          ),
        );
      },
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
              ? EmptyStateWidget(
                  svgPath: 'assets/empty.svg',
                  message: isExpired
                      ? "Không có bài kiểm tra đã hết hạn."
                      : "Không có bài kiểm tra đang diễn ra.")
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse, // 👉 Cho phép kéo bằng chuột
                    },
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tests.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final test = tests[index];
                      return GestureDetector(
                        onTap: () => _onTestTap(test, isExpired),
                        child: _TestCard(
                            test: test,
                            isExpired: isExpired,
                            onDeleted: () {
                              fetchTests(); // Gọi lại hàm load bài kiểm tra
                            }),
                      );
                    },
                  ),
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

class _TestCard extends StatefulWidget {
  final Map<String, dynamic> test;
  final bool isExpired;
  final VoidCallback onDeleted;

  const _TestCard(
      {Key? key,
      required this.test,
      required this.isExpired,
      required this.onDeleted})
      : super(key: key);

  @override
  State<_TestCard> createState() => _TestCardState();
}

class _TestCardState extends State<_TestCard> {
  late Future<bool> isAdmin;

  @override
  void initState() {
    super.initState();
    isAdmin = _checkAdminRole(); // Kiểm tra quyền admin khi widget được tạo
  }

  Future<bool> _checkAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = base64.normalize(parts[1]);
        final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
        final role = decoded['role'] ?? '';

        // Trả về true nếu là admin
        return role == 'admin';
      }
    }
    return false; // Nếu không có token hoặc không phải admin
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isAdmin, // Đợi kiểm tra quyền admin
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Hoặc một widget chờ đợi
        }

        bool isAdmin = snapshot.data ?? false; // Nếu là admin

        return Opacity(
          opacity: widget.isExpired ? 0.6 : 1.0,
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
                  widget.test['title'],
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _infoRow(Icons.access_time, widget.test['start']),
                _infoRow(Icons.access_time_outlined, widget.test['end']),
                _infoRow(Icons.timer_outlined,
                    "Thời gian: ${widget.test['duration']}"),
                _infoRow(
                    Icons.list_alt, "Câu hỏi: ${widget.test['questions']}"),
                _infoRow(Icons.groups_outlined,
                    widget.test['isPublic'] ? "Công khai" : "Riêng tư"),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isExpired ? "Đã hết hạn" : "Đang diễn ra",
                      style: TextStyle(
                        color: widget.isExpired ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Hiển thị menu "Sửa" và "Xóa" nếu là admin
                    if (isAdmin)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editTest(widget.test); // Sửa bài kiểm tra
                          } else if (value == 'delete') {
                            _deleteTest(widget.test); // Xóa bài kiểm tra
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Sửa'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Xóa'),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert,
                            size: 18, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editTest(Map<String, dynamic> exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExamScreen(
          exam: {
            '_id': exam['_id'],
            'title': exam['title'],
            'expiredDate': exam['expiredDate'],
            'timeLimit': exam['timeLimit'],
            'questionCount': exam['questionCount'],
            'questionPackageId': exam['questionPackageId'],
            'selectedUsers': exam['selectedUsers'],
            'department': exam['department'],
            'categoryId': exam['categoryId'],
          },
        ),
      ),
    ).then((value) {
      widget.onDeleted(); // GỌI LẠI load
    });
  }

  void _deleteTest(Map<String, dynamic> test) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content:
            const Text('Bạn có chắc chắn muốn xóa bài kiểm tra này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await http.delete(
          Uri.parse('${AppConstants.baseUrl}/api/exams/${test['_id']}'),
          headers: {
            'Authorization': 'Bearer ${await _getAuthToken()}',
          },
        );

        if (res.statusCode == 200) {
          widget.onDeleted(); // GỌI LẠI load
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa bài kiểm tra thành công')),
          );
        }
      } catch (e) {
        print('❌ Lỗi xóa bài kiểm tra: $e');
      }
    }
  }

// Hàm lấy token (ví dụ, từ SharedPreferences)
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
      ],
    );
  }
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
