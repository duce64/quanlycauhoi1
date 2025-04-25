import 'package:flutter/material.dart';
import 'package:flutterquiz/model/question.dart';
import 'package:flutterquiz/provider/score_provider.dart';
import 'package:flutterquiz/screen/dashboard.dart';
import 'package:flutterquiz/screen/show_question_screen.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/widget/button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class QuizFinishPage extends StatefulWidget {
  final String? title;
  final Map<int, dynamic>? answer;
  final List<Question>? listQuestion;

  const QuizFinishPage({Key? key, this.title, this.answer, this.listQuestion})
      : super(key: key);

  @override
  _QuizFinishPageState createState() => _QuizFinishPageState();
}

class _QuizFinishPageState extends State<QuizFinishPage> {
  int correct = 0;
  int incorrect = 0;
  int score = 0;
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.answer?.forEach((key, value) {
      if (widget.listQuestion?[key].correctAnswer == value) {
        correct++;
        score += 10;
      } else {
        incorrect++;
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTitleColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kết quả bài thi',
          style: TextStyle(color: kTitleColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/congratulate.png', width: 180),
                    const SizedBox(height: 24),
                    Text(
                      widget.title ?? 'Bài kiểm tra',
                      style: kHeadingTextStyleAppBar.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Điểm số của bạn: $score",
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildStatCard(
                            Icons.check_circle, "$correct đúng", Colors.green),
                        _buildStatCard(
                            Icons.cancel, "$incorrect sai", Colors.red),
                        _buildStatCard(
                            Icons.help_outline,
                            "${widget.listQuestion!.length} câu",
                            Colors.blueGrey),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Button(
                            title: 'Xem chi tiết',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShowQuestionScreen(
                                    answer: widget.answer ?? {},
                                    listQuestion: widget.listQuestion ?? [],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Button(
                            title: 'Trang chủ',
                            onTap: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DashboardPage()),
                                (route) => false,
                              );
                            },
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
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _buildDialogSaveScore() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lưu điểm số',
                  style: kHeadingTextStyleAppBar.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Tên của bạn",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("Tổng điểm: ", style: TextStyle(fontSize: 16)),
                    Text(
                      "$score",
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Huỷ"),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveScore() async {
    final now = DateTime.now();
    String datetime = DateFormat.yMd().format(now);
    await Provider.of<ScoreProvider>(context, listen: false).addScore(
      nameController.text,
      widget.title ?? '',
      score,
      datetime,
      correct,
      widget.listQuestion!.length,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
  }
}
