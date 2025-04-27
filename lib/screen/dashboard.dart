import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/screen/ChangePasswordScreen.dart';
import 'package:flutterquiz/screen/ExamResultScreenUser.dart';
import 'package:flutterquiz/screen/UpdateProfileScreen.dart';
import 'package:flutterquiz/screen/admin/ongoing_test_screen.dart';
import 'package:flutterquiz/screen/homes_screen.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final List<String> menuTitles = [
    'Đang diễn ra',
    'Trang chủ',
    'Lịch sử',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
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
          screens = [
            OngoingTestScreen(),
            HomeScreen(),
            const UserExamResultScreen(),
            UpdateProfileScreen(),
            ChangePasswordScreen(),
          ];
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
            const Text("e64",
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
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            color: Colors.grey[800],
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'update') {
                setState(() => currentIndex = 3);
              } else if (value == 'change_password') {
                setState(() => currentIndex = 4);
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
                  onTap: () => setState(() => currentIndex = index),
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
}
