import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/activity_models.dart';
import '../../../services/activities_api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import 'games/memory_animals.dart';
import 'games/memory_monuments.dart';
import 'games/sorting.dart';
import 'games/sudoku_easy.dart';
import 'games/sudoku_med.dart';
import 'games/sudoku_hard.dart';
import 'games/wordle_easy.dart';
import 'games/wordle_med.dart';
import 'games/wordle_hard.dart';
import 'widgets/activity_card.dart';

class AllActivitiesPage extends StatefulWidget {
  final bool initialDarkMode;

  const AllActivitiesPage({
    super.key,
    this.initialDarkMode = true,
  });

  @override
  State<AllActivitiesPage> createState() => _AllActivitiesPageState();
}

class _AllActivitiesPageState extends State<AllActivitiesPage> {
  final ActivitiesApiService _api = const ActivitiesApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  Timer? _debounce;

  bool isDarkMode = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<Activity> _activities = [];

  String? _selectedType;
  bool _useDifficultyFilter = false;
  bool _useExactDifficulty = false;
  RangeValues _difficultyRange = const RangeValues(0, 5);
  double _exactDifficulty = 2.5;
  // Advanced filters removed

  static const Duration _debounceDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _fetchActivities();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _fetchActivities);
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final queryText = _searchController.text.trim();
    final titleText = _titleController.text.trim();

    double? difficulty;
    double? difficultyMin;
    double? difficultyMax;

    if (_useDifficultyFilter) {
      if (_useExactDifficulty) {
        difficulty = _exactDifficulty;
      } else if (_difficultyRange.start > 0 || _difficultyRange.end < 5) {
        difficultyMin = _difficultyRange.start;
        difficultyMax = _difficultyRange.end;
      }
    }

    try {
      final results = await _api.searchActivities(
        query: queryText.isEmpty ? null : queryText,
        type: _selectedType,
        difficulty: difficulty,
        difficultyMin: difficultyMin,
        difficultyMax: difficultyMax,
        title: titleText.isEmpty ? null : titleText,
      );
      // Filtrar activitats que comencen amb "TEST - "
      final filteredResults = results.where((activity) {
        return !activity.title.startsWith('TEST - ');
      }).toList();
      setState(() {
        _activities = filteredResults;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'S’ha produït un error en carregar les activitats.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                  Text(
                    'Totes les activitats',
                    style: TextStyle(
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cerca activitats…',
                    style: TextStyle(
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 12),
                  // Inline filters removed; they are shown in a popup now
                  _buildSearchWithFiltersButton(),
                  const SizedBox(height: 12),
                  // Filters moved to popup; inline card removed
                  const SizedBox(height: 12),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchWithFiltersButton() {
    return Row(
      children: [
        // Expanded search field
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.getFieldBackgroundColor(isDarkMode),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _scheduleSearch(),
              decoration: InputDecoration(
                hintText: 'Cerca activitats…',
                hintStyle: TextStyle(
                  color: AppColors.getPlaceholderTextColor(isDarkMode),
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.getPlaceholderTextColor(isDarkMode),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: TextStyle(
                color: AppColors.getInputTextColor(isDarkMode),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Filters button on the opposite side of the search icon
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
            tooltip: 'Obrir filtres',
            icon: Icon(
              Icons.tune,
              color: AppColors.getPrimaryTextColor(isDarkMode),
            ),
            onPressed: _openFiltersPopup,
          ),
        ),
      ],
    );
  }

  void _openFiltersPopup() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, innerSetState) {
            void _uiSetState(VoidCallback fn) {
              setState(fn);
              innerSetState(fn);
            }

            return Dialog(
              backgroundColor:
                  AppColors.getSecondaryBackgroundColor(isDarkMode),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filtres',
                            style: TextStyle(
                              color: AppColors.getPrimaryTextColor(isDarkMode),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: AppColors.getPrimaryTextColor(isDarkMode),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Reuse the same filters UI inside the popup (no auto-apply)
                      _buildFiltersCard(
                        applyOnChange: false,
                        uiSetState: _uiSetState,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _fetchActivities();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AppColors.getPrimaryButtonColor(isDarkMode),
                            ),
                            child: const Text('Aplicar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFiltersCard({
    bool applyOnChange = true,
    void Function(VoidCallback fn)? uiSetState,
  }) {
    void _updateState(VoidCallback fn) {
      if (uiSetState != null) {
        uiSetState!(fn);
      } else {
        setState(fn);
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            AppColors.getSecondaryBackgroundColor(isDarkMode).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.containerShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.getPrimaryButtonColor(isDarkMode).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtres',
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _updateState(() {
                    _selectedType = null;
                    _useDifficultyFilter = false;
                    _useExactDifficulty = false;
                    _difficultyRange = const RangeValues(0, 5);
                    _exactDifficulty = 2.5;
                    _titleController.clear();
                  });
                  if (applyOnChange) {
                    _fetchActivities();
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restableix'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 68,
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Tipus d\'activitat',
                filled: true,
                fillColor: AppColors.getFieldBackgroundColor(isDarkMode),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                  fontSize: 13,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              dropdownColor: AppColors.getSecondaryBackgroundColor(isDarkMode),
              iconEnabledColor: AppColors.getPrimaryTextColor(isDarkMode),
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tots'),
                ),
                DropdownMenuItem(
                  value: 'concentration',
                  child: const Text('Concentració'),
                ),
                DropdownMenuItem(
                  value: 'speed',
                  child: const Text('Velocitat'),
                ),
                DropdownMenuItem(
                  value: 'words',
                  child: const Text('Paraules'),
                ),
                DropdownMenuItem(
                  value: 'sorting',
                  child: const Text('Ordenació'),
                ),
                DropdownMenuItem(
                  value: 'multitasking',
                  child: const Text('Multitasca'),
                ),
              ],
              onChanged: (value) {
                _updateState(() {
                  _selectedType = value;
                });
                if (applyOnChange) {
                  _scheduleSearch();
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Filtrar per dificultat',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
              ),
            ),
            value: _useDifficultyFilter,
            onChanged: (value) {
              _updateState(() {
                _useDifficultyFilter = value;
              });
              if (applyOnChange) {
                _scheduleSearch();
              }
            },
            activeColor: AppColors.getPrimaryButtonColor(isDarkMode),
          ),
          if (_useDifficultyFilter) ...[
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Rang'),
                  selected: !_useExactDifficulty,
                  onSelected: (selected) {
                    _updateState(() {
                      _useExactDifficulty = !selected;
                    });
                    if (applyOnChange) {
                      _scheduleSearch();
                    }
                  },
                  labelStyle: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                  ),
                  backgroundColor:
                      AppColors.getSecondaryBackgroundColor(isDarkMode),
                  selectedColor: AppColors.getPrimaryButtonColor(isDarkMode)
                      .withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Exacta'),
                  selected: _useExactDifficulty,
                  onSelected: (selected) {
                    _updateState(() {
                      _useExactDifficulty = selected;
                    });
                    if (applyOnChange) {
                      _scheduleSearch();
                    }
                  },
                  labelStyle: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                  ),
                  backgroundColor:
                      AppColors.getSecondaryBackgroundColor(isDarkMode),
                  selectedColor: AppColors.getPrimaryButtonColor(isDarkMode)
                      .withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_useExactDifficulty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: _exactDifficulty,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: _exactDifficulty.toStringAsFixed(1),
                    activeColor: AppColors.getPrimaryButtonColor(isDarkMode),
                    onChanged: (value) {
                      _updateState(() {
                        _exactDifficulty = value;
                      });
                    },
                    onChangeEnd: (_) {
                      if (applyOnChange) {
                        _scheduleSearch();
                      }
                    },
                  ),
                  Text(
                    'Dificultat exacta: ${_exactDifficulty.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RangeSlider(
                    values: _difficultyRange,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    labels: RangeLabels(
                      _difficultyRange.start.toStringAsFixed(1),
                      _difficultyRange.end.toStringAsFixed(1),
                    ),
                    activeColor: AppColors.getPrimaryButtonColor(isDarkMode),
                    onChanged: (value) {
                      _updateState(() {
                        _difficultyRange = value;
                      });
                    },
                    onChangeEnd: (_) {
                      if (applyOnChange) {
                        _scheduleSearch();
                      }
                    },
                  ),
                  Text(
                    'Rang seleccionat: ${_difficultyRange.start.toStringAsFixed(1)} - ${_difficultyRange.end.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                    ),
                  ),
                ],
              ),
          ],
          // Advanced filters removed
        ],
      ),
    );
  }

  // Advanced filters field removed

  Widget _buildBody() {
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
              onPressed: _fetchActivities,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                foregroundColor:
                    AppColors.getPrimaryButtonTextColor(isDarkMode),
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
          'No s’ha trobat cap activitat amb aquests criteris.',
          style: TextStyle(
            color: AppColors.getSecondaryTextColor(isDarkMode),
          ),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      child: ListView.builder(
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          return ActivityCard(
            activity: _activities[index],
            isDarkMode: isDarkMode,
            onTap: () => _openActivity(_activities[index]),
          );
        },
      ),
    );
  }

  void _openActivity(Activity activity) {
    final lowerType = activity.activityType.toLowerCase();
    final lowerTitle = activity.title.toLowerCase();

    if (lowerType.contains('sudoku') || lowerTitle.contains('sudoku')) {
      if (lowerTitle.contains('fàcil')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SudokuEasyPage(),
          ),
        );
        return;
      } else if (lowerTitle.contains('mitjà')) {
        // Future implementation for medium difficulty
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SudokuMedPage(),
          ),
        );
        return;
      } else if (lowerTitle.contains('difícil')) {
        // Future implementation for hard difficulty
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SudokuHardPage(),
          ),
        );
        return;
      }
      return;
    }

    if (lowerType.contains('wordle') || lowerTitle.contains('wordle')) {
      if (lowerTitle.contains('fàcil')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const WordleEasyScreen(),
          ),
        );
        return;
      } else if (lowerTitle.contains('mitjà')) {
        // Future implementation for medium difficulty
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const WordleMedScreen(),
          ),
        );
        return;
      } else if (lowerTitle.contains('difícil')) {
        // Future implementation for hard difficulty
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const WordleHardScreen(),
          ),
        );
        return;
      }
      return;
    }

    if (lowerType.contains('memory') || lowerTitle.contains('memory')) {
      // Route to specific memory game based on title
      if (lowerTitle.contains('animals') || lowerTitle.contains('animal')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryGameAnimals(
              isDarkMode: isDarkMode,
              activityId: activity.id,
            ),
          ),
        );
      } else if (lowerTitle.contains('monuments') ||
          lowerTitle.contains('monument')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryGameMonuments(
              isDarkMode: isDarkMode,
              activityId: activity.id,
            ),
          ),
        );
      } else {
        // Default to animals if no specific match
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MemoryGameAnimals(
              isDarkMode: isDarkMode,
              activityId: activity.id,
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

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          activity.title,
          style: TextStyle(color: AppColors.getPrimaryTextColor(isDarkMode)),
        ),
        content: Text(
          activity.description,
          style: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
        ),
        backgroundColor: AppColors.getSecondaryBackgroundColor(isDarkMode),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tancar',
              style:
                  TextStyle(color: AppColors.getPrimaryButtonColor(isDarkMode)),
            ),
          ),
        ],
      ),
    );
  }
}
