class QuestionPackage {
  final int idQuestion;
  final String name;

  QuestionPackage({required this.idQuestion, required this.name});

  factory QuestionPackage.fromJson(Map<String, dynamic> json) {
    return QuestionPackage(
      idQuestion: json['idQuestion'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idQuestion': idQuestion,
      'name': name,
    };
  }
}
