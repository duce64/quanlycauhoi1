import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/screen/widgets/empty.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const kPrimaryColor = Color(0xFF1976D2);
const kLightBackground = Color(0xFFF9FAFB);
const kTitleColor = Color(0xFF002856);

class UserExamResultScreen extends StatefulWidget {
  const UserExamResultScreen({Key? key}) : super(key: key);

  @override
  State<UserExamResultScreen> createState() => _UserExamResultScreenState();
}

class _UserExamResultScreenState extends State<UserExamResultScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchResultsByUserId();
  }

  Future<void> _fetchResultsByUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("Token không tồn tại");

      final parts = token.split('.');
      if (parts.length != 3) throw Exception("Token không hợp lệ");

      final payload = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      final userId = decoded['userId'];

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/results/by-user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _results = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Lỗi khi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text("❌ $_error", style: TextStyle(color: Colors.red)))
              : _results.length==0?
              EmptyStateWidget(
                  svgPath: 'assets/empty.svg',
                  message: 'Không có kết quả thi nào',
                )
              :ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.grey),
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryColor.withOpacity(0.1),
                        child: Text(item['name'][0].toUpperCase(),
                            style: const TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(
                        item['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kTitleColor,
                        ),
                      ),
                      subtitle: Text(
                       "Ngày thi: ${formatDate(item['date'] ?? '')} - Điểm: ${item['score'] ?? '0'}/100",

                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      trailing:
                          const Icon(Icons.chevron_right, color: kPrimaryColor),
                      onTap: () {
                        // TODO: Xử lý khi nhấn vào item
                      },
                    );
                  },
                ),
    );
  }
  // Hàm định dạng ngày
String formatDate(String isoDate) {
  try {
    final dateTime = DateTime.parse(isoDate).toLocal(); // Chuyển về giờ địa phương nếu cần
    return DateFormat('dd/MM/yyyy').format(dateTime);
  } catch (e) {
    return ''; // Trả về rỗng nếu không đúng định dạng
  }
}
}
