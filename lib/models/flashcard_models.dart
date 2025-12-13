// Flashcard models representing activity analysis sent by the backend.
// The backend JSON is expected to include:
// 1) an array of cognitive areas with the percentage they represent in the activity
// 2) a description of the activity
// 3) the reason why doing this activity helps

class CognitiveArea {
  final String name;
  final double percentage;

  CognitiveArea({required this.name, required this.percentage});

  factory CognitiveArea.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CognitiveArea(name: '', percentage: 0.0);

    // Accept several possible keys for the area's name
    final nameVal = json['name'] ?? json['area'] ?? json['label'] ?? '';
    final name = nameVal?.toString() ?? '';

    // Accept several possible keys for the percentage/weight
    final num? rawPerc = (json['percentage'] as num?) ?? (json['percent'] as num?) ?? (json['value'] as num?);
    final double percentage = rawPerc?.toDouble() ?? 0.0;

    return CognitiveArea(name: name, percentage: percentage);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'percentage': percentage,
    };
  }
}

class Flashcard {
  /// List of cognitive areas (expected to contain 4 entries according to backend)
  final List<CognitiveArea> cognitiveAreas;

  /// Short text with a concrete recommendation or how to perform the activity
  final String recommendation;

  /// Reason why this activity helps
  final String reason;

  /// Original raw JSON for debugging or future fields
  final Map<String, dynamic> raw;

  Flashcard({
    this.cognitiveAreas = const [],
    this.recommendation = '',
    this.reason = '',
    this.raw = const {},
  });

  factory Flashcard.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Flashcard();

    final areasJson = (json['cognitive_areas'] as List?) ?? (json['areas'] as List?) ?? [];
    final areas = areasJson.whereType<Map<String, dynamic>>().map(CognitiveArea.fromJson).toList();

    final description = json['description']?.toString() ?? json['desc']?.toString() ?? '';
    final recommendation = json['recommendation']?.toString() ?? json['recommend']?.toString() ?? '';
    final reason = json['reason']?.toString() ?? json['why']?.toString() ?? '';

    return Flashcard(
      cognitiveAreas: areas,
      recommendation: recommendation,
      reason: reason,
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cognitive_areas': cognitiveAreas.map((a) => a.toJson()).toList(),
      'recommendation': recommendation,
      'reason': reason,
    }..removeWhere((k, v) => v == null);
  }
}

