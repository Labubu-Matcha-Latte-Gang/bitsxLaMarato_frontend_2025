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

  TranscriptionCompleteRequest({required this.sessionId});

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
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
}
