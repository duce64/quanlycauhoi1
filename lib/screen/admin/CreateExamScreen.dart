import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/mahoa.dart';
import 'package:flutterquiz/model/question.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateExamScreen extends StatefulWidget {
  final Map<String, dynamic>? exam; // Thêm dòng này

  const CreateExamScreen({Key? key, this.exam}) : super(key: key);

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController durationController =
      TextEditingController(); // thời gian làm bài
  final TextEditingController questionCountController =
      TextEditingController(); // số lượng câu hỏi

  List<dynamic> questionPackages = [];
  List<dynamic> users = [];
  bool isLoadingPackages = true;
  bool isLoadingUsers = false;
  int? selectCategoryId;
  int? selectedPackage;
  List<String> selectedUsers = [];
  String? selectedDepartment;

  int totalQuestions = 0; // Tổng số câu hỏi theo category

  final List<String> departments = [
    'Ban Tham Mưu',
    'Ban Chính Trị',
    'Ban HC-KT'
  ];

  @override
  void initState() {
    super.initState();
    fetchPackages().then((_) {
      if (widget.exam != null) {
        final exam = widget.exam!;
        titleController.text = exam['title'] ?? '';
        deadlineController.text = exam['expiredDate'] ?? '';
        durationController.text = exam['timeLimit']?.toString() ?? '';
        questionCountController.text = exam['questionCount']?.toString() ?? '';
        // selectedPackage = exam['questionPackageId'];
        // selectCategoryId = exam['categoryId'];
        // selectedDepartment = exam['department'];
        // selectedUsers = List<String>.from(exam['selectedUsers'] ?? []);

        if (selectedDepartment != null) {
          fetchUsersByDepartment(selectedDepartment!);
        }

        if (selectedPackage != null) {
          fetchTotalQuestions(selectedPackage!);
        }
      }
    });
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

  Future<void> fetchTotalQuestions(int categoryId) async {
    try {
      final res = await Dio()
          .get('${AppConstants.baseUrl}/api/questions/package/$categoryId');
      if (res.statusCode == 200) {
        final encrypted = res.data['result'];
        final iv = res.data['iv']; // nếu gửi từ backend
        final decryptedJson =
            decryptAes(encrypted, '1234567890abcdef', 'abcdef1234567890');
        final List<dynamic> questions = jsonDecode(decryptedJson);

        final listQuestion =
            questions.map((e) => Question.fromJson(e)).toList();
        // final List questions = res.data['result'];
        setState(() {
          totalQuestions = listQuestion.length;
        });
      }
    } catch (e) {
      print('Lỗi khi lấy tổng câu hỏi: $e');
    }
  }

  Future<void> selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          deadlineController.text = fullDateTime.toIso8601String();
        });
      }
    }
  }

  Future<void> createTest() async {
    if (titleController.text.isEmpty ||
        selectedPackage == null ||
        selectedUsers.isEmpty ||
        deadlineController.text.isEmpty ||
        selectedDepartment == null ||
        questionCountController.text.isEmpty ||
        durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final int questionCount = int.tryParse(questionCountController.text) ?? 0;
    if (questionCount <= 0 || questionCount > totalQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng câu hỏi không hợp lệ')),
      );
      return;
    }

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
      "questionCount": questionCount,
      "timeLimit":
          int.tryParse(durationController.text) ?? 0, // thêm thời gian làm bài
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
                    : ElevatedButton(
                        onPressed: openUserSelectDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          selectedUsers.isEmpty
                              ? "Chọn người kiểm tra"
                              : "Đã chọn ${selectedUsers.length} người",
                        ),
                      ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: selectedPackage,
                  items: questionPackages
                      .map((pkg) => DropdownMenuItem<int>(
                            value: pkg['idQuestion'],
                            child: Text(pkg['name']),
                          ))
                      .toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      final selectedPkg = questionPackages.firstWhere(
                        (pkg) => pkg['idQuestion'] == val,
                        orElse: () => null,
                      );

                      if (selectedPkg != null) {
                        final categoryId = selectedPkg['idCategory'];
                        setState(() {
                          selectedPackage = val;
                          selectCategoryId = categoryId;
                        });
                        print('check val ${val}');
                        await fetchTotalQuestions(val);
                      }
                    }
                  },
                  decoration: customInputDecoration('Chọn gói câu hỏi'),
                ),
                if (totalQuestions > 0) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: questionCountController,
                    keyboardType: TextInputType.number,
                    decoration: customInputDecoration(
                        'Số lượng câu hỏi (tối đa $totalQuestions)'),
                    onChanged: (value) {
                      int val = int.tryParse(value) ?? 0;
                      if (val > totalQuestions) {
                        questionCountController.text =
                            totalQuestions.toString();
                        questionCountController.selection =
                            TextSelection.fromPosition(
                          TextPosition(
                              offset: questionCountController.text.length),
                        );
                      }
                    },
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: customInputDecoration('Thời gian làm bài (phút)'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: deadlineController,
                  readOnly: true,
                  onTap: () => selectDateTime(context),
                  decoration: customInputDecoration('Ngày hết hạn').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saveExam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.exam != null
                          ? 'Cập nhật bài kiểm tra'
                          : 'Tạo bài kiểm tra',
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

  Future<void> saveExam() async {
    if (widget.exam != null) {
      await updateExam(); // sửa
    } else {
      await createTest(); // tạo mới
    }
  }

  Future<void> updateExam() async {
    if (titleController.text.isEmpty ||
        selectedPackage == null ||
        selectedUsers.isEmpty ||
        deadlineController.text.isEmpty ||
        selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final int questionCount = int.tryParse(questionCountController.text) ?? 0;
    if (questionCount <= 0 || questionCount > totalQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng câu hỏi không hợp lệ')),
      );
      return;
    }

    final data = {
      "title": titleController.text,
      "questionPackageId": selectedPackage,
      "selectedUsers": selectedUsers,
      "expiredDate": deadlineController.text,
      "department": selectedDepartment,
      "categoryId": selectCategoryId,
      "questionCount": questionCount,
      "timeLimit":
          int.tryParse(durationController.text) ?? 0, // thêm thời gian làm bài
    };

    try {
      print('checkid ${widget.exam!['_id']}');
      final res = await Dio().put(
        '${AppConstants.baseUrl}/api/exams/${widget.exam!['_id']}',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật bài kiểm tra thành công')),
        );
        Navigator.pop(context);
      } else {
        throw Exception("Cập nhật thất bại");
      }
    } catch (e) {
      print("Lỗi cập nhật bài kiểm tra: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật kiểm tra thất bại')),
      );
    }
  }

  void openUserSelectDialog() async {
    final List<String> tempSelectedUsers = List.from(selectedUsers);

    await showDialog(
      context: context,
      builder: (context) {
        bool isSelectAll = tempSelectedUsers.length == users.length;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Chọn người kiểm tra"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text("Chọn tất cả"),
                      value: isSelectAll,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            tempSelectedUsers.clear();
                            tempSelectedUsers
                                .addAll(users.map((u) => u['_id']));
                          } else {
                            tempSelectedUsers.clear();
                          }
                          isSelectAll = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: ListView(
                        children: users.map<Widget>((user) {
                          return CheckboxListTile(
                            title: Text(user['fullname']),
                            value: tempSelectedUsers.contains(user['_id']),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  tempSelectedUsers.add(user['_id']);
                                } else {
                                  tempSelectedUsers.remove(user['_id']);
                                }
                                isSelectAll =
                                    tempSelectedUsers.length == users.length;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedUsers = List.from(tempSelectedUsers);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Xác nhận"),
                ),
              ],
            );
          },
        );
      },
    );

    setState(() {});
  }
}
