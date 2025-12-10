// lib/features/screens/micro/web_audio_recorder_web.dart
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio' as web_audio;

class WebAudioRecorder {
  final int chunkMillis;

  MediaRecorder? _recorder;
  MediaStream? _stream;
  bool _isRecording = false;
  web_audio.AudioContext? _audioContext;

  final List<StreamSubscription> _subscriptions = [];

  WebAudioRecorder({required this.chunkMillis});

  /// Demana permís d'accés al micròfon sense iniciar una sessió de gravació.
  Future<bool> ensurePermission() async {
    final mediaDevices = window.navigator.mediaDevices;
    if (mediaDevices == null) return false;

    try {
      final tempStream = await mediaDevices.getUserMedia({'audio': true});
      tempStream.getTracks().forEach((track) => track.stop());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Empieza a grabar y va llamando a [onChunk] con cada fragmento ya convertido a WAV.
  Future<void> start(Future<void> Function(Uint8List bytes) onChunk) async {
    if (_isRecording) return;

    final mediaDevices = window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw Exception('MediaDevices API no soportada en este navegador');
    }

    // 1. Pedir acceso al micrófono
    _stream = await mediaDevices.getUserMedia({'audio': true});
    if (_stream == null) {
      throw Exception('No se pudo acceder al micrófono');
    }

    // 2. Crear el MediaRecorder priorizando formatos comprimidos (opus/mp3/etc.)
    String? selectedMimeType;

    final preferredMimeTypes = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/ogg;codecs=opus',
      'audio/mpeg',
      'audio/mp4;codecs=mp4a.40.2',
      'audio/mp4',
      'audio/aac',
    ];

    for (final mimeType in preferredMimeTypes) {
      if (MediaRecorder.isTypeSupported(mimeType)) {
        selectedMimeType = mimeType;
        print('WebAudioRecorder: Using MIME type: $mimeType');
        break;
      }
    }

    if (selectedMimeType != null) {
      try {
        _recorder = MediaRecorder(_stream!, {'mimeType': selectedMimeType});
        print('WebAudioRecorder: MediaRecorder created with $selectedMimeType');
      } catch (e) {
        _recorder = MediaRecorder(_stream!);
        print('WebAudioRecorder: Fallback MediaRecorder creation (error: $e)');
      }
    } else {
      _recorder = MediaRecorder(_stream!);
      print('WebAudioRecorder: No preferred format available, using browser default');
    }

    // 3. Escuchar el evento "dataavailable" y convertir cada blob a WAV independiente
    _subscriptions.add(
      _recorder!.on['dataavailable'].listen((event) async {
        final blobEvent = event as BlobEvent;
        final blob = blobEvent.data;
        if (blob == null || blob.size == 0) return;

        try {
          final wavBytes = await _blobToValidWav(blob);
          if (wavBytes.isEmpty) return;
          await onChunk(wavBytes);
        } catch (error) {
          print('WebAudioRecorder: Error converting chunk to WAV: $error');
        }
      }),
    );

    // 4. Empezar la grabación con "timeslice" = chunkMillis
    _recorder!.start(chunkMillis);
    _isRecording = true;
  }

  /// Detiene la grabación y libera los recursos.
  Future<void> stop() async {
    if (!_isRecording) return;

    if (_recorder != null && _recorder!.state == 'recording') {
      _recorder!.stop();
    }

    _stream?.getTracks().forEach((track) => track.stop());
    _stream = null;

    _isRecording = false;
  }

  void dispose() {
    if (_recorder != null && _recorder!.state == 'recording') {
      _recorder!.stop();
    }
    _stream?.getTracks().forEach((track) => track.stop());
    _stream = null;

    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    _audioContext?.close();
    _audioContext = null;
  }

  bool get isRecording => _isRecording;

  Future<Uint8List> _blobToValidWav(Blob blob) async {
    final buffer = await _readBlobAsBuffer(blob);
    if (buffer == null || buffer.lengthInBytes == 0) {
      return Uint8List(0);
    }

    final audioContext = await _ensureAudioContext();
    final audioBuffer = await audioContext.decodeAudioData(buffer);
    return _encodeAudioBufferToWav(audioBuffer);
  }

  Future<ByteBuffer?> _readBlobAsBuffer(Blob blob) {
    final reader = FileReader();
    final completer = Completer<ByteBuffer?>();

    reader.onError.listen((_) {
      completer.completeError(reader.error ?? 'Unknown FileReader error');
    });

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(result);
      } else if (result is Uint8List) {
        completer.complete(result.buffer);
      } else {
        completer.complete(null);
      }
    });

    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  Future<web_audio.AudioContext> _ensureAudioContext() async {
    _audioContext ??= web_audio.AudioContext();
    if (_audioContext!.state == 'suspended') {
      await _audioContext!.resume();
    }
    return _audioContext!;
  }

  Uint8List _encodeAudioBufferToWav(web_audio.AudioBuffer buffer) {
    final int numChannels = buffer.numberOfChannels ?? 1;
    final int sampleRate = (buffer.sampleRate ?? 44100).round();
    final int sampleCount = buffer.length ?? 0;
    if (sampleCount <= 0) {
      return Uint8List(0);
    }
    const bitsPerSample = 16;
    final bytesPerSample = bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bytesPerSample;
    final int byteRate = sampleRate * blockAlign;
    final int dataSize = sampleCount * blockAlign;
    final int totalSize = 44 + dataSize;
    final byteData = ByteData(totalSize);

    void writeString(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        byteData.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    byteData.setUint32(4, totalSize - 8, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);
    writeString(36, 'data');
    byteData.setUint32(40, dataSize, Endian.little);

    final channelData = List<Float32List>.generate(
      numChannels,
      (i) => buffer.getChannelData(i),
      growable: false,
    );

    var offset = 44;
    for (int i = 0; i < sampleCount; i++) {
      for (int channel = 0; channel < numChannels; channel++) {
        final sample = (channelData[channel][i] * 32767.0)
            .clamp(-32768.0, 32767.0)
            .round();
        byteData.setInt16(offset, sample, Endian.little);
        offset += bytesPerSample;
      }
    }

    return byteData.buffer.asUint8List();
  }
}
