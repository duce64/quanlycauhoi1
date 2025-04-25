class Exam {
  final String id;
  final String title;
  final int questionPackageId;
  final String userId;
  final String department;
  final DateTime deadline;
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.title,
    required this.questionPackageId,
    required this.userId,
    required this.department,
    required this.deadline,
    required this.createdAt,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['_id'],
      title: json['title'],
      questionPackageId: json['questionPackageId'],
      userId: json['userId'],
      department: json['department'],
      deadline: DateTime.parse(json['deadline']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
