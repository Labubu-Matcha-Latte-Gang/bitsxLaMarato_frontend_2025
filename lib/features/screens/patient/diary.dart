import 'dart:async';
import 'dart:io' show File;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../models/question_models.dart';
import '../../../models/transcription_models.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/effects/particle_system.dart';

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

  // Audio recording variables
  final Record _recorder = Record();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  String? _currentSessionId;
  int _nextChunkIndex = 0;
  String? _currentChunkPath;
  bool _isUploading = false;
  String? _transcriptionText;
  bool _hasUploadError = false;
  bool _showCompletionOverlay = false;
  bool _hasMicPermission = false;

  static const int _minRecordingSeconds = 10;

  bool get _hasReachedMinimumDuration =>
      _recordDuration.inSeconds >= _minRecordingSeconds;

  final List<Future<void>> _pendingChunkUploads = [];

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

  Future<bool> _requestMicPermission() async {
    try {
      final granted = await _recorder.hasPermission();
      if (mounted) {
        setState(() => _hasMicPermission = granted);
      }
      return granted;
    } catch (e) {
      _showError('No s\'ha pogut accedir al micròfon.');
      return false;
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _requestMicPermission();
    if (!hasPermission) {
      _showError('Necessites permís per accedir al micròfon.');
      return;
    }

    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _nextChunkIndex = 0;

    try {
      await _startNewMobileRecording();
    } catch (e) {
      _showError("No s'ha pogut iniciar la gravació.");
      return;
    }

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
      _transcriptionText = null;
      _hasUploadError = false;
      _showCompletionOverlay = false;
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

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    if (!_hasReachedMinimumDuration) {
      _showError('Necessites gravar almenys $_minRecordingSeconds segons.');
      return;
    }

    _timer?.cancel();
    _timer = null;
    _waveController.stop();
    _waveController.reset();

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

    try {
      if (_pendingChunkUploads.isNotEmpty) {
        await Future.wait(List<Future<void>>.from(_pendingChunkUploads));
      }
    } catch (_) {}

    await _completeDiaryTranscription();
  }

  Future<void> _sendCurrentMobileChunk({bool restart = true}) async {
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
            await _sendChunkDirect(bytes, 'webm', 'audio/webm');
          }
        }
      }

      if (restart && _isRecording) {
        await _startNewMobileRecording();
      }
    } catch (e) {
      print('ERROR sending chunk: $e');
      _hasUploadError = true;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _sendChunkDirect(
      List<int> bytes, String format, String contentType) async {
    setState(() => _isUploading = true);

    try {
      final chunkRequest = TranscriptionChunkRequest(
        sessionId: _currentSessionId!,
        chunkIndex: _nextChunkIndex,
        audioBytes: bytes,
        filename: 'diary_chunk_${_nextChunkIndex}.$format',
        contentType: contentType,
      );

      await ApiService.uploadTranscriptionChunk(chunkRequest);
      _nextChunkIndex += 1;
      print(
          'DEBUG - Diary chunk sent successfully (index ${_nextChunkIndex - 1})');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _completeDiaryTranscription() async {
    final String? sessionId = _currentSessionId;
    final questionId = _diaryQuestion?.id;

    if (sessionId == null || questionId == null || questionId.isEmpty) {
      _showError('Error: No es pot completar la transcripció.');
      return;
    }

    bool success = false;
    String? extracted;

    try {
      setState(() => _isUploading = true);

      final response = await ApiService.completeTranscriptionSession(
        TranscriptionCompleteRequest(
          sessionId: sessionId,
          questionId: questionId,
        ),
      );

      extracted = response.transcription ?? response.partialText ?? '';
      setState(() {
        _transcriptionText = extracted;
        _showCompletionOverlay = true;
      });
      success = true;
    } catch (e) {
      _hasUploadError = true;
      _showError('No s\'ha pogut completar la transcripció.');
    } finally {
      setState(() {
        _isUploading = false;
        _currentSessionId = null;
        _nextChunkIndex = 0;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _shortPreview(String text, [int max = 120]) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }

  Widget _buildWaveform() {
    final baseColor =
        _isRecording ? Colors.redAccent : Colors.white.withOpacity(0.3);
    final barColor = _isRecording
        ? Colors.white
        : AppColors.getPrimaryTextColor(isDarkMode).withOpacity(0.4);

    return SizedBox(
      height: 96,
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
            final barHeight = 22 + heightFactor * 58;

            return Container(
              width: 5,
              height: barHeight,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(0.35),
                    blurRadius: 8,
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

  @override
  Widget build(BuildContext context) {
    final bool baseRecordEnabled = _hasMicPermission && !_showCompletionOverlay;
    final bool stopLocked = _isRecording && !_hasReachedMinimumDuration;
    final bool buttonEnabled = baseRecordEnabled && !stopLocked;
    final VoidCallback? micButtonAction = baseRecordEnabled
        ? (_isRecording
            ? (stopLocked ? null : _stopRecording)
            : _startRecording)
        : null;

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
            particleCount: 50,
            maxSize: 3.0,
            minSize: 1.0,
            speed: 0.5,
            maxOpacity: 0.6,
            minOpacity: 0.2,
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
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
                            Icons.arrow_back,
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Diari Personal',
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(width: 56),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Center(
                    child: _isLoading
                        ? _buildLoadingState()
                        : _errorMessage != null
                            ? _buildErrorState()
                            : _buildMainContent(),
                  ),
                ),
              ],
            ),
          ),
          if (_showCompletionOverlay) _buildCompletionOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          color: AppColors.getPrimaryButtonColor(isDarkMode),
        ),
        const SizedBox(height: 16),
        Text(
          'Carregant pregunta del diari...',
          style: TextStyle(
            color: AppColors.getSecondaryTextColor(isDarkMode),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.containerShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _loadDiaryQuestion,
            icon: const Icon(Icons.refresh),
            label: const Text('Tornar a intentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_diaryQuestion == null) {
      return const SizedBox.shrink();
    }

    if (_isRecording) {
      return _buildRecordingUI();
    }

    return _buildPreRecordingUI();
  }

  Widget _buildPreRecordingUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getSecondaryBackgroundColor(isDarkMode),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.containerShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.getPrimaryButtonColor(isDarkMode)
                            .withAlpha((0.12 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.question_answer,
                        color: AppColors.getPrimaryButtonColor(isDarkMode),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pregunta del Diari',
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _diaryQuestion!.text,
                  style: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Start recording button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.getPrimaryButtonColor(isDarkMode)
                      .withAlpha(100),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _hasMicPermission ? _startRecording : null,
              backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
              foregroundColor: Colors.white,
              radius: 50,
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
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Waveform
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildWaveform(),
        ),
        const SizedBox(height: 40),

        // Timer
        Text(
          _formatDuration(_recordDuration),
          style: TextStyle(
            color: AppColors.getPrimaryTextColor(isDarkMode),
            fontSize: 60,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Question preview
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
            _diaryQuestion!.text,
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

        // Stop button
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
            radius: 50,
            child: const Icon(Icons.stop, size: 32),
          ),
        ),
        const SizedBox(height: 16),

        // Minimum duration warning
        if (!_hasReachedMinimumDuration)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Necessites gravar almenys $_minRecordingSeconds segons',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompletionOverlay() {
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (_hasUploadError ? Colors.orange : Colors.green)
                            .withAlpha((0.15 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasUploadError
                            ? Icons.warning_amber
                            : Icons.check_circle,
                        color: _hasUploadError ? Colors.orange : Colors.green,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      _hasUploadError
                          ? 'Resposta gravada (amb avís)'
                          : 'Resposta gravada amb èxit',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Transcription if available
                    if (_transcriptionText?.isNotEmpty == true) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getBackgroundColor(isDarkMode)
                              .withAlpha((0.5 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.getPrimaryButtonColor(isDarkMode)
                                .withAlpha((0.2 * 255).round()),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _shortPreview(_transcriptionText!, 150),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Back button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _showCompletionOverlay = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.getPrimaryButtonColor(isDarkMode),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tancar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
