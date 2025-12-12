import 'package:flutter/material.dart';

import '../../../models/activity_models.dart';
import '../../../services/activities_api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import 'games/sorting.dart';
import 'games/sudoku.dart';
import 'games/wordle_easy.dart';
import 'games/memory.dart';
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
      final results = await _api.fetchRecommendedActivities();
      setState(() {
        _recommendedActivity = results.isNotEmpty ? results.first : null;
      });
    } catch (e) {
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemoryGame(
            activityId: activity.id,
            isDarkMode: isDarkMode,
          ),
        ),
      );
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

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: InkWell(
                                onTap: () =>
                                    _openActivity(_recommendedActivity!),
                                borderRadius: BorderRadius.circular(16),
                                child: ActivityCard(
                                  activity: _recommendedActivity!,
                                  isDarkMode: isDarkMode,
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
