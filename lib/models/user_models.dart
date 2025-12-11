import 'question_models.dart';

class UserRoleData {
  final String? ailments;
  final String? gender;
  final int? age;
  final String? treatments;
  final double? heightCm;
  final double? weightKg;
  final List<String> doctors;
  final List<String> patients;
  final Map<String, dynamic> raw;

  const UserRoleData({
    this.ailments,
    this.gender,
    this.age,
    this.treatments,
    this.heightCm,
    this.weightKg,
    this.doctors = const [],
    this.patients = const [],
    this.raw = const {},
  });

  factory UserRoleData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserRoleData(raw: {});
    }

    final doctorsList = (json['doctors'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final patientsList = (json['patients'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return UserRoleData(
      ailments: json['ailments']?.toString(),
      gender: json['gender']?.toString(),
      age: (json['age'] as num?)?.toInt(),
      treatments: json['treatments']?.toString(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      doctors: doctorsList,
      patients: patientsList,
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (ailments != null) data['ailments'] = ailments;
    if (gender != null) data['gender'] = gender;
    if (age != null) data['age'] = age;
    if (treatments != null) data['treatments'] = treatments;
    if (heightCm != null) data['height_cm'] = heightCm;
    if (weightKg != null) data['weight_kg'] = weightKg;
    if (doctors.isNotEmpty) data['doctors'] = doctors;
    if (patients.isNotEmpty) data['patients'] = patients;
    return data;
  }
}

enum UserType { patient, doctor, admin, unknown }

extension UserRoleDataX on UserRoleData {
  UserType inferUserType() {
    final roleType = raw['role_type']?.toString().toLowerCase();
    if (roleType == 'doctor') return UserType.doctor;
    if (roleType == 'patient') return UserType.patient;
    if (roleType == 'admin') return UserType.admin;

    final hasPatientSignals = [
      ailments,
      gender,
      age,
      treatments,
      heightCm,
      weightKg,
    ].any((value) => value != null);

    final hasDoctorsList =
        doctors.isNotEmpty || raw.keys.map((k) => k.toString()).contains('doctors');
    final hasPatientsList =
        patients.isNotEmpty || raw.keys.map((k) => k.toString()).contains('patients');

    if (hasPatientSignals || hasDoctorsList) return UserType.patient;
    if (hasPatientsList) return UserType.doctor;
    return UserType.unknown;
  }
}

String? translateGenderToCatalan(String? gender) {
  if (gender == null) return null;
  final trimmed = gender.trim();
  if (trimmed.isEmpty) return null;
  switch (trimmed.toLowerCase()) {
    case 'male':
    case 'home':
      return 'Home';
    case 'female':
    case 'dona':
      return 'Dona';
    default:
      return trimmed;
  }
}

class UserProfile {
  final String email;
  final String name;
  final String surname;
  final UserRoleData role;

  UserProfile({
    required this.email,
    required this.name,
    required this.surname,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      role: UserRoleData.fromJson(json['role'] as Map<String, dynamic>?),
    );
  }
}

class UserUpdateRequest {
  final String name;
  final String surname;
  final String? password;
  final String? ailments;
  final String? gender;
  final int? age;
  final String? treatments;
  final double? heightCm;
  final double? weightKg;
  final List<String>? doctors;
  final List<String>? patients;

  UserUpdateRequest({
    required this.name,
    required this.surname,
    this.password,
    this.ailments,
    this.gender,
    this.age,
    this.treatments,
    this.heightCm,
    this.weightKg,
    this.doctors,
    this.patients,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'surname': surname,
    };
    if (password != null) data['password'] = password;
    if (ailments != null) data['ailments'] = ailments;
    if (gender != null) data['gender'] = gender;
    if (age != null) data['age'] = age;
    if (treatments != null) data['treatments'] = treatments;
    if (heightCm != null) data['height_cm'] = heightCm;
    if (weightKg != null) data['weight_kg'] = weightKg;
    if (doctors != null) data['doctors'] = doctors;
    if (patients != null) data['patients'] = patients;
    return data;
  }
}

class UserPartialUpdateRequest {
  final String? name;
  final String? surname;
  final String? password;
  final String? ailments;
  final String? gender;
  final int? age;
  final String? treatments;
  final double? heightCm;
  final double? weightKg;
  final List<String>? doctors;
  final List<String>? patients;

  UserPartialUpdateRequest({
    this.name,
    this.surname,
    this.password,
    this.ailments,
    this.gender,
    this.age,
    this.treatments,
    this.heightCm,
    this.weightKg,
    this.doctors,
    this.patients,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (surname != null) data['surname'] = surname;
    if (password != null) data['password'] = password;
    if (ailments != null) data['ailments'] = ailments;
    if (gender != null) data['gender'] = gender;
    if (age != null) data['age'] = age;
    if (treatments != null) data['treatments'] = treatments;
    if (heightCm != null) data['height_cm'] = heightCm;
    if (weightKg != null) data['weight_kg'] = weightKg;
    if (doctors != null) data['doctors'] = doctors;
    if (patients != null) data['patients'] = patients;
    return data;
  }
}

class ScoreSummary {
  final String activityId;
  final String activityTitle;
  final String? activityType;
  final String completedAt;
  final double score;
  final double secondsToFinish;

  ScoreSummary({
    required this.activityId,
    required this.activityTitle,
    required this.activityType,
    required this.completedAt,
    required this.score,
    required this.secondsToFinish,
  });

  factory ScoreSummary.fromJson(Map<String, dynamic> json) {
    return ScoreSummary(
      activityId: json['activity_id']?.toString() ?? '',
      activityTitle: json['activity_title']?.toString() ?? '',
      activityType: json['activity_type']?.toString(),
      completedAt: json['completed_at']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      secondsToFinish: (json['seconds_to_finish'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GraphFile {
  final String filename;
  final String contentType;
  final String content;

  GraphFile({
    required this.filename,
    required this.contentType,
    required this.content,
  });

  factory GraphFile.fromJson(Map<String, dynamic> json) {
    return GraphFile(
      filename: json['filename']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }
}

class PatientDataResponse {
  final UserProfile patient;
  final List<ScoreSummary> scores;
  final List<QuestionAnswerWithAnalysis> questions;
  final List<GraphFile> graphFiles;

  PatientDataResponse({
    required this.patient,
    required this.scores,
    required this.questions,
    required this.graphFiles,
  });

  factory PatientDataResponse.fromJson(Map<String, dynamic> json) {
    final scoresJson = (json['scores'] as List?) ?? [];
    final questionsJson = (json['questions'] as List?) ?? [];
    final graphJson = (json['graph_files'] as List?) ?? [];

    return PatientDataResponse(
      patient: UserProfile.fromJson(
        (json['patient'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      scores: scoresJson
          .whereType<Map<String, dynamic>>()
          .map(ScoreSummary.fromJson)
          .toList(),
      questions: questionsJson
          .whereType<Map<String, dynamic>>()
          .map(QuestionAnswerWithAnalysis.fromJson)
          .toList(),
      graphFiles: graphJson
          .whereType<Map<String, dynamic>>()
          .map(GraphFile.fromJson)
          .toList(),
    );
  }
}

class QuestionAnswerWithAnalysis {
  final Question question;
  final String answeredAt;
  final Map<String, double> analysis;

  QuestionAnswerWithAnalysis({
    required this.question,
    required this.answeredAt,
    required this.analysis,
  });

  factory QuestionAnswerWithAnalysis.fromJson(Map<String, dynamic> json) {
    final analysisData = (json['analysis'] as Map?) ?? {};
    final parsedAnalysis = <String, double>{};
    analysisData.forEach((key, value) {
      if (value is num) {
        parsedAnalysis[key.toString()] = value.toDouble();
      }
    });

    return QuestionAnswerWithAnalysis(
      question: Question.fromJson(
          (json['question'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
      answeredAt: json['answered_at']?.toString() ?? '',
      analysis: parsedAnalysis,
    );
  }
}

class PatientSearchResult {
  final String query;
  final List<UserProfile> results;

  const PatientSearchResult({
    required this.query,
    required this.results,
  });

  factory PatientSearchResult.fromJson(Map<String, dynamic> json) {
    final resultsJson = (json['results'] as List?) ?? [];
    return PatientSearchResult(
      query: json['query']?.toString() ?? '',
      results: resultsJson
          .whereType<Map<String, dynamic>>()
          .map(UserProfile.fromJson)
          .toList(),
    );
  }
}
