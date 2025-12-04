import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

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

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }
  
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if(!hasPermission) return;
    
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
  
  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _timer?.cancel();
    _timer = null;
    
    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
      _recordedFilePath = path ?? _recordedFilePath;
    });
    
    //TODO: send filepath to backend for processing
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
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //Maybe change RawMaterialButton?
                        //Microphone button
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
                        //Spacer between button and timer
                        const SizedBox(height: 8.0),

                        SizedBox(
                          width: 200.0,
                          child: LinearProgressIndicator(
                            value: (_recordDuration.inSeconds/60).clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withAlpha(3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isRecording ? Colors.redAccent : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      )
    );
  }
}