import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../models/activity_models.dart';
import '../../../../services/api_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/effects/particle_system.dart';

/// Dynamic implementation of a WCST inspired sorting task. The behaviour adapts
/// to the difficulty (or id) provided by the backend configuration.
class SortingActivityPage extends StatefulWidget {
  final Activity activity;
  final bool initialDarkMode;

  const SortingActivityPage({
    super.key,
    required this.activity,
    this.initialDarkMode = false,
  });

  @override
  State<SortingActivityPage> createState() => _SortingActivityPageState();
}

class _SortingActivityPageState extends State<SortingActivityPage> {
  late bool isDarkMode;
  late SortingVariantConfig _config;

  final List<SortingCardData> _referenceCards = [
    SortingCardData(
      id: 'ref_red_triangle_1',
      color: const Color(0xFFE76F51),
      colorName: 'Vermell',
      icon: Icons.change_history_rounded,
      shapeName: 'Triangle',
      count: 1,
    ),
    SortingCardData(
      id: 'ref_teal_square_2',
      color: const Color(0xFF2A9D8F),
      colorName: 'Turquesa',
      icon: Icons.crop_square_rounded,
      shapeName: 'Quadrat',
      count: 2,
    ),
    SortingCardData(
      id: 'ref_blue_circle_3',
      color: const Color(0xFF457B9D),
      colorName: 'Blau',
      icon: Icons.circle_rounded,
      shapeName: 'Cercle',
      count: 3,
    ),
    SortingCardData(
      id: 'ref_yellow_star_4',
      color: const Color(0xFFF4A261),
      colorName: 'Groc',
      icon: Icons.star_rounded,
      shapeName: 'Estrella',
      count: 4,
    ),
  ];

  final Random _random = Random();
  late List<SortingCardData> _deck;
  int _currentIndex = 0;
  SortingCardData? _currentCard;

  SortingRule _currentRule = SortingRule.color;
  int _correct = 0;
  int _errors = 0;
  int _errorsWhileExploring = 0;
  int _errorsAfterLearning = 0;
  int _errorsDuringRuleChange = 0;
  int _ruleChanges = 0;
  int _slowPenalties = 0;
  int _streak = 0;
  bool _ruleLearned = false;
  bool _postChangeGrace = false;

  double? _finalScore;
  double? _finalElapsedSeconds;
  bool _submissionSuccess = false;
  String? _submissionError;

  bool _hasWarnedAboutChange = false;
  bool _gameFinished = false;
  bool _submitting = false;
  bool _timeoutReached = false;
  bool _hasStarted = false;
  bool _instructionsVisible = true;

  final Stopwatch _elapsedStopwatch = Stopwatch();
  final Stopwatch _reactionStopwatch = Stopwatch();
  Timer? _ticker;

  Duration? _remainingTime;
  final List<SortingAttempt> _recentAttempts = [];

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _config = SortingVariantConfig.fromActivity(widget.activity);
    _bootstrapGame();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _elapsedStopwatch.stop();
    _reactionStopwatch.stop();
    super.dispose();
  }

  void _bootstrapGame() {
    _deck = _buildDeck();
    _currentIndex = 0;
    _currentCard = _deck.first;
    _correct = 0;
    _errors = 0;
    _errorsWhileExploring = 0;
    _errorsAfterLearning = 0;
    _errorsDuringRuleChange = 0;
    _ruleChanges = 0;
    _streak = 0;
    _slowPenalties = 0;
    _ruleLearned = false;
    _postChangeGrace = false;
    _gameFinished = false;
    _timeoutReached = false;
    _hasWarnedAboutChange = false;
    _recentAttempts.clear();

    _currentRule = SortingRule.values[
        _random.nextInt(SortingRule.values.length)];

    _elapsedStopwatch
      ..reset();
    _reactionStopwatch
      ..reset();
    _remainingTime = _config.totalTimeLimit;
    _ticker?.cancel();
    _hasStarted = false;
    _instructionsVisible = true;
    setState(() {});
  }

  void _startGameplay() {
    if (_hasStarted) return;
    setState(() {
      _hasStarted = true;
      _instructionsVisible = false;
    });
    _elapsedStopwatch.start();
    _reactionStopwatch.start();
    if (_config.totalTimeLimit != null) {
      _remainingTime = _config.totalTimeLimit;
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _gameFinished) return;
        setState(() {
          final elapsed = _elapsedStopwatch.elapsed;
          final remaining = _config.totalTimeLimit! - elapsed;
          _remainingTime = remaining.isNegative ? Duration.zero : remaining;
          if (remaining <= Duration.zero) {
            _timeoutReached = true;
            _finishGame();
          }
        });
      });
    }
  }

  List<SortingCardData> _buildDeck() {
    const colors = [
      SortingPaletteColor('Vermell', Color(0xFFE76F51)),
      SortingPaletteColor('Turquesa', Color(0xFF2A9D8F)),
      SortingPaletteColor('Blau', Color(0xFF457B9D)),
      SortingPaletteColor('Groc', Color(0xFFF4A261)),
    ];

    const shapes = [
      SortingShape('Triangle', Icons.change_history_rounded),
      SortingShape('Quadrat', Icons.crop_square_rounded),
      SortingShape('Cercle', Icons.circle_rounded),
      SortingShape('Estrella', Icons.star_rounded),
    ];

    final List<SortingCardData> cards = [];
    for (final color in colors) {
      for (final shape in shapes) {
        for (int count = 1; count <= 4; count++) {
          cards.add(
            SortingCardData(
              id: 'card_${color.name}_${shape.name}_${count}_${cards.length}',
              color: color.color,
              colorName: color.name,
              icon: shape.icon,
              shapeName: shape.name,
              count: count,
            ),
          );
        }
      }
    }
    cards.shuffle(_random);
    return cards.take(_config.deckSize).toList();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _handleSelection(int targetIndex) {
    if (!_hasStarted || _gameFinished || _currentCard == null) return;
    if (targetIndex < 0 || targetIndex >= _referenceCards.length) return;

    final target = _referenceCards[targetIndex];
    final card = _currentCard!;
    final reaction = _reactionStopwatch.elapsed;
    _reactionStopwatch
      ..reset()
      ..start();

    final isCorrect = _matchesRule(card, target, _currentRule);
    final slowResponse =
        _config.penalizeSlowResponses && reaction > _config.slowThreshold;

    setState(() {
      _recentAttempts.insert(
        0,
        SortingAttempt(
          card: card,
          isCorrect: isCorrect,
          ruleEvaluated: _config.showHints ? _currentRule : null,
          reactionTime: reaction,
          wasSlow: slowResponse,
        ),
      );
      if (_recentAttempts.length > 5) {
        _recentAttempts.removeLast();
      }
    });

    if (isCorrect) {
      _correct += 1;
      _streak += 1;
      _ruleLearned = true;
      if (_config.warnBeforeRuleChange &&
          !_hasWarnedAboutChange &&
          _streak == _config.correctAnswersToChangeRule - 1) {
        _hasWarnedAboutChange = true;
        _showPreRuleChangeWarning();
      }
    } else {
      _errors += 1;
      _streak = 0;
      if (_postChangeGrace) {
        _errorsDuringRuleChange += 1;
      } else if (_ruleLearned) {
        _errorsAfterLearning += 1;
      } else {
        _errorsWhileExploring += 1;
      }
      _hasWarnedAboutChange = false;
      if (_config.resetRuleOnError) {
        _changeRule(forceRandom: true);
      }
    }

    if (slowResponse) {
      _slowPenalties += 1;
    }

    if (isCorrect &&
        _streak >= _config.correctAnswersToChangeRule &&
        !_timeoutReached) {
      _changeRule();
    }

    _advanceDeck();
    _postChangeGrace = false;
  }

  void _advanceDeck() {
    _currentIndex += 1;
    if (_currentIndex >= _deck.length) {
      _finishGame();
      return;
    }
    setState(() {
      _currentCard = _deck[_currentIndex];
    });
  }

  void _changeRule({bool forceRandom = false}) {
    final availableRules = SortingRule.values
        .where((rule) => forceRandom ? true : rule != _currentRule)
        .toList();
    availableRules.shuffle(_random);
    setState(() {
      _currentRule = availableRules.first;
      _ruleChanges += 1;
      _streak = 0;
      _hasWarnedAboutChange = false;
      _ruleLearned = false;
      _postChangeGrace = true;
    });

    if (_config.showHints) {
      _showHintSnackBar('Nova regla: ${_currentRule.label}');
    }
  }

  void _showPreRuleChangeWarning() {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Atenció! La regla canviarà després del proper encert.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.9),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showHintSnackBar(String text) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.secondary.withOpacity(0.95),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _matchesRule(
    SortingCardData attempt,
    SortingCardData reference,
    SortingRule rule,
  ) {
    switch (rule) {
      case SortingRule.color:
        return attempt.colorName == reference.colorName;
      case SortingRule.shape:
        return attempt.shapeName == reference.shapeName;
      case SortingRule.number:
        return attempt.count == reference.count;
    }
  }

  void _finishGame() {
    if (_gameFinished) return;
    _gameFinished = true;
    _elapsedStopwatch.stop();
    _reactionStopwatch.stop();
    _ticker?.cancel();

    final computedScore = _calculateScore();
    final elapsedSeconds = _elapsedStopwatch.elapsed.inSeconds.toDouble();

    setState(() {
      _finalScore = computedScore;
      _finalElapsedSeconds = elapsedSeconds;
      _submissionSuccess = false;
      _submissionError = null;
      _submitting = true;
    });

    _submitScore(computedScore, elapsedSeconds);

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _showCompletionSheet();
    });
  }

  void _showCompletionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bgColor = AppColors.getSecondaryBackgroundColor(isDarkMode)
            .withOpacity(0.98);
        final score = _finalScore ?? _calculateScore();
        final elapsedSeconds =
            _finalElapsedSeconds ?? _elapsedStopwatch.elapsed.inSeconds.toDouble();
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.containerShadow.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _timeoutReached
                        ? Icons.alarm_off_rounded
                        : Icons.emoji_events_rounded,
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _timeoutReached
                          ? 'Temps esgotat'
                          : 'Activitat completada!',
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getPrimaryButtonColor(isDarkMode),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                isDarkMode: isDarkMode,
                elapsedSeconds: elapsedSeconds,
                correct: _correct,
                errors: _errors,
                slow: _slowPenalties,
                ruleChanges: _ruleChanges,
              ),
              const SizedBox(height: 16),
              _SubmissionStatus(
                isDarkMode: isDarkMode,
                submitting: _submitting,
                success: _submissionSuccess,
                errorMessage: _submissionError,
                onRetry: (_finalScore != null && _finalElapsedSeconds != null)
                    ? () => _submitScore(_finalScore!, _finalElapsedSeconds!)
                    : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _bootstrapGame();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reiniciar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Tancar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitScore(double score, double elapsedSeconds) async {
    setState(() {
      _submitting = true;
      _submissionError = null;
    });
    try {
      final request = ActivityCompleteRequest(
        id: widget.activity.id,
        score: score,
        secondsToFinish: elapsedSeconds,
      );
      await ApiService.completeActivity(request);
      if (!mounted) return;
      setState(() {
        _submissionSuccess = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resultats enviats automàticament.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submissionError = e.toString();
        _submissionSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  double _calculateScore() {
    final bool hiddenCriteria = !_config.showHints;
    final totalAttemptsForAccuracy = hiddenCriteria
        ? max(1, _correct + _errorsAfterLearning)
        : max(1, _deck.length - _errorsDuringRuleChange);
    final accuracy = _correct / totalAttemptsForAccuracy;
    final streakBonus = min(
      _ruleChanges /
          (_deck.length / _config.correctAnswersToChangeRule + 0.01),
      1.0,
    );
    final normalizedDifficulty =
        (_config.difficulty.clamp(0.0, 5.0) / 5.0).clamp(0.0, 1.0);
    final double searchPenaltyWeight = hiddenCriteria
        ? 0
        : _config.errorPenaltyWeight * 0.35;
    final double masteryPenaltyWeight = hiddenCriteria
        ? _config.errorPenaltyWeight * 0.5
        : _config.errorPenaltyWeight;

    final effectiveExplorationErrors =
        max(0, _errorsWhileExploring - _errorsDuringRuleChange);
    final adjustedErrorPenalty =
        effectiveExplorationErrors * searchPenaltyWeight +
            _errorsAfterLearning * masteryPenaltyWeight;
    final adjustedSlowPenalty = _slowPenalties *
        _config.slowPenaltyWeight *
        (1 - 0.25 * normalizedDifficulty);

    final masteryBonus =
        hiddenCriteria && _errorsAfterLearning == 0 ? 0.6 : 0.0;

    final baseScore = (accuracy * 0.65 +
            streakBonus * 0.3 +
            normalizedDifficulty * 0.05) *
        10;
    final rawScore =
        baseScore - adjustedErrorPenalty - adjustedSlowPenalty + masteryBonus;
    return rawScore.clamp(0, 10);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final background = AppColors.getBackgroundGradient(isDarkMode);
    final currentScore = _calculateScore();
    final progress =
        _deck.isEmpty ? 0.0 : (_currentIndex / _deck.length).clamp(0.0, 1.0);

    final content = SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _GlassButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.activity.title,
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _config.variantName,
                        style: TextStyle(
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _GlassButton(
                  icon: isDarkMode
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round,
                  onPressed: _toggleTheme,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.getPrimaryButtonColor(isDarkMode),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getBlurContainerColor(isDarkMode)
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Puntuació ${currentScore.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_config.totalTimeLimit != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(
                          _remainingTime ?? _config.totalTimeLimit!,
                        ),
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: LinearProgressIndicator(
                            value: (_remainingTime?.inMilliseconds ?? 0) /
                                _config.totalTimeLimit!.inMilliseconds,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFE76F51),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_config.showHints && !_gameFinished)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _HintBanner(
                rule: _currentRule,
                isDarkMode: isDarkMode,
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal =
                    constraints.maxWidth > 900 && constraints.maxHeight > 500;
                final referenceBoard = _ReferenceBoard(
                  cards: _referenceCards,
                  currentRule: _currentRule,
                  config: _config,
                  onTap: _handleSelection,
                  isDarkMode: isDarkMode,
                );
                final playArea = _PlayArea(
                  card: _currentCard,
                  attempts: _recentAttempts,
                  isDarkMode: isDarkMode,
                  total: _deck.length,
                  currentIndex: _currentIndex,
                  showRule: _config.showHints,
                  reaction: _reactionStopwatch.elapsed,
                  slowThreshold: _config.slowThreshold,
                );

                if (horizontal) {
                  return Row(
                    children: [
                      Expanded(flex: 2, child: referenceBoard),
                      Expanded(flex: 3, child: playArea),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(child: referenceBoard),
                    Expanded(child: playArea),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: background)),
          ParticleSystemWidget(
            isDarkMode: isDarkMode,
            particleCount: 60,
            maxSize: 3,
            minSize: 1,
            speed: 0.5,
            maxOpacity: 0.5,
            minOpacity: 0.2,
          ),
          content,
          if (_instructionsVisible && !_gameFinished)
            _buildIntroOverlay(context),
        ],
      ),
    );
  }

  Widget _buildIntroOverlay(BuildContext context) {
    final surfaceColor =
        AppColors.getSecondaryBackgroundColor(isDarkMode).withOpacity(0.95);
    final ruleVisibility = _config.showHints
        ? 'Veus la pista de la regla actual (color, forma o nombre).'
        : 'No veuràs la regla: dedueix-la a partir dels encerts i errors.';
    final ruleChange = _config.warnBeforeRuleChange
        ? 'T\'avisarem abans de canviar la regla perquè et puguis adaptar.'
        : 'La regla pot canviar sense avís; segueix el feedback per detectar-ho.';
    final speed = _config.penalizeSlowResponses || _config.totalTimeLimit != null
        ? 'Hi ha límit de temps i les respostes lentes es penalitzen, així que sigues àgil.'
        : 'No hi ha penalització per temps; centra\'t en encertar la regla.';
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.55),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.getPrimaryButtonColor(isDarkMode)
                        .withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.containerShadow.withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.activity.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.activity.description,
                      style: TextStyle(
                        color: AppColors.getSecondaryTextColor(isDarkMode),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Com funciona',
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IntroBullet(text: ruleVisibility, isDarkMode: isDarkMode),
                        const SizedBox(height: 6),
                        _IntroBullet(text: ruleChange, isDarkMode: isDarkMode),
                        const SizedBox(height: 6),
                        _IntroBullet(text: speed, isDarkMode: isDarkMode),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  AppColors.getPrimaryButtonColor(isDarkMode),
                              side: BorderSide(
                                color: AppColors.getPrimaryButtonColor(isDarkMode)
                                    .withOpacity(0.7),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Sortir'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _startGameplay,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppColors.getPrimaryButtonColor(isDarkMode),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Començar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroBullet extends StatelessWidget {
  final String text;
  final bool isDarkMode;

  const _IntroBullet({
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: AppColors.getPrimaryButtonColor(isDarkMode),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class SortingVariantConfig {
  final String variantName;
  final bool showHints;
  final bool warnBeforeRuleChange;
  final bool resetRuleOnError;
  final bool penalizeSlowResponses;
  final Duration slowThreshold;
  final double slowPenaltyWeight;
  final double errorPenaltyWeight;
  final double difficulty;
  final Duration? totalTimeLimit;
  final int deckSize;
  final int correctAnswersToChangeRule;

  const SortingVariantConfig({
    required this.variantName,
    required this.showHints,
    required this.warnBeforeRuleChange,
    required this.resetRuleOnError,
    required this.penalizeSlowResponses,
    required this.slowThreshold,
    required this.slowPenaltyWeight,
    required this.errorPenaltyWeight,
    required this.difficulty,
    required this.totalTimeLimit,
    required this.deckSize,
    required this.correctAnswersToChangeRule,
  });

  static SortingVariantConfig fromActivity(Activity activity) {
    final blueprint =
        SortingBlueprintRegistry.resolve(activity.id, activity.difficulty);

    if (blueprint.difficulty <= 2) {
        return SortingVariantConfig(
          variantName: blueprint.title,
          showHints: true,
          warnBeforeRuleChange: true,
          resetRuleOnError: false,
          penalizeSlowResponses: false,
          slowThreshold: const Duration(seconds: 6),
          slowPenaltyWeight: 0,
          errorPenaltyWeight: 0.3,
          difficulty: blueprint.difficulty,
          totalTimeLimit: null,
          deckSize: 18,
          correctAnswersToChangeRule: 4,
        );
      } else if (blueprint.difficulty < 4) {
        return SortingVariantConfig(
        variantName: blueprint.title,
        showHints: false,
        warnBeforeRuleChange: false,
        resetRuleOnError: false,
        penalizeSlowResponses: false,
          slowThreshold: const Duration(seconds: 5),
          slowPenaltyWeight: 0,
          errorPenaltyWeight: 0.45,
          difficulty: blueprint.difficulty,
          totalTimeLimit: null,
          deckSize: 24,
          correctAnswersToChangeRule: 5,
        );
      } else {
        return SortingVariantConfig(
        variantName: blueprint.title,
        showHints: false,
        warnBeforeRuleChange: false,
        resetRuleOnError: false,
        penalizeSlowResponses: true,
          slowThreshold: const Duration(seconds: 3),
          slowPenaltyWeight: 0.4,
          errorPenaltyWeight: 0.5,
          difficulty: blueprint.difficulty,
          totalTimeLimit: const Duration(minutes: 2),
          deckSize: 28,
          correctAnswersToChangeRule: 4,
        );
    }
  }
}

enum SortingRule { color, shape, number }

extension SortingRuleText on SortingRule {
  String get label {
    switch (this) {
      case SortingRule.color:
        return 'Color';
      case SortingRule.shape:
        return 'Forma';
      case SortingRule.number:
        return 'Nombre';
    }
  }

  IconData get icon {
    switch (this) {
      case SortingRule.color:
        return Icons.palette_rounded;
      case SortingRule.shape:
        return Icons.category_rounded;
      case SortingRule.number:
        return Icons.onetwothree;
    }
  }
}

class SortingCardData {
  final String id;
  final Color color;
  final String colorName;
  final IconData icon;
  final String shapeName;
  final int count;

  const SortingCardData({
    required this.id,
    required this.color,
    required this.colorName,
    required this.icon,
    required this.shapeName,
    required this.count,
  });
}

class SortingAttempt {
  final SortingCardData card;
  final bool isCorrect;
  final SortingRule? ruleEvaluated;
  final Duration reactionTime;
  final bool wasSlow;

  SortingAttempt({
    required this.card,
    required this.isCorrect,
    required this.ruleEvaluated,
    required this.reactionTime,
    required this.wasSlow,
  });
}

class SortingPaletteColor {
  final String name;
  final Color color;

  const SortingPaletteColor(this.name, this.color);
}

class SortingShape {
  final String name;
  final IconData icon;

  const SortingShape(this.name, this.icon);
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDarkMode;

  const _GlassButton({
    required this.icon,
    required this.onPressed,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getBlurContainerColor(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.containerShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.getPrimaryTextColor(isDarkMode),
      ),
    );
  }
}

class _ReferenceBoard extends StatelessWidget {
  final List<SortingCardData> cards;
  final SortingRule currentRule;
  final SortingVariantConfig config;
  final bool isDarkMode;
  final ValueChanged<int> onTap;

  const _ReferenceBoard({
    required this.cards,
    required this.currentRule,
    required this.config,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cartes objectiu',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runSpacing: 16,
              spacing: 16,
              children: [
                for (int i = 0; i < cards.length; i++)
                  GestureDetector(
                    onTap: () => onTap(i),
                    child: _ReferenceCard(
                      data: cards[i],
                      highlightRule: config.showHints ? currentRule : null,
                      isDarkMode: isDarkMode,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  final SortingCardData data;
  final SortingRule? highlightRule;
  final bool isDarkMode;

  const _ReferenceCard({
    required this.data,
    required this.highlightRule,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final focused = highlightRule != null;
    final borderColor = focused
        ? data.color.withOpacity(0.9)
        : AppColors.getPrimaryButtonColor(isDarkMode).withOpacity(0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: focused ? 2.4 : 1.4),
        color:
            AppColors.getBlurContainerColor(isDarkMode).withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.25),
            blurRadius: focused ? 16 : 8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(
              data.count,
              (_) => Icon(
                data.icon,
                color: data.color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.colorName,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            data.shapeName,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 12,
            ),
          ),
          Text(
            '${data.count} símbols',
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayArea extends StatelessWidget {
  final SortingCardData? card;
  final List<SortingAttempt> attempts;
  final bool isDarkMode;
  final int total;
  final int currentIndex;
  final bool showRule;
  final Duration reaction;
  final Duration slowThreshold;

  const _PlayArea({
    required this.card,
    required this.attempts,
    required this.isDarkMode,
    required this.total,
    required this.currentIndex,
    required this.showRule,
    required this.reaction,
    required this.slowThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StatChip(
                icon: Icons.flag_rounded,
                label: 'Cartes',
                value: '${currentIndex + 1}/$total',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.speed_rounded,
                label: 'Reacció',
                value:
                    '${reaction.inMilliseconds ~/ 1000}.${(reaction.inMilliseconds % 1000) ~/ 100}s',
                highlight: reaction > slowThreshold,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: child,
                  );
                },
                child: card == null
                    ? const SizedBox.shrink()
                    : _CardFace(
                        key: ValueKey(card!.id),
                        data: card!,
                        isDarkMode: isDarkMode,
                        showRule: showRule,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Historial recent',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: attempts.length,
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _HistoryCard(
                    attempt: attempt,
                    isDarkMode: isDarkMode,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final bool isDarkMode;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.getBlurContainerColor(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? Colors.redAccent
                : AppColors.getPrimaryButtonColor(isDarkMode).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.getSecondaryTextColor(isDarkMode),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final SortingCardData data;
  final bool isDarkMode;
  final bool showRule;

  const _CardFace({
    super.key,
    required this.data,
    required this.isDarkMode,
    required this.showRule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            data.color.withOpacity(0.85),
            data.color.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              data.count,
              (_) => Icon(
                data.icon,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            data.colorName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          Text(
            data.shapeName,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            '${data.count} símbols',
            style: const TextStyle(color: Colors.white70),
          ),
          if (showRule) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lightbulb, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Utilitza les pistes a dalt per classificar.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SortingAttempt attempt;
  final bool isDarkMode;

  const _HistoryCard({
    required this.attempt,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.getBlurContainerColor(isDarkMode),
        border: Border.all(
          color: attempt.isCorrect ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(attempt.card.icon, color: attempt.card.color),
          const SizedBox(height: 6),
          Text(
            attempt.isCorrect ? 'Correcte' : 'Error',
            style: TextStyle(
              color:
                  attempt.isCorrect ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${attempt.reactionTime.inMilliseconds / 1000}s',
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 11,
            ),
          ),
          if (attempt.wasSlow)
            Text(
              'Lent',
              style: TextStyle(color: Colors.orange[200], fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  final SortingRule rule;
  final bool isDarkMode;

  const _HintBanner({
    required this.rule,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.getPrimaryButtonColor(isDarkMode).withOpacity(0.9),
            AppColors.getPrimaryButtonColor(isDarkMode).withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.getPrimaryButtonColor(isDarkMode)
                .withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(rule.icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pista visual: classifica segons ${rule.label.toLowerCase()}.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final bool isDarkMode;
  final double elapsedSeconds;
  final int correct;
  final int errors;
  final int slow;
  final int ruleChanges;

  const _SummaryRow({
    required this.isDarkMode,
    required this.elapsedSeconds,
    required this.correct,
    required this.errors,
    required this.slow,
    required this.ruleChanges,
  });

  @override
  Widget build(BuildContext context) {
    String formatTime(double seconds) {
      final duration = Duration(seconds: seconds.round());
      final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$secs';
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryChip(
          icon: Icons.timer,
          label: 'Temps',
          value: formatTime(elapsedSeconds),
          isDarkMode: isDarkMode,
        ),
        _SummaryChip(
          icon: Icons.check_circle,
          label: 'Encerts',
          value: '$correct',
          isDarkMode: isDarkMode,
        ),
        _SummaryChip(
          icon: Icons.close_rounded,
          label: 'Errors',
          value: '$errors',
          isDarkMode: isDarkMode,
        ),
        _SummaryChip(
          icon: Icons.speed_outlined,
          label: 'Lents',
          value: '$slow',
          isDarkMode: isDarkMode,
        ),
        _SummaryChip(
          icon: Icons.autorenew_rounded,
          label: 'Canvis',
          value: '$ruleChanges',
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDarkMode;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.getBlurContainerColor(isDarkMode),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.getPrimaryButtonColor(isDarkMode)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _SubmissionStatus extends StatelessWidget {
  final bool isDarkMode;
  final bool submitting;
  final bool success;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const _SubmissionStatus({
    required this.isDarkMode,
    required this.submitting,
    required this.success,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon;
    String text;
    Color textColor;

    if (submitting) {
      icon = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      text = 'Enviant resultats...';
      textColor = AppColors.getPrimaryTextColor(isDarkMode);
    } else if (success) {
      icon = const Icon(Icons.check_circle, color: Colors.greenAccent);
      text = 'Resultats enviats correctament.';
      textColor = Colors.greenAccent;
    } else if (errorMessage != null) {
      icon = const Icon(Icons.error_outline, color: Colors.orangeAccent);
      text = 'Error en l\'enviament: $errorMessage';
      textColor = Colors.orangeAccent;
    } else {
      icon = Icon(Icons.info_outline,
          color: AppColors.getPrimaryTextColor(isDarkMode));
      text = 'Resultats pendents d\'enviament.';
      textColor = AppColors.getPrimaryTextColor(isDarkMode);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getBlurContainerColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (errorMessage != null && onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: submitting ? null : onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Torna-ho a provar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SortingBlueprint {
  final String id;
  final String title;
  final String description;
  final double difficulty;

  SortingBlueprint({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
  });

  factory SortingBlueprint.fromJson(Map<String, dynamic> json) {
    return SortingBlueprint(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'WCST',
      description: json['description']?.toString() ?? '',
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SortingBlueprintRegistry {
  static final List<SortingBlueprint> _entries =
      _sortingBlueprintJson.map(SortingBlueprint.fromJson).toList();

  static SortingBlueprint resolve(String id, double difficulty) {
    return _entries.firstWhere(
      (entry) => entry.id == id,
      orElse: () {
        return SortingBlueprint(
          id: id,
          title: difficulty >= 4
              ? 'WCST avançat'
              : difficulty >= 2.5
                  ? 'WCST Estàndard'
                  : 'WCST Guiat',
          description: '',
          difficulty: difficulty,
        );
      },
    );
  }
}

const List<Map<String, dynamic>> _sortingBlueprintJson = [
  {
    'activity_type': 'sorting',
    'description':
        'Versió simplificada del test. L\'usuari ha de classificar cartes segons un criteri (color, forma o nombre). S\'ofereixen pistes visuals i el canvi de regla s\'avisa prèviament per reduir la frustració.',
    'difficulty': 1.5,
    'id': 'ed1f215e-69e8-48cb-bcf8-6eed7e1052e0',
    'title': 'WCST: Iniciació Guiada'
  },
  {
    'activity_type': 'sorting',
    'description':
        'La versió clàssica del test. L\'usuari ha de deduir la regla de classificació basant-se únicament en el feedback d\'encert o error. La regla canvia sense avís després d\'una sèrie d\'encerts consecutius.',
    'difficulty': 3,
    'id': '963361f5-7ea8-45e4-ace7-b9d6bb567998',
    'title': 'WCST: Pràctica Estàndard'
  },
  {
    'activity_type': 'sorting',
    'description':
        'Versió d\'alta exigència cognitiva. Els canvis de regles són més freqüents i sobtats. Es penalitzen els temps de reacció lents per estimular la velocitat de processament i la flexibilitat mental.',
    'difficulty': 4.8,
    'id': '1083340c-2a65-4a35-b292-c0f92829006d',
    'title': 'WCST: Desafiament de Flexibilitat'
  }
];
