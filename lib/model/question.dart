class Question {
  String? id; // _id từ MongoDB
  String? category;
  String? type;
  String? difficulty;
  String? question;
  String? correctAnswer;
  List<String>? incorrectAnswers;

  int? categoryId;
  int? idQuestionPackage;
  bool? isLocal;
  Question({
    this.id,
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
    required this.categoryId,
    required this.idQuestionPackage,
    this.isLocal = true,
  });

  Question.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    category = json['category'];
    type = json['type'];
    difficulty = json['difficulty'];
    question = json['name'];
    correctAnswer = json['correct_answer'];
    incorrectAnswers = json['incorrect_answers'].cast<String>();

    categoryId = json['categoryId'];
    idQuestionPackage = json['idQuestionPackage'];
    isLocal = false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['category'] = this.category;
    data['type'] = this.type;
    data['difficulty'] = this.difficulty;
    data['question'] = this.question;
    data['correct_answer'] = this.correctAnswer;
    data['incorrect_answers'] = this.incorrectAnswers;

    data['categoryId'] = this.categoryId;
    data['idQuestionPackage'] = this.idQuestionPackage;
    return data;
  }
}
