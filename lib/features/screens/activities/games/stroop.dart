import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../utils/app_colors.dart';

class SroopTestPage extends StatefulWidget {
  final bool isDarkMode;

  const SroopTestPage({
    super.key,
    this.isDarkMode = false,
  });

  @override
  State<SroopTestPage> createState() => _SroopTestPageState();
}

enum _SroopPhase { words, colors, interference, results }

class _ColorItem {
  final String label;
  final Color color;

  _ColorItem(this.label, this.color);
}

class _SroopTestPageState extends State<SroopTestPage> {
  static const int _phaseDuration = 45; // seconds per phase
  static const int _itemsPerPhase = 20; // number of items to display

  late bool isDarkMode;

  _SroopPhase _currentPhase = _SroopPhase.words;
  int _phaseProgress = 0; // 0 to _itemsPerPhase
  int _timeRemaining = _phaseDuration;
  late Timer _timer;
  bool _isRunning = false;

  int _wordsErrors = 0;
  int _colorsErrors = 0;
  int _interferenceErrors = 0;

  int _wordsTime = _phaseDuration;
  int _colorsTime = _phaseDuration;
  int _interferenceTime = _phaseDuration;

  // Current item being displayed
  late _ColorItem _currentItem;
  late List<_ColorItem> _currentPhaseItems;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    _initializePhase();
  }

  void _initializePhase() {
    _phaseProgress = 0;
    _timeRemaining = _phaseDuration;
    _isRunning = true;

    switch (_currentPhase) {
      case _SroopPhase.words:
        _currentPhaseItems = _generateWordsPhase();
        break;
      case _SroopPhase.colors:
        _currentPhaseItems = _generateColorsPhase();
        break;
      case _SroopPhase.interference:
        _currentPhaseItems = _generateInterferencePhase();
        break;
      case _SroopPhase.results:
        _isRunning = false;
        return;
    }

    _currentItem = _currentPhaseItems[_phaseProgress];
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _nextPhase();
          timer.cancel();
        }
      });
    });
  }

  List<_ColorItem> _generateWordsPhase() {
    final colors = [
      _ColorItem('VERMELL', Colors.black),
      _ColorItem('BLAU', Colors.black),
      _ColorItem('VERD', Colors.black),
      _ColorItem('GROC', Colors.black),
      _ColorItem('NEGRE', Colors.black),
      _ColorItem('BLANC', Colors.black),
    ];

    final items = <_ColorItem>[];
    for (int i = 0; i < _itemsPerPhase; i++) {
      items.add(colors[i % colors.length]);
    }
    return items;
  }

  List<_ColorItem> _generateColorsPhase() {
    final colorOptions = [
      _ColorItem('XXXX', Colors.red),
      _ColorItem('XXXX', Colors.blue),
      _ColorItem('XXXX', Colors.green),
      _ColorItem('XXXX', Colors.amber),
      _ColorItem('XXXX', Colors.purple),
      _ColorItem('XXXX', Colors.cyan),
    ];

    final items = <_ColorItem>[];
    for (int i = 0; i < _itemsPerPhase; i++) {
      items.add(colorOptions[i % colorOptions.length]);
    }
    return items;
  }

  List<_ColorItem> _generateInterferencePhase() {
    final words = ['VERMELL', 'BLAU', 'VERD', 'GROC', 'NEGRE', 'BLANC'];
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.cyan
    ];
    final colorLabels = ['VERMELL', 'BLAU', 'VERD', 'GROC', 'MORAT', 'CIAN'];

    final items = <_ColorItem>[];
    for (int i = 0; i < _itemsPerPhase; i++) {
      final wordIndex = i % words.length;
      final colorIndex = (i + 2) % colors.length; // Offset to create conflicts
      items.add(_ColorItem(words[wordIndex], colors[colorIndex]));
    }
    return items;
  }

  void _handleAnswer(String selectedLabel) {
    final correctColor = _getCorrectColorLabel(_currentItem.color);

    if (selectedLabel != correctColor) {
      switch (_currentPhase) {
        case _SroopPhase.words:
          _wordsErrors++;
          break;
        case _SroopPhase.colors:
          _colorsErrors++;
          break;
        case _SroopPhase.interference:
          _interferenceErrors++;
          break;
        case _SroopPhase.results:
          break;
      }
    }

    _nextItem();
  }

  String _getCorrectColorLabel(Color color) {
    if (color == Colors.red) return 'VERMELL';
    if (color == Colors.blue) return 'BLAU';
    if (color == Colors.green) return 'VERD';
    if (color == Colors.amber) return 'GROC';
    if (color == Colors.purple) return 'MORAT';
    if (color == Colors.cyan) return 'CIAN';
    return '';
  }

  void _nextItem() {
    setState(() {
      _phaseProgress++;
      if (_phaseProgress >= _itemsPerPhase) {
        _nextPhase();
      } else {
        _currentItem = _currentPhaseItems[_phaseProgress];
      }
    });
  }

  void _nextPhase() {
    _timer.cancel();

    // Save phase time
    switch (_currentPhase) {
      case _SroopPhase.words:
        _wordsTime = _phaseDuration - _timeRemaining;
        setState(() => _currentPhase = _SroopPhase.colors);
        break;
      case _SroopPhase.colors:
        _colorsTime = _phaseDuration - _timeRemaining;
        setState(() => _currentPhase = _SroopPhase.interference);
        break;
      case _SroopPhase.interference:
        _interferenceTime = _phaseDuration - _timeRemaining;
        setState(() => _currentPhase = _SroopPhase.results);
        return;
      case _SroopPhase.results:
        return;
    }

    _initializePhase();
  }

  double _calculateScore() {
    // Part A: Precision (max 5 points)
    final double precisionScore = (5 - (_interferenceErrors * 0.5)).clamp(0, 5);

    // Part B: Interference Resistance (max 5 points)
    final int interferenceIndex = _interferenceTime - _colorsTime;
    double resistanceScore = 5;

    if (interferenceIndex < 2) {
      resistanceScore = 5;
    } else if (interferenceIndex < 5) {
      resistanceScore = 4;
    } else if (interferenceIndex < 10) {
      resistanceScore = 3;
    } else if (interferenceIndex < 15) {
      resistanceScore = 2;
    } else {
      resistanceScore = 1;
    }

    return precisionScore + resistanceScore;
  }

  @override
  void dispose() {
    if (_isRunning) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      body: SafeArea(
        child: _currentPhase == _SroopPhase.results
            ? _buildResultsScreen()
            : _buildTestScreen(),
      ),
    );
  }

  Widget _buildTestScreen() {
    return Column(
      children: [
        // Header with phase info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getPhaseName(),
                    style: TextStyle(
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$_timeRemaining s',
                    style: TextStyle(
                      color: _timeRemaining < 10
                          ? Colors.red
                          : AppColors.getPrimaryButtonColor(isDarkMode),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _phaseProgress / _itemsPerPhase,
                  minHeight: 6,
                  backgroundColor: AppColors.getSecondaryTextColor(isDarkMode)
                      .withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.getPrimaryButtonColor(isDarkMode),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_phaseProgress / $_itemsPerPhase',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display current item
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.getSecondaryBackgroundColor(isDarkMode),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.getSecondaryBackgroundColor(isDarkMode),
                    ),
                  ),
                  child: Text(
                    _currentItem.label,
                    style: TextStyle(
                      color: _currentItem.color,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                // Color buttons for answer
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _buildAnswerButtons(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAnswerButtons() {
    final colors = [
      ('VERMELL', Colors.red),
      ('BLAU', Colors.blue),
      ('VERD', Colors.green),
      ('GROC', Colors.amber),
      ('MORAT', Colors.purple),
      ('CIAN', Colors.cyan),
    ];

    return colors.map((item) {
      final label = item.$1;
      final color = item.$2;
      return SizedBox(
        width: 80,
        child: ElevatedButton(
          onPressed: () => _handleAnswer(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(isDarkMode ? 0.7 : 1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildResultsScreen() {
    final totalScore = _calculateScore();
    final precisionScore = (5 - (_interferenceErrors * 0.5)).clamp(0, 5);
    final interferenceIndex = _interferenceTime - _colorsTime;

    double resistanceScore = 5;
    if (interferenceIndex < 2) {
      resistanceScore = 5;
    } else if (interferenceIndex < 5) {
      resistanceScore = 4;
    } else if (interferenceIndex < 10) {
      resistanceScore = 3;
    } else if (interferenceIndex < 15) {
      resistanceScore = 2;
    } else {
      resistanceScore = 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Text(
              'Resultats del Test de Stroop',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Total Score Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getPrimaryButtonColor(isDarkMode),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getPrimaryButtonColor(isDarkMode)
                      .withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Puntuació Total',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${totalScore.toStringAsFixed(1)} / 10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Phase Times
          Text(
            'Temps per fase',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildPhaseTimeCard('Fase de Paraules (P)', _wordsTime),
          const SizedBox(height: 8),
          _buildPhaseTimeCard('Fase de Colors (C)', _colorsTime),
          const SizedBox(height: 8),
          _buildPhaseTimeCard('Fase d\'Interferència (PC)', _interferenceTime),
          const SizedBox(height: 24),

          // Scoring Breakdown
          Text(
            'Desglose de la puntuació',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Precision
          _buildScoreCard(
            title: 'Part A: Precisió',
            value: precisionScore.toStringAsFixed(1),
            description:
                'Errors en fase d\'interferència: $_interferenceErrors\nFórmula: 5 - (errores × 0,5)',
            subtitle: '${precisionScore.toStringAsFixed(1)} / 5',
          ),
          const SizedBox(height: 8),

          // Interference Resistance
          _buildScoreCard(
            title: 'Part B: Resistència a la Interferència',
            value: resistanceScore.toStringAsFixed(1),
            description:
                'Diferència de temps: ${interferenceIndex}s\nFase 3 - Fase 2: $_interferenceTime - $_colorsTime',
            subtitle: '${resistanceScore.toStringAsFixed(1)} / 5',
          ),
          const SizedBox(height: 24),

          // Error Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.getSecondaryBackgroundColor(isDarkMode),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.getSecondaryBackgroundColor(isDarkMode)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resum d\'errors',
                  style: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildErrorRow('Fase de Paraules', _wordsErrors),
                const SizedBox(height: 8),
                _buildErrorRow('Fase de Colors', _colorsErrors),
                const SizedBox(height: 8),
                _buildErrorRow('Fase d\'Interferència', _interferenceErrors),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Exit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check),
              label: const Text('Finalitzar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTimeCard(String phaseName, int timeInSeconds) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.getSecondaryBackgroundColor(isDarkMode)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            phaseName,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$timeInSeconds s',
            style: TextStyle(
              color: AppColors.getPrimaryButtonColor(isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard({
    required String title,
    required String value,
    required String description,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.getSecondaryBackgroundColor(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.getPrimaryButtonColor(isDarkMode)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorRow(String label, int errorCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.getSecondaryTextColor(isDarkMode),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: errorCount > 0
                ? Colors.red.withOpacity(0.15)
                : AppColors.getPrimaryButtonColor(isDarkMode).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$errorCount',
            style: TextStyle(
              color: errorCount > 0
                  ? Colors.red
                  : AppColors.getPrimaryButtonColor(isDarkMode),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _getPhaseName() {
    switch (_currentPhase) {
      case _SroopPhase.words:
        return 'Fase 1: Paraules';
      case _SroopPhase.colors:
        return 'Fase 2: Colors';
      case _SroopPhase.interference:
        return 'Fase 3: Interferència';
      case _SroopPhase.results:
        return 'Resultats';
    }
  }
}
