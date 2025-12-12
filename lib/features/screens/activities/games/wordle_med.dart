import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../utils/effects/particle_system.dart';
import '../../../../utils/app_colors.dart';
import '../recommended_activities_page.dart';

// Wordle game screen: 8 tries, 5-letter words.
class WordleScreen extends StatefulWidget {
  final bool isDarkMode;
  const WordleScreen({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

enum LetterState { initial, correct, present, absent }

class _WordleScreenState extends State<WordleScreen>
    with SingleTickerProviderStateMixin {
  static const int rows = 6; // changed to 6 guesses x 5 columns (classic Wordle)
  static const int cols = 5;

  // Shake animation controller for invalid-word feedback
  late AnimationController _shakeController;

  // Note: word list removed — secret word will be chosen from med_words.json

  late String secretWord;
  List<String> guesses = [];
  String currentGuess = '';
  Map<String, LetterState> keyStates = {};
  bool isDark = false;
  List<String>? _dictionary;
  Set<String>? _dictionarySet;
  List<String>? _medWords;

  // Gameplay stats (previously removed) — keep them here so other parts of the file compile
  int invalidWordCount = 0;
  int incorrectGuessCount = 0;

  @override
  void initState() {
    super.initState();
    isDark = widget.isDarkMode;
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    // Load dictionaries first, then start the game so we can prefer easy words
    _loadDictionary().whenComplete(() {
      // After the first frame, show difficulty selector before starting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDialog();
      });
    });
  }

  Future<void> _loadDictionary() async {
    try {
      final raw = await rootBundle.loadString(
          'lib/features/screens/activities/dictionary/words_sorted.json');
      // JSON might be a list or newline-separated. Try to parse as JSON first.
      List<String> words = [];
      try {
        final decoded = raw.trim();
        if (decoded.startsWith('[')) {
          final List<dynamic> arr =
          (await Future.value(jsonDecode(decoded))) as List<dynamic>;
          words = arr.map((e) => e.toString().toUpperCase()).toList();
        } else {
          // Fallback: treat as newline-separated text
          words = decoded
              .split(RegExp(r"\r?\n"))
              .where((s) => s.trim().isNotEmpty)
              .map((s) => s.trim().toUpperCase())
              .toList();
        }
      } catch (e) {
        // fallback to newline split
        words = raw
            .split(RegExp(r"\r?\n"))
            .where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim().toUpperCase())
            .toList();
      }

      // Ensure sorted and create a Set for O(1) lookups
      words.sort();
      _dictionary = words;
      _dictionarySet = words.map((w) => w.toUpperCase()).toSet();
      // Try loading easy words as well (optional)
      try {
        final rawEasy = await rootBundle.loadString(
            'lib/features/screens/activities/dictionary/med_words.json');
        final List<dynamic> arr2 = jsonDecode(rawEasy) as List<dynamic>;
        _medWords = arr2.map((e) => e.toString().toUpperCase()).toList();
      } catch (_) {
        _medWords = null;
      }
      // print('Loaded dictionary with ${words.length} words');
    } catch (e) {
      // ignore failures — dictionary remains null
      _dictionary = null;
      print('Warning: failed to load dictionary asset: $e');
    }
  }

  void _startNewGame() {
    // Choose secret word exclusively from med_words.json if available.
    // If med_words.json is missing or empty, fall back to a fixed default.
    // (Removed an unnecessary if that caused an unmatched brace)
    // Reset stats for the new game
    invalidWordCount = 0;
    incorrectGuessCount = 0;

    // Set the pool to the easy words list since this is the easy version.
    List<String>? pool = _medWords;

    if (pool != null && pool.isNotEmpty) {
      final copy = List<String>.from(pool);
      copy.shuffle();
      secretWord = copy.first.toUpperCase();
      // Optionally set validation to pool; keep full dictionary validation by default so guesses from other lists are accepted
      // _dictionarySet = copy.map((w) => w.toUpperCase()).toSet();
    } else if (_dictionary != null && _dictionary!.isNotEmpty) {
      final copy = List<String>.from(_dictionary!);
      copy.shuffle();
      secretWord = copy.first.toUpperCase();
    } else if (_medWords != null && _medWords!.isNotEmpty) {
      final copy = List<String>.from(_medWords!);
      copy.shuffle();
      secretWord = copy.first.toUpperCase();
    } else {
      // Default secret when med_words isn't available
      secretWord = 'VISIO';
    }
    guesses = [];
    currentGuess = '';
    keyStates.clear();
    for (var c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++)
      keyStates[String.fromCharCode(c)] = LetterState.initial;
    setState(() {});
  }

  // Show dialog
  Future<void> _showDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Benvingut al Wordle!'),
          content: StatefulBuilder(builder: (ctx, setState) {
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8),
                Text('Aquí ens trobem en la versió mitjana.\n'),
                Text('Intenta endevinar la paraula secreta en només 6 intents. Només es poden utilitzar paraules de 5 lletres del català.\n'),
                Text('Bona sort!'),
              ],
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startNewGame();
              },
              child: const Text('Acceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  void _onKeyTap(String key) {
    if (guesses.length >= rows) return;
    if (key == 'ENTER') {
      _submitGuess();
      return;
    }
    if (key == 'BACK') {
      _backspace();
      return;
    }
    if (currentGuess.length >= cols) return;
    setState(() {
      currentGuess += key;
    });
  }

  void _backspace() {
    if (currentGuess.isEmpty) return;
    setState(() {
      currentGuess = currentGuess.substring(0, currentGuess.length - 1);
    });
  }

  void _submitGuess() {
    if (currentGuess.length != cols) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a 5-letter word')),
      );
      return;
    }
    final guess = currentGuess.toUpperCase();
    // If dictionary loaded, validate word exists
    if (_dictionary != null) {
      if (!_isValidWord(guess)) {
        // Count invalid / non-existing word attempts
        invalidWordCount++;
        // Provide immediate feedback by shaking the current row
        _triggerInvalidWordFeedback();
        return;
      }
    }
    // Optionally enforce dictionary (not enforced here)
    final results = _evaluateGuess(guess, secretWord);

    // Count valid but incorrect guesses
    if (guess != secretWord) {
      incorrectGuessCount++;
    }

    // Update keyStates
    for (int i = 0; i < cols; i++) {
      final ch = guess[i];
      final res = results[i];
      final prev = keyStates[ch] ?? LetterState.initial;
      // Upgrades only (initial -> present -> correct)
      if (prev == LetterState.correct) continue;
      if (res == LetterState.correct) {
        keyStates[ch] = LetterState.correct;
      } else if (res == LetterState.present) {
        if (prev != LetterState.correct) keyStates[ch] = LetterState.present;
      } else {
        if (prev == LetterState.initial) keyStates[ch] = LetterState.absent;
      }
    }

    setState(() {
      guesses = List.from(guesses)..add(guess);
      currentGuess = '';
    });

    if (guess == secretWord) {
      _showResultDialog(won: true);
    } else if (guesses.length >= rows) {
      _showResultDialog(won: false);
    }
  }

  // Wordle evaluation with duplicate handling.
  List<LetterState> _evaluateGuess(String guess, String solution) {
    final res = List<LetterState>.filled(cols, LetterState.absent);
    final solChars = solution.split('');
    final guessChars = guess.split('');

    // First pass: correct letters
    for (int i = 0; i < cols; i++) {
      if (guessChars[i] == solChars[i]) {
        res[i] = LetterState.correct;
        solChars[i] = '#'; // mark used
      }
    }

    // Count remaining letters in solution
    final Map<String, int> counts = {};
    for (final c in solChars) {
      if (c == '#') continue;
      counts[c] = (counts[c] ?? 0) + 1;
    }

    // Second pass: present (yellow) if still available
    for (int i = 0; i < cols; i++) {
      if (res[i] == LetterState.correct) continue;
      final c = guessChars[i];
      final cnt = counts[c] ?? 0;
      if (cnt > 0) {
        res[i] = LetterState.present;
        counts[c] = cnt - 1;
      } else {
        res[i] = LetterState.absent;
      }
    }

    return res;
  }

  Color _colorForState(LetterState s) {
    // Use AppColors/theme-aware colors so tiles adapt when toggling the theme
    switch (s) {
      case LetterState.correct:
        return Colors.green.shade600;
      case LetterState.present:
        return Colors.yellow.shade700;
      case LetterState.absent:
        return isDark ? Colors.grey.shade800 : Colors.grey.shade400;
      case LetterState.initial:
        return AppColors.getFieldBackgroundColor(isDark);
    }
  }

  bool _isValidWord(String word) {
    if (_dictionarySet == null)
      return true; // if dictionary not loaded, accept all
    return _dictionarySet!.contains(word);
  }

  void _triggerInvalidWordFeedback() {
    try {
      _shakeController.forward(from: 0.0);
    } catch (_) {}
  }


  // Centered results dialog showing statistics and an Accept button that returns
  // the user to the Recommended Activities page.
  void _showResultDialog({required bool won}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final title = won ? 'Has guanyat!' : 'Final';
        final message = won
            ? 'Ho has aconseguit en ${guesses.length} intents.'
            : 'No has encertat. La paraula era $secretWord.';
        return AlertDialog(
          title: Text(title, style: TextStyle(color: AppColors.getPrimaryTextColor(isDark))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
              const SizedBox(height: 12),
              Text('Nombre d\'intents: ${guesses.length}', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
              Text('Intents incorrectes vàlids: $incorrectGuessCount', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
              Text('Paraules no existents: $invalidWordCount', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
            ],
          ),
          backgroundColor: AppColors.getSecondaryBackgroundColor(isDark),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                // Navigate back to Recommended Activities page
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => RecommendedActivitiesPage(initialDarkMode: isDark)));
              },
              child: Text('Acceptar', style: TextStyle(color: AppColors.getPrimaryButtonColor(isDark))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = isDark ? ThemeData.dark() : ThemeData.light();

    Widget buildGrid(double maxWidth) {
      final tileSize = maxWidth / cols;

      return SizedBox(
        width: tileSize * cols,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (r) {
            final isCurrent = r == guesses.length;
            final rowGuess = r < guesses.length
                ? guesses[r]
                : (isCurrent ? currentGuess : '');
            List<LetterState> states =
            List.generate(cols, (_) => LetterState.initial);
            if (r < guesses.length) states = _evaluateGuess(guesses[r], secretWord);

            // Build the row tiles
            Widget rowTiles() {
              return Row(
                children: List.generate(cols, (c) {
                  final ch = c < rowGuess.length ? rowGuess[c] : '';
                  final state = (r < guesses.length) ? states[c] : LetterState.initial;

                  final bgColor = (r < guesses.length)
                      ? _colorForState(state)
                      : (isCurrent && c < currentGuess.length)
                      ? AppColors.getPrimaryButtonColor(isDark).withAlpha((0.18 * 255).round())
                      : AppColors.getSecondaryBackgroundColor(isDark);

                  final fgColor = (r < guesses.length)
                      ? ((state == LetterState.correct || state == LetterState.present)
                      ? Colors.white
                      : AppColors.getPrimaryTextColor(isDark))
                      : AppColors.getPrimaryTextColor(isDark);

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (r < guesses.length) ? Colors.transparent : Colors.grey.shade500,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          ch.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.6,
                            fontSize: tileSize * 0.33,
                            color: fgColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }

            // Wrap the current row in the shake AnimatedBuilder, otherwise just show the row
            return SizedBox(
              height: tileSize,
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  double dx = 0.0;
                  if (isCurrent && _shakeController.isAnimating) {
                    final t = _shakeController.value;
                    dx = sin(t * pi * 8) * 10 * (1 - t);
                  }
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: rowTiles(),
              ),
            );
          }),
        ),
      );
    }

    return Theme(
      data: theme,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.getBackgroundGradient(isDark),
                ),
              ),
            ),
            Positioned.fill(
              // Match the particle theme used in Login / Activities pages for visual consistency
              child: ParticleSystemWidget(
                isDarkMode: isDark,
                particleCount: 50,
                maxSize: 3.0,
                minSize: 1.0,
                speed: 0.5,
                maxOpacity: 0.6,
                minOpacity: 0.2,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Top bar: back, reload, theme (styled like LoginScreen)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button (styled)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.getBlurContainerColor(isDark),
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
                              color: AppColors.getPrimaryTextColor(isDark),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        // Right-side controls: reload + theme
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Reload button
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.getBlurContainerColor(isDark),
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
                                  color: AppColors.getPrimaryTextColor(isDark),
                                ),
                                onPressed: _startNewGame,
                                tooltip: 'New game',
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Theme toggle
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.getBlurContainerColor(isDark),
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
                                  isDark
                                      ? Icons.wb_sunny
                                      : Icons.nightlight_round,
                                  color: AppColors.getPrimaryTextColor(isDark),
                                ),
                                onPressed: _toggleTheme,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(builder: (context, constraints) {
                        final maxWidth =
                        min(constraints.maxWidth * 0.95, 560.0);
                        return buildGrid(maxWidth);
                      }),
                    ),
                  ),

                  // Keyboard
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(builder: (ctx) {
                      // Slightly smaller keys and margins for mobile so the full keyboard fits on screen
                      final keySize =
                      min(40.0, MediaQuery.of(ctx).size.width / 12);

                      Widget keyWidget(String k) {
                        final state = keyStates[k] ?? LetterState.initial;
                        final color = _colorForState(state);
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 1.5, vertical: 2.5),
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.grey.shade500, width: 1)),
                          child: InkWell(
                            onTap: () => _onKeyTap(k),
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                                width: keySize,
                                height: keySize,
                                child: Center(
                                    child: Text(k,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                            fontSize: keySize * 0.34,
                                            color: (state ==
                                                LetterState.correct ||
                                                state ==
                                                    LetterState.present)
                                                ? Colors.white
                                                : AppColors.getPrimaryTextColor(
                                                isDark))))),
                          ),
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            ...'QWERTYUIOP'
                                .split('')
                                .map((k) => keyWidget(k))
                                .toList()
                          ]),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            ...'ASDFGHJKL'
                                .split('')
                                .map((k) => keyWidget(k))
                                .toList()
                          ]),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            ...'ZXCVBNM'
                                .split('')
                                .map((k) => keyWidget(k))
                                .toList()
                          ]),
                          const SizedBox(height: 12),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5, vertical: 2.5),
                                decoration: BoxDecoration(
                                    color:
                                    AppColors.getPrimaryButtonColor(isDark),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.grey.shade500, width: 1)),
                                child: InkWell(
                                    onTap: () => _onKeyTap('ENTER'),
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                        width: keySize * 2.2,
                                        height: keySize,
                                        child: Center(
                                            child: Text('ENTER',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: -0.5,
                                                    fontSize: keySize * 0.34,
                                                    color: Colors.white)))))),
                            const SizedBox(width: 6),
                            // Backspace icon instead of text label
                            Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5, vertical: 2.5),
                                decoration: BoxDecoration(
                                    color:
                                    AppColors.getPrimaryButtonColor(isDark),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.grey.shade500, width: 1)),
                                child: InkWell(
                                    onTap: () => _onKeyTap('BACK'),
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                        width: keySize * 2.2,
                                        height: keySize,
                                        child: Center(
                                            child: Icon(
                                                Icons.backspace_outlined,
                                                color: Colors.white,
                                                size: keySize * 0.48))))),
                          ])
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
