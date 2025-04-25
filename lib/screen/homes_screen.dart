import 'package:flutter/material.dart';
import 'package:flutterquiz/animation/fade_animation.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/model/categories.dart';
import 'package:flutterquiz/provider/question_provider.dart';
import 'package:flutterquiz/screen/QuestionPackageListScreenH.dart';
import 'package:flutterquiz/screen/quiz_bottomsheet.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';
import 'package:flutterquiz/widget/card.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:convert' show base64Url, base64Decode;
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _categories = [];
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _userName = '';
  String _department = '';
  String _detail = '';
  int unreadCount = 0;
  @override
  void initState() {
    super.initState();
    _loadUserFromToken();
    _loadCategories();
    _loadNotifications();
    Provider.of<QuestionProvider>(context, listen: false).initValue();
  }

  Future<void> _loadUserFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = base64Url.normalize(parts[1]);
        final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));

        final exp = decoded['exp'];
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (exp != null && exp < now) {
          await _logoutExpired();
          return;
        }

        setState(() {
          _userName = decoded['fullname'] ?? '';
          _department = decoded['department'] ?? '';
          _detail = decoded['role'] ?? '';
        });
      }
    }
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

  Future<void> _logoutExpired() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    Navigator.of(context)
        .pushNamedAndRemoveUntil(LoginScreen, (route) => false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận đăng xuất'),
        content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      Navigator.of(context)
          .pushNamedAndRemoveUntil(LoginScreen, (route) => false);
    }
  }

  Future<List<Category>> fetchCategories() async {
    final response =
        await http.get(Uri.parse('${AppConstants.baseUrl}/api/categories'));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }

  Future<void> _loadCategories() async {
    try {
      List<Category> fetched = await fetchCategories();
      setState(() {
        _categories = fetched;
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi tải category: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStyledItem(Category category) {
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
            backgroundColor: kItemSelectBottomNav.withOpacity(0.1),
            backgroundImage: MemoryImage(base64Decode(category.image)),
            radius: 28,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002856),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Mã danh mục: ${category.id}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[500])
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      width: double.infinity,
      color: Color(0xFFE9F1FB),
      child: Column(
        children: <Widget>[
          Container(
            height: 70,
            width: double.infinity,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Xin chào, $_userName",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kItemSelectBottomNav,
                      ),
                    ),
                    Text(
                      "Phòng ban: $_department | Vai trò: $_detail",
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    )
                  ],
                ),
                Row(
                  children: [
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 18, minHeight: 18),
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
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.red),
                      tooltip: 'Đăng xuất',
                      onPressed: _logout,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: kItemSelectBottomNav,
                            strokeWidth: 3.5,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Đang tải dữ liệu...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(top: 10),
                    itemCount: _categories.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestionPackageListScreen(
                                categoryId: _categories[index].id,
                                categoryName: _categories[index].name,
                              ),
                            ),
                          );
                        },
                        child: _buildStyledItem(_categories[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    ));
  }

  _buildBottomSheet(BuildContext context, String title, int id) {
    return showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        context: context,
        builder: (_) {
          return QuizBottomSheet(
            title: title,
            id: id,
          );
        });
  }
}

String formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$day/$month/$year $hour:$minute";
  } catch (e) {
    return isoDate; // fallback nếu lỗi
  }
}
