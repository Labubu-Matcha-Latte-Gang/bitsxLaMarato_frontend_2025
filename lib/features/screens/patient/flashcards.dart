import 'dart:async';

import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';

class Flashcards extends StatefulWidget {
  final bool initialDarkMode;

  const Flashcards({
    super.key,
    this.initialDarkMode = true,
  });

  @override
  State<Flashcards> createState() => _Flashcards();
}

class _Flashcards extends State<Flashcards>{
  late bool isDarkMode = true;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
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
        ],
      ),
    );
  }
}

