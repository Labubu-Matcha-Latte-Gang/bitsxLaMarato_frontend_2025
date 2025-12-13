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

  static const int _maxChunkSeconds = 5;
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
    } catch (_) {
      // Ignorar errors silenciosament
    }
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

  void _submitAnswer() {
    // Placeholder per la funcionalitat d'enviar la resposta
    final answer = _answerController.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Si us plau, escriu una resposta abans de continuar.'),
          backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
        ),
      );
      return;
    }

    // TODO: Implementar la crida a l'API per enviar la resposta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resposta guardada: $answer'),
        backgroundColor: Colors.green,
      ),
    );
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
    // Verificar permiso
    final hasPermission = await _requestMicPermission();
    if (!hasPermission) {
      _showError('Necessites permís per accedir al micròfon.');
      return;
    }

    // Crear sessió de transcripció
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
      _showAudioResponse = false;
    });

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
      _showError(
        'Necessites gravar almenys $_minRecordingSeconds segons abans de poder aturar-te.',
      );
      return;
    }

    _timer?.cancel();
    _timer = null;

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

    // Wait for pending uploads
    try {
      if (_pendingChunkUploads.isNotEmpty) {
        await Future.wait(List<Future<void>>.from(_pendingChunkUploads));
      }
    } catch (_) {}

    // Complete transcription
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
        _showAudioResponse = true;
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
            particleCount: 50,
            maxSize: 3.0,
            minSize: 1.0,
            speed: 0.5,
            maxOpacity: 0.6,
            minOpacity: 0.2,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
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
                          tooltip: 'Tornar',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Diari Personal',
                          style: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _isLoading
                            ? _buildLoadingState()
                            : _errorMessage != null
                                ? _buildErrorState()
                                : _buildQuestionContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
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
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
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
      ),
    );
  }

  Widget _buildQuestionContent() {
    if (_diaryQuestion == null) {
      return const SizedBox.shrink();
    }

    // Si hi ha transcripció, mostrar resposta d'àudio
    if (_showAudioResponse && _transcriptionText != null) {
      return _buildAudioResponseDisplay();
    }

    // Si estem gravant, mostrar la interfície de gravació
    if (_isRecording) {
      return _buildRecordingInterface();
    }

    // Interfície normal de resposta
    return _buildNormalResponseInterface();
  }

  Widget _buildNormalResponseInterface() {
    return SingleChildScrollView(
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimaryButtonColor(isDarkMode)
                        .withAlpha((0.12 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.question_answer,
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'El meu Diari',
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question text
            Container(
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
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tabs: Text response or Audio response
            Container(
              decoration: BoxDecoration(
                color: AppColors.getBackgroundColor(isDarkMode)
                    .withAlpha((0.3 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _showAudioResponse = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showAudioResponse
                              ? AppColors.getPrimaryButtonColor(isDarkMode)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Text',
                            style: TextStyle(
                              color: !_showAudioResponse
                                  ? Colors.white
                                  : AppColors.getSecondaryTextColor(isDarkMode),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _showAudioResponse = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showAudioResponse
                              ? AppColors.getPrimaryButtonColor(isDarkMode)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Àudio',
                            style: TextStyle(
                              color: _showAudioResponse
                                  ? Colors.white
                                  : AppColors.getSecondaryTextColor(isDarkMode),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Text response section
            Text(
              'La teva resposta',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              maxLines: 5,
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Escriu la teva resposta aquí...',
                hintStyle: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                ),
                filled: true,
                fillColor: AppColors.getBackgroundColor(isDarkMode)
                    .withAlpha((0.5 * 255).round()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getPrimaryButtonColor(isDarkMode)
                        .withAlpha((0.2 * 255).round()),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getPrimaryButtonColor(isDarkMode)
                        .withAlpha((0.2 * 255).round()),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _submitAnswer,
              icon: const Icon(Icons.send),
              label: const Text(
                'Enviar Resposta (Text)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Audio response button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(180),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _startRecording,
              icon: const Icon(Icons.mic),
              label: const Text(
                'Gravar Resposta (Àudio)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Audio option hint
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getPrimaryButtonColor(isDarkMode)
                    .withAlpha((0.08 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pots gravar una resposta d\'àudio en lloc de text.',
                      style: TextStyle(
                        color: AppColors.getSecondaryTextColor(isDarkMode),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingInterface() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recording indicator
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gravant...',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Timer
          Center(
            child: Text(
              _formatDuration(_recordDuration),
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Durada',
              style: TextStyle(
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Question text (mini)
          Container(
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
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Stop button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: _isUploading ? null : _stopRecording,
            icon: const Icon(Icons.stop),
            label: Text(
              _isUploading ? 'Enviant...' : 'Aturar Gravació',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Minimum duration warning
          if (!_hasReachedMinimumDuration)
            Padding(
              padding: const EdgeInsets.only(top: 16),
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
      ),
    );
  }

  Widget _buildAudioResponseDisplay() {
    return SingleChildScrollView(
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success indicator
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_hasUploadError ? Colors.orange : Colors.green)
                      .withAlpha((0.15 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _hasUploadError ? Icons.warning_amber : Icons.check_circle,
                  color: _hasUploadError ? Colors.orange : Colors.green,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                _hasUploadError
                    ? 'Resposta gravada (amb avís)'
                    : 'Resposta gravada amb èxit',
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transcription text
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transcripció:',
                    style: TextStyle(
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _transcriptionText ?? 'Sin transcripción',
                    style: TextStyle(
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Back button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () {
                setState(() => _showAudioResponse = false);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'Tornar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
