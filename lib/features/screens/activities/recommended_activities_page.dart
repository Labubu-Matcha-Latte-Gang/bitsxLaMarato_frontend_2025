import 'package:flutter/material.dart';

import '../../../models/activity_models.dart';
import '../../../services/activities_api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import 'games/wordle.dart';
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
  List<Activity> _activities = [];

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
        _activities = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'No s’han pogut carregar les activitats recomanades. Torna-ho a provar.';
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
                                isDarkMode
                                    ? Icons.wb_sunny
                                    : Icons.nightlight_round,
                                color:
                                    AppColors.getPrimaryTextColor(isDarkMode),
                              ),
                              onPressed: _toggleTheme,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.sports_esports,
                                color:
                                    AppColors.getPrimaryTextColor(isDarkMode),
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
                  const SizedBox(height: 16),

                  // Juegos en el centro
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildGameCard(
                          context: context,
                          title: 'Wordle',
                          icon: Icons.abc,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WordleScreen(),
                              ),
                            );
                          },
                        ),
                        _buildGameCard(
                          context: context,
                          title: 'Memory',
                          icon: Icons.casino,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MemoryGame(isDarkMode: false),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

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

                      if (_activities.isEmpty) {
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

                      return ListView.builder(
                        itemCount: _activities.length,
                        itemBuilder: (context, index) {
                          return ActivityCard(
                            activity: _activities[index],
                            isDarkMode: isDarkMode,
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
