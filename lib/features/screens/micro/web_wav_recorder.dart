// lib/features/screens/micro/web_wav_recorder.dart
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

// dart:web_audio is only available on web; silence analyzer on non-web builds
// ignore: uri_does_not_exist
import 'dart:web_audio' as web_audio;

/// Simple WAV recorder for Flutter Web using AudioContext + ScriptProcessor.
/// Produces self-contained WAV chunks of fixed duration (chunkMillis).
class WebWavRecorder {
  final int chunkMillis;

  MediaStream? _stream;
  web_audio.AudioContext? _audioCtx;
  web_audio.ScriptProcessorNode? _processor;
  web_audio.MediaStreamAudioSourceNode? _source;
  bool _isRecording = false;

  final List<Float32List> _buffers = [];
  int _sampleRate = 48000; // default; will read from AudioContext when created
  late int _samplesPerChunk;

  WebWavRecorder({required this.chunkMillis}) {
    _samplesPerChunk = ((_sampleRate * chunkMillis) / 1000).round();
  }

  Future<void> start(Future<void> Function(Uint8List bytes) onChunk) async {
    if (_isRecording) return;

    final mediaDevices = window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw Exception('MediaDevices API no soportada');
    }

    _stream = await mediaDevices.getUserMedia({'audio': true});
    if (_stream == null) {
      throw Exception('No se pudo acceder al micrófono');
    }

    _audioCtx = web_audio.AudioContext();
    // Read actual sample rate from context (fallback to 48000)
    final num? sr = _audioCtx!.sampleRate;
    _sampleRate = (sr == null ? 48000 : sr.toInt());
    _samplesPerChunk = ((_sampleRate * chunkMillis) / 1000).round();

    _source = _audioCtx!.createMediaStreamSource(_stream!);
    // ScriptProcessor buffer size: 4096 samples per channel
    _processor = _audioCtx!.createScriptProcessor(4096, 1, 1);

    int accumulatedSamples = 0;
    _buffers.clear();

    _processor!.onAudioProcess.listen((web_audio.AudioProcessingEvent e) async {
      final input = e.inputBuffer;
      if (input == null) return;
      final channelData = input.getChannelData(0);
      if (channelData == null) return;

      // Copy to avoid retaining backing buffer
      final copy = Float32List.fromList(channelData);
      _buffers.add(copy);
      accumulatedSamples += copy.length;

      if (accumulatedSamples >= _samplesPerChunk) {
        // Assemble PCM
        final pcm = _concatFloat32(_buffers);
        _buffers.clear();
        accumulatedSamples = 0;

        // Encode to WAV and emit
        final wav = _encodeWav(pcm, _sampleRate);
        await onChunk(wav);
      }
    });

    _source!.connectNode(_processor!);
    // destination is nullable; assert non-null after context creation
    _processor!.connectNode(_audioCtx!.destination!);
    _isRecording = true;
  }

  Future<void> stop() async {
    if (!_isRecording) return;
    try {
      _processor?.disconnect();
      _source?.disconnect();
      _processor = null;
      _source = null;

      _audioCtx?.close();
      _audioCtx = null;

      _stream?.getTracks().forEach((t) => t.stop());
      _stream = null;
    } finally {
      _isRecording = false;
      _buffers.clear();
    }
  }

  void dispose() {
    stop();
  }

  bool get isRecording => _isRecording;

  // Helpers
  Float32List _concatFloat32(List<Float32List> parts) {
    int total = 0;
    for (final p in parts) total += p.length;
    final out = Float32List(total);
    int offset = 0;
    for (final p in parts) {
      out.setRange(offset, offset + p.length, p);
      offset += p.length;
    }
    return out;
  }

  /// Encode 32-bit float PCM [-1,1] mono into 16-bit PCM WAV
  Uint8List _encodeWav(Float32List pcm, int sampleRate) {
    final int numChannels = 1;
    final int bytesPerSample = 2; // 16-bit
    final int blockAlign = numChannels * bytesPerSample;
    final int byteRate = sampleRate * blockAlign;
    final int dataSize = pcm.length * bytesPerSample;
    final int chunkSize = 36 + dataSize;

    final bytes = BytesBuilder();

    // RIFF header
    bytes.add(_ascii('RIFF'));
    bytes.add(_u32le(chunkSize));
    bytes.add(_ascii('WAVE'));

    // fmt chunk
    bytes.add(_ascii('fmt '));
    bytes.add(_u32le(16)); // PCM fmt chunk size
    bytes.add(_u16le(1)); // PCM format
    bytes.add(_u16le(numChannels));
    bytes.add(_u32le(sampleRate));
    bytes.add(_u32le(byteRate));
    bytes.add(_u16le(blockAlign));
    bytes.add(_u16le(16)); // bits per sample

    // data chunk
    bytes.add(_ascii('data'));
    bytes.add(_u32le(dataSize));

    // samples
    final data = Uint8List(dataSize);
    int o = 0;
    for (int i = 0; i < pcm.length; i++) {
      double s = pcm[i];
      // clamp and convert to 16-bit
      s = s.clamp(-1.0, 1.0);
      final int si = (s * 32767.0).round();
      data[o++] = si & 0xFF; // little-endian
      data[o++] = (si >> 8) & 0xFF;
    }
    bytes.add(data);

    return bytes.toBytes();
  }

  Uint8List _ascii(String s) {
    final out = Uint8List(s.length);
    for (int i = 0; i < s.length; i++) {
      out[i] = s.codeUnitAt(i);
    }
    return out;
  }

  Uint8List _u16le(int v) => Uint8List.fromList([v & 0xFF, (v >> 8) & 0xFF]);
  Uint8List _u32le(int v) => Uint8List.fromList([
        v & 0xFF,
        (v >> 8) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 24) & 0xFF,
      ]);
}
