import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../../../services/api_service.dart';
import '../../../models/flashcard_models.dart';

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

  String? recommendation;
  String? reason;
  String? description;
  List<CognitiveArea> areas = [];
  bool _loadingRecommendation = true;

  // Titles/text placeholders were removed - front/back now use backend data

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));

    // Fetch recommendation as soon as the page opens
    fetchFlashcardData();
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

  void fetchFlashcardData() async {
    // Example API call to fetch flashcard data
    setState(() {
      _loadingRecommendation = true;
    });
    try {
      final Flashcard data = await ApiService.getRecommendedTask();
      if (!mounted) return;
      setState(() {
        recommendation = data.recommendation.isNotEmpty ? data.recommendation : null;
        reason = data.reason.isNotEmpty ? data.reason : null;
        description = data.description.isNotEmpty ? data.description : null;
        areas = data.cognitiveAreas;
        _loadingRecommendation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // keep nulls and stop loading; UI will show fallback text
        _loadingRecommendation = false;
      });
    }
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

                  // Flashcard area — center both vertically and horizontally
                  Expanded(
                    child: Center(
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
                            final angle = progress * math.pi;
                            // Determine whether to show front or back based on angle
                            final showFront = angle <= (math.pi / 2);

                            // Enlarge the card and make its surface more distinct from the particle background.
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
                              child: SizedBox(
                                width: math.min(MediaQuery.of(context).size.width * 0.95, 700.0),
                                // Height scales with available height but stays constrained so the pie is visible
                                height: math.min(MediaQuery.of(context).size.height * 0.62, 420.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Stack(
                                    children: [
                                      // Blur background behind card to slightly blend, but card surface will be distinct
                                      Positioned.fill(
                                        child: BackdropFilter(
                                          filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                                          child: Container(
                                            color: AppColors.getSecondaryBackgroundColor(isDarkMode).withAlpha((0.28 * 255).round()),
                                          ),
                                        ),
                                      ),

                                      // Card content surface (with solid background + border)
                                      Positioned.fill(
                                        child: Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: AppColors.getSecondaryBackgroundColor(isDarkMode).withAlpha((0.92 * 255).round()),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: AppColors.getPrimaryTextColor(isDarkMode).withAlpha((0.12 * 255).round()),
                                              width: 1.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.containerShadow,
                                                blurRadius: 14,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Transform(
                                              alignment: Alignment.center,
                                              // When showing the back side, un-rotate the inner content so text isn't mirrored
                                              transform: Matrix4.identity()..rotateY(showFront ? 0 : math.pi),
                                              child: _loadingRecommendation
                                                  ? const Center(
                                                      child: CircularProgressIndicator(),
                                                    )
                                                  : (showFront ? _frontContent() : _backContent()),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Flip hint arrow — outside the flip transform so it stays readable and doesn't mirror
                                      Positioned(
                                        bottom: 10,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Opacity(
                                            opacity: 0.9,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _flipped ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                                                  size: 14,
                                                  color: AppColors.getPrimaryTextColor(isDarkMode).withAlpha((0.6 * 255).round()),
                                                ),
                                                const SizedBox(width: 6),
                                                // Hide the text label when inverted
                                                if (!_flipped)
                                                  Text(
                                                    'Gira la targeta',
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        color: AppColors.getPrimaryTextColor(isDarkMode).withAlpha((0.6 * 255).round()),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
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
                 ),
               ],
             ),
           ),
         ),
       ],
     ),
   );
  }

  Widget _frontContent() {
    final text = recommendation ?? '';
    return SingleChildScrollView(
      child: Center(
        child: Text(
          text.isNotEmpty ? text : 'Cap recomanació disponible.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 22,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _backContent() {
    final reasonText = reason ?? '';
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reasonText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                reasonText,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          // Pie chart showing cognitive areas
          if (areas.isNotEmpty) ...[
            Text(
              'Mètriques Millorades',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode).withAlpha((0.8 * 255).round()),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 120,
              child: _AreasPieChart(
                areas: areas,
                isDarkMode: isDarkMode,
              ),
            )
          ] else
            Text(
              'No hi ha dades d\'àrees.',
              style: GoogleFonts.poppins(textStyle: TextStyle(color: AppColors.getPrimaryTextColor(isDarkMode))),
            ),
        ],
      ),
    );
  }
}

class _AreasPieChart extends StatelessWidget {
  final List<CognitiveArea> areas;
  final bool isDarkMode;

  const _AreasPieChart({required this.areas, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final total = areas.fold<double>(0.0, (p, e) => p + e.percentage);
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
    ];

    // Inner color should match card surface so donut blends naturally
    final innerColor = AppColors.getSecondaryBackgroundColor(isDarkMode).withAlpha((0.92 * 255).round());

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: CustomPaint(
            size: const Size.square(140),
            painter: _PiePainter(areas: areas, colors: colors, total: total, innerColor: innerColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: areas.map((a) {
                final idx = areas.indexOf(a) % colors.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Colored circle marker (no icon) to indicate the legend color
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors[idx],
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.getPrimaryTextColor(isDarkMode).withAlpha((0.12 * 255).round())),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _translateCognitiveArea(_capitalize(a.name)),
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: AppColors.getPrimaryTextColor(isDarkMode),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${total > 0 ? (a.percentage / total * 100).toStringAsFixed(0) : a.percentage.toStringAsFixed(0)}% ',
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<CognitiveArea> areas;
  final List<Color> colors;
  final double total;
  final Color innerColor;

  _PiePainter({required this.areas, required this.colors, required this.total, required this.innerColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    double startRadian = -math.pi / 2;
    for (int i = 0; i < areas.length; i++) {
      final a = areas[i];
      final sweep = (total > 0 ? (a.percentage / total) : 0.0) * math.pi * 2;
      paint.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startRadian, sweep, true, paint);
      startRadian += sweep;
    }

    // Draw inner circle for donut effect using provided innerColor (matches card surface)
    final innerPaint = Paint()..color = innerColor;
    canvas.drawCircle(center, radius * 0.55, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

String _translateCognitiveArea(String area) {
  switch (area.toLowerCase()) {
    case 'memory':
      return 'Memòria';
    case 'attention':
      return 'Atenció';
    case 'speed':
      return 'Velocitat';
    case 'alternating_fluency':
      return 'Fluïdesa Alternant';
    default:
      return area;
  }
}
