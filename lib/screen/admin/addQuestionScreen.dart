// Các import giữ nguyên
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/model/question.dart';
import 'package:flutterquiz/screen/admin/preview_question_screen.dart';
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
  final jumpToController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    fetchExistingQuestions();
    [
      questionController,
      correctAnswerController,
      incorrect1Controller,
      incorrect2Controller,
      incorrect3Controller
    ].forEach((controller) => controller.addListener(() => setState(() {})));
    jumpToController.addListener(() => setState(() {}));
  }

  Future<void> fetchExistingQuestions() async {
    final url = Uri.parse(
        '${AppConstants.baseUrl}/api/questions/package/${widget.idQuestionPackage}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['result'];
      final fetchedQuestions = data.map((e) => Question.fromJson(e)).toList();

      setState(() {
        questions.addAll(fetchedQuestions);
        loadQuestion();
      });
    }
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
      isLocal: currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex].isLocal
          : true, // Mặc định là mới
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

    final localQuestions = questions.where((q) => q.isLocal ?? false).toList();

    if (localQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có câu hỏi mới để gửi')),
      );
      return;
    }

    final url =
        Uri.parse('${AppConstants.baseUrl}/api/questions/add-questions');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(localQuestions.map((q) => q.toJson()).toList());

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi thành công')),
      );
      setState(() {
        for (var q in questions) {
          q.isLocal = false;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${response.body}')),
      );
    }
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
        title: const Text('Thêm câu hỏi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye),
            onPressed: () {
              saveCurrentQuestion();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PreviewQuestionScreen(questions: questions),
                ),
              );
            },
          )
        ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Câu ${currentQuestionIndex + 1} / ${questions.length}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Text("Đi đến câu: "),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: jumpToController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: "VD: 10",
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onChanged: (value) {
                                if (value.isEmpty) return;

                                final index = int.tryParse(value);
                                if (index == null) {
                                  jumpToController.text = '';
                                  return;
                                }

                                // Nếu nhập quá số câu thì cắt lại về hợp lệ
                                if (index > questions.length) {
                                  // Cắt bớt ký tự cuối
                                  jumpToController.text =
                                      value.substring(0, value.length - 1);
                                  jumpToController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset: jumpToController.text.length),
                                  );
                                  return;
                                }

                                // Hợp lệ thì nhảy tới câu
                                saveCurrentQuestion();
                                setState(() {
                                  currentQuestionIndex = index - 1;
                                  loadQuestion();
                                });
                              },
                              onSubmitted: (value) {
                                final index = int.tryParse(value);
                                if (index != null &&
                                    index > 0 &&
                                    index <= questions.length) {
                                  setState(() {
                                    saveCurrentQuestion(); // lưu lại câu hiện tại nếu đang chỉnh
                                    currentQuestionIndex = index - 1;
                                    loadQuestion(); // load nội dung câu hỏi mới
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Số câu không hợp lệ")),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: questionController,
                    decoration: inputDecoration('Nội dung câu hỏi'),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          saveCurrentQuestion();
                          setState(() {
                            currentQuestionIndex = questions.length;
                            questions.add(
                              Question(
                                question: '',
                                correctAnswer: '',
                                incorrectAnswers: ['', '', ''],
                                categoryId: widget.categoryId,
                                idQuestionPackage: widget.idQuestionPackage,
                                isLocal: true, // <-- đảm bảo đây là câu mới
                              ),
                            );
                            loadQuestion(); // load ngay câu mới trắng
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm câu hỏi mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(160, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
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
