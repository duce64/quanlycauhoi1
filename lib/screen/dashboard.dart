import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/screen/ChangePasswordScreen.dart';
import 'package:flutterquiz/screen/ExamResultScreenUser.dart';
import 'package:flutterquiz/screen/UpdateProfileScreen.dart';
import 'package:flutterquiz/screen/admin/AdminExamResultScreen.dart';
import 'package:flutterquiz/screen/admin/CreatedTestListScreen.dart';
import 'package:flutterquiz/screen/admin/admin_screen.dart';
import 'package:flutterquiz/screen/category_screen.dart';
import 'package:flutterquiz/screen/homes_screen.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  bool isAdmin = false;
  bool isExpanded = true;
  int? hoveredIndex;

  List<Widget> screens = [];
  final List<String> menuTitles = [
    'Trang chủ',
    'Quản trị',
    'Lịch sử thi',
    'Bài kiểm tra đã tạo',
    'Kết quả kiểm tra', // ✅ Thêm mục mới
    'Cập nhật thông tin',
    'Đổi mật khẩu',
  ];

  final List<IconData> menuIcons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.userGear,
    FontAwesomeIcons.clockRotateLeft,
    FontAwesomeIcons.fileCircleCheck,
    FontAwesomeIcons.chartColumn, // ✅ Icon cho "Kết quả kiểm tra"
    FontAwesomeIcons.userPen,
    FontAwesomeIcons.lock,
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
        setState(() {
          isAdmin = role == 'admin';
          screens = [
            HomeScreen(),
            if (isAdmin) const AdminDashboardScreen(),
            const UserExamResultScreen(),
            const CreatedTestListScreen(),
            if (isAdmin) const AdminExamResultScreen(), // ✅ Thêm dòng này
            UpdateProfileScreen(), // NEW
            ChangePasswordScreen(), // NEW
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = kItemSelectBottomNav;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isExpanded ? (isMobile ? 200 : 240) : 72,
            color: Colors.white,
            child: Column(
              children: [
                IconButton(
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isExpanded ? 0 : 0.5,
                    child: const Icon(Icons.menu),
                  ),
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: isAdmin ? 7 : 4,
                    itemBuilder: (context, index) {
                      final title = menuTitles[index];
                      final icon = menuIcons[index];

                      final isHovered = hoveredIndex == index;
                      final isSelected = currentIndex == index;

                      return MouseRegion(
                        onEnter: (_) => setState(() => hoveredIndex = index),
                        onExit: (_) => setState(() => hoveredIndex = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          color: isHovered || isSelected
                              ? themeColor.withOpacity(0.1)
                              : Colors.transparent,
                          child: ListTile(
                            leading: Icon(
                              icon,
                              color: isSelected ? themeColor : Colors.grey[700],
                            ),
                            title: isExpanded
                                ? Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? themeColor
                                          : Colors.grey[800],
                                    ),
                                  )
                                : null,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                currentIndex = index;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: screens.isNotEmpty
                ? screens[currentIndex]
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
