import 'package:bitsxlamarato_frontend_2025/features/screens/activities/games/sudoku.dart';
import 'package:flutter/material.dart';

import '../../../models/activity_models.dart';
import '../../../services/activities_api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
<<<<<<< Updated upstream
import 'games/wordle.dart';
=======
import 'games/wordle_easy.dart';
import 'games/memory.dart';
>>>>>>> Stashed changes
import 'widgets/activity_card.dart';

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

class _RecommendedActivitiesPageState
    extends State<RecommendedActivitiesPage> {
  final ActivitiesApiService _api = const ActivitiesApiService();
  bool isDarkMode = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _loadActivities();
  }

  // Minimal local fallback activities so games are always available even if the API
  // fails (useful for dev / CORS issues). These are appended only if not present
  // in the API response.
  List<Activity> _localFallbackActivities() {
    return [
      Activity(
        id: 'local_sudoku',
        title: 'Sudoku',
        description: 'A simple 9x9 Sudoku puzzle to exercise logic and memory.',
        activityType: 'game:sudoku',
        difficulty: 2.5,
      ),
      Activity(
        id: 'local_wordle',
        title: 'Wordle',
        description: 'Guess the daily word in six tries.',
        activityType: 'game:wordle',
        difficulty: 2.0,
      ),
    ];
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await _api.fetchRecommendedActivities();

      // Merge results with local fallbacks (if not already present). This ensures
      // Sudoku and Wordle are selectable even if the backend fails due to CORS
      // or other network issues.
      final fallbacks = _localFallbackActivities();
      final merged = <Activity>[];
      merged.addAll(results);

      for (final fb in fallbacks) {
        final exists = merged.any((a) =>
            a.id == fb.id || a.title.toLowerCase() == fb.title.toLowerCase() || a.activityType.toLowerCase().contains(fb.activityType.split(':').last));
        if (!exists) merged.add(fb);
      }

      setState(() {
        _activities = merged;
      });
    } catch (e) {
      // Show a helpful error message but still provide local game fallbacks so
      // the user can play Sudoku/Wordle even when API calls fail (for example
      // due to CORS when running on web during development).
      setState(() {
        _errorMessage =
            'No s’han pogut carregar les activitats recomanades. Torna-ho a provar.';
        _activities = _localFallbackActivities();
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

    if (lowerType.contains('sudoku') || lowerTitle.contains('sudoku') || activity.id == 'local_sudoku') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SudokuPage(isDarkMode: isDarkMode),
        ),
      );
      return;
    }

    if (lowerType.contains('wordle') || lowerTitle.contains('wordle') || activity.id == 'local_wordle') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const WordleScreen(),
        ),
      );
      return;
    }

    // Default behaviour: show a details dialog with the activity description.
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.title, style: TextStyle(color: AppColors.getPrimaryTextColor(isDarkMode))),
        content: Text(activity.description, style: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode))),
        backgroundColor: AppColors.getSecondaryBackgroundColor(isDarkMode),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tancar', style: TextStyle(color: AppColors.getPrimaryButtonColor(isDarkMode))),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                                color: AppColors.getPrimaryTextColor(isDarkMode),
                              ),
                              onPressed: _toggleTheme,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.sports_esports,
                                color: AppColors.getPrimaryTextColor(isDarkMode),
                              ),
                              tooltip: 'Jocs',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const WordleScreen(),
                                  ),
                                );
                              },
                            ),
                            // Sudoku game
                            IconButton(
                              icon: Icon(
                                Icons.extension,
                                color: AppColors.getPrimaryTextColor(isDarkMode),
                              ),
                              tooltip: 'Sudoku',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SudokuPage(isDarkMode: isDarkMode),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Activitats recomanades',
                    style: TextStyle(
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Body: loading / error / list
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
                                'Carregant activitats…',
                                style: TextStyle(
                                  color: AppColors.getSecondaryTextColor(isDarkMode),
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
                                color: AppColors.getPrimaryButtonColor(isDarkMode),
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.getSecondaryTextColor(isDarkMode),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadActivities,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                                  foregroundColor: AppColors.getPrimaryButtonTextColor(isDarkMode),
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

                      if (_activities.isEmpty) {
                        return Center(
                          child: Text(
                            'No hi ha activitats recomanades en aquest moment.',
                            style: TextStyle(
                              color: AppColors.getSecondaryTextColor(isDarkMode),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: _activities.length,
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          return InkWell(
                            onTap: () => _openActivity(activity),
                            borderRadius: BorderRadius.circular(16),
                            child: ActivityCard(
                              activity: activity,
                              isDarkMode: isDarkMode,
                            ),
                          );
                        },
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
