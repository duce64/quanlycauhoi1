import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:http/http.dart' as http;

const kPrimaryColor = Color(0xFF1976D2);
const kLightBackground = Color(0xFFE9F1FB);
const kCardBackground = Colors.white;
const kTitleColor = Color(0xFF002856);

class ManageUserScreen extends StatefulWidget {
  const ManageUserScreen({Key? key}) : super(key: key);

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response =
          await http.get(Uri.parse('${AppConstants.baseUrl}/getAllUser'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _users = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTitleColor),
        title: const Text(
          "👥 Quản lý người dùng",
          style: TextStyle(
            color: kTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text("❌ $_error", style: TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final userId = user['_id'] ?? '';
                    final name = (user['fullname'] is String &&
                            user['fullname'].isNotEmpty)
                        ? user['fullname']
                        : 'Không rõ';
                    final department = (user['department'] is String &&
                            user['department'].isNotEmpty)
                        ? user['department']
                        : 'Không có phòng ban';
                    final role =
                        (user['role'] is String && user['role'].isNotEmpty)
                            ? user['role']
                            : 'user';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: kPrimaryColor.withOpacity(0.1),
                            child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kTitleColor)),
                                const SizedBox(height: 4),
                                Text("Phòng ban: $department",
                                    style: TextStyle(color: Colors.grey[700])),
                                Row(
                                  children: [
                                    const Text("Vai trò: ",
                                        style: TextStyle(color: Colors.grey)),
                                    DropdownButton<String>(
                                      value: role,
                                      items: ['admin', 'user'].map((role) {
                                        return DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            role,
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _users[index]['role'] = newValue;
                                          });
                                          _updateUserRole(userId, newValue);
                                        }
                                      },
                                      underline: Container(),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(userId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmDelete(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc chắn muốn xoá người dùng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteUser(userId);
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/delete/$userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _users.removeWhere((user) => user['_id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xoá người dùng thành công')),
        );
      } else {
        throw Exception('Lỗi xoá: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e')),
      );
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/users/updateRole'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'role': newRole}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật vai trò thành công')),
        );
      } else {
        throw Exception('Lỗi cập nhật: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e')),
      );
    }
  }
}
