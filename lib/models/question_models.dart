class Question {
  final String id;
  final String text;
  final String questionType;
  final double difficulty;

  Question({
    required this.id,
    required this.text,
    required this.questionType,
    required this.difficulty,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      questionType: json['question_type']?.toString() ?? '',
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'question_type': questionType,
      'difficulty': difficulty,
    };
  }
}
