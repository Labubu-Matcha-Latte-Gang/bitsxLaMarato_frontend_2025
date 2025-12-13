import 'dart:async';
import 'dart:io' show File;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
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

  // Audio recording variables (matching mic.dart exactly)
  final Record _recorder = Record();
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
    _recorder.dispose();
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
      print('ERROR - Failed to start diary recording: $e');
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

  Future<void> _startNewMobileRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/diary_chunk_${DateTime.now().millisecondsSinceEpoch}.webm';
      _currentChunkPath = filePath;

      await _recorder.start(
        path: filePath,
        encoder: AudioEncoder.opus,
        bitRate: 128000,
        samplingRate: 48000,
      );

      print('DEBUG - Diary recording started: $filePath');
    } catch (e) {
      print('ERROR - Failed to start diary recording: $e');
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

    try {
      final Future<void> f = _sendCurrentMobileChunk(restart: false);
      _pendingChunkUploads.add(f);
      await f;
      _pendingChunkUploads.remove(f);
    } catch (e) {
      print('ERROR stopping recording: $e');
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

    try {
      setState(() => _isUploading = true);

      final request = TranscriptionCompleteRequest(
        sessionId: _currentSessionId!,
        questionId: _diaryQuestion!.id,
      );

      final response = await ApiService.completeTranscriptionSession(request);

      setState(() {
        _transcriptionText = response.transcription;
        _showCompletionOverlay = true;
        _isUploading = false;
      });

      print('DEBUG - Diary transcription complete: ${response.transcription}');
    } catch (e) {
      _hasUploadError = true;
      _showError('Error completant la transcripció. Torna-ho a provar.');
      print('ERROR completing diary transcription: $e');

      setState(() {
        _showCompletionOverlay = true;
        _isUploading = false;
      });
    }
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
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
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPreRecordingUI() {
    if (_diaryQuestion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getBackgroundColor(isDarkMode)
                .withAlpha((0.5 * 255).round()),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withAlpha((0.3 * 255).round()),
              width: 2,
            ),
          ),
          child: Text(
            _diaryQuestion!.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 48),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(100),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _hasMicPermission ? _startRecording : null,
            backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
            foregroundColor: Colors.white,
            child: const Icon(Icons.mic, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Pressiona el botó per gravar',
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildWaveform(),
        ),
        const SizedBox(height: 40),
        Text(
          _formatDuration(_recordDuration),
          style: TextStyle(
            color: AppColors.getPrimaryTextColor(isDarkMode),
            fontSize: 60,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getBackgroundColor(isDarkMode)
                .withAlpha((0.5 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withAlpha((0.2 * 255).round()),
              width: 1.5,
            ),
          ),
          child: Text(
            _diaryQuestion?.text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withAlpha(100),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _hasReachedMinimumDuration ? _stopRecording : null,
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            child: const Icon(Icons.stop, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        if (!_hasReachedMinimumDuration)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Necessites gravar almenys $_minRecordingSeconds segons',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.amber[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompletionOverlay() {
    return Dialog(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasUploadError ? Icons.error : Icons.check_circle,
              size: 64,
              color: _hasUploadError ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              _hasUploadError ? 'Error en la gravació' : 'Gravació completada!',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_transcriptionText != null && _transcriptionText!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getBackgroundColor(isDarkMode)
                      .withAlpha((0.7 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _transcriptionText!.length > 150
                      ? '${_transcriptionText!.substring(0, 150)}...'
                      : _transcriptionText!,
                  style: TextStyle(
                    color: AppColors.getSecondaryTextColor(isDarkMode),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tancar'),
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
          ParticleSystemWidget(
            isDarkMode: isDarkMode,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Diari Personal',
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                            isDarkMode ? Icons.light_mode : Icons.dark_mode),
                        onPressed: () {
                          setState(() => isDarkMode = !isDarkMode);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
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
