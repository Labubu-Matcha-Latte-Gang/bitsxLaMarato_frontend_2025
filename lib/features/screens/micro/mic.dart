// lib/features/screens/micro/mic.dart

import 'dart:async';
import 'dart:io' show File;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:universal_html/universal_html.dart' as html;
import 'package:uuid/uuid.dart';

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
  final Record _recorder = Record();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  Timer? _chunkTimer;

  // Ruta temporal del fragment actual en dispositius mòbils
  String? _currentChunkPath;

  // Components per a la gravació al web
  html.MediaRecorder? _webRecorder;
  html.MediaStream? _webStream;

  // Estat de càrrega i transcripció
  bool _isUploading = false;
  String? _transcriptionText;
  bool _hasUploadError = false;

  // Sessió i índex de fragment
  String? _currentSessionId;
  int _nextChunkIndex = 0;

  // Llista de càrregues pendents per esperar-les abans de finalitzar
  final List<Future<void>> _pendingChunkUploads = [];

  // Màxim de segons per fragment
  static const int _maxChunkSeconds = 15;

  // Pregunta diària carregada des de l'API
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

  // Mostra un missatge d'error de forma uniforme
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<Question> _getDailyQuestion() async {
    return await ApiService.getDailyQuestion();
  }

  /// Inicia la gravació. Es genera un nou session_id i es configuren els
  /// temporitzadors per enviar fragments de veu de 15 segons al backend.
  Future<void> _startRecording() async {
    if (_isRecording) return;
    // Reinicialitza estat de la sessió
    _transcriptionText = null;
    _hasUploadError = false;
    _currentSessionId = const Uuid().v4();
    _nextChunkIndex = 0;
    _pendingChunkUploads.clear();

    if (kIsWeb) {
      // Gravació al navegador utilitzant MediaRecorder
      final md = html.window.navigator.mediaDevices;
      if (md == null) {
        _showError('No s’ha pogut accedir al micròfon.');
        return;
      }
      try {
        _webStream = await md.getUserMedia({'audio': true});
      } catch (e) {
        _showError('No s’ha pogut accedir al micròfon.');
        return;
      }

      // Configuració del MediaRecorder amb timeslice per generar fragments
      // Fem servir audio/mpeg (MP3) si el navegador ho suporta; en cas contrari,
      // MediaRecorder utilitzarà el format per defecte, però enviarem el
      // contentType com a MP3 al backend.
      _webRecorder = html.MediaRecorder(
        _webStream!,
        {
          'mimeType': 'audio/webm;codecs=opus',
        },
      );

      // Quan arriba un fragment, s'envia al backend
      _webRecorder!.addEventListener('dataavailable', (event) {
        try {
          final dynamic data = (event as dynamic).data;
          if (data != null && data is html.Blob) {
            final Future<void> f = _sendWebChunk(data);
            _pendingChunkUploads.add(f);
            f.whenComplete(() => _pendingChunkUploads.remove(f));
          }
        } catch (_) {
          // ignore unexpected event shape
        }
      });

      // No cal processar res especial a l'esdeveniment stop;
      _webRecorder!.addEventListener('stop', (event) {});

      // Iniciar la gravació amb fragments de 15 segons (en ms)
      try {
        _webRecorder!.start(_maxChunkSeconds * 1000);
      } catch (e) {
        _showError('No s’ha pogut iniciar la gravació.');
        return;
      }

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });

      // Temporitzador per actualitzar la durada visible
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
      });

      return;
    }

    // Gravació en dispositius mòbils/escriptori
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

    // Temporitzador de la UI
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordDuration += const Duration(seconds: 1);
      });
    });

    // Temporitzador que envia un fragment cada _maxChunkSeconds segons
    _chunkTimer?.cancel();
    _chunkTimer = Timer.periodic(
      const Duration(seconds: _maxChunkSeconds),
      (_) {
        // Enviar el fragment actual i reiniciar-ne un de nou
        final Future<void> f = _sendCurrentMobileChunk(restart: true);
        _pendingChunkUploads.add(f);
        f.whenComplete(() => _pendingChunkUploads.remove(f));
      },
    );
  }

  /// Atura la gravació. Es cancel·len els temporitzadors, s'envia el
  /// darrer fragment pendent i, finalment, es notifica al servidor que
  /// la sessió ha finalitzat.
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    // Cancel·lar els temporitzadors de durada i fragments
    _timer?.cancel();
    _timer = null;
    _chunkTimer?.cancel();
    _chunkTimer = null;

    if (kIsWeb) {
      // Aturar el MediaRecorder (generarà l'últim dataavailable)
      try {
        _webRecorder?.stop();
      } catch (_) {}
      // Esperar una mica per permetre que arribin els darrers esdeveniments
      await Future.delayed(const Duration(milliseconds: 100));
      // Alliberar recursos del microfon
      try {
        _webStream?.getTracks().forEach((t) => t.stop());
      } catch (_) {}
      _webStream = null;
      _webRecorder = null;
    } else {
      // Aturar la gravació en dispositius mòbils i enviar el darrer fragment
      try {
        // Enviar l'últim fragment sense reiniciar la gravació
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

    // Esperar que es completin totes les càrregues pendents
    try {
      if (_pendingChunkUploads.isNotEmpty) {
        await Future.wait(List<Future<void>>.from(_pendingChunkUploads));
      }
    } catch (_) {}

    // Finalitzar la sessió de transcripció
    await _completeTranscription();
  }

  /// Inicia una nova gravació en un dispositiu mòbil, creant un fitxer
  /// temporal per emmagatzemar el fragment actual. L'àudio es codifica
  /// com a MP3 perquè els fragments s'enviïn en aquest format.
  Future<void> _startNewMobileRecording() async {
    final dir = await getTemporaryDirectory();
    // Guardem els fragments amb extensió .mp3 per indicar l'ús de mp3
    final filePath = '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.mp3';
    _currentChunkPath = filePath;
    await _recorder.start(
      path: filePath,
      // Fem servir l'encoder MP3 si està suportat pel plugin. En cas contrari,
      // el plugin utilitzarà un format per defecte, però l'arxiu i el
      // contentType s'indicaran com a MP3 en enviar el fragment.
      encoder: AudioEncoder.mp3,
    );
  }

  /// Envia el fragment actual enregistrat en dispositius mòbils. Si
  /// [restart] és cert, després de l'enviament es torna a iniciar una nova
  /// gravació. S'actualitzen els indicadors de càrrega i es gestionen
  /// possibles errors.
  Future<void> _sendCurrentMobileChunk({bool restart = true}) async {
    if (_currentSessionId == null) return;
    try {
      // Finalitzar la gravació i obtenir el fitxer
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
        filename: 'fragment.webm',
        contentType: 'audio/webm',
      );

      await ApiService.uploadTranscriptionChunk(chunkRequest);
      _nextChunkIndex += 1;

      // Esborra el fitxer temporal
      await file.delete().catchError((_) {});
    } catch (e) {
      _hasUploadError = true;
      _showError('Error en enviar l’àudio. Torna-ho a provar.');
    } finally {
      setState(() => _isUploading = false);
      // Iniciar la següent gravació si cal
      if (restart && _isRecording) {
        try {
          await _startNewMobileRecording();
        } catch (_) {}
      }
    }
  }

  /// Llegeix un [html.Blob] com a [Uint8List]. S'utilitza per a la
  /// gravació al web.
  Future<Uint8List> _readBlobAsUint8List(html.Blob blob) async {
    final reader = html.FileReader();
    final completer = Completer<Uint8List>();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(Uint8List.view(result));
      } else if (result is List<int>) {
        completer.complete(Uint8List.fromList(result));
      } else {
        completer.completeError('No s’ha pogut llegir el blob');
      }
    });
    reader.onError.listen((event) {
      completer.completeError(event);
    });

    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  /// Envia un fragment enregistrat al web com a [html.Blob].
  Future<void> _sendWebChunk(html.Blob blob) async {
    if (_currentSessionId == null) return;
    try {
      final Uint8List bytes = await _readBlobAsUint8List(blob);
      setState(() => _isUploading = true);
      final chunkRequest = TranscriptionChunkRequest(
        sessionId: _currentSessionId!,
        chunkIndex: _nextChunkIndex,
        audioBytes: bytes,
        filename: 'fragment.webm',
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

  /// Completa la sessió actual enviant una petició al backend perquè combini
  /// tots els fragments i retorni la transcripció. Actualitza l’estat de
  /// transcripció i mostra un missatge adequat.
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
      // Reinicialitzar la sessió per a una nova gravació
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
    try {
      _webStream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    super.dispose();
  }

  /// Formata la durada en minuts i segons.
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
          // Fons amb gradient
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

          // Contingut principal
          SafeArea(
            child: Column(
              children: [
                // Capçalera amb logotip i commutador de tema
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logotip
                      Image.asset(
                        isDarkMode ? TImages.lightLogo : TImages.darkLogo,
                        width: 40,
                        height: 40,
                      ),

                      // Botó per canviar el tema
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
                // Cos amb pregunta, micròfon i controls
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pregunta del dia
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
                              padding: const EdgeInsets.symmetric(horizontal: 28.0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 720),
                                child: child,
                              ),
                            );
                          },
                        ),
                        // Botó de micròfon
                        RawMaterialButton(
                          onPressed: _isRecording ? _stopRecording : _startRecording,
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
                        // Temporitzador que mostra el temps de gravació
                        Text(
                          _formatDuration(_recordDuration),
                          style: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // Indicador de càrrega i vista prèvia de la transcripció
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
                        // Barra de progrés amb duració màxima de 60 segons (per exemple)
                        SizedBox(
                          width: 200.0,
                          child: LinearProgressIndicator(
                            value: (_recordDuration.inSeconds / 60).clamp(0.0, 1.0),
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
                            backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                            foregroundColor: AppColors.getPrimaryButtonTextColor(isDarkMode),
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