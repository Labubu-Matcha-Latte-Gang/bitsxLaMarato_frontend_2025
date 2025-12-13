import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/effects/particle_system.dart';
import '../../../../services/api_service.dart';
import '../../../../models/activity_models.dart' show ActivityCompleteRequest;

/// Memory Monuments: identical UI/logic as Memory, fixed to Monuments set.
class MemoryGameMonuments extends StatefulWidget {
  final bool isDarkMode;
  final String? activityId;

  const MemoryGameMonuments({
    super.key,
    this.isDarkMode = false,
    this.activityId,
  });

  @override
  State<MemoryGameMonuments> createState() => _MemoryGameMonumentsState();
}

class _MemoryGameMonumentsState extends State<MemoryGameMonuments> {
  late bool isDarkMode;

  static const List<String> _monumentsImages = [
    'lib/features/screens/activities/cardsMemory/historic/angkor-wat.png',
    'lib/features/screens/activities/cardsMemory/historic/atenas.png',
    'lib/features/screens/activities/cardsMemory/historic/aztecas.png',
    'lib/features/screens/activities/cardsMemory/historic/coliseo.png',
    'lib/features/screens/activities/cardsMemory/historic/eiffel.png',
    'lib/features/screens/activities/cardsMemory/historic/esfinge.png',
    'lib/features/screens/activities/cardsMemory/historic/estatua.libertad.png',
    'lib/features/screens/activities/cardsMemory/historic/jesucristo-brazil.png',
    'lib/features/screens/activities/cardsMemory/historic/meca.png',
    'lib/features/screens/activities/cardsMemory/historic/moai.png',
    'lib/features/screens/activities/cardsMemory/historic/muralla-china.png',
    'lib/features/screens/activities/cardsMemory/historic/piramides.png',
    'lib/features/screens/activities/cardsMemory/historic/sagrada-familia.png',
    'lib/features/screens/activities/cardsMemory/historic/stonehenge.png',
    'lib/features/screens/activities/cardsMemory/historic/taj-mahal.png',
  ];

  static const String _cardBack =
      'lib/features/screens/activities/cardsMemory/historic/reverso.png';

  List<String> get _currentImages => _monumentsImages;
  String get _currentCardBack => _cardBack;

  late List<_MemoryCard> _cards;
  _MemoryCard? _firstSelection;
  _MemoryCard? _secondSelection;

  int _moves = 0;
  int _matchedPairs = 0;
  int _score = 0;

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _startNewGame() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _moves = 0;
    _matchedPairs = 0;
    _score = 0;
    _isRunning = true;

    final duplicated = <String>[];
    for (final img in _currentImages) {
      duplicated
        ..add(img)
        ..add(img);
    }
    duplicated.shuffle(Random());

    _cards = List.generate(
      duplicated.length,
      (index) => _MemoryCard(id: index, imagePath: duplicated[index]),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRunning) return;
      setState(() => _elapsedSeconds++);
    });

    setState(() {
      _firstSelection = null;
      _secondSelection = null;
    });
  }

  void _onCardTap(_MemoryCard card) {
    if (!_isRunning || card.isMatched || card.isFaceUp) return;
    if (_secondSelection != null) return;

    setState(() {
      card.isFaceUp = true;
      if (_firstSelection == null) {
        _firstSelection = card;
      } else {
        _secondSelection = card;
        _moves += 1;
      }
    });

    if (_firstSelection != null && _secondSelection != null) {
      final first = _firstSelection!;
      final second = _secondSelection!;

      if (first.imagePath == second.imagePath) {
        setState(() {
          first.isMatched = true;
          second.isMatched = true;
          _matchedPairs += 1;
          _updateScore(isMatch: true);
        });
        _resetSelections();

        if (_matchedPairs == _currentImages.length) {
          _isRunning = false;
          Future.delayed(const Duration(milliseconds: 500), () {
            _showGameCompletedDialog();
          });
        }
      } else {
        _updateScore(isMatch: false);
        Future.delayed(const Duration(milliseconds: 900), () {
          setState(() {
            first.isFaceUp = false;
            second.isFaceUp = false;
            _resetSelections();
          });
        });
      }
    }
  }

  void _resetSelections() {
    _firstSelection = null;
    _secondSelection = null;
  }

  void _updateScore({required bool isMatch}) {
    final int optimalMoves = _currentImages.length;
    const double k = 0.6;

    if (_moves <= 0 || _moves <= optimalMoves) {
      _score = 100;
    } else {
      final ratio = optimalMoves / _moves;
      final double score10 = (10 * pow(ratio, k)).toDouble();
      final double clamped = score10.clamp(0.0, 10.0);
      _score = (clamped * 10).round();
    }
  }

  double getFinalScore() {
    return _score / 10.0;
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showGameCompletedDialog() {
    final time = _formatTime(_elapsedSeconds);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getBlurContainerColor(isDarkMode),
        title: Text(
          '¡Joc Completat!',
          style: TextStyle(
            color: _getAccentColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temps: $time'),
            const SizedBox(height: 8),
            Text('Moviments: $_moves'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: Text(
              'Jugar de Nou',
              style:
                  TextStyle(color: AppColors.getPrimaryTextColor(isDarkMode)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.activityId != null) {
                _submitScore(getFinalScore());
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getAccentColor(),
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar Resultats'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitScore(double score) async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.getBlurContainerColor(isDarkMode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_getAccentColor()),
              ),
              const SizedBox(height: 16),
              Text(
                'Enviant resultats...',
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      );

      final request = ActivityCompleteRequest(
        id: widget.activityId!,
        score: score,
        secondsToFinish: _elapsedSeconds.toDouble(),
      );

      final response = await ApiService.completeActivity(request);

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.getBlurContainerColor(isDarkMode),
          title: Text(
            'Resultats Enviats',
            style: TextStyle(
              color: _getAccentColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Els resultats s\'han registrat correctament.',
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Resposta de l\'API:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Activitat: ${response.activity.title}',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                ),
              ),
              Text(
                'Puntuació: ${response.score.toStringAsFixed(1)}/10',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                ),
              ),
              Text(
                'Temps: ${(response.secondsToFinish / 60).floor()}:${(response.secondsToFinish % 60).round().toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                ),
              ),
              if (response.completedAt != null)
                Text(
                  'Completat: ${response.completedAt!.day}/${response.completedAt!.month}/${response.completedAt!.year} ${response.completedAt!.hour}:${response.completedAt!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: AppColors.getSecondaryTextColor(isDarkMode),
                  ),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getAccentColor(),
                foregroundColor: Colors.white,
              ),
              child: const Text('Acceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.getBlurContainerColor(isDarkMode),
          title: Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'No s\'ha pogut enviar els resultats: $e',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: _getAccentColor(),
              ),
              child: const Text('Acceptar'),
            ),
          ],
        ),
      );
    }
  }

  Color _getAccentColor() {
    return isDarkMode ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                            Icons.arrow_back,
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Text(
                        'Memory (Monuments)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  AppColors.getBlurContainerColor(isDarkMode),
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
                                Icons.refresh,
                                color:
                                    AppColors.getPrimaryTextColor(isDarkMode),
                              ),
                              onPressed: _startNewGame,
                              tooltip: 'Reiniciar',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  AppColors.getBlurContainerColor(isDarkMode),
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
                                color:
                                    AppColors.getPrimaryTextColor(isDarkMode),
                              ),
                              onPressed: _toggleTheme,
                              tooltip: 'Canviar tema',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availableHeight = constraints.maxHeight;
                              final availableWidth = constraints.maxWidth;
                              final cardWidth = (availableWidth - (4 * 8)) / 5;
                              final cardHeight = cardWidth / 0.72;
                              final totalHeight = (cardHeight * 6) + (5 * 8);
                              final finalAspectRatio =
                                  totalHeight > availableHeight
                                      ? (availableWidth - (4 * 8)) /
                                          5 /
                                          ((availableHeight - (5 * 8)) / 6)
                                      : 0.72;

                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: finalAspectRatio,
                                ),
                                itemCount: _cards.length,
                                itemBuilder: (context, index) {
                                  final card = _cards[index];
                                  return _MemoryCardWidget(
                                    card: card,
                                    cardBack: _currentCardBack,
                                    onTap: () => _onCardTap(card),
                                    isDarkMode: isDarkMode,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _StatChip(
            label: 'Temps',
            value: _formatTime(_elapsedSeconds),
            icon: Icons.timer,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'Moviments',
            value: _moves.toString(),
            icon: Icons.touch_app,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'Parelles',
            value: '$_matchedPairs/${_currentImages.length}',
            icon: Icons.check_circle_outline,
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDarkMode;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getBlurContainerColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.containerShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.getPrimaryTextColor(isDarkMode),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemoryCardWidget extends StatelessWidget {
  final _MemoryCard card;
  final String cardBack;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _MemoryCardWidget({
    required this.card,
    required this.cardBack,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: AppColors.containerShadow,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          color: AppColors.getSecondaryBackgroundColor(isDarkMode),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: card.isFaceUp || card.isMatched
              ? Image.asset(
                  card.imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                )
              : Image.asset(
                  cardBack,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
        ),
      ),
    );
  }
}

class _MemoryCard {
  final int id;
  final String imagePath;
  bool isFaceUp = false;
  bool isMatched = false;

  _MemoryCard({
    required this.id,
    required this.imagePath,
  });
}
