import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/model/question.dart';
import 'package:http/http.dart' as http;
import 'package:flutterquiz/util/constant.dart';

class AddQuestionScreen extends StatefulWidget {
  final int categoryId;
  final int idQuestionPackage;

  const AddQuestionScreen({
    Key? key,
    required this.categoryId,
    required this.idQuestionPackage,
  }) : super(key: key);

  @override
  _AddQuestionScreenState createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final List<Question> questions = [];
  int currentQuestionIndex = 0;

  final questionController = TextEditingController();
  final correctAnswerController = TextEditingController();
  final incorrect1Controller = TextEditingController();
  final incorrect2Controller = TextEditingController();
  final incorrect3Controller = TextEditingController();

  bool isFormValid() {
    return questionController.text.isNotEmpty &&
        correctAnswerController.text.isNotEmpty &&
        incorrect1Controller.text.isNotEmpty &&
        incorrect2Controller.text.isNotEmpty &&
        incorrect3Controller.text.isNotEmpty;
  }

  void saveCurrentQuestion() {
    if (!isFormValid()) return;

    final currentQuestion = Question(
      question: questionController.text,
      correctAnswer: correctAnswerController.text,
      incorrectAnswers: [
        incorrect1Controller.text,
        incorrect2Controller.text,
        incorrect3Controller.text,
      ],
      categoryId: widget.categoryId,
      idQuestionPackage: widget.idQuestionPackage,
    );

    if (currentQuestionIndex < questions.length) {
      questions[currentQuestionIndex] = currentQuestion;
    } else {
      questions.add(currentQuestion);
    }
  }

  void loadQuestion() {
    if (currentQuestionIndex < questions.length) {
      final q = questions[currentQuestionIndex];
      questionController.text = q.question ?? '';
      correctAnswerController.text = q.correctAnswer ?? '';
      incorrect1Controller.text = q.incorrectAnswers![0];
      incorrect2Controller.text = q.incorrectAnswers![1];
      incorrect3Controller.text = q.incorrectAnswers![2];
    } else {
      clearFields();
    }
  }

  void clearFields() {
    questionController.clear();
    correctAnswerController.clear();
    incorrect1Controller.clear();
    incorrect2Controller.clear();
    incorrect3Controller.clear();
  }

  void nextQuestion() {
    saveCurrentQuestion();
    setState(() {
      currentQuestionIndex++;
      loadQuestion();
    });
  }

  void previousQuestion() {
    saveCurrentQuestion();
    setState(() {
      currentQuestionIndex--;
      loadQuestion();
    });
  }

  Future<void> submitQuestions() async {
    saveCurrentQuestion();

    final url =
        Uri.parse('${AppConstants.baseUrl}/api/questions/add-questions');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(questions.map((q) => q.toJson()).toList());

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${response.body}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadQuestion();
    [
      questionController,
      correctAnswerController,
      incorrect1Controller,
      incorrect2Controller,
      incorrect3Controller
    ].forEach((controller) => controller.addListener(() => setState(() {})));
  }

  InputDecoration inputDecoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE9F1FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Thêm câu hỏi',
          style: TextStyle(color: kTitleColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: kTitleColor),
      ),
      body: Center(
        child: Container(
          width: isWide ? 700 : double.infinity,
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    'Câu hỏi ${currentQuestionIndex + 1}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: questionController,
                    decoration: inputDecoration('Nội dung câu hỏi'),
                    maxLines: null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: correctAnswerController,
                    decoration: inputDecoration('Đáp án đúng'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: incorrect1Controller,
                    decoration: inputDecoration('Đáp án sai 1'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: incorrect2Controller,
                    decoration: inputDecoration('Đáp án sai 2'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: incorrect3Controller,
                    decoration: inputDecoration('Đáp án sai 3'),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            currentQuestionIndex > 0 ? previousQuestion : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Trước'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 45),
                          backgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: isFormValid() ? nextQuestion : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Sau'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 45),
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: submitQuestions,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Hoàn tất'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(120, 45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
