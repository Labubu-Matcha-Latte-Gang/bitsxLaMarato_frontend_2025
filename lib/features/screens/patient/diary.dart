import 'dart:async';
import 'dart:io' show File;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart'; // Asegúrate de que este import sigue ahí
import 'package:uuid/uuid.dart';

import '../../../models/question_models.dart';
import '../../../models/transcription_models.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/effects/particle_system.dart';
import '../micro/web_audio_recorder.dart';

class DiaryPage extends StatefulWidget {
  final bool initialDarkMode;

  const DiaryPage({
    super.key,
    this.initialDarkMode = false,
  });

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage>
    with SingleTickerProviderStateMixin {
  late bool isDarkMode;
  bool _isLoading = true;
  Question? _diaryQuestion;
  String? _errorMessage;

  // Se cambia 'Record' por 'AudioRecorder' para compatibilidad con v6
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  Timer? _chunkTimer;

  // Web recorder
  WebAudioRecorder? _webRecorder;

  String? _currentChunkPath;
  bool _isUploading = false;
  String? _transcriptionText;
  bool _hasUploadError = false;

  String? _currentSessionId;
  int _nextChunkIndex = 0;
  final List<Future<void>> _pendingChunkUploads = [];

  static const int _maxChunkSeconds = 5;
  static const int _minRecordingSeconds = 10;

  bool get _hasReachedMinimumDuration =>
      _recordDuration.inSeconds >= _minRecordingSeconds;

  int _consecutiveErrors = 0;

  bool _hasMicPermission = false;
  bool _isCheckingPermission = false;
  bool _showCompletionOverlay = false;
  bool _isProcessing = false; // Loading state during API call

  // Waveform animation
  late final AnimationController _waveController;
  final Random _waveRandom = Random();
  static const int _waveBarCount = 22;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadDiaryQuestion();
    _prefetchMobilePermission();
  }

  void _prefetchMobilePermission() async {
    try {
      final granted = await _recorder.hasPermission();
      if (mounted) {
        setState(() => _hasMicPermission = granted);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chunkTimer?.cancel();
    if (!kIsWeb) {
      try {
        _recorder.dispose();
      } catch (_) {}
    } else {
      try {
        _webRecorder?.dispose();
      } catch (_) {}
    }
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaryQuestion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final question = await ApiService.getDiaryQuestion();
      setState(() {
        _diaryQuestion = question;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error desconegut: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<bool> _ensureMicPermission() async {
    if (_hasMicPermission) return true;

    setState(() => _isCheckingPermission = true);

    bool granted = false;
    try {
      granted = await _recorder.hasPermission();
    } catch (e) {
      _showError('No s\'ha pogut demanar el micròfon. Revisa els permisos.');
    } finally {
      if (mounted) {
        setState(() {
          _hasMicPermission = granted;
          _isCheckingPermission = false;
        });
      }
    }

    if (!granted) {
      _showError('Cal autoritzar el micròfon per continuar.');
    }

    return granted;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    final permitted = await _ensureMicPermission();
    if (!permitted) return;

    setState(() {
      _showCompletionOverlay = false;
      _transcriptionText = null;
      _hasUploadError = false;
    });

    _currentSessionId = const Uuid().v4();
    _nextChunkIndex = 0;
    _pendingChunkUploads.clear();

    // --- WEB: use WebAudioRecorder ---
    if (kIsWeb) {
      _webRecorder ??= WebAudioRecorder(
        chunkMillis: (_maxChunkSeconds + 1) * 1000,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });
      _waveController.repeat();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _recordDuration += const Duration(seconds: 1);
          });
        }
      });

      try {
        await _webRecorder!.start((Uint8List bytes) async {
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

    // --- MOBILE: use Record plugin ---
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

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
      }
    });

    _chunkTimer?.cancel();
    _chunkTimer = Timer.periodic(
      const Duration(seconds: _maxChunkSeconds),
      (_) async {
        if (_currentSessionId == null || _isUploading) return;
        final Future<void> f = _sendCurrentMobileChunkSimple();
        _pendingChunkUploads.add(f);
        f.whenComplete(() => _pendingChunkUploads.remove(f));
      },
    );
  }

  // Uso de RecordConfig para la v6
  Future<void> _startNewMobileRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/diary_chunk_${DateTime.now().millisecondsSinceEpoch}.webm';
      _currentChunkPath = filePath;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 128000,
          sampleRate: 48000, // samplingRate ahora es sampleRate
        ),
        path: filePath,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _sendCurrentMobileChunkSimple() async {
    if (_currentSessionId == null || _isUploading) return;

    setState(() => _isUploading = true);

    try {
      final String? path = await _recorder.stop();
      final String? filePath = path ?? _currentChunkPath;

      if (filePath != null) {
        final file = File(filePath);

        if (await file.exists()) {
          final bytes = await file.readAsBytes();

          if (bytes.isNotEmpty && bytes.length > 1000) {
            final chunkRequest = TranscriptionChunkRequest(
              sessionId: _currentSessionId!,
              chunkIndex: _nextChunkIndex,
              audioBytes: bytes,
              filename: 'diary_chunk_$_nextChunkIndex.webm',
              contentType: 'audio/webm',
            );

            print(
                'DEBUG - Sending diary chunk: index=$_nextChunkIndex, size=${bytes.length}');
            await ApiService.uploadTranscriptionChunk(chunkRequest);
            _consecutiveErrors = 0;
            _nextChunkIndex += 1;

            try {
              await file.delete();
            } catch (e) {
              print('Error deleting file: $e');
            }
          } else {
            print('WARNING - Chunk too small: ${bytes.length} bytes');
          }
        } else {
          print('WARNING - File does not exist: $filePath');
        }
      }

      if (_isRecording && _currentSessionId != null) {
        await _startNewMobileRecording();
      }
    } catch (e) {
      _consecutiveErrors++;
      _hasUploadError = true;
      _showError("Error enviant l'àudio. Torna-ho a provar.");
      print('ERROR in _sendCurrentMobileChunkSimple ($_consecutiveErrors): $e');

      if (_consecutiveErrors >= 3) {
        print('CRITICAL - Too many consecutive errors, restarting session...');
        _currentSessionId = const Uuid().v4();
        _nextChunkIndex = 0;
        _consecutiveErrors = 0;
      }

      if (_isRecording && _currentSessionId != null) {
        try {
          await _startNewMobileRecording();
        } catch (restartError) {
          print('ERROR restarting recording: $restartError');
        }
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _sendWebChunk(Uint8List bytes) async {
    if (_currentSessionId == null) return;

    try {
      final chunkRequest = TranscriptionChunkRequest(
        sessionId: _currentSessionId!,
        chunkIndex: _nextChunkIndex,
        audioBytes: bytes,
        filename: 'diary_chunk_$_nextChunkIndex.wav',
        contentType: 'audio/wav',
      );

      print(
          'DEBUG - Sending web diary chunk: index=$_nextChunkIndex, size=${bytes.length}');
      await ApiService.uploadTranscriptionChunk(chunkRequest);
      _consecutiveErrors = 0;
      _nextChunkIndex += 1;
    } catch (e) {
      _consecutiveErrors++;
      _hasUploadError = true;
      _showError("Error enviant l'àudio. Torna-ho a provar.");
      print('ERROR in _sendWebChunk ($_consecutiveErrors): $e');

      if (_consecutiveErrors >= 3) {
        print('CRITICAL - Too many consecutive errors, restarting session...');
        _currentSessionId = const Uuid().v4();
        _nextChunkIndex = 0;
        _consecutiveErrors = 0;
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    if (!_hasReachedMinimumDuration) {
      _showError(
          'Necessites gravar almenys $_minRecordingSeconds segons abans de poder aturar-te.');
      return;
    }

    _timer?.cancel();
    _timer = null;
    _chunkTimer?.cancel();
    _chunkTimer = null;

    if (kIsWeb) {
      try {
        await _webRecorder?.stop();
      } catch (_) {}
    } else {
      try {
        final Future<void> f = _sendCurrentMobileChunk(restart: false);
        _pendingChunkUploads.add(f);
        await f;
        _pendingChunkUploads.remove(f);
      } catch (e) {
        print('ERROR stopping recording: $e');
      }
    }

    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
    });
    _waveController.stop();
    _waveController.reset();

    try {
      if (_pendingChunkUploads.isNotEmpty) {
        await Future.wait(List<Future<void>>.from(_pendingChunkUploads));
      }
    } catch (_) {}

    await _completeDiaryTranscription();
  }

  Future<void> _sendCurrentMobileChunk({bool restart = true}) async {
    if (_currentSessionId == null) return;

    try {
      final String? path = await _recorder.stop();
      final String? filePath = path ?? _currentChunkPath;

      if (filePath != null) {
        final file = File(filePath);

        if (await file.exists()) {
          final bytes = await file.readAsBytes();

          if (bytes.isNotEmpty && bytes.length > 1000) {
            if (restart) {
              await _startNewMobileRecording();
            }

            final chunkRequest = TranscriptionChunkRequest(
              sessionId: _currentSessionId!,
              chunkIndex: _nextChunkIndex,
              audioBytes: bytes,
              filename: 'diary_chunk_$_nextChunkIndex.webm',
              contentType: 'audio/webm',
            );

            print('DEBUG - Sending final diary chunk: index=$_nextChunkIndex');
            await ApiService.uploadTranscriptionChunk(chunkRequest);
            _nextChunkIndex += 1;
          }

          try {
            await file.delete();
          } catch (e) {
            print('Error deleting file: $e');
          }
        }
      }
    } catch (e) {
      _hasUploadError = true;
      _showError("Error enviant l'àudio. Torna-ho a provar.");
      print('ERROR in _sendCurrentMobileChunk: $e');

      if (restart && _isRecording) {
        try {
          await _startNewMobileRecording();
        } catch (restartError) {
          print('ERROR restarting recording: $restartError');
        }
      }
    }
  }

  Future<void> _completeDiaryTranscription() async {
    if (_currentSessionId == null || _diaryQuestion == null) return;

    // Show overlay with loading state immediately
    setState(() {
      _isProcessing = true;
      _showCompletionOverlay = true;
      _isUploading = true;
    });

    try {
      // Wait for all pending chunk uploads to complete
      if (_pendingChunkUploads.isNotEmpty) {
        print(
            'DEBUG - Waiting for ${_pendingChunkUploads.length} pending chunks...');
        await Future.wait(_pendingChunkUploads);
        print('DEBUG - All pending chunks uploaded');
      }

      final request = TranscriptionCompleteRequest(
        sessionId: _currentSessionId!,
        questionId: _diaryQuestion!.id,
      );

      final response = await ApiService.completeTranscriptionSession(request);

      setState(() {
        _transcriptionText = response.transcription;
        _isProcessing = false; // Stop loading
        _isUploading = false;
      });

      print('DEBUG - Diary transcription complete: ${response.transcription}');
    } catch (e) {
      _hasUploadError = true;
      _showError('Error completant la transcripció. Torna-ho a provar.');
      print('ERROR completing diary transcription: $e');

      setState(() {
        _isProcessing = false; // Stop loading on error
        _isUploading = false;
      });
    }
  }

  Widget _buildWaveform() {
    return SizedBox(
      height:
          168, // Altura fija: 24 (padding top) + 120 (max height) + 24 (padding bottom)
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_waveBarCount, (index) {
                final height = 20 +
                    50 *
                        (sin((_waveController.value * 2 * pi) +
                                (index / _waveBarCount) * 2 * pi) +
                            1) /
                        2 +
                    ((_waveRandom.nextDouble() - 0.5) * 10);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Container(
                    width: 4,
                    height: height.clamp(10, 120),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimaryButtonColor(isDarkMode),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getPrimaryButtonColor(isDarkMode)
                              .withAlpha(100),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPreRecordingUI() {
    if (_diaryQuestion == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.getPrimaryButtonColor(isDarkMode),
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.getSecondaryBackgroundColor(isDarkMode),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withAlpha((0.4 * 255).round()),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(50),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            _diaryQuestion!.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 56),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(150),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: SizedBox(
            width: 96,
            height: 96,
            child: FloatingActionButton(
              onPressed: _hasMicPermission ? _startRecording : null,
              shape: const CircleBorder(),
              backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
              foregroundColor: AppColors.getPrimaryButtonTextColor(isDarkMode),
              elevation: 10,
              child: const Icon(Icons.mic, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Pressiona el botó per gravar',
          style: TextStyle(
            color: AppColors.getSecondaryTextColor(isDarkMode),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1) Enunciat a sobre
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSecondaryBackgroundColor(isDarkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withAlpha((0.2 * 255).round()),
              width: 1,
            ),
          ),
          child: Text(
            _diaryQuestion?.text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // 2) Temporitzador al mig
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.getSecondaryBackgroundColor(isDarkMode),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withAlpha((0.3 * 255).round()),
              width: 1.5,
            ),
          ),
          child: Text(
            _formatDuration(_recordDuration),
            style: TextStyle(
              color: AppColors.getPrimaryButtonColor(isDarkMode),
              fontSize: 56,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // 3) Botó de stop
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFFEF476F).withAlpha(180),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: SizedBox(
            width: 96,
            height: 96,
            child: FloatingActionButton(
              onPressed: _hasReachedMinimumDuration ? _stopRecording : null,
              shape: const CircleBorder(),
              backgroundColor: const Color(0xFFEF476F),
              foregroundColor: Colors.white,
              elevation: 10,
              child: const Icon(Icons.stop, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!_hasReachedMinimumDuration)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Necessites gravar almenys $_minRecordingSeconds segons',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFEF476F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 24),
        // 4) Animació d'ones a sota
        _buildWaveform(),
      ],
    );
  }

  Widget _buildCompletionOverlay() {
    // Show loading state while processing
    if (_isProcessing) {
      return Dialog(
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.getPrimaryButtonColor(isDarkMode),
                ),
                strokeWidth: 3,
              ),
              const SizedBox(height: 40),
              Text(
                'Processant resposta...',
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Si us plau espera',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show completion result
    return Dialog(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasUploadError
                    ? Color(0xFFEF476F).withAlpha(30)
                    : Color(0xFF06A77D).withAlpha(30),
              ),
              child: Icon(
                _hasUploadError ? Icons.error_outline : Icons.check_circle,
                size: 64,
                color: _hasUploadError ? Color(0xFFEF476F) : Color(0xFF06A77D),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _hasUploadError ? 'Error en la gravació' : 'Gravació completada!',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                  foregroundColor:
                      AppColors.getPrimaryButtonTextColor(isDarkMode),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Tancar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.getBackgroundGradient(isDarkMode),
            ),
          ),
          ParticleSystemWidget(
            isDarkMode: isDarkMode,
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.getSecondaryBackgroundColor(isDarkMode),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.getPrimaryButtonColor(isDarkMode)
                            .withAlpha((0.2 * 255).round()),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                        ),
                        onPressed: () => Navigator.of(context).pop(isDarkMode),
                      ),
                      Text(
                        'Diari Personal',
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                        ),
                        onPressed: () {
                          setState(() => isDarkMode = !isDarkMode);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.getPrimaryButtonColor(isDarkMode),
                            ),
                          ),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Color(0xFFEF476F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : _isRecording
                              ? _buildRecordingUI()
                              : _buildPreRecordingUI(),
                ),
              ],
            ),
          ),
          if (_showCompletionOverlay) _buildCompletionOverlay(),
        ],
      ),
    );
  }
}