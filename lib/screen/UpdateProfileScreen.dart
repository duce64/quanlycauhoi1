import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  String? email;
  String? department;
  bool isLoading = false;

  final List<String> departments = [
    'Ban Tham Mưu',
    'Ban Chính Trị',
    'Ban HC-KT',
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      final payload = base64Url.normalize(token.split('.')[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));

      setState(() {
        fullnameController.text = decoded['fullname'] ?? '';
        detailController.text = decoded['detail'] ?? '';
        department = decoded['department'];
        email = decoded['email'];
      });
    }
  }

  Future<void> updateProfile() async {
    if (fullnameController.text.isEmpty ||
        detailController.text.isEmpty ||
        department == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final payload = base64Url.normalize(token.split('.')[1]);
    final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
    final userId = decoded['userId'];

    final data = {
      "fullname": fullnameController.text,
      "detail": detailController.text,
      "department": department,
    };

    try {
      setState(() => isLoading = true);
      final res = await Dio().put(
        '${AppConstants.baseUrl}/update/$userId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
        await prefs.setString('auth_token', res.data['token']);
      } else {
        throw Exception('Lỗi cập nhật');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(fontSize: 14, color: Colors.black87))),
          Expanded(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tài khoản
                const Text('Tài khoản',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                buildRow(
                  label: 'Email',
                  child:
                      Text(email ?? '', style: const TextStyle(fontSize: 14)),
                ),
                buildRow(
                  label: 'Điện thoại',
                  child: const Text('Chưa cập nhật',
                      style: TextStyle(fontSize: 14)),
                ),
                buildRow(
                  label: 'Mật khẩu',
                  child:
                      const Text('**********', style: TextStyle(fontSize: 14)),
                ),
                const Divider(height: 32, thickness: 1),

                // Thông tin liên hệ
                const Text('Thông tin liên hệ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                buildRow(
                  label: 'Họ và tên',
                  child: TextField(
                    controller: fullnameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                buildRow(
                  label: 'Chi tiết',
                  child: TextField(
                    controller: detailController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const Divider(height: 32, thickness: 1),

                // Cài đặt khác
                const Text('Cài đặt khác',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                buildRow(
                  label: 'Phòng ban',
                  child: DropdownButtonFormField<String>(
                    value: department,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: departments.map((dep) {
                      return DropdownMenuItem<String>(
                        value: dep,
                        child: Text(dep),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        department = val;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Button cập nhật
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kItemSelectBottomNav,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cập nhật',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
