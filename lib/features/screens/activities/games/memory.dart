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
  String _selectedMode = 'Animals'; // Modalidad actual

  // Modalidad: Monuments
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

  // Modalidad: Animals
  static const List<String> _animalsImages = [
    'lib/features/screens/activities/cardsMemory/animales/aguila.png',
    'lib/features/screens/activities/cardsMemory/animales/ballena.png',
    'lib/features/screens/activities/cardsMemory/animales/cerdo.png',
    'lib/features/screens/activities/cardsMemory/animales/cuervo.png',
    'lib/features/screens/activities/cardsMemory/animales/elefante.png',
    'lib/features/screens/activities/cardsMemory/animales/gallina.png',
    'lib/features/screens/activities/cardsMemory/animales/iguana.png',
    'lib/features/screens/activities/cardsMemory/animales/jirafa.png',
    'lib/features/screens/activities/cardsMemory/animales/leon.png',
    'lib/features/screens/activities/cardsMemory/animales/loro.png',
    'lib/features/screens/activities/cardsMemory/animales/panda.png',
    'lib/features/screens/activities/cardsMemory/animales/pantera.png',
    'lib/features/screens/activities/cardsMemory/animales/rinoceronte.png',
    'lib/features/screens/activities/cardsMemory/animales/tiburon.png',
    'lib/features/screens/activities/cardsMemory/animales/vaca.png',
  ];

  static const Map<String, List<String>> _modeImages = {
    'Monuments': _monumentsImages,
    'Animals': _animalsImages,
  };

  static const Map<String, String> _modeBacks = {
    'Monuments':
        'lib/features/screens/activities/cardsMemory/historic/reverso.png',
    'Animals':
        'lib/features/screens/activities/cardsMemory/animales/reverso-animales.png',
  };

  List<String> get _currentImages =>
      _modeImages[_selectedMode] ?? _modeImages['Monuments']!;

  String get _currentCardBack =>
      _modeBacks[_selectedMode] ?? _modeBacks['Monuments']!;

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
        if (_matchedPairs == _currentImages.length) {
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
    // Puntuación sobre 10 basada en eficiencia de movimientos.
    // Movimientos óptimos = 15 (número de parejas).
    // Fórmula: 10 - (movimientos - 15) * penalización, con mínimo de 0.
    const int optimalMoves = 15;
    const double penaltyPerExtraMove = 0.3;

    if (_moves >= optimalMoves) {
      final extraMoves = _moves - optimalMoves;
      _score = max(0, (10 - (extraMoves * penaltyPerExtraMove) * 10).round());
    } else {
      _score = 100; // 10.0 en escala de 100 para mantener int
    }
  }

  // Obtener puntuación final sobre 10 para enviar al backend
  double getFinalScore() {
    return _score / 10.0;
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
                      // Título y selector de modalidad
                      Row(
                        children: [
                          Text(
                            'Memory',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getPrimaryTextColor(isDarkMode),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.getBlurContainerColor(isDarkMode),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.containerShadow,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedMode,
                                isDense: true,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color:
                                      AppColors.getPrimaryTextColor(isDarkMode),
                                  size: 20,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      AppColors.getPrimaryTextColor(isDarkMode),
                                  fontWeight: FontWeight.w600,
                                ),
                                dropdownColor:
                                    AppColors.getBlurContainerColor(isDarkMode),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Monuments',
                                    child: Text('Monuments'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Animals',
                                    child: Text('Animals'),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedMode = newValue;
                                      // Aquí se puede reiniciar el juego con la nueva modalidad
                                      _startNewGame();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calcular aspect ratio ajustado para cartas más anchas
                              // Aspect ratio típico de cartas de juego es ~0.7 (ancho/alto)
                              final availableHeight = constraints.maxHeight;
                              final availableWidth = constraints.maxWidth;

                              // Calcular basándose en un aspect ratio fijo de carta (0.65)
                              // que hace las cartas un poco más anchas
                              final cardWidth = (availableWidth - (4 * 8)) / 5;
                              final cardHeight = cardWidth /
                                  0.65; // Aspect ratio de carta más ancha

                              // Verificar que cabe en altura
                              final totalHeight = (cardHeight * 6) + (5 * 8);
                              final finalAspectRatio =
                                  totalHeight > availableHeight
                                      ? (availableWidth - (4 * 8)) /
                                          5 /
                                          ((availableHeight - (5 * 8)) / 6)
                                      : 0.65;

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
