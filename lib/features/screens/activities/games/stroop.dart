import 'dart:async';
import 'dart:math';
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

  bool _showInstructions = true;
  _SroopPhase _currentPhase = _SroopPhase.interference;
  int _phaseProgress = 0; // 0 to _itemsPerPhase
  int _timeRemaining = _phaseDuration;
  late Timer _timer;
  bool _isRunning = false;

  int _interferenceErrors = 0;
  int _interferenceTime = _phaseDuration;

  // Current item being displayed
  late _ColorItem _currentItem;
  late List<_ColorItem> _currentPhaseItems;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  void _startTest() {
    setState(() {
      _showInstructions = false;
    });
    _initializePhase();
  }

  void _initializePhase() {
    _phaseProgress = 0;
    _timeRemaining = _phaseDuration;
    _isRunning = true;

    if (_currentPhase == _SroopPhase.results) {
      _isRunning = false;
      return;
    }

    _currentPhaseItems = _generateInterferencePhase();
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

  List<_ColorItem> _generateInterferencePhase() {
    final words = ['VERMELL', 'BLAU', 'VERD', 'GROC', 'MORAT', 'CIAN'];
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.cyan
    ];
    final random = Random();

    final items = <_ColorItem>[];
    for (int i = 0; i < _itemsPerPhase; i++) {
      final randomWord = words[random.nextInt(words.length)];
      final randomColor = colors[random.nextInt(colors.length)];
      items.add(_ColorItem(randomWord, randomColor));
    }
    return items;
  }

  void _handleAnswer(String selectedLabel) {
    final correctColor = _getCorrectColorLabel(_currentItem.color);

    if (selectedLabel != correctColor) {
      _interferenceErrors++;
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

    // Only one phase (interference), go directly to results
    setState(() => _currentPhase = _SroopPhase.results);
  }

  double _calculateScore() {
    // Puntuación basada solo en precisión (max 10 points)
    final double precisionScore =
        (10 - (_interferenceErrors * 0.5)).clamp(0, 10);
    return precisionScore;
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
        child: _showInstructions
            ? _buildInstructionsScreen()
            : _currentPhase == _SroopPhase.results
                ? _buildResultsScreen()
                : _buildTestScreen(),
      ),
    );
  }

  Widget _buildInstructionsScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final fontSize = isMobile ? 16.0 : 18.0;
        final titleFontSize = isMobile ? 28.0 : 36.0;
        final buttonFontSize = isMobile ? 18.0 : 22.0;

        return Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.psychology,
                size: isMobile ? 80 : 100,
                color: AppColors.getPrimaryButtonColor(isDarkMode),
              ),
              const SizedBox(height: 24),
              Text(
                'Test de Stroop',
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  color: AppColors.getSecondaryBackgroundColor(isDarkMode),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.getSecondaryBackgroundColor(isDarkMode),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Com funciona:',
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionItem(
                      '1',
                      'Veuràs paraules de colors escrites en diferents colors',
                      fontSize,
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      '2',
                      'Has de seleccionar el COLOR en què està escrita la paraula, NO el que diu la paraula',
                      fontSize,
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      '3',
                      'Tens 45 segons per completar 20 ítems',
                      fontSize,
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      '4',
                      'Respon el més ràpid i precís possible',
                      fontSize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: AppColors.getPrimaryButtonColor(isDarkMode)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getPrimaryButtonColor(isDarkMode)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.getPrimaryButtonColor(isDarkMode),
                      size: isMobile ? 24 : 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Exemple: Si veus "VERMELL" escrit en blau, has de seleccionar BLAU',
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontSize: fontSize - 1,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                  foregroundColor:
                      AppColors.getPrimaryButtonTextColor(isDarkMode),
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 18 : 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Començar Test',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructionItem(String number, String text, double fontSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.getPrimaryButtonColor(isDarkMode),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontSize: fontSize,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1024;
        final isDesktop = screenWidth >= 1024;

        // Responsive font sizes
        final headerFontSize = isMobile
            ? 27.0
            : isTablet
                ? 33.0
                : 42.0;
        final itemFontSize = isMobile
            ? 72.0
            : isTablet
                ? 96.0
                : 144.0;
        final buttonFontSize = isMobile
            ? 24.0
            : isTablet
                ? 27.0
                : 33.0;
        final buttonWidth = isMobile
            ? 135.0
            : isTablet
                ? 165.0
                : 210.0;
        final buttonPadding = isMobile
            ? const EdgeInsets.symmetric(vertical: 21)
            : isTablet
                ? const EdgeInsets.symmetric(vertical: 24)
                : const EdgeInsets.symmetric(vertical: 30);
        final itemPadding = isMobile
            ? 20.0
            : isTablet
                ? 32.0
                : 48.0;
        final spaceBetweenSections = isMobile
            ? 24.0
            : isTablet
                ? 32.0
                : 48.0;

        return Column(
          children: [
            // Header with phase info
            Padding(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _getPhaseName(),
                          style: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_timeRemaining s',
                        style: TextStyle(
                          color: _timeRemaining < 10
                              ? Colors.red
                              : AppColors.getPrimaryButtonColor(isDarkMode),
                          fontSize: headerFontSize,
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
                      backgroundColor:
                          AppColors.getSecondaryTextColor(isDarkMode)
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
                      fontSize: isMobile ? 11.0 : 12.0,
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Display current item
                    Container(
                      padding: EdgeInsets.all(itemPadding),
                      decoration: BoxDecoration(
                        color:
                            AppColors.getSecondaryBackgroundColor(isDarkMode),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              AppColors.getSecondaryBackgroundColor(isDarkMode),
                        ),
                      ),
                      child: Text(
                        _currentItem.label,
                        style: TextStyle(
                          color: _currentItem.color,
                          fontSize: itemFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: spaceBetweenSections),
                    // Color buttons for answer
                    Wrap(
                      spacing: isMobile ? 8 : 12,
                      runSpacing: isMobile ? 8 : 12,
                      alignment: WrapAlignment.center,
                      children: _buildAnswerButtons(
                        buttonWidth: buttonWidth,
                        buttonPadding: buttonPadding,
                        buttonFontSize: buttonFontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildAnswerButtons({
    required double buttonWidth,
    required EdgeInsets buttonPadding,
    required double buttonFontSize,
  }) {
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
        width: buttonWidth,
        child: ElevatedButton(
          onPressed: () => _handleAnswer(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(isDarkMode ? 0.7 : 1),
            foregroundColor: Colors.white,
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: buttonFontSize,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildResultsScreen() {
    final totalScore = _calculateScore();

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

          // Phase Time
          Text(
            'Temps de la prova',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildPhaseTimeCard('Fase d\'Interferència', _interferenceTime),
          const SizedBox(height: 24),

          // Scoring Breakdown
          Text(
            'Detall de la puntuació',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Precision
          _buildScoreCard(
            title: 'Precisió',
            value: totalScore.toStringAsFixed(1),
            description:
                'Errors comesos: $_interferenceErrors\nFórmula: 10 - (errors × 0,5)',
            subtitle: '${totalScore.toStringAsFixed(1)} / 10',
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
                _buildErrorRow('Errors totals', _interferenceErrors),
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
    return 'Test de Stroop';
  }
}
