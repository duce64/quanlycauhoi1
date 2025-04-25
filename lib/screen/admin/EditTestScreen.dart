import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditTestScreen extends StatefulWidget {
  final Map<String, dynamic> testData;

  const EditTestScreen({Key? key, required this.testData}) : super(key: key);

  @override
  State<EditTestScreen> createState() => _EditTestScreenState();
}

class _EditTestScreenState extends State<EditTestScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();

  String? selectedDepartment;
  String? selectedPackage;
  String? selectedUser;

  List<Map<String, dynamic>> questionPackages = [];
  List<Map<String, dynamic>> users = [];

  bool isLoadingPackages = true;
  bool isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.testData['title'] ?? '';
    deadlineController.text =
        widget.testData['deadline']?.toString().split('T')[0] ?? '';
    selectedDepartment = widget.testData['department'];
    // selectedPackage = widget.testData['questionPackageId'];
    selectedUser = widget.testData['users']?.isNotEmpty == true
        ? widget.testData['users'][0]
        : null;

    fetchPackages().then((_) {
      if (selectedDepartment != null && selectedDepartment!.isNotEmpty) {
        // fetchUsersByDepartment(selectedDepartment!);
      }
    });
  }

  Future<void> fetchPackages() async {
    try {
      final res = await Dio().get('http://192.168.52.91:3000/api/questions');
      if (res.statusCode == 200) {
        setState(() {
          questionPackages = List<Map<String, dynamic>>.from(res.data);
          isLoadingPackages = false;
        });
      }
    } catch (e) {
      print('Lỗi load packages: $e');
    }
  }

  Future<void> fetchUsersByDepartment(String department) async {
    setState(() {
      isLoadingUsers = true;
    });
    try {
      final res = await Dio().get(
        'http://192.168.52.91:3000/by-department',
        queryParameters: {'department': department},
      );
      if (res.statusCode == 200) {
        setState(() {
          users = List<Map<String, dynamic>>.from(res.data);
          isLoadingUsers = false;
        });
      }
    } catch (e) {
      print('Lỗi load user: $e');
      setState(() {
        isLoadingUsers = false;
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (titleController.text.isEmpty ||
        selectedPackage == null ||
        selectedDepartment == null ||
        selectedUser == null ||
        deadlineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")));
      return;
    }

    try {
      final res = await Dio().put(
        'http://192.168.52.91:3000/api/exams/${widget.testData['_id']}',
        data: {
          "title": titleController.text,
          "questionPackageId": selectedPackage,
          "department": selectedDepartment,
          "expiredDate": deadlineController.text,
          "selectedUsers": [selectedUser],
        },
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Cập nhật thành công")));
        Navigator.pop(context, true);
      } else {
        throw Exception("Lỗi từ server");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi khi cập nhật: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F1FB),
      appBar: AppBar(
        title: const Text("Sửa bài kiểm tra"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Tiêu đề",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              isLoadingPackages
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      value: selectedPackage,
                      items: questionPackages
                          .map((pkg) => DropdownMenuItem(
                                value: pkg['_id'].toString(),
                                child: Text(pkg['name']),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedPackage = val),
                      decoration: const InputDecoration(
                        labelText: 'Chọn gói câu hỏi',
                        border: OutlineInputBorder(),
                      ),
                    ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedDepartment,
                items: ["Ban Tham Mưu", "Ban Chính Trị", "Ban HC-KT"]
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedDepartment = val;
                    selectedUser = null;
                  });
                  if (val != null) fetchUsersByDepartment(val);
                },
                decoration: const InputDecoration(
                  labelText: "Chọn ban",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              isLoadingUsers
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      value: selectedUser,
                      items: users
                          .map((user) => DropdownMenuItem(
                                value: user['_id'].toString(),
                                child: Text(user['fullname']),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedUser = val),
                      decoration: const InputDecoration(
                        labelText: "Người cần kiểm tra",
                        border: OutlineInputBorder(),
                      ),
                    ),
              const SizedBox(height: 20),
              TextField(
                controller: deadlineController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Hạn chót",
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(deadlineController.text) ??
                        DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    deadlineController.text =
                        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  }
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("LƯU THAY ĐỔI",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
