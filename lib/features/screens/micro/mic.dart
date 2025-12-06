// lib/features/screens/micro/mic.dart

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
import '../activities/activities_page.dart';

class MicScreen extends StatefulWidget {
  const MicScreen({super.key});

  @override
  State<MicScreen> createState() => _MicScreenState();
}

class _MicScreenState extends State<MicScreen> {
  bool isDarkMode = false;

  /// Grabador nativo (móvil / desktop)
  final Record _recorder = Record();

  /// Grabador específico para Web (MediaRecorder + chunks .webm bien formados)
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

  // Máximo de segundos por fragment
  static const int _maxChunkSeconds = 15;

  // Pregunta diaria cargada desde la API
  late final Future<Question> _dailyQuestionFuture;

  @override
  void initState() {
    super.initState();
    _dailyQuestionFuture = _getDailyQuestion();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  // Muestra un mensaje de error
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<Question> _getDailyQuestion() async {
    return await ApiService.getDailyQuestion();
  }

  /// Inicia la grabación. Se genera un nuevo session_id y se configuran los
  /// temporizadores para enviar fragmentos de voz de 15s al backend.
  Future<void> _startRecording() async {
    if (_isRecording) return;

    // Reinicializa estado de la sesión
    _transcriptionText = null;
    _hasUploadError = false;
    _currentSessionId = const Uuid().v4();
    _nextChunkIndex = 0;
    _pendingChunkUploads.clear();

    // --- WEB: usamos WebAudioRecorder (MediaRecorder + chunks .webm válidos) ---
    if (kIsWeb) {
      _webRecorder ??= WebAudioRecorder(
        chunkMillis: _maxChunkSeconds * 1000,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });

      // Temporizador para actualizar la duración visible
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
      });

      try {
        await _webRecorder!.start((Uint8List bytes) async {
          // Cada chunk llega como bytes de un .webm válido
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
        _showError('No s’ha pogut accedir al micròfon.');
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
      _showError('No s’ha pogut accedir al micròfon.');
      return;
    }

    // Iniciar el primer fragment
    try {
      await _startNewMobileRecording();
    } catch (e) {
      _showError('No s’ha pogut iniciar la gravació.');
      return;
    }

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });

    // Temporizador de la UI
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordDuration += const Duration(seconds: 1);
      });
    });

    // Temporizador para enviar un fragmento cada _maxChunkSeconds
    _chunkTimer?.cancel();
    _chunkTimer = Timer.periodic(
      const Duration(seconds: _maxChunkSeconds),
      (_) {
        final Future<void> f = _sendCurrentMobileChunk(restart: true);
        _pendingChunkUploads.add(f);
        f.whenComplete(() => _pendingChunkUploads.remove(f));
      },
    );
  }

  /// Detiene la grabación, envía el último fragmento y completa la sesión.
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    // Cancelar temporizadores
    _timer?.cancel();
    _timer = null;
    _chunkTimer?.cancel();
    _chunkTimer = null;

    if (kIsWeb) {
      // Detener grabación en Web
      try {
        await _webRecorder?.stop();
      } catch (_) {}
    } else {
      // Detener la grabación móvil y enviar el último fragmento
      try {
        final Future<void> f = _sendCurrentMobileChunk(restart: false);
        _pendingChunkUploads.add(f);
        await f;
        _pendingChunkUploads.remove(f);
      } catch (_) {}
    }

    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
    });

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
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.webm';
    _currentChunkPath = filePath;

    await _recorder.start(
      path: filePath,
      encoder: AudioEncoder.opus, // contenedor/webm compatible con Whisper
      bitRate: 128000,
      samplingRate: 48000,
    );
  }

  /// Envía el fragmento actual grabado en móvil. Si [restart] es true, arranca
  /// una nueva grabación inmediatamente.
  Future<void> _sendCurrentMobileChunk({bool restart = true}) async {
    if (_currentSessionId == null) return;

    try {
      final String? path = await _recorder.stop();
      final String? filePath = path ?? _currentChunkPath;
      if (filePath == null) return;

      final file = File(filePath);
      final bytes = await file.readAsBytes();

      setState(() => _isUploading = true);

      final chunkRequest = TranscriptionChunkRequest(
        sessionId: _currentSessionId!,
        chunkIndex: _nextChunkIndex,
        audioBytes: bytes,
        filename: 'chunk_${_nextChunkIndex}.webm',
        contentType: 'audio/webm',
      );

      await ApiService.uploadTranscriptionChunk(chunkRequest);
      _nextChunkIndex += 1;

      await file.delete().catchError((_) {});
    } catch (e) {
      _hasUploadError = true;
      _showError('Error en enviar l’àudio. Torna-ho a provar.');
    } finally {
      setState(() => _isUploading = false);

      if (restart && _isRecording) {
        try {
          await _startNewMobileRecording();
        } catch (_) {}
      }
    }
  }

  /// Envía un fragmento grabado en Web ya como bytes de un .webm válido.
  Future<void> _sendWebChunk(Uint8List bytes) async {
    if (_currentSessionId == null) return;

    try {
      setState(() => _isUploading = true);

      final chunkRequest = TranscriptionChunkRequest(
        sessionId: _currentSessionId!,
        chunkIndex: _nextChunkIndex,
        audioBytes: bytes,
        filename: 'chunk_${_nextChunkIndex}.webm',
        contentType: 'audio/webm',
      );

      await ApiService.uploadTranscriptionChunk(chunkRequest);
      _nextChunkIndex += 1;
    } catch (e) {
      _hasUploadError = true;
      _showError('Error en enviar l’àudio. Torna-ho a provar.');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Completa la sesión actual y obtiene la transcripción.
  Future<void> _completeTranscription() async {
    final String? sessionId = _currentSessionId;
    if (sessionId == null) return;

    try {
      setState(() => _isUploading = true);

      final response = await ApiService.completeTranscriptionSession(
        TranscriptionCompleteRequest(sessionId: sessionId),
      );

      final extracted = response.transcription ?? response.partialText ?? '';
      setState(() {
        _transcriptionText = extracted;
      });

      if (extracted.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transcripció: ${_shortPreview(extracted)}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La transcripció s’ha completat.')),
        );
      }
    } catch (e) {
      _showError('No s’ha pogut completar la transcripció.');
    } finally {
      setState(() => _isUploading = false);
      _currentSessionId = null;
      _nextChunkIndex = 0;
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
    super.dispose();
  }

  /// Formatea la duración en mm:ss
  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.getBackgroundGradient(isDarkMode),
            ),
          ),

          // Sistema de partículas decorativas
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
                            isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                          ),
                          onPressed: _toggleTheme,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cuerpo con pregunta, micrófono y controles
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pregunta del día
                        FutureBuilder<Question>(
                          future: _dailyQuestionFuture,
                          builder: (context, snapshot) {
                            Widget child;
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              child = Text(
                                'Carregant…',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.getPrimaryTextColor(isDarkMode),
                                  fontSize: 18.0,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              child = Text(
                                'Error',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.getPrimaryTextColor(isDarkMode),
                                  fontSize: 18.0,
                                ),
                              );
                            } else {
                              final question = snapshot.data;
                              child = Text(
                                question?.text ??
                                    'No hi ha cap pregunta avui. Relata una experiència teva!',
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: TextStyle(
                                  color: AppColors.getPrimaryTextColor(isDarkMode),
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28.0),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 720),
                                child: child,
                              ),
                            );
                          },
                        ),

                        // Botón de micrófono
                        RawMaterialButton(
                          onPressed:
                              _isRecording ? _stopRecording : _startRecording,
                          fillColor: _isRecording ? Colors.red : Colors.white,
                          shape: const CircleBorder(),
                          elevation: 4.0,
                          constraints: const BoxConstraints.tightFor(
                            width: 96.0,
                            height: 96.0,
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 48.0,
                            color: _isRecording ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Temporizador
                        Text(
                          _formatDuration(_recordDuration),
                          style: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        // Indicador de carga y preview de transcripción
                        if (_isUploading) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2.0),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pujant…',
                                style: TextStyle(
                                  color: AppColors.getPrimaryTextColor(isDarkMode),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_transcriptionText != null && !_isUploading) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 280,
                            child: Text(
                              _transcriptionText!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.getPrimaryTextColor(isDarkMode),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8.0),

                        // Barra de progreso (ej: 60s máx)
                        SizedBox(
                          width: 200.0,
                          child: LinearProgressIndicator(
                            value:
                                (_recordDuration.inSeconds / 60).clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withAlpha(3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isRecording ? Colors.redAccent : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ActivitiesPage(
                                  initialDarkMode: isDarkMode,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.getPrimaryButtonColor(isDarkMode),
                            foregroundColor:
                                AppColors.getPrimaryButtonTextColor(isDarkMode),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.local_activity_outlined),
                          label: const Text('Activitats'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
