import 'dart:typed_data';

/// Placeholder recorder used when `dart:html` is unavailable (e.g. tests, mobile).
class WebAudioRecorder {
  final int chunkMillis;

  WebAudioRecorder({required this.chunkMillis});

  Future<void> start(Future<void> Function(Uint8List bytes) onChunk) {
    throw UnsupportedError(
      'WebAudioRecorder only works on the web. chunkMillis=$chunkMillis',
    );
  }

  Future<void> stop() async {}

  void dispose() {}

  bool get isRecording => false;
}
