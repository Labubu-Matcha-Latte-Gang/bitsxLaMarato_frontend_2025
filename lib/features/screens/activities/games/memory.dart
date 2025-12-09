import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/effects/particle_system.dart';

/// Memory (parejas) con cronómetro, contador de movimientos y puntuación.
/// Usa las 15 imágenes de `lib/features/screens/activities/cardsMemory/historic/`
/// generando 30 cartas (15 parejas).
class MemoryGame extends StatefulWidget {
  final bool isDarkMode;
  const MemoryGame({super.key, this.isDarkMode = false});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  late bool isDarkMode;

  // Lista de rutas de imágenes de las 15 cartas únicas.
  static const List<String> _cardImages = [
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

  // Reverso de carta.
  static const String _cardBack =
      'lib/features/screens/activities/cardsMemory/historic/reverso.png';

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

    // Crear 2 copias de cada imagen y barajar.
    final duplicated = <String>[];
    for (final img in _cardImages) {
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
    if (_secondSelection != null) return; // esperando cierre de cartas

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
        // Match
        setState(() {
          first.isMatched = true;
          second.isMatched = true;
          _matchedPairs += 1;
          _updateScore(isMatch: true);
        });
        _resetSelections();

        // Si todas las parejas encontradas, parar cronómetro.
        if (_matchedPairs == _cardImages.length) {
          _isRunning = false;
        }
      } else {
        // No match: voltear después de un pequeño delay para que el usuario vea.
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
    // Puntuación basada en eficiencia: recompensa matches, penaliza movimientos.
    // Fórmula sencilla y transparente.
    if (isMatch) {
      _score += 150; // bonus por encontrar pareja
      // Bono pequeño por velocidad: menos tiempo => más puntos
      _score += max(0, 50 - (_elapsedSeconds ~/ 5));
    } else {
      _score = max(0, _score - 30); // penalización por fallo
    }
    // Penalización ligera por movimiento extra para incentivar memoria
    _score = max(0, _score - (_moves ~/ 5));
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.getBackgroundGradient(isDarkMode),
            ),
          ),

          // Sistema de partículas
          ParticleSystemWidget(
            isDarkMode: isDarkMode,
            particleCount: 50,
            maxSize: 3.0,
            minSize: 1.0,
            speed: 0.5,
            maxOpacity: 0.6,
            minOpacity: 0.2,
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Header con botones
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón de back
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
                      // Título
                      Text(
                        'Memory - Monuments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                        ),
                      ),
                      // Botones de acción
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

                // Stats y grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  5, // 5 columnas x 6 filas = 30 cartas
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _cards.length,
                            itemBuilder: (context, index) {
                              final card = _cards[index];
                              return _MemoryCardWidget(
                                card: card,
                                cardBack: _cardBack,
                                onTap: () => _onCardTap(card),
                                isDarkMode: isDarkMode,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatChip(
          label: 'Temps',
          value: _formatTime(_elapsedSeconds),
          icon: Icons.timer,
        ),
        _StatChip(
          label: 'Moviments',
          value: _moves.toString(),
          icon: Icons.touch_app,
        ),
        _StatChip(
          label: 'Puntuació',
          value: _score.toString(),
          icon: Icons.star,
        ),
        _StatChip(
          label: 'Parelles',
          value: '$_matchedPairs/${_cardImages.length}',
          icon: Icons.check_circle_outline,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
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

  const _MemoryCardWidget({
    required this.card,
    required this.cardBack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: card.isFaceUp || card.isMatched
              ? Image.asset(card.imagePath, fit: BoxFit.cover)
              : Image.asset(cardBack, fit: BoxFit.cover),
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
