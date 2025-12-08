import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/activity_models.dart';
import '../../../services/activities_api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import 'widgets/activity_card.dart';

class AllActivitiesPage extends StatefulWidget {
  final bool initialDarkMode;

  const AllActivitiesPage({
    super.key,
    this.initialDarkMode = false,
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
  bool _showAdvanced = false;

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
      setState(() {
        _activities = results;
      });
    } catch (_) {
      setState(() {
        _errorMessage =
        'S’ha produït un error en carregar les activitats.';
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
                            isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
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
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildFiltersCard(),
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

  Widget _buildSearchField() {
    return Container(
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
    );
  }

  Widget _buildFiltersCard() {
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
                  setState(() {
                    _selectedType = null;
                    _useDifficultyFilter = false;
                    _useExactDifficulty = false;
                    _difficultyRange = const RangeValues(0, 5);
                    _exactDifficulty = 2.5;
                    _titleController.clear();
                  });
                  _fetchActivities();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restableix'),
                style: TextButton.styleFrom(
                  foregroundColor:
                  AppColors.getPrimaryButtonColor(isDarkMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
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
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
              dropdownColor:
              AppColors.getSecondaryBackgroundColor(isDarkMode),
              iconEnabledColor: AppColors.getPrimaryTextColor(isDarkMode),
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
              ),
              items: const [
                'concentration',
                'speed',
                'words',
                'sorting',
                'multitasking',
              ]
                  .map(
                    (type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                    ),
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
                _scheduleSearch();
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
              setState(() {
                _useDifficultyFilter = value;
              });
              _scheduleSearch();
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
                    setState(() {
                      _useExactDifficulty = !selected;
                    });
                    _scheduleSearch();
                  },
                  labelStyle: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                  ),
                  selectedColor:
                  AppColors.getPrimaryButtonColor(isDarkMode).withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Exacta'),
                  selected: _useExactDifficulty,
                  onSelected: (selected) {
                    setState(() {
                      _useExactDifficulty = selected;
                    });
                    _scheduleSearch();
                  },
                  labelStyle: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                  ),
                  selectedColor:
                  AppColors.getPrimaryButtonColor(isDarkMode).withOpacity(0.2),
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
                      setState(() {
                        _exactDifficulty = value;
                      });
                    },
                    onChangeEnd: (_) => _scheduleSearch(),
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
                      setState(() {
                        _difficultyRange = value;
                      });
                    },
                    onChangeEnd: (_) => _scheduleSearch(),
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
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres avançats',
                  style: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _showAdvanced
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                ),
              ],
            ),
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 10),
            _buildAdvancedField(
              controller: _titleController,
              label: 'Títol exacte',
              icon: Icons.title,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.getFieldBackgroundColor(isDarkMode),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(
          color: AppColors.getSecondaryTextColor(isDarkMode),
        ),
      ),
      style: TextStyle(
        color: AppColors.getInputTextColor(isDarkMode),
      ),
      onChanged: (_) => _scheduleSearch(),
    );
  }

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

    return ListView.builder(
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        return ActivityCard(
          activity: _activities[index],
          isDarkMode: isDarkMode,
        );
      },
    );
  }
}
