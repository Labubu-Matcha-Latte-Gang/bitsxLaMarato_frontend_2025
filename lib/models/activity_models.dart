class Activity {
  final String id;
  final String title;
  final String description;
  final String activityType;
  final double difficulty;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.activityType,
    required this.difficulty,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      activityType: json['activity_type']?.toString() ?? '',
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ActivityQueryParams {
  final String? id;
  final String? title;
  final String? activityType;
  final double? difficulty;
  final double? difficultyMin;
  final double? difficultyMax;

  ActivityQueryParams({
    this.id,
    this.title,
    this.activityType,
    this.difficulty,
    this.difficultyMin,
    this.difficultyMax,
  });

  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {};
    if (id != null && id!.isNotEmpty) params['id'] = id!;
    if (title != null && title!.isNotEmpty) params['title'] = title!;
    if (activityType != null && activityType!.isNotEmpty) {
      params['activity_type'] = activityType!;
    }
    if (difficulty != null) params['difficulty'] = difficulty!.toString();
    if (difficultyMin != null) {
      params['difficulty_min'] = difficultyMin!.toString();
    }
    if (difficultyMax != null) {
      params['difficulty_max'] = difficultyMax!.toString();
    }
    return params;
  }
}

class ActivityCompleteRequest {
  final String id;
  final double score;
  final double secondsToFinish;

  ActivityCompleteRequest({
    required this.id,
    required this.score,
    required this.secondsToFinish,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'score': score,
      'seconds_to_finish': secondsToFinish,
    };
  }
}

class ActivityCompleteResponse {
  final Map<String, dynamic> patient;
  final Activity activity;
  final DateTime? completedAt;
  final double score;
  final double secondsToFinish;

  ActivityCompleteResponse({
    required this.patient,
    required this.activity,
    required this.completedAt,
    required this.score,
    required this.secondsToFinish,
  });

  factory ActivityCompleteResponse.fromJson(Map<String, dynamic> json) {
    final activityJson =
        (json['activity'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return ActivityCompleteResponse(
      patient: (json['patient'] as Map<String, dynamic>?) ?? {},
      activity: Activity.fromJson(activityJson),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      secondsToFinish:
          (json['seconds_to_finish'] as num?)?.toDouble() ?? 0,
    );
  }
}
