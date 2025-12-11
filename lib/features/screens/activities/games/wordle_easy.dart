import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../utils/effects/particle_system.dart';
import '../../../../utils/app_colors.dart';
import '../recommended_activities_page.dart';

// Wordle game screen: 8 tries, 5-letter words.
class WordleScreen extends StatefulWidget {
<<<<<<< Updated upstream
  const WordleScreen({Key? key}) : super(key: key);
=======
  final bool isDarkMode;
  const WordleScreen({Key? key, this.isDarkMode = false}) : super(key: key);
>>>>>>> Stashed changes

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

enum LetterState { initial, correct, present, absent }

class _WordleScreenState extends State<WordleScreen>
    with SingleTickerProviderStateMixin {
<<<<<<< Updated upstream
  static const int rows = 6; // changed to 6 guesses x 5 columns (classic Wordle)
  static const int cols = 5;

  // Shake animation controller for invalid-word feedback
  late AnimationController _shakeController;

=======
  static const int rows =
      6; // changed to 6 guesses x 5 columns (classic Wordle)
  static const int cols = 5;

>>>>>>> Stashed changes
  // Note: word list removed — secret word will be chosen from easy_words.json

  late String secretWord;
  List<String> guesses = [];
  String currentGuess = '';
  Map<String, LetterState> keyStates = {};
  bool isDarkMode = false;
  // The codebase uses `isDark` in many places; keep a local alias to avoid
  // breaking existing references.
  bool isDark = false;
  List<String>? _dictionary;
  Set<String>? _dictionarySet;
  List<String>? _easyWords;
<<<<<<< Updated upstream
  List<String>? _medWords;
  List<String>? _hardWords;

  double difficulty = 2.0;

  // Gameplay stats (previously removed) — keep them here so other parts of the file compile
  int invalidWordCount = 0;
  int incorrectGuessCount = 0;
=======
>>>>>>> Stashed changes

  // Shake animation for invalid-word feedback
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  int _shakingRow = -1;

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    // Load dictionaries first, then start the game so we can prefer easy words
    _loadDictionary().whenComplete(() {
      // After the first frame, show difficulty selector before starting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDifficultyDialog();
      });
=======
    isDark = widget.isDarkMode;
    // Load dictionaries first, then start the game so we can prefer easy words
    _loadDictionary().whenComplete(() {
      _startNewGame();
>>>>>>> Stashed changes
    });

    // Setup shake animation controller
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset after animation
        setState(() {
          _shakingRow = -1;
        });
      }
    });
  }

  Future<void> _loadDictionary() async {
    try {
<<<<<<< Updated upstream
      final raw = await rootBundle.loadString('lib/features/screens/activities/dictionary/words_sorted.json');
=======
      final raw = await rootBundle.loadString(
          'lib/features/screens/activities/dictionary/words_sorted.json');
>>>>>>> Stashed changes
      // JSON might be a list or newline-separated. Try to parse as JSON first.
      List<String> words = [];
      try {
        final decoded = raw.trim();
        if (decoded.startsWith('[')) {
<<<<<<< Updated upstream
          final List<dynamic> arr = (await Future.value(jsonDecode(decoded))) as List<dynamic>;
          words = arr.map((e) => e.toString().toUpperCase()).toList();
        } else {
          // Fallback: treat as newline-separated text
          words = decoded.split(RegExp(r"\r?\n")).where((s) => s.trim().isNotEmpty).map((s) => s.trim().toUpperCase()).toList();
        }
      } catch (e) {
        // fallback to newline split
        words = raw.split(RegExp(r"\r?\n")).where((s) => s.trim().isNotEmpty).map((s) => s.trim().toUpperCase()).toList();
=======
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
>>>>>>> Stashed changes
      }

      // Ensure sorted and create a Set for O(1) lookups
      words.sort();
      _dictionary = words;
      _dictionarySet = words.map((w) => w.toUpperCase()).toSet();
      // Try loading easy words as well (optional)
      try {
<<<<<<< Updated upstream
        final rawEasy = await rootBundle.loadString('lib/features/screens/activities/dictionary/easy_words.json');
=======
        final rawEasy = await rootBundle.loadString(
            'lib/features/screens/activities/dictionary/easy_words.json');
>>>>>>> Stashed changes
        final List<dynamic> arr2 = jsonDecode(rawEasy) as List<dynamic>;
        _easyWords = arr2.map((e) => e.toString().toUpperCase()).toList();
      } catch (_) {
        _easyWords = null;
      }
<<<<<<< Updated upstream
      // Try loading medium words
      try {
        final rawMed = await rootBundle.loadString('lib/features/screens/activities/dictionary/med_words.json');
        final List<dynamic> arr3 = jsonDecode(rawMed) as List<dynamic>;
        _medWords = arr3.map((e) => e.toString().toUpperCase()).toList();
      } catch (_) {
        _medWords = null;
      }
      // Try loading hard words
      try {
        final rawHard = await rootBundle.loadString('lib/features/screens/activities/dictionary/hard_words.json');
        final List<dynamic> arr4 = jsonDecode(rawHard) as List<dynamic>;
        _hardWords = arr4.map((e) => e.toString().toUpperCase()).toList();
      } catch (_) {
        _hardWords = null;
      }
=======
>>>>>>> Stashed changes
      // print('Loaded dictionary with ${words.length} words');
    } catch (e) {
      // ignore failures — dictionary remains null
      _dictionary = null;
      print('Warning: failed to load dictionary asset: $e');
    }
  }

  void _startNewGame() {
<<<<<<< Updated upstream
    // Reset stats for the new game
    invalidWordCount = 0;
    incorrectGuessCount = 0;

    // Choose pool according to difficulty:
    // difficulty <= 1.5 -> easy
    // difficulty in [2.0, 3.5] -> medium
    // difficulty > 4.0 -> hard
    List<String>? pool;
    if (difficulty <= 1.5) {
      pool = _easyWords;
    } else if (difficulty >= 2.0 && difficulty <= 3.5) {
      pool = _medWords;
    } else if (difficulty > 4.0) {
      pool = _hardWords;
    } else {
      // For intermediate values not explicitly mapped, fall back to the general dictionary if available
      pool = _dictionary ?? _easyWords;
    }

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
    } else if (_easyWords != null && _easyWords!.isNotEmpty) {
=======
    // Choose secret exclusively from easy_words.json if available.
    // If easy_words.json is missing or empty, fall back to a fixed default.
    if (_easyWords != null && _easyWords!.isNotEmpty) {
>>>>>>> Stashed changes
      final copy = List<String>.from(_easyWords!);
      copy.shuffle();
      secretWord = copy.first.toUpperCase();
    } else {
<<<<<<< Updated upstream
<<<<<<< Updated upstream:lib/features/screens/activities/games/wordle.dart
      secretWord = 'APPLE';
=======
      // Default secret when easy_words isn't available
      secretWord = 'VIOLA';
>>>>>>> Stashed changes:lib/features/screens/activities/games/wordle_easy.dart
=======
      // Default secret when easy_words isn't available
      secretWord = 'VIOLA';
>>>>>>> Stashed changes
    }
    guesses = [];
    currentGuess = '';
    keyStates.clear();
<<<<<<< Updated upstream
    for (var c = 'A'.codeUnitAt(0);
        c <= 'Z'.codeUnitAt(0);
        c++) keyStates[String.fromCharCode(c)] = LetterState.initial;
    setState(() {});
  }

  // Show difficulty selector dialog with 0.5 increments
  Future<void> _showDifficultyDialog() async {
    double temp = difficulty;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona la dificultat'),
          content: StatefulBuilder(builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Dificultat: ${temp.toStringAsFixed(1)}'),
                Slider(
                  value: temp,
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  label: temp.toStringAsFixed(1),
                  onChanged: (v) => setState(() => temp = v),
                ),
                const SizedBox(height: 8),
                Text('0.0 = fàcil, 5.0 = difícil'),
              ],
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                // snap to nearest 0.5 and start
                difficulty = (temp * 2).round() / 2.0;
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

=======
    for (var c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++)
      keyStates[String.fromCharCode(c)] = LetterState.initial;
    setState(() {});
  }

>>>>>>> Stashed changes
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

  void _triggerInvalidWordAnimation() {
    setState(() {
      _shakingRow = guesses.length; // animate current row
    });
    _shakeController.forward(from: 0.0);
  }

  void _showEndDialog({required bool won}) {
    final attempts = guesses.length;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            won ? 'Has guanyat!' : 'Final',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(won
                  ? 'Has endevinat la paraula en $attempts intent(s).'
                  : 'No has encertat. La paraula era $secretWord.'),
              const SizedBox(height: 12),
              // simple stats: list of guesses
              Text('Intent(s):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...guesses.map((g) => Text(g)).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Navigate back to RecommendedActivitiesPage
                Navigator.of(ctx).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        // Use the recommended activities page as requested
                        // Pass current theme preference
                        RecommendedActivitiesPage(initialDarkMode: isDark),
                  ),
                );
              },
              child: const Text('Acceptar'),
            ),
          ],
        );
      },
    );
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
<<<<<<< Updated upstream
<<<<<<< Updated upstream:lib/features/screens/activities/games/wordle.dart
        // Count invalid / non-existing word attempts
        invalidWordCount++;
        // Provide immediate feedback by shaking the current row
        _triggerInvalidWordFeedback();
=======
        // Play shake animation on the current row instead of showing a SnackBar
        _triggerInvalidWordAnimation();
>>>>>>> Stashed changes:lib/features/screens/activities/games/wordle_easy.dart
=======
        // Play shake animation on the current row instead of showing a SnackBar
        _triggerInvalidWordAnimation();
>>>>>>> Stashed changes
        return;
      }
    }
    // Optionally enforce dictionary (not enforced here)
    final results = _evaluateGuess(guess, secretWord);

<<<<<<< Updated upstream
    // Count valid but incorrect guesses
    if (guess != secretWord) {
      incorrectGuessCount++;
    }

=======
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
<<<<<<< Updated upstream:lib/features/screens/activities/games/wordle.dart
      _showResultDialog(won: true);
    } else if (guesses.length >= rows) {
      _showResultDialog(won: false);
=======
=======
>>>>>>> Stashed changes
      // Show popup dialog with stats
      _showEndDialog(won: true);
    } else if (guesses.length >= rows) {
      // Show popup with correct word and stats
      _showEndDialog(won: false);
<<<<<<< Updated upstream
>>>>>>> Stashed changes:lib/features/screens/activities/games/wordle_easy.dart
=======
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    if (_dictionarySet == null) return true; // if dictionary not loaded, accept all
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

=======
    if (_dictionarySet == null)
      return true; // if dictionary not loaded, accept all
    return _dictionarySet!.contains(word);
  }

>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    final theme = isDark ? ThemeData.dark() : ThemeData.light();

    Widget buildGrid(double maxWidth) {
      final tileSize = maxWidth / cols;
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
      return SizedBox(
        width: tileSize * cols,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (r) {
            final isCurrent = r == guesses.length;
<<<<<<< Updated upstream
            final rowGuess = r < guesses.length ? guesses[r] : (isCurrent ? currentGuess : '');
            List<LetterState> states = List.generate(cols, (_) => LetterState.initial);
            if (r < guesses.length) states = _evaluateGuess(guesses[r], secretWord);

<<<<<<< Updated upstream:lib/features/screens/activities/games/wordle.dart
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
                child: Row(
                  children: List.generate(cols, (c) {
                    final ch = c < rowGuess.length ? rowGuess[c] : '';
                    final state = (r < guesses.length) ? states[c] : LetterState.initial;
                    final bgColor = (r < guesses.length)
                        ? _colorForState(state)
                        : (isCurrent && c < currentGuess.length)
                            ? AppColors.getPrimaryButtonColor(isDark).withAlpha((0.18 * 255).round())
                            : AppColors.getSecondaryBackgroundColor(isDark);

                    final fgColor = (r < guesses.length)
                        ? ((state == LetterState.correct || state == LetterState.present) ? Colors.white : AppColors.getPrimaryTextColor(isDark))
=======
=======
            final rowGuess = r < guesses.length
                ? guesses[r]
                : (isCurrent ? currentGuess : '');
            List<LetterState> states =
                List.generate(cols, (_) => LetterState.initial);
            if (r < guesses.length)
              states = _evaluateGuess(guesses[r], secretWord);

>>>>>>> Stashed changes
            // Apply a horizontal shake transform only to the currently animated row
            return AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final dx = (r == _shakingRow) ? _shakeAnimation.value : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: SizedBox(
                height: tileSize,
                child: Row(
                  children: List.generate(cols, (c) {
                    final ch = c < rowGuess.length ? rowGuess[c] : '';
                    final state =
                        (r < guesses.length) ? states[c] : LetterState.initial;
                    final bgColor = (r < guesses.length)
                        ? _colorForState(state)
                        : (isCurrent && c < currentGuess.length)
                            ? AppColors.getPrimaryButtonColor(isDark)
                                .withOpacity(0.18)
                            : AppColors.getSecondaryBackgroundColor(isDark);

                    final fgColor = (r < guesses.length)
                        ? ((state == LetterState.correct ||
                                state == LetterState.present)
                            ? Colors.white
                            : AppColors.getPrimaryTextColor(isDark))
<<<<<<< Updated upstream
>>>>>>> Stashed changes:lib/features/screens/activities/games/wordle_easy.dart
=======
>>>>>>> Stashed changes
                        : AppColors.getPrimaryTextColor(isDark);

                    return Expanded(
                      child: Container(
<<<<<<< Updated upstream
<<<<<<< Updated upstream:lib/features/screens/activities/games/wordle.dart
                        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
=======
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 3),
>>>>>>> Stashed changes:lib/features/screens/activities/games/wordle_easy.dart
=======
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 3),
>>>>>>> Stashed changes
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
<<<<<<< Updated upstream
<<<<<<< Updated upstream:lib/features/screens/activities/games/wordle.dart
                            color: (r < guesses.length) ? Colors.transparent : Colors.grey.shade500,
=======
                            color: (r < guesses.length)
                                ? Colors.transparent
                                : Colors.grey.shade500,
>>>>>>> Stashed changes:lib/features/screens/activities/games/wordle_easy.dart
=======
                            color: (r < guesses.length)
                                ? Colors.transparent
                                : Colors.grey.shade500,
>>>>>>> Stashed changes
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            ch.toUpperCase(),
<<<<<<< Updated upstream
<<<<<<< Updated upstream:lib/features/screens/activities/games/wordle.dart
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.6, fontSize: tileSize * 0.33, color: fgColor),
=======
=======
>>>>>>> Stashed changes
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.6,
                                fontSize: tileSize * 0.33,
                                color: fgColor),
<<<<<<< Updated upstream
>>>>>>> Stashed changes:lib/features/screens/activities/games/wordle_easy.dart
=======
>>>>>>> Stashed changes
                          ),
                        ),
                      ),
                    );
                  }),
                ),
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
<<<<<<< Updated upstream
<<<<<<< Updated upstream:lib/features/screens/activities/games/wordle.dart
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.getBackgroundGradient(isDark),
                ),
              ),
            ),
            Positioned.fill(
              // Match the particle theme used in Login / Activities pages for visual consistency
              child: ParticleSystemWidget(isDarkMode: isDark, particleCount: 50, maxSize: 3.0, minSize: 1.0, speed: 0.5, maxOpacity: 0.6, minOpacity: 0.2, particleColor: AppColors.getParticleColor(isDark)),
=======
=======
>>>>>>> Stashed changes
              child: ParticleSystemWidget(
                isDarkMode: isDarkMode,
                particleCount: 50,
                maxSize: 3.0,
                minSize: 1.0,
                speed: 0.5,
                maxOpacity: 0.6,
                minOpacity: 0.2,
              ),
<<<<<<< Updated upstream
>>>>>>> Stashed changes:lib/features/screens/activities/games/wordle_easy.dart
=======
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                                  isDark ? Icons.wb_sunny : Icons.nightlight_round,
=======
                                  isDark
                                      ? Icons.wb_sunny
                                      : Icons.nightlight_round,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                        final maxWidth = min(constraints.maxWidth * 0.95, 560.0);
=======
                        final maxWidth =
                            min(constraints.maxWidth * 0.95, 560.0);
>>>>>>> Stashed changes
                        return buildGrid(maxWidth);
                      }),
                    ),
                  ),

                  // Keyboard
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(builder: (ctx) {
                      // Slightly smaller keys and margins for mobile so the full keyboard fits on screen
<<<<<<< Updated upstream
                      final keySize = min(40.0, MediaQuery.of(ctx).size.width / 12);
=======
                      final keySize =
                          min(40.0, MediaQuery.of(ctx).size.width / 12);
>>>>>>> Stashed changes

                      Widget keyWidget(String k) {
                        final state = keyStates[k] ?? LetterState.initial;
                        final color = _colorForState(state);
                        return Container(
<<<<<<< Updated upstream
<<<<<<< Updated upstream:lib/features/screens/activities/games/wordle.dart
                          margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2.5),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade500, width: 1)),
                          child: InkWell(
                            onTap: () => _onKeyTap(k),
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(width: keySize, height: keySize, child: Center(child: Text(k, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: keySize * 0.34, color: (state == LetterState.correct || state == LetterState.present) ? Colors.white : AppColors.getPrimaryTextColor(isDark))))),
=======
=======
>>>>>>> Stashed changes
                          margin: const EdgeInsets.symmetric(
                              horizontal: 1.5, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.grey.shade500, width: 1),
                          ),
                          child: InkWell(
                            onTap: () => _onKeyTap(k),
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: keySize,
                              height: keySize,
                              child: Center(
                                child: Text(
                                  k,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    fontSize: keySize * 0.34,
                                    color: (state == LetterState.correct ||
                                            state == LetterState.present)
                                        ? Colors.white
                                        : AppColors.getPrimaryTextColor(isDark),
                                  ),
                                ),
                              ),
                            ),
<<<<<<< Updated upstream
>>>>>>> Stashed changes:lib/features/screens/activities/games/wordle_easy.dart
=======
>>>>>>> Stashed changes
                          ),
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
<<<<<<< Updated upstream
                          Row(mainAxisSize: MainAxisSize.min, children: [...'QWERTYUIOP'.split('').map((k) => keyWidget(k)).toList()]),
                          Row(mainAxisSize: MainAxisSize.min, children: [...'ASDFGHJKL'.split('').map((k) => keyWidget(k)).toList()]),
                          Row(mainAxisSize: MainAxisSize.min, children: [...'ZXCVBNM'.split('').map((k) => keyWidget(k)).toList()]),
                          const SizedBox(height: 12),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2.5), decoration: BoxDecoration(color: AppColors.getPrimaryButtonColor(isDark), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade500, width: 1)), child: InkWell(onTap: () => _onKeyTap('ENTER'), borderRadius: BorderRadius.circular(6), child: SizedBox(width: keySize * 2.2, height: keySize, child: Center(child: Text('ENTER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: keySize * 0.34, color: Colors.white)))))),
                            const SizedBox(width: 6),
                            // Backspace icon instead of text label
                            Container(margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2.5), decoration: BoxDecoration(color: AppColors.getPrimaryButtonColor(isDark), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade500, width: 1)), child: InkWell(onTap: () => _onKeyTap('BACK'), borderRadius: BorderRadius.circular(6), child: SizedBox(width: keySize * 2.2, height: keySize, child: Center(child: Icon(Icons.backspace_outlined, color: Colors.white, size: keySize * 0.48))))),
=======
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
>>>>>>> Stashed changes
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
