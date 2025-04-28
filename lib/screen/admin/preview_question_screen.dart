import 'package:flutter/material.dart';
import 'package:flutterquiz/model/question.dart';

class PreviewQuestionScreen extends StatelessWidget {
  final List<Question> questions;

  const PreviewQuestionScreen({Key? key, required this.questions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Xem trước câu hỏi')),
      body: questions.isEmpty
          ? Center(child: Text('Chưa có câu hỏi nào'))
          : ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
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
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
