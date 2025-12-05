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
  String? _recordedFilePath;

  html.MediaRecorder? _webRecorder;
  html.MediaStream? _webStream;
  final List<html.Blob> _webChunks = [];
  String? _webBlobUrl;
  // Completer to wait for web MediaRecorder 'stop' event before uploading
  Completer<void>? _webStopCompleter;
  // Uploading UI state
  bool _isUploading = false;
  String? _transcriptionText;

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

  Future<void> uploadRecording() async {
    setState(() => _isUploading = true);
    try {
      Uint8List bytes;
      String filename;
      String contentType;

      if(kIsWeb) {
        if(_webChunks.isEmpty) return;

        final blob = html.Blob(_webChunks, 'audio/webm');
        final reader = html.FileReader();
        final completer = Completer<Uint8List>();

        reader.onLoadEnd.listen((_) {
          final result = reader.result;
          if(result is ByteBuffer) {
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
        bytes = await completer.future;
        filename = 'recording.webm';
        contentType = 'audio/webm';
      } else {
        final path = _recordedFilePath;
        if(path == null || path.isEmpty) return;
        final file = File(path);
        bytes = await file.readAsBytes();
        filename = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'recording.m4a';
        contentType = 'audio/mp4';
      }

      final transcriptionResponse = await ApiService.uploadRecordingFromBytes(
        bytes,
        filename: filename,
        contentType: contentType,
      );

      // extract a readable transcription/message if possible
      String? extracted;
      try {
        final dynamic resp = transcriptionResponse;
        if (resp == null) {
          extracted = null;
        } else if (resp is Map<String, dynamic>) {
          extracted = resp['text']?.toString() ?? resp['transcription']?.toString() ?? resp['message']?.toString();
        } else {
          // try common field names on typed object
          try {
            extracted = resp.text ?? resp.transcription ?? resp.message;
            if (extracted != null) extracted = extracted.toString();
          } catch (_) {
            extracted = resp.toString();
          }
        }
      } catch (_) {
        extracted = transcriptionResponse.toString();
      }

      if (mounted) {
        setState(() => _transcriptionText = extracted);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extracted != null ? 'Processed: ${_shortPreview(extracted)}' : 'Upload complete')),
        );
      }
      // debug log
      print('Transcription response: $transcriptionResponse');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      _webChunks.clear();
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _shortPreview(String text, [int max = 120]) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }

  Future<void> _startRecording() async {
    if (kIsWeb) {
      try {
        final md = html.window.navigator.mediaDevices;
        if (md == null) return;
        _webStream = await md.getUserMedia({'audio': true});
      } catch (e) {
        // permission denied or unsupported
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
        _isRecording = true;
        _recordDuration = Duration.zero;
        _recordedFilePath = null;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
      });

      return;
    }

    // existing mobile/desktop implementation
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      path: filePath,
      encoder: AudioEncoder.aacLc,
    );

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
      _recordedFilePath = filePath;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordDuration += const Duration(seconds: 1);
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
        _isRecording = false;
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
      _isRecording = false;
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

                        // Uploading indicator and transcription preview
                        const SizedBox(height: 8.0),
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
                                'Uploading...',
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
