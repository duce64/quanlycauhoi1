import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:flutterquiz/mahoa.dart';
import 'package:flutterquiz/model/question.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:flutterquiz/widget/snackbar.dart';
import 'package:flutterquiz/screen/quiz_finish_screen.dart';
import 'package:flutterquiz/widget/awesomedialog.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizPageApi extends StatefulWidget {
  final int categoryId;
  final int questionId;
  final bool isTest;
  final String idTest;
  final int timeLimitMinutes;
  final int? numberQuestion; // ✅ thêm tham số
  const QuizPageApi({
    Key? key,
    required this.categoryId,
    required this.questionId,
    required this.isTest,
    required this.idTest,
    required this.timeLimitMinutes,
    this.numberQuestion, // ✅ thêm tham số
  }) : super(key: key);

  @override
  State<QuizPageApi> createState() => _QuizPageApiState();
}

class _QuizPageApiState extends State<QuizPageApi> {
  List<Question> listQuestion = [];
  bool isLoading = true;
  String error = '';
  int currentIndex = 0;
  Map<int, dynamic> answer = {};
  Map<int, List<String>> shuffledOptions = {};
  final unescape = HtmlUnescape();

  late Timer _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
    _remainingSeconds = widget.timeLimitMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _submitWhenTimeOut();
      }
    });
  }

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> fetchQuestions() async {
    print('check  numberQuestion${widget.numberQuestion}');
    final dio = Dio();
    final url =
        "${AppConstants.baseUrl}/api/questions/package/${widget.questionId}";

    try {
      setState(() => isLoading = true);
      final res = await dio.get(url);

      if (res.statusCode == 200) {
        final encrypted = res.data['result'];
        final iv = res.data['iv']; // nếu gửi từ backend
        final decryptedJson =
            decryptAes(encrypted, '1234567890abcdef', 'abcdef1234567890');
        final List<dynamic> questions = jsonDecode(decryptedJson);

        listQuestion = questions.map((e) => Question.fromJson(e)).toList();

        // ✅ Nếu có numberQuestion và số lượng ít hơn danh sách, thì random chọn
        if (widget.numberQuestion != null &&
            widget.numberQuestion! < listQuestion.length) {
          listQuestion.shuffle();
          listQuestion = listQuestion.take(widget.numberQuestion!).toList();
        }

        for (int i = 0; i < listQuestion.length; i++) {
          final q = listQuestion[i];
          final List<String> options = [
            ...(q.incorrectAnswers ?? []),
            q.correctAnswer ?? ''
          ];
          options.shuffle();
          shuffledOptions[i] = options;
        }

        setState(() => isLoading = false);
      } else {
        setState(() {
          error = 'Tải câu hỏi thất bại';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        print('check error $e');
        error = 'Lỗi kết nối: $e';
        isLoading = false;
      });
    }
  }

  void selectAnswer(dynamic value) {
    setState(() {
      answer[currentIndex] = value;
    });
  }

  void nextOrSubmit() async {
    if (answer[currentIndex] == null) {
      SnackBars.buildMessage(context, "Vui lòng chọn đáp án!");
      return;
    }

    if (currentIndex == listQuestion.length - 1) {
      buildDialog(
        context,
        "Hoàn thành?",
        "Bạn chắc chắn muốn kết thúc bài thi?",
        DialogType.success,
        () async {
          await submitExamResult();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => QuizFinishPage(
                title: listQuestion[0].category ?? '',
                answer: answer,
                listQuestion: listQuestion,
              ),
            ),
          );
        },
        () {},
      );
    } else {
      setState(() {
        currentIndex++;
      });
    }
  }

  Future<void> submitExamResult() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final parts = token.split('.');
    String name = 'Không rõ';
    String userId = '';
    if (parts.length == 3) {
      final payload = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      name = decoded['name'] ?? 'Không rõ';
      userId = decoded['userId'] ?? '';
    }

    int score = 0;
    for (int i = 0; i < listQuestion.length; i++) {
      if (answer[i] == listQuestion[i].correctAnswer) {
        score += (100 ~/ listQuestion.length);
      }
    }

    final status = score >= 50 ? 'Passed' : 'Failed';

    final dio = Dio();
    try {
      await dio.post(
        '${AppConstants.baseUrl}/api/results/add',
        data: {
          "name": name,
          "score": score,
          "status": status,
          "date": DateTime.now().toIso8601String(),
          "categoryId": widget.categoryId,
          "questionId": widget.categoryId,
          "userId": userId,
          "isTest": widget.isTest,
          "testId": widget.idTest,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      print('check ${{
        "name": name,
        "score": score,
        "status": status,
        "date": DateTime.now().toIso8601String(),
        "categoryId": widget.categoryId,
        "questionId": widget.categoryId,
        "userId": userId,
        "isTest": widget.isTest,
        "testId": widget.idTest,
      }}');
    } catch (e) {
      print("Lỗi nộp bài: $e");
    }
  }

  void _submitWhenTimeOut() async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Hết giờ"),
          content: const Text("Bài thi sẽ được tự động nộp."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 2));

    bool submitSuccess = false;
    int retryCount = 0;

    while (!submitSuccess && retryCount < 3) {
      try {
        await submitExamResult();
        submitSuccess = true;
      } catch (e) {
        retryCount++;
        if (retryCount >= 3) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text("Nộp bài thất bại. Vui lòng kiểm tra kết nối mạng."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (!mounted) return;

    Navigator.of(context).pop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizFinishPage(
          title: listQuestion.isNotEmpty
              ? listQuestion[0].category ?? ''
              : 'Bài thi',
          answer: answer,
          listQuestion: listQuestion,
        ),
      ),
    );
  }

  void changeQuestion(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestionText = listQuestion.isNotEmpty
        ? listQuestion[currentIndex].question ?? 'Bài thi'
        : 'Bài thi';

    return Scaffold(
      backgroundColor: const Color(0xFFE9F1FB),
      body: Column(
        children: [
          Container(
            height: 70,
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: kTitleColor),
                  onPressed: () {
                    buildDialog(
                      context,
                      "Cảnh báo!",
                      'Bạn có muốn thoát khỏi bài thi không?',
                      DialogType.warning,
                      () => Navigator.pop(context),
                      () {},
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentQuestionText.length > 60
                        ? currentQuestionText.substring(0, 60) + '...'
                        : currentQuestionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTitleColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                  child: Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      letterSpacing: 1.5,
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                    ? Center(child: Text(error))
                    : buildQuizContent(),
          ),
        ],
      ),
    );
  }

  Widget buildQuizContent() {
    final q = listQuestion[currentIndex];
    final options = shuffledOptions[currentIndex] ?? [];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Container(
        key: ValueKey<int>(currentIndex),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Câu ${currentIndex + 1} trên ${listQuestion.length}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  unescape.convert(q.question ?? ''),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...options.map((opt) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: answer[currentIndex] == opt
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: RadioListTile<String>(
                    value: opt,
                    groupValue: answer[currentIndex],
                    onChanged: (val) => selectAnswer(val),
                    title: Text(unescape.convert(opt)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentIndex > 0)
                  ElevatedButton(
                    onPressed: () => changeQuestion(currentIndex - 1),
                    child: const Text("Trước"),
                  ),
                ElevatedButton(
                  onPressed: nextOrSubmit,
                  child: Text(
                    currentIndex == listQuestion.length - 1
                        ? "Nộp bài"
                        : "Tiếp theo",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
