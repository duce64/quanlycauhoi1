import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  String? selectedDepartment;

  final List<String> departments = [
    'Ban Tham Mưu',
    'Ban Chính Trị',
    'Ban HC-KT',
  ];

  bool isLoading = false;

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
        selectedDepartment = decoded['department'];
      });
    }
  }

  Future<void> updateProfile() async {
    if (fullnameController.text.isEmpty ||
        detailController.text.isEmpty ||
        selectedDepartment == null) {
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
      "department": selectedDepartment
    };

    try {
      setState(() => isLoading = true);
      final res = await Dio().put(
        'http://192.168.52.91:3000/update/$userId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
        // 🔄 Lưu lại token mới
        await prefs.setString('auth_token', res.data['token']);
      } else {
        throw Exception("Lỗi cập nhật");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: kItemSelectBottomNav),
        title: Text(
          "🧑‍💼 Cập nhật thông tin",
          style: TextStyle(
            color: kItemSelectBottomNav,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullnameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailController,
                  decoration: const InputDecoration(
                    labelText: 'Chi tiết',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  items: departments
                      .map((dep) => DropdownMenuItem(
                            value: dep,
                            child: Text(dep),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() {
                    selectedDepartment = val;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Phòng ban',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : updateProfile,
                    icon: const Icon(Icons.save),
                    label: const Text("Cập nhật"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kItemSelectBottomNav,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
