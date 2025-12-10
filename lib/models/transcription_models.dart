import 'dart:convert';

// ESTRATEGIA CORREGIDA DE CHUNKS (preserva silencios para análisis backend):
// - Web: MediaRecorder genera chunks automáticamente cada 15s
// - Móvil: Chunks cada 15s con restart inmediato para minimizar gaps
// - Silencios intermedios se preservan para análisis de pausas/respiración
// - Archivos grandes se dividen en chunks de 10MB para el upload

class TranscriptionChunkRequest {
  final String sessionId;
  final int chunkIndex;
  final List<int> audioBytes;
  final String filename;
  final String contentType;

  TranscriptionChunkRequest({
    required this.sessionId,
    required this.chunkIndex,
    required this.audioBytes,
    this.filename = 'chunk.wav',
    this.contentType = 'audio/wav',
  });
}

class TranscriptionCompleteRequest {
  final String sessionId;
  final String questionId;

  TranscriptionCompleteRequest({
    required this.sessionId,
    required this.questionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'question_id': questionId,
    };
  }
}

class TranscriptionResponse {
  final String status;
  final String? transcription;
  final String? partialText;
  final Map<String, dynamic> analysis;

  TranscriptionResponse({
    required this.status,
    this.transcription,
    this.partialText,
    this.analysis = const {},
  });

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(
      status: json['status']?.toString() ?? '',
      transcription: json['transcription']?.toString(),
      partialText: json['partial_text']?.toString(),
      analysis: (json['analysis'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (transcription != null) 'transcription': transcription,
      if (partialText != null) 'partial_text': partialText,
      if (analysis.isNotEmpty) 'analysis': analysis,
    };
  }

  @override
  String toString() {
    // Prefer showing the full transcription if available, then partial, then status
    if (transcription != null && transcription!.isNotEmpty) {
      return transcription!;
    }
    if (partialText != null && partialText!.isNotEmpty) {
      return partialText!;
    }
    // Fallback to a compact JSON representation
    try {
      return jsonEncode(toJson());
    } catch (_) {
      return 'TranscriptionResponse(status: $status)';
    }
  }
}

// --- New wrapper type used by existing UI code ---
class TranscriptionCompleteResponse extends TranscriptionResponse {
  TranscriptionCompleteResponse({
    required String status,
    String? transcription,
    String? partialText,
    Map<String, dynamic> analysis = const {},
  }) : super(
          status: status,
          transcription: transcription,
          partialText: partialText,
          analysis: analysis,
        );

  factory TranscriptionCompleteResponse.fromJson(Map<String, dynamic> json) {
    final base = TranscriptionResponse.fromJson(json);
    return TranscriptionCompleteResponse(
      status: base.status,
      transcription: base.transcription,
      partialText: base.partialText,
      analysis: base.analysis,
    );
  }
}
