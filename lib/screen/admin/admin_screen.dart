import 'package:flutter/material.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFE9F1FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "📋 Trang quản trị",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTitleColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active_outlined,
                color: kItemSelectBottomNav),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: GridView.count(
              crossAxisCount: isWideScreen ? 3 : 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AdminMenuCard(
                  icon: Icons.category_outlined,
                  title: "Quản lý danh mục",
                  color: Colors.orange,
                  onTap: () =>
                      Navigator.of(context).pushNamed(CategoryManagerScreens),
                ),
                _AdminMenuCard(
                  icon: Icons.quiz_outlined,
                  title: "Quản lý câu hỏi",
                  color: Colors.green,
                  onTap: () =>
                      Navigator.of(context).pushNamed(ManageQuestionScreens),
                ),
                _AdminMenuCard(
                  icon: Icons.bar_chart_outlined,
                  title: "Kết quả thi",
                  color: Colors.deepPurple,
                  onTap: () => Navigator.pushNamed(context, ResultExamScreens),
                ),
                _AdminMenuCard(
                  icon: Icons.group_outlined,
                  title: "Người dùng",
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, ManageUserScreenss),
                ),
                _AdminMenuCard(
                  icon: Icons.assignment_turned_in_outlined,
                  title: "Tạo bài kiểm tra",
                  color: Colors.teal,
                  onTap: () => Navigator.pushNamed(context, CreateExamScreens),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _AdminMenuCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: kTitleColor,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
