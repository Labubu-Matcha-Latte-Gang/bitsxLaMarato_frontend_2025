// lib/features/screens/micro/web_audio_recorder_web.dart
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

class WebAudioRecorder {
  final int chunkMillis;

  MediaRecorder? _recorder;
  MediaStream? _stream;
  bool _isRecording = false;

  final List<StreamSubscription> _subscriptions = [];

  WebAudioRecorder({required this.chunkMillis});

  /// Empieza a grabar y va llamando a [onChunk] con cada fragmento (.webm).
  /// El callback puede ser async.
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

    // 2. Crear el MediaRecorder con formato MP3 preferido
    // EVITAR WebM completamente - causa fragmentos incompatibles
    String? selectedMimeType;

    // Lista de formatos preferidos (priorizar webm/opus para máxima compatibilidad)
    final preferredMimeTypes = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/ogg;codecs=opus',
      'audio/mpeg',
      'audio/mp4;codecs=mp4a.40.2',
      'audio/mp4',
      'audio/aac',
    ];

    // Intentar cada formato hasta encontrar uno compatible
    for (String mimeType in preferredMimeTypes) {
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
        // Fallback sin especificar mimeType
        _recorder = MediaRecorder(_stream!);
        print('WebAudioRecorder: Fallback MediaRecorder creation (error: $e)');
      }
    } else {
      // Si ningún formato preferido está disponible, usar el predeterminado
      _recorder = MediaRecorder(_stream!);
      print(
          'WebAudioRecorder: No preferred format available, using browser default');
    }

    // 3. Escuchar el evento "dataavailable"
    _subscriptions.add(
      _recorder!.on['dataavailable'].listen((event) async {
        final blobEvent = event as BlobEvent;
        final blob = blobEvent.data;
        if (blob == null || blob.size == 0) return;

        // Blob -> Uint8List
        final reader = FileReader();
        final completer = Completer<Uint8List>();

        reader.onLoadEnd.listen((_) {
          final result = reader.result;
          if (result is ByteBuffer) {
            completer.complete(Uint8List.view(result));
          } else if (result is Uint8List) {
            completer.complete(result);
          } else {
            completer.complete(Uint8List(0));
          }
        });

        reader.readAsArrayBuffer(blob);

        final bytes = await completer.future;
        await onChunk(bytes);
      }),
    );

    // 4. Empezar la grabación con "timeslice" = chunkMillis
    // Esto hace que el navegador dispare "dataavailable" periódicamente.
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
    // No esperamos a que termine, liberamos best-effort
    if (_recorder != null && _recorder!.state == 'recording') {
      _recorder!.stop();
    }
    _stream?.getTracks().forEach((track) => track.stop());
    _stream = null;

    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  bool get isRecording => _isRecording;
}
