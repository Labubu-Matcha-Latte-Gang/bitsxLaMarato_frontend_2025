import 'package:flutter/material.dart';

import '../../../models/activity_models.dart';
import '../../../services/activities_api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import 'games/sorting.dart';
import 'games/sudoku.dart';
import 'games/wordle_easy.dart';
import 'games/memory_animals.dart';
import 'games/memory_monuments.dart';

class RecommendedActivitiesPage extends StatefulWidget {
  final bool initialDarkMode;

  const RecommendedActivitiesPage({
    super.key,
    this.initialDarkMode = false,
  });

  @override
  State<RecommendedActivitiesPage> createState() =>
      _RecommendedActivitiesPageState();
}

class _RecommendedActivitiesPageState extends State<RecommendedActivitiesPage> {
  final ActivitiesApiService _api = const ActivitiesApiService();
  bool isDarkMode = false;
  bool _isLoading = true;
  String? _errorMessage;
  Activity? _recommendedActivity;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      print('DEBUG - Fetching recommended activity from API...');
      final results = await _api.fetchRecommendedActivities();

      if (results.isNotEmpty) {
        final activity = results.first;
        print('DEBUG - ✓ Recommended activity loaded successfully');
        print('DEBUG - Activity ID: ${activity.id}');
        print('DEBUG - Activity Title: ${activity.title}');
        print('DEBUG - Activity Type: ${activity.activityType}');
        print('DEBUG - Activity Difficulty: ${activity.difficulty}');
        print('DEBUG - Activity Description: ${activity.description}');
      } else {
        print('DEBUG - ⚠ API returned empty results');
      }

      setState(() {
        _recommendedActivity = results.isNotEmpty ? results.first : null;
      });
    } catch (e) {
      print('DEBUG - ✗ Error loading recommended activity: $e');
      setState(() {
        _errorMessage =
            'No s\'ha pogut carregar l\'activitat recomanada. Torna-ho a provar.';
        _recommendedActivity = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _openActivity(Activity activity) {
    final lowerType = activity.activityType.toLowerCase();
    final lowerTitle = activity.title.toLowerCase();

    if (lowerType.contains('sudoku') || lowerTitle.contains('sudoku')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SudokuPage(isDarkMode: isDarkMode),
        ),
      );
      return;
    }

    if (lowerType.contains('wordle') || lowerTitle.contains('wordle')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const WordleScreen(),
        ),
      );
      return;
    }

    if (lowerType.contains('memory') ||
        lowerTitle.contains('memory') ||
        lowerTitle.contains('memoritzar') ||
        lowerType.contains('concentration')) {
      // Route to specific memory game based on title
      if (lowerTitle.contains('animals') || lowerTitle.contains('animal')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryGameAnimals(
              activityId: activity.id,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      } else if (lowerTitle.contains('monuments') ||
          lowerTitle.contains('monument')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryGameMonuments(
              activityId: activity.id,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      } else {
        // Default to animals if no specific match
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryGameAnimals(
              activityId: activity.id,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      }
      return;
    }

    if (lowerType.contains('sorting')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SortingActivityPage(
            activity: activity,
            initialDarkMode: isDarkMode,
          ),
        ),
      );
      return;
    }

    // Default behaviour: show a details dialog with the activity description.
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.title,
            style: TextStyle(color: AppColors.getPrimaryTextColor(isDarkMode))),
        content: Text(activity.description,
            style:
                TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode))),
        backgroundColor: AppColors.getSecondaryBackgroundColor(isDarkMode),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tancar',
                style: TextStyle(
                    color: AppColors.getPrimaryButtonColor(isDarkMode))),
          )
        ],
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
                  Text(
                    'Activitat recomanada',
                    style: TextStyle(
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Body: loading / error / activity card
                  Expanded(
                    child: Builder(builder: (context) {
                      if (_isLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.getPrimaryButtonColor(isDarkMode),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Carregant activitat…',
                                style: TextStyle(
                                  color: AppColors.getSecondaryTextColor(
                                      isDarkMode),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_errorMessage != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color:
                                    AppColors.getPrimaryButtonColor(isDarkMode),
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.getSecondaryTextColor(
                                      isDarkMode),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadActivities,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.getPrimaryButtonColor(
                                          isDarkMode),
                                  foregroundColor:
                                      AppColors.getPrimaryButtonTextColor(
                                          isDarkMode),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Torna-ho a provar'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_recommendedActivity == null) {
                        return Center(
                          child: Text(
                            'No hi ha activitats recomanades en aquest moment.',
                            style: TextStyle(
                              color:
                                  AppColors.getSecondaryTextColor(isDarkMode),
                            ),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20.0, horizontal: 16.0),
                              child: InkWell(
                                onTap: () =>
                                    _openActivity(_recommendedActivity!),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.getSecondaryBackgroundColor(
                                                isDarkMode)
                                            .withAlpha((0.98 * 255).round()),
                                        AppColors.getSecondaryBackgroundColor(
                                                isDarkMode)
                                            .withAlpha((0.92 * 255).round()),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.containerShadow
                                            .withAlpha((0.6 * 255).round()),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: AppColors.getPrimaryButtonColor(
                                                isDarkMode)
                                            .withAlpha((0.15 * 255).round()),
                                        blurRadius: 30,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: AppColors.getPrimaryButtonColor(
                                              isDarkMode)
                                          .withAlpha((0.3 * 255).round()),
                                      width: 2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    AppColors
                                                            .getPrimaryButtonColor(
                                                                isDarkMode)
                                                        .withAlpha((0.3 * 255)
                                                            .round()),
                                                    AppColors
                                                            .getPrimaryButtonColor(
                                                                isDarkMode)
                                                        .withAlpha((0.2 * 255)
                                                            .round()),
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors
                                                          .getPrimaryButtonColor(
                                                              isDarkMode)
                                                      .withAlpha(
                                                          (0.4 * 255).round()),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.auto_awesome,
                                                color: AppColors
                                                    .getPrimaryButtonColor(
                                                        isDarkMode),
                                                size: 40,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Activitat del dia',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .getSecondaryTextColor(
                                                              isDarkMode),
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    _recommendedActivity!.title,
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .getPrimaryTextColor(
                                                              isDarkMode),
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.getBlurContainerColor(
                                                        isDarkMode)
                                                    .withAlpha(
                                                        (0.4 * 255).round()),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppColors
                                                      .getPrimaryButtonColor(
                                                          isDarkMode)
                                                  .withAlpha(
                                                      (0.2 * 255).round()),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Descripció',
                                                style: TextStyle(
                                                  color: AppColors
                                                      .getPrimaryTextColor(
                                                          isDarkMode),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                _recommendedActivity!
                                                    .description,
                                                style: TextStyle(
                                                  color: AppColors
                                                      .getSecondaryTextColor(
                                                          isDarkMode),
                                                  fontSize: 15,
                                                  height: 1.6,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: [
                                            _InfoChip(
                                              icon: Icons.category_outlined,
                                              label: _recommendedActivity!
                                                  .activityType,
                                              isDarkMode: isDarkMode,
                                            ),
                                            _InfoChip(
                                              icon: Icons.trending_up,
                                              label:
                                                  'Dificultat: ${_recommendedActivity!.difficulty.toStringAsFixed(1)}',
                                              isDarkMode: isDarkMode,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 28),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () => _openActivity(
                                                _recommendedActivity!),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors
                                                  .getPrimaryButtonColor(
                                                      isDarkMode),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              elevation: 4,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'Començar activitat',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 22,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDarkMode;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.getBlurContainerColor(isDarkMode)
            .withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getPrimaryButtonColor(isDarkMode)
              .withAlpha((0.25 * 255).round()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.getPrimaryButtonColor(isDarkMode),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
