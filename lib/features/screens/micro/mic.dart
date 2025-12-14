import 'dart:async';
import 'dart:io' show File;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import 'web_audio_recorder.dart';

import '../../../models/question_models.dart';
import '../../../models/transcription_models.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../patient/patient_menu_page.dart';

class MicScreen extends StatefulWidget {
  const MicScreen({super.key});

  @override
  State<MicScreen> createState() => _MicScreenState();
}

class _MicScreenState extends State<MicScreen>
    with SingleTickerProviderStateMixin {
  bool isDarkMode = false;

  /// Grabador nativo (móvil / desktop)
  final AudioRecorder _recorder = AudioRecorder();

  /// Grabador específico para Web (chunks .webm/MP3 comprimidos)
  WebAudioRecorder? _webRecorder;

  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  Timer? _chunkTimer;

  // Ruta temporal del fragment actual en dispositivos móviles
  String? _currentChunkPath;

  // Estado de carga y transcripción
  bool _isUploading = false;
  String? _transcriptionText;
  bool _hasUploadError = false;

  // Sesión e índice de fragment
  String? _currentSessionId;
  int _nextChunkIndex = 0;

  // Lista de cargas pendientes para esperar antes de finalizar
  final List<Future<void>> _pendingChunkUploads = [];

  // Máximo de segundos por fragment (Web automático, móvil con buffer overlap)
  static const int _maxChunkSeconds = 5;
  static const int _minRecordingSeconds = 10;

  bool get _hasReachedMinimumDuration =>
      _recordDuration.inSeconds >= _minRecordingSeconds;

  // Contador de errores consecutivos para debugging
  int _consecutiveErrors = 0;

  // WebM chunk buffering variables
  final List<Uint8List> _webmChunkBuffer = [];
  Timer? _bufferFlushTimer;
  static const int _maxBufferChunks = 3;
  static const Duration _bufferFlushInterval = Duration(seconds: 2);

  // MP4/MP3 chunk buffering variables (for minimum duration requirement)
  final List<Uint8List> _mp4ChunkBuffer = [];
  Timer? _mp4BufferFlushTimer;
  static const int _maxMp4BufferChunks =
      5; // Allow more chunks to reach 0.1s minimum
  static const Duration _mp4BufferFlushInterval = Duration(seconds: 3);

  // Pregunta diaria cargada desde la API
  late final Future<Question> _dailyQuestionFuture;
  Question? _currentDailyQuestion;

  // Permisos y flujo de finalització
  bool _hasMicPermission = false;
  bool _isCheckingPermission = false;
  bool _canNavigateToActivities = false;
  bool _showCompletionOverlay = false;
  bool _completionHadError = false;
  String? _completionMessage;

  // Animació de ones simulades
  late final AnimationController _waveController;
  final Random _waveRandom = Random();
  static const int _waveBarCount = 22;

  @override
  void initState() {
    super.initState();
    _dailyQuestionFuture = _getDailyQuestion();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (!kIsWeb) {
      _prefetchMobilePermission();
    }
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Future<void> _prefetchMobilePermission() async {
    try {
      final granted = await _recorder.hasPermission();
      if (mounted) {
        setState(() => _hasMicPermission = granted);
      }
    } catch (_) {
      // Ignorar errors silenciosament en el precheck
    }
  }

  Future<bool> _requestMicPermission({bool showToast = true}) async {
    setState(() {
      _isCheckingPermission = true;
    });

    bool granted = false;
    try {
      if (kIsWeb) {
        _webRecorder ??= WebAudioRecorder(
          chunkMillis: (_maxChunkSeconds + 1) * 1000,
        );
        granted = await _webRecorder!.ensurePermission();
      } else {
        granted = await _recorder.hasPermission();
      }
    } catch (e) {
      if (showToast) {
        _showError(
          'No hem pogut demanar el micròfon. Revisa els permisos del sistema.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _hasMicPermission = granted;
          _isCheckingPermission = false;
        });
      }
    }

    if (!granted && showToast) {
      _showError("Cal autoritzar el micròfon per continuar.");
    }

    return granted;
  }

  Future<bool> _ensureMicPermission() async {
    if (_hasMicPermission) return true;
    return _requestMicPermission();
  }

  // Muestra un mensaje de error
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<Question> _getDailyQuestion() async {
    final question = await ApiService.getDailyQuestion();
    _currentDailyQuestion = question;
    return question;
  }

  /// Inicia la grabación. Se genera un nuevo session_id y se configuran los
  /// temporizadores para enviar fragmentos de voz de 15s al backend.
  Future<void> _startRecording() async {
    if (_isRecording) return;

    final permitted = await _ensureMicPermission();
    if (!permitted) return;

    setState(() {
      _showCompletionOverlay = false;
      _canNavigateToActivities = false;
      _completionMessage = null;
    });

    // Reinicializa estado de la sesión
    _transcriptionText = null;
    _hasUploadError = false;
    _currentSessionId = const Uuid().v4();
    _nextChunkIndex = 0;
    _pendingChunkUploads.clear();

    // --- WEB: usamos WebAudioRecorder (MediaRecorder + chunks .webm válidos) ---
    if (kIsWeb) {
      // Use larger chunkMillis on web to produce fewer, longer chunks
      _webRecorder ??= WebAudioRecorder(
        // Use 2000–3000ms chunks to satisfy minimum duration and reduce overhead
        chunkMillis: (_maxChunkSeconds + 1) * 1000,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });
      _waveController.repeat();

      // Temporizador para actualizar la duración visible
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
      });

      try {
        await _webRecorder!.start((Uint8List bytes) async {
          // Cada chunk llega como bytes de un .wav válido
          if (_currentSessionId == null) return;

          final Future<void> f = _sendWebChunk(bytes);
          _pendingChunkUploads.add(f);
          try {
            await f;
          } finally {
            _pendingChunkUploads.remove(f);
          }
        });
      } catch (e) {
        _showError("No s'ha pogut accedir al micròfon.");
        setState(() {
          _isRecording = false;
          _recordDuration = Duration.zero;
        });
      }

      return;
    }

    // --- MÓVIL / DESKTOP: plugin record ---
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showError("No s'ha pogut accedir al micròfon.");
      return;
    }

    // Iniciar el primer fragment
    try {
      await _startNewMobileRecording();
    } catch (e) {
      _showError("No s'ha pogut iniciar la gravació.");
      return;
    }

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });
    _waveController.repeat();

    // Temporizador de la UI
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordDuration += const Duration(seconds: 1);
      });
    });

    // ESTRATEGIA SIMPLIFICADA: Volvemos al enfoque original
    // El restart rápido está causando archivos corruptos
    // Mejor tener un gap pequeño que chunks inválidos

    _chunkTimer?.cancel();
    _chunkTimer = Timer.periodic(
      const Duration(seconds: _maxChunkSeconds),
      (_) async {
        if (_currentSessionId == null || _isUploading) return;

        // Envío simple sin restart para evitar corrupción
        // HACK: Crear nueva sesión para cada chunk como test
        final Future<void> f = _sendCurrentMobileChunkSimple();
        _pendingChunkUploads.add(f);
        f.whenComplete(() => _pendingChunkUploads.remove(f));
      },
    );
  }

  /// Detiene la grabación, envía el último fragmento y completa la sesión.
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    if (!_hasReachedMinimumDuration) {
      _showError(
        'Necessites gravar almenys $_minRecordingSeconds segons abans de poder aturar-te.',
      );
      return;
    }

    // Cancelar temporizadores
    _timer?.cancel();
    _timer = null;
    _chunkTimer?.cancel();
    _chunkTimer = null;

    if (kIsWeb) {
      // Detener grabación en Web
      try {
        await _webRecorder?.stop();

        // Clear any legacy WebM buffer usage
        if (_webmChunkBuffer.isNotEmpty) {
          _webmChunkBuffer.clear();
        }
        _bufferFlushTimer?.cancel();
      } catch (_) {}
    } else {
      // Detener la grabación móvil y enviar el último fragmento
      try {
        final Future<void> f = _sendCurrentMobileChunk(restart: false);
        _pendingChunkUploads.add(f);
        await f;
        _pendingChunkUploads.remove(f);
      } catch (e) {
        print('ERROR en stop recording: $e');
      }
    }

    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
    });
    _waveController.stop();
    _waveController.reset();

    // Esperar cargas pendientes
    try {
      if (_pendingChunkUploads.isNotEmpty) {
        await Future.wait(List<Future<void>>.from(_pendingChunkUploads));
      }
    } catch (_) {}

    // Finalizar la sesión de transcripción
    await _completeTranscription();
  }

  /// Inicia una nueva grabación (móvil) creando un archivo temporal.
  Future<void> _startNewMobileRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.webm';
      _currentChunkPath = filePath;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus, // contenedor/webm compatible con Whisper
          bitRate: 128000,
          sampleRate: 48000, // sampleRate corregido
        ),
        path: filePath,
      );

      print('DEBUG - Nueva grabación iniciada: $filePath');
    } catch (e) {
      print('ERROR - Fallo al iniciar nueva grabación: $e');
      rethrow;
    }
  }

  /// Envía el chunk actual SIN restart (estrategia simplificada)
  Future<void> _sendCurrentMobileChunkSimple() async {
    if (_currentSessionId == null || _isUploading) return;

    setState(() => _isUploading = true);

    try {
      // Detener grabación temporalmente
      final String? path = await _recorder.stop();
      final String? filePath = path ?? _currentChunkPath;

      if (filePath != null) {
        final file = File(filePath);

        if (await file.exists()) {
          final bytes = await file.readAsBytes();

          if (bytes.isNotEmpty && bytes.length > 1000) {
            // Validar archivo válido

            // HACK TEMPORAL: Crear nueva sesión para cada chunk como test
            // Esto nos ayudará a determinar si el problema es de estado en el backend
            final testSessionId =
                _nextChunkIndex == 0 ? _currentSessionId! : const Uuid().v4();

            final chunkRequest = TranscriptionChunkRequest(
              sessionId: testSessionId,
              chunkIndex: _nextChunkIndex == 0
                  ? 0
                  : 0, // Siempre enviar como chunk 0 para test
              audioBytes: bytes,
              filename: 'chunk_${_nextChunkIndex}.webm',
              contentType: 'audio/webm',
            );

            print(
                'DEBUG - HACK TEST: Enviando chunk con session=$testSessionId, originalIndex=${_nextChunkIndex}, testIndex=0');
            await ApiService.uploadTranscriptionChunk(chunkRequest);
            _consecutiveErrors = 0; // Reset contador en éxito
            _nextChunkIndex += 1;

            // Limpiar archivo
            try {
              await file.delete();
            } catch (e) {
              print('Error borrando: $e');
            }
          } else {
            print('WARNING - Chunk muy pequeño: ${bytes.length} bytes');
          }
        } else {
          print('WARNING - Archivo no existe: $filePath');
        }
      }

      // Reiniciar grabación después del envío
      if (_isRecording && _currentSessionId != null) {
        await _startNewMobileRecording();
      }
    } catch (e) {
      _consecutiveErrors++;
      _hasUploadError = true;
      _showError("Error en enviar l'àudio. Torna-ho a provar.");
      print(
          'ERROR en _sendCurrentMobileChunkSimple (${_consecutiveErrors} consecutivos): $e');

      // Si hay muchos errores consecutivos, reiniciar sesión
      if (_consecutiveErrors >= 3) {
        print(
            'CRITICAL - Demasiados errores consecutivos, reiniciando sesión...');
        _currentSessionId = const Uuid().v4();
        _nextChunkIndex = 0;
        _consecutiveErrors = 0;
      }

      // Intentar reiniciar grabación si está en curso
      if (_isRecording && _currentSessionId != null) {
        try {
          await _startNewMobileRecording();
        } catch (restartError) {
          print('ERROR reiniciando grabación: $restartError');
        }
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Verifica y procesa chunks de audio manteniendo continuidad
  Future<void> _processContinuousChunk() async {
    if (_currentSessionId == null || _isUploading) return;

    // Prevenir múltiples uploads simultáneos
    setState(() => _isUploading = true);

    try {
      // Enviar chunk actual manteniendo la grabación activa
      await _sendCurrentMobileChunk(restart: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Envía el fragmento actual grabado en móvil. Si [restart] es true, arranca
  /// una nueva grabación inmediatamente.
  Future<void> _sendCurrentMobileChunk({bool restart = true}) async {
    if (_currentSessionId == null) return;

    try {
      if (!restart) {
        // Caso final: detener y enviar último chunk
        final String? path = await _recorder.stop();
        final String? filePath = path ?? _currentChunkPath;
        if (filePath == null) return;

        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            setState(() => _isUploading = true);
            try {
              await _sendAudioInChunks(bytes, file);
            } finally {
              setState(() => _isUploading = false);
            }
          } else {
            print('WARNING - Archivo final vacío: $filePath');
            await file.delete().catchError((_) {});
          }
        }
      } else {
        // ESTRATEGIA MEJORADA: Validaciones adicionales
        // CORREGIDO: Usamos _isRecording local porque .isRecording() no existe en v6
        if (!_isRecording) {
          print(
              'WARNING - Recorder no está grabando, iniciando nueva grabación');
          await _startNewMobileRecording();
          return;
        }

        final String? currentPath = await _recorder.stop();
        final String? filePath = currentPath ?? _currentChunkPath;

        if (filePath != null) {
          final file = File(filePath);

          // Validar que el archivo existe y tiene contenido antes de procesar
          if (await file.exists()) {
            final bytes = await file.readAsBytes();

            if (bytes.isNotEmpty && bytes.length > 1000) {
              // Mínimo 1KB para ser válido
              // Iniciar nueva grabación ANTES de procesar
              await _startNewMobileRecording();

              // Procesar chunk válido
              final chunkRequest = TranscriptionChunkRequest(
                sessionId: _currentSessionId!,
                chunkIndex: _nextChunkIndex,
                audioBytes: bytes,
                filename: 'chunk_${_nextChunkIndex}.webm',
                contentType: 'audio/webm',
              );

              print(
                  'DEBUG - Enviando chunk válido: index=${_nextChunkIndex}, size=${bytes.length}');
              await ApiService.uploadTranscriptionChunk(chunkRequest);
              _nextChunkIndex += 1;
            } else {
              print(
                  'WARNING - Archivo muy pequeño o vacío (${bytes.length} bytes), reiniciando grabación');
              await _startNewMobileRecording();
            }

            // Limpiar archivo procesado
            try {
              await file.delete();
            } catch (e) {
              print('Error borrando archivo: $e');
            }
          } else {
            print(
                'WARNING - Archivo no existe: $filePath, reiniciando grabación');
            await _startNewMobileRecording();
          }
        } else {
          print(
              'ERROR - No se obtuvo path del archivo, reiniciando grabación');
          await _startNewMobileRecording();
        }
      }
    } catch (e) {
      _hasUploadError = true;
      _showError("Error en enviar l'àudio. Torna-ho a provar.");

      // En caso de error, intentar reiniciar grabación si es restart=true
      if (restart && _isRecording) {
        try {
          await _startNewMobileRecording();
        } catch (restartError) {
          print('ERROR - No se pudo reiniciar grabación: $restartError');
        }
      }
    }
    // NOTA: _isUploading se maneja en _processContinuousChunk o localmente
  }

  /// Divide archivos de audio grandes en chunks para envío
  Future<void> _sendAudioInChunks(
      List<int> audioBytes, File originalFile) async {
    const int maxChunkSizeBytes = 10 * 1024 * 1024; // 10MB por chunk

    if (audioBytes.length <= maxChunkSizeBytes) {
      // Archivo pequeño, enviar directamente
      final chunkRequest = TranscriptionChunkRequest(
        sessionId: _currentSessionId!,
        chunkIndex: _nextChunkIndex,
        audioBytes: audioBytes,
        filename: 'chunk_${_nextChunkIndex}.webm',
        contentType: 'audio/webm',
      );

      await ApiService.uploadTranscriptionChunk(chunkRequest);
      _nextChunkIndex += 1;
    } else {
      // Archivo grande, dividir en chunks temporales
      int offset = 0;
      while (offset < audioBytes.length) {
        final end = (offset + maxChunkSizeBytes) < audioBytes.length
            ? (offset + maxChunkSizeBytes)
            : audioBytes.length;

        final chunkBytes = audioBytes.sublist(offset, end);

        final chunkRequest = TranscriptionChunkRequest(
          sessionId: _currentSessionId!,
          chunkIndex: _nextChunkIndex,
          audioBytes: chunkBytes,
          filename: 'chunk_${_nextChunkIndex}.webm',
          contentType: 'audio/webm',
        );

        await ApiService.uploadTranscriptionChunk(chunkRequest);
        _nextChunkIndex += 1;
        offset = end;
      }
    }

    // Limpiar archivo temporal
    try {
      await originalFile.delete();
    } catch (_) {}
  }

  /// Maneja grabaciones extremadamente largas (>60s) dividiendo sin interrumpir
  Future<void> _splitLongRecording() async {
    // Esta función se puede implementar en el futuro si es necesario
    // Por ahora, simplemente logueamos el evento
    print(
        'DEBUG - Grabación larga detectada: ${_recordDuration.inSeconds}s');
  }

  /// Envía un fragmento grabado en Web con estrategia de buffering para WebM.
  /// Los chunks WebM se acumulan y envían como un archivo más grande y válido.
  Future<void> _sendWebChunk(Uint8List bytes) async {
    if (_currentSessionId == null) return;

    try {
      // Detectar formato del chunk basado en los primeros bytes
      String detectedFormat = 'wav'; // default fallback
      String contentType = 'audio/wav';

      print(
          'DEBUG - *** NUEVA VERSIÓN CON BUFFERING ACTIVA *** chunk size: ${bytes.length}');

      if (bytes.length > 4) {
        // Detectar WAV (header: RIFF....WAVE)
        if (bytes.length > 12 &&
            bytes[0] == 0x52 && // R
            bytes[1] == 0x49 && // I
            bytes[2] == 0x46 && // F
            bytes[3] == 0x46 && // F
            bytes[8] == 0x57 && // W
            bytes[9] == 0x41 && // A
            bytes[10] == 0x56 && // V
            bytes[11] == 0x45) {
          // E
          detectedFormat = 'wav';
          contentType = 'audio/wav';
          print('\U0001f3b5 DEBUG - WAV format detected');
        }
        // Detectar WebM/Matroska (EBML header 1A 45 DF A3)
        else if (bytes[0] == 0x1A &&
            bytes[1] == 0x45 &&
            bytes[2] == 0xDF &&
            bytes[3] == 0xA3) {
          detectedFormat = 'webm';
          contentType = 'audio/webm';
          print('\U0001f3b5 DEBUG - WEBM format detected');
        }
        // Detectar MP3 (headers: 0xFF 0xFB, 0xFF 0xFA, o "ID3")
        else if ((bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) ||
            (bytes.length > 3 &&
                bytes[0] == 0x49 &&
                bytes[1] == 0x44 &&
                bytes[2] == 0x33)) {
          detectedFormat = 'mp3';
          contentType = 'audio/mpeg';
          print(
              '\U0001f3b5 DEBUG - MP3 format detected! Using direct upload strategy');
        }
        // Detectar MP4/M4A (header: ftyp)
        else if (bytes.length > 8 &&
            bytes[4] == 0x66 &&
            bytes[5] == 0x74 &&
            bytes[6] == 0x79 &&
            bytes[7] == 0x70) {
          detectedFormat = 'm4a';
          contentType = 'audio/mp4';
          print(
              '\U0001f3b5 DEBUG - MP4/M4A format detected! Using direct upload strategy');
        }
        // Detectar OGG (header: "OggS")
        else if (bytes.length > 4 &&
            bytes[0] == 0x4F &&
            bytes[1] == 0x67 &&
            bytes[2] == 0x67 &&
            bytes[3] == 0x53) {
          detectedFormat = 'ogg';
          contentType = 'audio/ogg';
          print(
              '\U0001f3b5 DEBUG - OGG format detected! Using direct upload strategy');
        }
      }

      print(
          'DEBUG - Detected audio format: $detectedFormat, size: ${bytes.length} bytes');

      // Strategy: Buffer chunks that need accumulation due to format limitations
      if (detectedFormat == 'webm') {
        // Legacy path no longer used; send directly to avoid invalid fragments
        print(
            '\u26a0\ufe0f DEBUG - WebM detected, sending directly to avoid fragment issues');
        await _sendChunkDirect(bytes, 'webm', 'audio/webm');
      } else if (detectedFormat == 'mp3' || detectedFormat == 'm4a') {
        print(
            '\U0001f3b5 DEBUG - MP4/MP3 detected, routing to accumulation strategy (min duration requirement) \U0001f3b5');
        await _handleMp4Chunk(bytes, detectedFormat, contentType);
      } else {
        print(
            'DEBUG - Non-buffered format detected ($detectedFormat), sending directly');
        // Formats that can be sent directly (OGG, etc.)
        await _sendChunkDirect(bytes, detectedFormat, contentType);
      }
    } catch (e) {
      _hasUploadError = true;
      print('ERROR in _sendWebChunk: $e');
      _showError("Error en enviar l'àudio. Torna-ho a provar.");
    }
  }

  /// Handle WebM chunks with buffering strategy
  Future<void> _handleWebMChunk(Uint8List bytes) async {
    print('DEBUG - _handleWebMChunk called with ${bytes.length} bytes');

    // Add to buffer
    _webmChunkBuffer.add(bytes);
    print(
        'DEBUG - WebM chunk buffered (${_webmChunkBuffer.length}/${_maxBufferChunks}, size: ${bytes.length})');

    // Cancel existing timer
    _bufferFlushTimer?.cancel();

    // Send immediately if buffer is full OR if this is the first chunk
    bool shouldFlushNow =
        _webmChunkBuffer.length >= _maxBufferChunks || _nextChunkIndex == 0;
    print(
        'DEBUG - Should flush now: $shouldFlushNow (buffer: ${_webmChunkBuffer.length}, chunkIndex: $_nextChunkIndex)');

    if (shouldFlushNow) {
      await _flushWebMBuffer();
    } else {
      // Set timer to flush buffer after interval
      _bufferFlushTimer = Timer(_bufferFlushInterval, () {
        print(
            'DEBUG - WebM buffer timer triggered after ${_bufferFlushInterval.inSeconds}s');
        _flushWebMBuffer();
      });
      print(
          'DEBUG - WebM buffer timer set for ${_bufferFlushInterval.inSeconds}s');
    }
  }

  /// Flush accumulated WebM chunks as a single larger chunk
  Future<void> _flushWebMBuffer() async {
    if (_webmChunkBuffer.isEmpty || _currentSessionId == null) return;

    _bufferFlushTimer?.cancel();

    try {
      setState(() => _isUploading = true);

      // Combine all buffered chunks
      int totalSize =
          _webmChunkBuffer.fold(0, (sum, chunk) => sum + chunk.length);
      Uint8List combinedChunk = Uint8List(totalSize);

      int offset = 0;
      for (Uint8List chunk in _webmChunkBuffer) {
        combinedChunk.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      print(
          'DEBUG - Flushing ${_webmChunkBuffer.length} WebM chunks as combined chunk (${totalSize} bytes)');

      // Send combined chunk
      await _sendChunkDirect(combinedChunk, 'webm', 'audio/webm');

      // Clear buffer
      _webmChunkBuffer.clear();
    } catch (e) {
      _hasUploadError = true;
      print('ERROR in _flushWebMBuffer: $e');
      _showError("Error en enviar l'àudio. Torna-ho a provar.");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Handle MP4/MP3 chunks with accumulation for minimum duration requirement
  Future<void> _handleMp4Chunk(
      Uint8List bytes, String format, String contentType) async {
    print('DEBUG - _handleMp4Chunk called with ${bytes.length} bytes');

    // Add to MP4 buffer
    _mp4ChunkBuffer.add(bytes);
    print(
        'DEBUG - MP4 chunk buffered (${_mp4ChunkBuffer.length}/${_maxMp4BufferChunks}, size: ${bytes.length})');

    // Cancel existing timer
    _mp4BufferFlushTimer?.cancel();

    // Decide flush based on combined size or buffer count (avoid flushing only header)
    int combinedSize =
        _mp4ChunkBuffer.fold(0, (sum, chunk) => sum + chunk.length);
    const int minFirstFlushBytes = 10 * 1024; // ~10KB to exceed ~0.1s safely
    bool shouldFlushNow =
        _mp4ChunkBuffer.length >= 2 || // at least two chunks before first send
            combinedSize >= minFirstFlushBytes ||
            _mp4ChunkBuffer.length >= _maxMp4BufferChunks; // safety cap
    print(
        'DEBUG - Should flush MP4 now: $shouldFlushNow (buffer: ${_mp4ChunkBuffer.length}, combinedSize: $combinedSize, chunkIndex: $_nextChunkIndex)');

    if (shouldFlushNow) {
      await _flushMp4Buffer(format, contentType);
    } else {
      // Set timer to flush after interval
      _mp4BufferFlushTimer = Timer(_mp4BufferFlushInterval, () {
        print(
            'DEBUG - MP4 buffer timer triggered after ${_mp4BufferFlushInterval.inSeconds}s');
        int combinedSize =
            _mp4ChunkBuffer.fold(0, (sum, chunk) => sum + chunk.length);
        const int minFirstFlushBytes = 10 * 1024;
        bool canFlush = _mp4ChunkBuffer.length >= 2 ||
            combinedSize >= minFirstFlushBytes ||
            _mp4ChunkBuffer.length >= _maxMp4BufferChunks;
        if (canFlush) {
          _flushMp4Buffer(format, contentType);
        } else {
          // Not enough yet, re-arm timer to check again
          print(
              'DEBUG - MP4 buffer timer: not enough data yet (buffer: ${_mp4ChunkBuffer.length}, combinedSize: $combinedSize). Re-arming.');
          _mp4BufferFlushTimer = Timer(_mp4BufferFlushInterval, () {
            print('DEBUG - MP4 buffer timer re-triggered');
            int combinedSize2 =
                _mp4ChunkBuffer.fold(0, (sum, chunk) => sum + chunk.length);
            bool canFlush2 = _mp4ChunkBuffer.length >= 2 ||
                combinedSize2 >= minFirstFlushBytes ||
                _mp4ChunkBuffer.length >= _maxMp4BufferChunks;
            if (canFlush2) {
              _flushMp4Buffer(format, contentType);
            } else {
              print(
                  'DEBUG - MP4 buffer timer: still not enough (buffer: ${_mp4ChunkBuffer.length}, combinedSize: $combinedSize2). Re-arming again.');
              // Re-arm again until we have enough data
              _mp4BufferFlushTimer = Timer(_mp4BufferFlushInterval, () {
                print('DEBUG - MP4 buffer timer final re-trigger');
                _flushMp4Buffer(format, contentType);
              });
            }
          });
        }
      });
      print(
          'DEBUG - MP4 buffer timer set for ${_mp4BufferFlushInterval.inSeconds}s');
    }
  }

  /// Flush accumulated MP4 chunks as single combined chunk
  Future<void> _flushMp4Buffer(String format, String contentType) async {
    if (_mp4ChunkBuffer.isEmpty || _currentSessionId == null) return;

    _mp4BufferFlushTimer?.cancel();
    setState(() => _isUploading = true);

    try {
      // Combine all MP4 chunks into one
      int totalSize =
          _mp4ChunkBuffer.fold(0, (sum, chunk) => sum + chunk.length);
      Uint8List combinedChunk = Uint8List(totalSize);

      int offset = 0;
      for (Uint8List chunk in _mp4ChunkBuffer) {
        combinedChunk.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      print(
          'DEBUG - Flushing ${_mp4ChunkBuffer.length} MP4 chunks as combined chunk (${totalSize} bytes)');

      // Send combined chunk
      await _sendChunkDirect(combinedChunk, format, contentType);

      // Clear buffer
      _mp4ChunkBuffer.clear();
    } catch (e) {
      _hasUploadError = true;
      print('ERROR in _flushMp4Buffer: $e');
      _showError("Error en enviar l'àudio MP4. Torna-ho a provar.");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Send chunk directly to API
  Future<void> _sendChunkDirect(
      Uint8List bytes, String format, String contentType) async {
    setState(() => _isUploading = true);

    try {
      final chunkRequest = TranscriptionChunkRequest(
        sessionId: _currentSessionId!,
        chunkIndex: _nextChunkIndex,
        audioBytes: bytes,
        filename: 'chunk_${_nextChunkIndex}.$format',
        contentType: contentType,
      );

      await ApiService.uploadTranscriptionChunk(chunkRequest);
      _nextChunkIndex += 1;
      print(
          'DEBUG - Chunk $format sent successfully (index ${_nextChunkIndex - 1})');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Completa la sessió actual i mostra la confirmació.
  Future<void> _completeTranscription() async {
    final String? sessionId = _currentSessionId;
    if (sessionId == null) return;
    final questionId = _currentDailyQuestion?.id;

    bool success = false;
    String? extracted;

    try {
      setState(() => _isUploading = true);

      if (questionId == null || questionId.isEmpty) {
        throw Exception('Pregunta diària no carregada');
      }

      final response = await ApiService.completeTranscriptionSession(
        TranscriptionCompleteRequest(
          sessionId: sessionId,
          questionId: questionId,
        ),
      );

      extracted = response.transcription ?? response.partialText ?? '';
      setState(() {
        _transcriptionText = extracted;
      });
      success = true;
    } catch (e) {
      _hasUploadError = true;
      _showError(
        'No s\'ha pogut completar la transcripció, però pots continuar.',
      );
    } finally {
      setState(() {
        _isUploading = false;
        _currentSessionId = null;
        _nextChunkIndex = 0;
        _webmChunkBuffer.clear();
        _showCompletionOverlay = true;
        _canNavigateToActivities = true;
        _completionHadError = !success;
        _completionMessage = success
            ? 'Resposta enregistrada amb èxit.'
            : 'Hi ha hagut un problema en l\'enviament, però pots continuar.';
      });
      _bufferFlushTimer?.cancel();
    }
  }

  String _shortPreview(String text, [int max = 120]) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chunkTimer?.cancel();
    _recorder.dispose();
    _webRecorder?.dispose();
    _waveController.dispose();
    super.dispose();
  }

  /// Formatea la duración en mm:ss
  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Widget _buildWaveform() {
    final Color activeColor = _isRecording
        ? const Color(0xFFEF476F)
        : AppColors.getPrimaryButtonColor(isDarkMode);

    return SizedBox(
      height: 168,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, _) {
          final progress = _waveController.value;
          final bars = List.generate(_waveBarCount, (index) {
            final phase = (progress * 2 * pi) + (index * 0.35);
            final noise =
                _waveRandom.nextDouble() * (_isRecording ? 0.35 : 0.15);
            final normalized = (sin(phase) + 1) / 2;
            final heightFactor = (normalized * 0.7) + noise;
            final double barHeight =
                (22 + heightFactor * 58).clamp(10.0, 120.0);

            return Container(
              width: 4,
              height: barHeight,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withAlpha(100),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          });

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: bars,
          );
        },
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    if (!_showCompletionOverlay) return const SizedBox.shrink();

    final title = _completionHadError
        ? 'Resposta enregistrada amb incidències'
        : 'Resposta enregistrada!';
    final subtitle = _completionMessage ??
        (_completionHadError
            ? 'Hi ha hagut un problema amb el servidor, però pots continuar.'
            : 'Hem rebut la teva resposta. Prem continuar per anar a activitats.');

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.getBlurContainerColor(isDarkMode)
                    .withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 18,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.greenAccent.withOpacity(0.2),
                                Colors.greenAccent.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.shade400,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 18,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (_transcriptionText?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Text(
                      _shortPreview(_transcriptionText!, 110),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canNavigateToActivities
                          ? _navigateToActivities
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.getPrimaryButtonColor(isDarkMode),
                        foregroundColor:
                            AppColors.getPrimaryButtonTextColor(isDarkMode),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToActivities() {
    if (!_canNavigateToActivities) return;

    setState(() {
      _showCompletionOverlay = false;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientMenuPage(
          initialDarkMode: isDarkMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool baseRecordEnabled = _hasMicPermission &&
        !_showCompletionOverlay &&
        (_isRecording || !_isUploading);
    final bool stopLocked = _isRecording && !_hasReachedMinimumDuration;
    final bool buttonEnabled = baseRecordEnabled && !stopLocked;
    final bool showMinDurationWarning = _isRecording && stopLocked;
    final VoidCallback? micButtonAction = baseRecordEnabled
        ? (_isRecording
            ? (stopLocked ? null : _stopRecording)
            : _startRecording)
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.getBackgroundGradient(isDarkMode),
            ),
          ),

          // Sistema de partícules decoratives
          ParticleSystemWidget(
            isDarkMode: isDarkMode,
            particleCount: 50,
            maxSize: 3.0,
            minSize: 1.0,
            speed: 0.5,
            maxOpacity: 0.6,
            minOpacity: 0.2,
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Cabecera con logo y switch de tema
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        isDarkMode ? TImages.lightLogo : TImages.darkLogo,
                        width: 40,
                        height: 40,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getBlurContainerColor(isDarkMode),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.containerShadow,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isDarkMode
                                ? Icons.wb_sunny
                                : Icons.nightlight_round,
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                          ),
                          onPressed: _toggleTheme,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cos amb pregunta, micròfon i controls
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pregunta del dia
                          FutureBuilder<Question>(
                            future: _dailyQuestionFuture,
                            builder: (context, snapshot) {
                              Widget child;
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                child = Text(
                                  'Carregant...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.getPrimaryTextColor(
                                        isDarkMode),
                                    fontSize: 18.0,
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                child = Text(
                                  "S'ha produït un error en carregar la pregunta.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.getPrimaryTextColor(
                                        isDarkMode),
                                    fontSize: 18.0,
                                  ),
                                );
                              } else {
                                final question = snapshot.data;
                                child = Text(
                                  question?.text ??
                                      'No hi ha cap pregunta avui. Explica una experiència teva!',
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: AppColors.getPrimaryTextColor(
                                        isDarkMode),
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.getSecondaryBackgroundColor(
                                            isDarkMode),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.getPrimaryButtonColor(
                                              isDarkMode)
                                          .withAlpha((0.4 * 255).round()),
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1A000000),
                                        blurRadius: 12,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 720),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 18.0),

                          if (!_hasMicPermission) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.getBlurContainerColor(isDarkMode),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      AppColors.getPrimaryTextColor(isDarkMode)
                                          .withOpacity(0.15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Permet el micròfon per començar.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.getPrimaryTextColor(
                                          isDarkMode),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _isCheckingPermission
                                        ? null
                                        : () => _requestMicPermission(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.getPrimaryButtonColor(
                                              isDarkMode),
                                      foregroundColor:
                                          AppColors.getPrimaryButtonTextColor(
                                              isDarkMode),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(Icons.lock_open_rounded),
                                    label: Text(
                                      _isCheckingPermission
                                          ? 'Sol·licitant...'
                                          : 'Permetre micròfon',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Botó de micròfon
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording
                                          ? const Color(0xFFEF476F)
                                          : AppColors.getPrimaryButtonColor(
                                              isDarkMode))
                                      .withAlpha(150),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: FloatingActionButton(
                                onPressed: micButtonAction,
                                shape: const CircleBorder(),
                                backgroundColor: _isRecording
                                    ? const Color(0xFFEF476F)
                                    : AppColors.getPrimaryButtonColor(
                                        isDarkMode),
                                foregroundColor: Colors.white,
                                elevation: buttonEnabled ? 10 : 4,
                                child: Icon(
                                  _isRecording ? Icons.stop : Icons.mic,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          Text(
                            _hasMicPermission
                                ? (_isRecording
                                    ? 'Gravant...'
                                    : 'Prem per començar')
                                : 'Autoritza el micròfon per gravar',
                            style: TextStyle(
                              color:
                                  AppColors.getSecondaryTextColor(isDarkMode),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20.0),

                          // Temporitzador
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.getSecondaryBackgroundColor(
                                  isDarkMode),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    AppColors.getPrimaryButtonColor(isDarkMode)
                                        .withAlpha((0.35 * 255).round()),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              _formatDuration(_recordDuration),
                              style: TextStyle(
                                color:
                                    AppColors.getPrimaryTextColor(isDarkMode),
                                fontSize: 18.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          if (showMinDurationWarning)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Necessites gravar almenys $_minRecordingSeconds segons abans de poder aturar la gravació.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFEF476F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          const SizedBox(height: 12.0),

                          // Indicador de càrrega i preview
                          if (_isUploading) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.getPrimaryButtonColor(
                                          isDarkMode),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pujant àudio...',
                                  style: TextStyle(
                                    color: AppColors.getPrimaryTextColor(
                                        isDarkMode),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_hasUploadError && !_isUploading)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28.0, vertical: 4),
                              child: Text(
                                "Hi ha hagut un problema enviant l'àudio. Pots tornar-ho a provar.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFEF476F),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (_transcriptionText != null && !_isUploading) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 320,
                              child: Text(
                                _transcriptionText!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      AppColors.getPrimaryTextColor(isDarkMode),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8.0),

                          // Barra de progrés
                          SizedBox(
                            width: 220.0,
                            child: LinearProgressIndicator(
                              value: (_recordDuration.inSeconds / 60)
                                  .clamp(0.0, 1.0),
                              backgroundColor:
                                  AppColors.getSecondaryBackgroundColor(
                                          isDarkMode)
                                      .withOpacity(0.35),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isRecording
                                    ? const Color(0xFFEF476F)
                                    : AppColors.getPrimaryButtonColor(
                                        isDarkMode),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: AppColors.getSecondaryTextColor(
                                      isDarkMode),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "Les activitats es desbloquegen després d'enviar la resposta d'avui.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.getSecondaryTextColor(
                                        isDarkMode),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildSuccessOverlay(),
        ],
      ),
    );
  }
}