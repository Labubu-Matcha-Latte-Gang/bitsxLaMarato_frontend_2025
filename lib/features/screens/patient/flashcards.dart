import 'dart:math';
import 'dart:ui' as ui;

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

class _Flashcards extends State<Flashcards> with SingleTickerProviderStateMixin {
  late bool isDarkMode = true;

  // Flip card state
  bool _flipped = false;
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  // Example texts — replace with dynamic data as needed
  final String _frontText = 'Quins àrees cognitives treballa aquesta activitat?';
  final String _backText = 'Memòria: 40%\nAtenció: 30%\nLlenguatge: 20%\nExecució: 10%\n\nAquesta activitat ajuda a exercitar la memòria i l\'atenció.';

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back,
                              color: AppColors.getPrimaryTextColor(isDarkMode),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            isDarkMode ? TImages.lightLogo : TImages.darkLogo,
                            width: 36,
                            height: 36,
                          ),
                        ],
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
                  const SizedBox(height: 12),

                  // Flashcard area
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _flipped = !_flipped;
                          if (_flipped) {
                            _flipController.forward(from: 0.0);
                          } else {
                            _flipController.reverse(from: 1.0);
                          }
                        });
                      },
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final progress = _flipAnimation.value;
                          // rotation 0..pi
                          final angle = progress * pi;
                          // Determine whether to show front or back based on angle
                          final showFront = angle <= (pi / 2);

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
                            child: SizedBox(
                              width: min(MediaQuery.of(context).size.width * 0.9, 520.0),
                              height: 220,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    // Blur background
                                    Positioned.fill(
                                      child: BackdropFilter(
                                        filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                                        child: Container(
                                          color: AppColors.getSecondaryBackgroundColor(isDarkMode).withAlpha((0.35 * 255).round()),
                                        ),
                                      ),
                                    ),
                                    // Card content
                                    Positioned.fill(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppColors.getSecondaryBackgroundColor(isDarkMode).withAlpha((0.6 * 255).round()),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.containerShadow,
                                              blurRadius: 10,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Transform(
                                            alignment: Alignment.center,
                                            // When showing the back side, un-rotate the inner content so text isn't mirrored
                                            transform: Matrix4.identity()..rotateY(showFront ? 0 : pi),
                                            child: Text(
                                              showFront ? _frontText : _backText,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: AppColors.getPrimaryTextColor(isDarkMode),
                                                fontSize: 16,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
