import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/screen/ChangePasswordScreen.dart';
import 'package:flutterquiz/screen/ExamResultScreenUser.dart';
import 'package:flutterquiz/screen/UpdateProfileScreen.dart';
import 'package:flutterquiz/screen/admin/AdminExamResultScreen.dart';
import 'package:flutterquiz/screen/admin/category_admin_screen.dart';
import 'package:flutterquiz/screen/admin/ongoing_test_screen.dart';
import 'package:flutterquiz/screen/admin/question_admin_screen.dart';
import 'package:flutterquiz/screen/homes_screen.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;
  bool isAdmin = false;
  String? userFullName;
  List<Widget> screens = [];
  List<dynamic> _notifications = [];
  List<String> menuTitles = [];

  int unreadCount = 0;
  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final payload = base64Url.normalize(token.split('.')[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      final userId = decoded['userId'] ?? '';

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/notifications/user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(response.body);
          unreadCount =
              _notifications.where((notif) => notif['isRead'] == false).length;
        });
      }
    } catch (e) {
      print("Lỗi khi tải thông báo: $e");
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = base64.normalize(parts[1]);
        final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
        final role = decoded['role'] ?? '';
        userFullName = decoded['fullname'] ?? '';
        setState(() {
          isAdmin = role == 'admin';
          if (isAdmin) {
            menuTitles = [
              'Đang diễn ra',
              'Luyện tập',
              'Lịch sử',
              'Quản lý câu hỏi',
              'Quản lý danh mục',
              'Kết quả kiểm tra',
            ];
            screens = [
              OngoingTestScreen(),
              HomesScreen(),
              const UserExamResultScreen(),
              const ManageQuestionScreen(),
              const ManageCategoryScreen(),
              const AdminExamResultScreen(),
              UpdateProfileScreen(),
              ChangePasswordScreen(),
            ];
          } else {
            menuTitles = [
              'Đang diễn ra',
              'Luyện tập',
              'Lịch sử',
            ];
            screens = [
              OngoingTestScreen(),
              HomesScreen(),
              const UserExamResultScreen(),
              UpdateProfileScreen(),
              ChangePasswordScreen(),
            ];
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = kItemSelectBottomNav;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text("PHẦN MỀM KIỂM TRA TRỰC TUYẾN",
                style: TextStyle(fontSize: 18, color: Colors.black)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
            color: Colors.grey[800],
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
            color: Colors.grey[800],
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications,
                    color: Colors.blue, size: 30),
                tooltip: 'Thông báo',
                onPressed: _showNotifications,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'update') {
                setState(() => currentIndex = isAdmin ? 6 : 3);
              } else if (value == 'change_password') {
                setState(() => currentIndex = isAdmin ? 7 : 4);
              } else if (value == 'logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token'); // Xóa token
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('LoginScreen',
                    (route) => false); // Điều hướng về màn đăng nhập
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'update',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Cập nhật thông tin'),
                ),
              ),
              const PopupMenuItem(
                value: 'change_password',
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Đổi mật khẩu'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
            child: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                (userFullName != null && userFullName!.isNotEmpty)
                    ? userFullName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: Colors.white,
            child: Row(
              children: List.generate(menuTitles.length, (index) {
                final selected = index == currentIndex;
                return InkWell(
                  onTap: () => setState(() {
                    if (index < screens.length) {
                      currentIndex = index;
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              selected ? Colors.deepPurple : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      menuTitles[index],
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? Colors.deepPurple : Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: screens.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: currentIndex,
              children: screens,
            ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🔔 Thông báo",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kItemSelectBottomNav,
              ),
            ),
            const Divider(height: 24),
            if (_notifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "Không có thông báo mới.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final bool isRead = notif['isRead'] == true;

                    return InkWell(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('auth_token');
                        if (token == null) return;

                        final payload =
                            base64Url.normalize(token.split('.')[1]);
                        final decoded =
                            jsonDecode(utf8.decode(base64Url.decode(payload)));
                        final userId = decoded['userId'];
                        final questionId = notif['questionId'];

                        // ✅ Đánh dấu đã đọc
                        await http.put(
                          Uri.parse(
                              '${AppConstants.baseUrl}/api/notifications/${notif['_id']}/read'),
                          headers: {'Authorization': 'Bearer $token'},
                        );

                        _loadNotifications();

                        final expiredDateStr = notif['expiredDate'];
                        final expiredDate = expiredDateStr != null
                            ? DateTime.tryParse(expiredDateStr)
                            : null;
                        final isExpired = expiredDate != null
                            ? expiredDate.isBefore(DateTime.now())
                            : true;

                        final checkRes = await http.get(
                          Uri.parse(
                              '${AppConstants.baseUrl}/api/results/check?userId=$userId&testId=${notif['_id']}'),
                          headers: {'Authorization': 'Bearer $token'},
                        );

                        final checkData = jsonDecode(checkRes.body);

                        if (checkRes.statusCode == 200 &&
                            checkData['hasTaken'] == false &&
                            !isExpired) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
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
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Huỷ"),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
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
                            Navigator.pushNamed(
                              context,
                              QuizScreenH,
                              arguments: {
                                'categoryId': notif['categoryId'],
                                'questionId': notif['questionId'],
                                'idTest': '${notif['idTest']}',
                                'isTest': true,
                              },
                            );
                          }
                        } else if (isExpired) {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_off,
                                        color: Colors.redAccent, size: 48),
                                    const SizedBox(height: 12),
                                    const Text("Bài kiểm tra này đã hết hạn.",
                                        style: TextStyle(fontSize: 16)),
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
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_outline,
                                        color: Colors.orange, size: 48),
                                    const SizedBox(height: 12),
                                    const Text(
                                        "Bạn đã hoàn thành bài kiểm tra này.",
                                        style: TextStyle(fontSize: 16)),
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
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notifications,
                                size: 30, color: kItemSelectBottomNav),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif['content'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatDate(notif['date']),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ngày hết hạn: ${formatDate(notif['expiredDate'] ?? '')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isRead)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) =>
                                    SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                                child: isRead
                                    ? Container(
                                        key: const ValueKey("read"),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border:
                                              Border.all(color: Colors.green),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.check_circle,
                                                color: Colors.green, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              "Đã đọc",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
