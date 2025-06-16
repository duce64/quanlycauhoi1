import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/mahoa.dart';
import 'package:flutterquiz/model/question.dart';
import 'package:http/http.dart' as http;

class ViewQuestionsByCategoryScreen extends StatefulWidget {
  final int categoryId;

  const ViewQuestionsByCategoryScreen({Key? key, required this.categoryId})
      : super(key: key);

  @override
  State<ViewQuestionsByCategoryScreen> createState() =>
      _ViewQuestionsByCategoryScreenState();
}

class _ViewQuestionsByCategoryScreenState
    extends State<ViewQuestionsByCategoryScreen> {
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    final dio = Dio();
    final url =
        "${AppConstants.baseUrl}/api/questions/package/${widget.categoryId}";

    try {
      setState(() => _isLoading = true);

      final res = await dio.get(url);

      if (res.statusCode == 200) {
        final encrypted = res.data['result'];
        final decryptedJson =
            decryptAes(encrypted, '1234567890abcdef', 'abcdef1234567890');
        final List<dynamic> questions = jsonDecode(decryptedJson);

        List<Question> loadedQuestions =
            questions.map((e) => Question.fromJson(e)).toList();

        setState(() {
          _questions = loadedQuestions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        print('Lỗi khi gọi API hoặc giải mã: $e');

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Danh sách câu hỏi')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(child: Text('Không có câu hỏi nào'))
              : ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Câu hỏi ${index + 1}: ${q.question}",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text("Đáp án đúng: ${q.correctAnswer}",
                                style: TextStyle(color: Colors.green)),
                            ...q.incorrectAnswers!
                                .map((ans) => Text("Đáp án sai: $ans"))
                                .toList(),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _showEditDialog(q),
                                  child: Text('Sửa',
                                      style: TextStyle(color: Colors.blue)),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _deleteQuestion(q.id.toString()),
                                  child: Text('Xóa',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showEditDialog(Question question) {
  final questionController = TextEditingController(text: question.question);
  final correctAnswerController =
      TextEditingController(text: question.correctAnswer);

  final incorrectControllers = (question.incorrectAnswers ?? [])
      .map((text) => TextEditingController(text: text))
      .toList();

  if (incorrectControllers.isEmpty) {
    incorrectControllers.add(TextEditingController());
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text('Sửa câu hỏi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: InputDecoration(labelText: 'Câu hỏi'),
                  maxLines: null,
        
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: correctAnswerController,
                  decoration: InputDecoration(labelText: 'Đáp án đúng'),
                ),
                const SizedBox(height: 12),
                Text('Đáp án sai:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...List.generate(incorrectControllers.length, (i) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: incorrectControllers[i],
                          decoration: InputDecoration(
                              labelText: 'Đáp án sai ${i + 1}'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            incorrectControllers.removeAt(i);
                          });
                        },
                      )
                    ],
                  );
                }),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Thêm đáp án sai"),
                  onPressed: () {
                    setState(() {
                      incorrectControllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Lưu'),
              onPressed: () async {
                final updated = Question(
                  id: question.id,
                  question: questionController.text.trim(),
                  correctAnswer: correctAnswerController.text.trim(),
                  incorrectAnswers: incorrectControllers
                      .map((c) => c.text.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  categoryId: question.categoryId,
                  idQuestionPackage: question.idQuestionPackage,
                );

                final success = await updateQuestion(updated);
                if (success) {
                  Navigator.pop(context);
                  _fetchQuestions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cập nhật thành công')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cập nhật thất bại')),
                  );
                }
              },
            ),
          ],
        );
      });
    },
  );
}


  Future<bool> updateQuestion(Question question) async {
    final url =
        Uri.parse('${AppConstants.baseUrl}/api/questions/${question.id}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(question.toJson()),
    );
    return response.statusCode == 200;
  }

  void _editQuestion(Question question) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => EditQuestionScreen(question: question),
    //   ),
    // ).then((_) {
    //   _fetchQuestions(); // làm mới danh sách sau khi chỉnh sửa
    // });
  }
  Future<void> _deleteQuestion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn xóa câu hỏi này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text('Không')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text('Có')),
        ],
      ),
    );

    if (confirm != true) return;

    final url = Uri.parse('${AppConstants.baseUrl}/api/questions/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {
        _questions.removeWhere((q) => q.id == id);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã xóa câu hỏi.')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Xóa thất bại.')));
    }
  }
}
