// lib/features/screens/micro/mic.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../models/question_models.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../activities/activities_page.dart';
import 'package:universal_html/universal_html.dart' as html;
import '../../../services/api_service.dart';
import 'dart:typed_data';
import 'dart:io' show File;
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../../models/transcription_models.dart';

/// Recording state enum for clear UI states
enum RecordingState {
  idle,       // Not recording
  recording,  // Actively recording audio
  uploading,  // Uploading chunks / completing session
  error,      // Error occurred
}

class MicScreen extends StatefulWidget {
  const MicScreen({super.key});

  @override
  State<MicScreen> createState() => _MicScreenState();
}

class _MicScreenState extends State<MicScreen> {
  bool isDarkMode = false;
  final Record _recorder = Record();
  RecordingState _recordingState = RecordingState.idle;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  Timer? _chunkTimer;
  String? _recordedFilePath;
  String? _currentChunkPath;

  html.MediaRecorder? _webRecorder;
  html.MediaStream? _webStream;
  final List<html.Blob> _webChunks = [];
  String? _webBlobUrl;
  // Completer to wait for web MediaRecorder 'stop' event before uploading
  Completer<void>? _webStopCompleter;
  // Uploading UI state
  String? _transcriptionText;
  String? _errorMessage;
  String? _currentSessionId;
  int _nextChunkIndex = 0;
  final List<Future<void>> _pendingChunkUploads = [];
  bool _hasUploadError = false;
  static const int _maxChunkSeconds = 15;
  // Track seconds since last chunk upload (for 15-second chunks)
  int _secondsSinceLastChunk = 0;

  late final Future<Question> _dailyQuestionFuture;
  
  // Helper getters for backwards compatibility
  bool get _isRecording => _recordingState == RecordingState.recording;
  bool get _isUploading => _recordingState == RecordingState.uploading;

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

  /// Reset recording state for a new session
  void _resetRecordingSession() {
    _currentSessionId = const Uuid().v4();
    _nextChunkIndex = 0;
    _secondsSinceLastChunk = 0;
    _hasUploadError = false;
    _errorMessage = null;
    _transcriptionText = null;
    _webChunks.clear();
    _pendingChunkUploads.clear();
  }

  /// Upload a single audio chunk to the backend
  Future<void> _uploadChunk(List<int> audioBytes, String filename, String contentType) async {
    if (_currentSessionId == null) return;
    
    const int maxAttempts = 3;
    final chunkRequest = TranscriptionChunkRequest(
      sessionId: _currentSessionId!,
      chunkIndex: _nextChunkIndex,
      audioBytes: audioBytes,
      filename: filename,
      contentType: contentType,
    );

    print('DEBUG - Uploading chunk: session=${_currentSessionId} index=${_nextChunkIndex} size=${audioBytes.length}');

    int attempt = 0;
    while (true) {
      attempt += 1;
      try {
        await ApiService.uploadTranscriptionChunk(chunkRequest);
        _nextChunkIndex += 1;
        break;
      } catch (e) {
        if (attempt >= maxAttempts) {
          _hasUploadError = true;
          rethrow;
        }
        final backoff = Duration(milliseconds: 200 * (1 << (attempt - 1)));
        await Future.delayed(backoff);
      }
    }
  }

  /// Complete the transcription session after all chunks are sent
  Future<TranscriptionResponse> _completeSession() async {
    if (_currentSessionId == null) {
      throw ApiException("No s'ha trobat cap sessió activa.", 0);
    }

    print('DEBUG - Completing session: ${_currentSessionId}');

    TranscriptionResponse completeResp;
    int completeAttempt = 0;
    const int maxAttempts = 2;

    while (true) {
      completeAttempt += 1;
      try {
        completeResp = await ApiService.completeTranscriptionSession(
          TranscriptionCompleteRequest(sessionId: _currentSessionId!),
        );
        break;
      } catch (e) {
        if (completeAttempt >= maxAttempts) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return completeResp;
  }

  /// Upload recording at the end and complete the session
  Future<void> uploadRecording() async {
    setState(() {
      _recordingState = RecordingState.uploading;
      _errorMessage = null;
    });
    
    try {
      // Generate new session if we don't have one
      _currentSessionId ??= const Uuid().v4();
      const int chunkSize = 64 * 1024; // 64 KB per chunk
      const Duration betweenChunksDelay = Duration(milliseconds: 300);

      print('DEBUG - Finalizing upload session: $_currentSessionId');

      if (kIsWeb) {
        if (_webChunks.isEmpty) {
          setState(() => _recordingState = RecordingState.idle);
          return;
        }

        // Upload each Blob we collected; further split each blob into smaller parts
        for (final blob in List<html.Blob>.from(_webChunks)) {
          final Uint8List blobBytes = await _readBlobAsUint8List(blob);
          int offset = 0;
          while (offset < blobBytes.length) {
            final end = min(offset + chunkSize, blobBytes.length);
            final part = blobBytes.sublist(offset, end);

            await _uploadChunk(part, 'recording.webm', 'audio/webm');
            await Future.delayed(betweenChunksDelay);
            offset = end;
          }
        }
      } else {
        final path = _recordedFilePath;
        if (path == null || path.isEmpty) {
          setState(() => _recordingState = RecordingState.idle);
          return;
        }
        final file = File(path);
        final Uint8List allBytes = await file.readAsBytes();

        int offset = 0;
        while (offset < allBytes.length) {
          final end = min(offset + chunkSize, allBytes.length);
          final part = allBytes.sublist(offset, end);
          
          final filename = file.uri.pathSegments.isNotEmpty 
              ? file.uri.pathSegments.last 
              : 'recording.m4a';
          
          await _uploadChunk(part, filename, 'audio/mp4');
          await Future.delayed(betweenChunksDelay);
          offset = end;
        }
      }

      // Tell server we're done and get the final transcription
      final completeResp = await _completeSession();

      final String? extracted = completeResp.transcription ?? 
          completeResp.partialText ?? 
          (completeResp.status.isNotEmpty ? completeResp.status : null);

      if (mounted) {
        setState(() {
          _transcriptionText = extracted;
          _recordingState = RecordingState.idle;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              extracted != null 
                  ? 'Processat: ${_shortPreview(extracted)}' 
                  : 'Àudio enviat correctament'
            ),
          ),
        );
      }

      print('Transcription response: $completeResp');
    } catch (e) {
      if (mounted) {
        setState(() {
          _recordingState = RecordingState.error;
          _errorMessage = "Error en enviar l'àudio. Torna-ho a provar.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error en enviar l'àudio: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _webChunks.clear();
      if (mounted && _recordingState == RecordingState.uploading) {
        setState(() => _recordingState = RecordingState.idle);
      }
    }
  }

  // Helper to read a web Blob into a Uint8List
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
        completer.completeError('Unable to read Blob result');
      }
    });
    reader.onError.listen((event) {
      completer.completeError(event);
    });

    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  String _shortPreview(String text, [int max = 120]) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }

  Future<void> _startRecording() async {
    // Reset session for new recording
    _resetRecordingSession();
    
    if (kIsWeb) {
      try {
        final md = html.window.navigator.mediaDevices;
        if (md == null) {
          setState(() {
            _recordingState = RecordingState.error;
            _errorMessage = "No s'ha pogut accedir al micròfon.";
          });
          return;
        }
        _webStream = await md.getUserMedia({'audio': true});
      } catch (e) {
        // permission denied or unsupported
        setState(() {
          _recordingState = RecordingState.error;
          _errorMessage = "No s'ha pogut accedir al micròfon. Comprova els permisos.";
        });
        return;
      }

      _webChunks.clear();
      // create a completer that will be completed when the stop event fires
      _webStopCompleter = Completer<void>();
      _webRecorder = html.MediaRecorder(_webStream!);

      // `addEventListener` is used because some universal_html implementations
      // don't expose typed `onDataAvailable` / `onStop` getters.
      _webRecorder!.addEventListener('dataavailable', (event) {
        try {
          final data = (event as dynamic).data;
          if (data != null && data is html.Blob) {
            _webChunks.add(data);
          }
        } catch (_) {
          // ignore unexpected event shape
        }
      });

      _webRecorder!.addEventListener('stop', (event) {
        final blob = html.Blob(_webChunks, 'audio/webm');
        _webBlobUrl = html.Url.createObjectUrlFromBlob(blob);
        setState(() {
          _recordedFilePath = _webBlobUrl;
        });
        // notify any waiter that stop has completed
        try {
          if (_webStopCompleter != null && !_webStopCompleter!.isCompleted) {
            _webStopCompleter!.complete();
          }
        } catch (_) {}
      });

      _webRecorder!.start();
      setState(() {
        _recordingState = RecordingState.recording;
        _recordDuration = Duration.zero;
        _recordedFilePath = null;
        _secondsSinceLastChunk = 0;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
          _secondsSinceLastChunk += 1;
        });
      });

      return;
    }

    // existing mobile/desktop implementation
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() {
        _recordingState = RecordingState.error;
        _errorMessage = "No s'ha pogut accedir al micròfon. Comprova els permisos.";
      });
      return;
    }

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      path: filePath,
      encoder: AudioEncoder.aacLc,
    );

    setState(() {
      _recordingState = RecordingState.recording;
      _recordDuration = Duration.zero;
      _recordedFilePath = filePath;
      _secondsSinceLastChunk = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordDuration += const Duration(seconds: 1);
        _secondsSinceLastChunk += 1;
      });
    });
  }

  Future<Question> _getDailyQuestion() async {
    return await ApiService.getDailyQuestion();
  }

  Future<void> _stopRecording() async {
    if (kIsWeb) {
      try {
        _webRecorder?.stop();
      } catch (_) {}

      // wait for the stop event to complete and fill _webChunks/_webBlobUrl
      try {
        if (_webStopCompleter != null) {
          // wait up to 5 seconds for the browser events to fire
          await _webStopCompleter!.future.timeout(const Duration(seconds: 5));
        }
      } catch (_) {}

      // stop tracks to release microphone
      try {
        _webStream?.getTracks().forEach((t) => t.stop());
      } catch (_) {}

      _webStream = null;
      _webRecorder = null;

      _timer?.cancel();
      _timer = null;

      setState(() {
        _recordDuration = Duration.zero;
        _recordedFilePath = _webBlobUrl;
      });

      // upload the recording that was just stopped
      await uploadRecording();
      // clear completer reference
      _webStopCompleter = null;
      return;
    }

    final path = await _recorder.stop();
    _timer?.cancel();
    _timer = null;

    setState(() {
      _recordDuration = Duration.zero;
      _recordedFilePath = path ?? _recordedFilePath;
    });

    // upload the recorded file for processing
    await uploadRecording();
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chunkTimer?.cancel();
    _recorder.dispose();
    try {
      _webStream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    // ensure any waiting completer is completed to avoid dangling futures
    try {
      if (_webStopCompleter != null && !_webStopCompleter!.isCompleted) {
        _webStopCompleter!.complete();
      }
    } catch (_) {}
    super.dispose();
  }

  /// Builds the status text widget based on current state
  Widget _buildStatusWidget() {
    switch (_recordingState) {
      case RecordingState.recording:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Gravant...',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case RecordingState.uploading:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.getPrimaryTextColor(isDarkMode),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Processant àudio...',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
              ),
            ),
          ],
        );
      case RecordingState.error:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _errorMessage ?? 'Error desconegut',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        );
      case RecordingState.idle:
      default:
        if (_transcriptionText != null) {
          return const SizedBox.shrink();
        }
        return Text(
          'Prem el botó per començar a gravar',
          style: TextStyle(
            color: AppColors.getSecondaryTextColor(isDarkMode),
            fontSize: 14,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        // Background gradient
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.getBackgroundGradient(isDarkMode),
            ),
          ),

          //Particle System Effect by Ernest
          ParticleSystemWidget(
            isDarkMode: isDarkMode,
            particleCount: 50,
            maxSize: 3.0,
            minSize: 1.0,
            speed: 0.5,
            maxOpacity: 0.6,
            minOpacity: 0.2,
          ),

          //Container with all of the content: logo @ top left, theme toggle @ top right, mic image @ center
          SafeArea(
            child: Column(
              children: [
                //Header with logo and theme toggle
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //Logo
                      Image.asset(
                        isDarkMode ? TImages.lightLogo : TImages.darkLogo,
                        width: 40,
                        height: 40,
                      ),

                      //Theme toggle button
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
                //Container with microphone button and timer and question
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //Maybe change RawMaterialButton?
                        //Microphone button
                        FutureBuilder<Question>(
                          future: _dailyQuestionFuture,
                          builder: (context, snapshot) {
                            Widget child;

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              child = Text(
                                'Carregant...',
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
                                question?.text ?? 'No hi ha cap pregunta avui. Relata una experiència teva!',
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: TextStyle(
                                  color: AppColors.getPrimaryTextColor(isDarkMode),
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }

                            // Constrain the width on wide screens and apply horizontal padding
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28.0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 720),
                                child: child,
                              ),
                            );
                          },
                        ),
                        RawMaterialButton(
                          onPressed: _isUploading 
                              ? null 
                              : (_isRecording ? _stopRecording : _startRecording),
                          fillColor: _isUploading 
                              ? Colors.grey 
                              : (_isRecording ? Colors.red : Colors.white),
                          shape: const CircleBorder(),
                          elevation: 4.0,
                          constraints: const BoxConstraints.tightFor(
                            width: 96.0,
                            height: 96.0,
                          ),
                          child: _isUploading
                              ? SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isRecording ? Icons.stop : Icons.mic,
                                  size: 48.0,
                                  color: _isRecording ? Colors.white : Colors.black,
                                ),
                        ),
                        // Spacer between button and timer
                        const SizedBox(height: 12.0),
                        Text(
                          _formatDuration(_recordDuration),
                          style: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        // Status indicator based on recording state
                        const SizedBox(height: 8.0),
                        _buildStatusWidget(),
                        
                        // Transcription result display
                        if (_transcriptionText != null && _recordingState == RecordingState.idle) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: 300,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: AppColors.getBlurContainerColor(isDarkMode),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Transcripció completada',
                                      style: TextStyle(
                                        color: AppColors.getPrimaryTextColor(isDarkMode),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _transcriptionText!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.getPrimaryTextColor(isDarkMode),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 8.0),

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
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
