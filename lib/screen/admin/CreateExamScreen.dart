import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({Key? key}) : super(key: key);

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();

  List<dynamic> questionPackages = [];
  List<dynamic> users = [];
  bool isLoadingPackages = true;
  bool isLoadingUsers = false;
  int? selectCategoryId;

  int? selectedPackage;
  List<String> selectedUsers = [];
  String? selectedDepartment;

  final List<String> departments = [
    'Ban Tham Mưu',
    'Ban Chính Trị',
    'Ban HC-KT'
  ];

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    try {
      final res = await Dio().get('${AppConstants.baseUrl}/api/questions');
      if (res.statusCode == 200) {
        setState(() {
          questionPackages = res.data;
          isLoadingPackages = false;
        });
      }
    } catch (e) {
      print("Lỗi khi load packages: $e");
    }
  }

  Future<void> fetchUsersByDepartment(String department) async {
    setState(() {
      isLoadingUsers = true;
    });
    try {
      final res = await Dio().get(
        '${AppConstants.baseUrl}/by-department',
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

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        deadlineController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> createTest() async {
    if (titleController.text.isEmpty ||
        selectedPackage == null ||
        selectedUsers.isEmpty ||
        deadlineController.text.isEmpty ||
        selectedDepartment == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    String? creatorId;
    if (token != null) {
      final payload = base64Url.normalize(token.split('.')[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      creatorId = decoded['userId'];
    }

    final data = {
      "title": titleController.text,
      "questionPackageId": selectedPackage,
      "selectedUsers": selectedUsers,
      "expiredDate": deadlineController.text,
      "department": selectedDepartment,
      "userId": creatorId,
      "categoryId": selectCategoryId,
    };
    try {
      final res = await Dio().post(
        '${AppConstants.baseUrl}/api/exams/create',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo bài kiểm tra thành công')),
        );
        Navigator.pop(context);
      } else {
        throw Exception("Tạo thất bại");
      }
    } catch (e) {
      print("Tạo kiểm tra thất bại: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo kiểm tra thất bại')),
      );
    }
  }

  InputDecoration customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Colors.black87),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Tạo bài kiểm tra",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Thông tin bài kiểm tra",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  decoration: customInputDecoration('Tên bài kiểm tra'),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedDepartment,
                  items: departments
                      .map((dep) => DropdownMenuItem(
                            value: dep,
                            child: Text(dep),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedDepartment = val;
                      selectedUsers.clear();
                    });
                    if (val != null) fetchUsersByDepartment(val);
                  },
                  decoration: customInputDecoration('Chọn ban'),
                ),
                const SizedBox(height: 20),
                isLoadingUsers
                    ? const Center(child: CircularProgressIndicator())
                    : MultiSelectDialogField(
                        items: users
                            .map((user) =>
                                MultiSelectItem(user['_id'], user['fullname']))
                            .toList(),
                        title: const Text("Người kiểm tra"),
                        buttonText: const Text("Chọn người kiểm tra"),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE0E0E0)),
                          color: Colors.white,
                        ),
                        listType: MultiSelectListType.LIST,
                        onConfirm: (values) {
                          setState(() {
                            selectedUsers =
                                values.map((e) => e.toString()).toList();
                          });
                        },
                        chipDisplay: MultiSelectChipDisplay.none(),
                      ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: selectedPackage,
                  items: questionPackages
                      .map((pkg) => DropdownMenuItem<int>(
                            value: pkg[
                                'idQuestion'], // vẫn giữ value là idQuestion
                            child: Text(pkg['name']),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      // Tìm object tương ứng từ danh sách
                      final selectedPkg = questionPackages.firstWhere(
                        (pkg) => pkg['idQuestion'] == val,
                        orElse: () => null,
                      );

                      if (selectedPkg != null) {
                        final categoryId = selectedPkg['idCategory'];
                        print('Selected package id: $val');
                        print('Corresponding categoryId: $categoryId');

                        setState(() {
                          selectedPackage = val;
                          // Lưu categoryId nếu cần
                          selectCategoryId = categoryId;
                        });
                      }
                    }
                  },
                  decoration: customInputDecoration('Chọn gói câu hỏi'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: deadlineController,
                  readOnly: true,
                  onTap: () => selectDate(context),
                  decoration: customInputDecoration('Ngày hết hạn').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: createTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Tạo bài kiểm tra",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
