import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../utils/effects/particle_system.dart';
import '../../../../utils/app_colors.dart';

// Wordle game screen: 8 tries, 5-letter words.
class WordleScreen extends StatefulWidget {
  const WordleScreen({Key? key}) : super(key: key);

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

enum LetterState { initial, correct, present, absent }

class _WordleScreenState extends State<WordleScreen>
    with SingleTickerProviderStateMixin {
  static const int rows = 6; // changed to 6 guesses x 5 columns (classic Wordle)
  static const int cols = 5;

  // Note: word list removed — secret word will be chosen from easy_words.json

  late String secretWord;
  List<String> guesses = [];
  String currentGuess = '';
  Map<String, LetterState> keyStates = {};
  bool isDark = false;
  List<String>? _dictionary;
  Set<String>? _dictionarySet;
  List<String>? _easyWords;

  @override
  void initState() {
    super.initState();
    // Load dictionaries first, then start the game so we can prefer easy words
    _loadDictionary().whenComplete(() {
      _startNewGame();
    });
  }

  Future<void> _loadDictionary() async {
    try {
      final raw = await rootBundle.loadString('lib/features/screens/activities/dictionary/words_sorted.json');
      // JSON might be a list or newline-separated. Try to parse as JSON first.
      List<String> words = [];
      try {
        final decoded = raw.trim();
        if (decoded.startsWith('[')) {
          final List<dynamic> arr = (await Future.value(jsonDecode(decoded))) as List<dynamic>;
          words = arr.map((e) => e.toString().toUpperCase()).toList();
        } else {
          // Fallback: treat as newline-separated text
          words = decoded.split(RegExp(r"\r?\n")).where((s) => s.trim().isNotEmpty).map((s) => s.trim().toUpperCase()).toList();
        }
      } catch (e) {
        // fallback to newline split
        words = raw.split(RegExp(r"\r?\n")).where((s) => s.trim().isNotEmpty).map((s) => s.trim().toUpperCase()).toList();
      }

      // Ensure sorted and create a Set for O(1) lookups
      words.sort();
      _dictionary = words;
      _dictionarySet = words.map((w) => w.toUpperCase()).toSet();
      // Try loading easy words as well (optional)
      try {
        final rawEasy = await rootBundle.loadString('lib/features/screens/activities/dictionary/easy_words.json');
        final List<dynamic> arr2 = jsonDecode(rawEasy) as List<dynamic>;
        _easyWords = arr2.map((e) => e.toString().toUpperCase()).toList();
      } catch (_) {
        _easyWords = null;
      }
      // print('Loaded dictionary with ${words.length} words');
    } catch (e) {
      // ignore failures — dictionary remains null
      _dictionary = null;
      print('Warning: failed to load dictionary asset: $e');
    }
  }

  void _startNewGame() {
    // Choose secret exclusively from easy_words.json if available.
    // If easy_words.json is missing or empty, fall back to a fixed default.
    if (_easyWords != null && _easyWords!.isNotEmpty) {
      final copy = List<String>.from(_easyWords!);
      copy.shuffle();
      secretWord = copy.first.toUpperCase();
    } else {
      // Default secret when easy_words isn't available
      secretWord = 'APPLE';
    }
    guesses = [];
    currentGuess = '';
    keyStates.clear();
    for (var c = 'A'.codeUnitAt(0);
        c <= 'Z'.codeUnitAt(0);
        c++) keyStates[String.fromCharCode(c)] = LetterState.initial;
    setState(() {});
  }

  @override
  void dispose() {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No és una paraula vàlida')),
        );
        return;
      }
    }
    // Optionally enforce dictionary (not enforced here)
    final results = _evaluateGuess(guess, secretWord);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has guanyat!')),
      );
    } else if (guesses.length >= rows) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Final - la paraula era $secretWord')),
      );
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
      default:
        return AppColors.getFieldBackgroundColor(isDark);
    }
  }

  bool _isValidWord(String word) {
    if (_dictionarySet == null) return true; // if dictionary not loaded, accept all
    return _dictionarySet!.contains(word);
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
            final rowGuess = r < guesses.length ? guesses[r] : (isCurrent ? currentGuess : '');
            List<LetterState> states = List.generate(cols, (_) => LetterState.initial);
            if (r < guesses.length) states = _evaluateGuess(guesses[r], secretWord);

            return SizedBox(
              height: tileSize,
              child: Row(
                children: List.generate(cols, (c) {
                  final ch = c < rowGuess.length ? rowGuess[c] : '';
                  final state = (r < guesses.length) ? states[c] : LetterState.initial;
                  final bgColor = (r < guesses.length)
                      ? _colorForState(state)
                      : (isCurrent && c < currentGuess.length)
                          ? AppColors.getPrimaryButtonColor(isDark).withOpacity(0.18)
                          : AppColors.getSecondaryBackgroundColor(isDark);

                  final fgColor = (r < guesses.length)
                      ? ((state == LetterState.correct || state == LetterState.present) ? Colors.white : AppColors.getPrimaryTextColor(isDark))
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
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.6, fontSize: tileSize * 0.33, color: fgColor),
                        ),
                      ),
                    ),
                  );
                }),
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
              child: ParticleSystemWidget(isDarkMode: isDark, particleCount: 40, maxSize: 3.0, minSize: 1.0, speed: 0.6, maxOpacity: isDark ? 0.35 : 0.25, minOpacity: isDark ? 0.05 : 0.02),
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
                                  isDark ? Icons.wb_sunny : Icons.nightlight_round,
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
                        final maxWidth = min(constraints.maxWidth * 0.95, 560.0);
                        return buildGrid(maxWidth);
                      }),
                    ),
                  ),

                  // Keyboard
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(builder: (ctx) {
                      // Slightly smaller keys and margins for mobile so the full keyboard fits on screen
                      final keySize = min(40.0, MediaQuery.of(ctx).size.width / 12);

                      Widget keyWidget(String k) {
                        final state = keyStates[k] ?? LetterState.initial;
                        final color = _colorForState(state);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2.5),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade500, width: 1)),
                          child: InkWell(
                            onTap: () => _onKeyTap(k),
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(width: keySize, height: keySize, child: Center(child: Text(k, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: keySize * 0.34, color: (state == LetterState.correct || state == LetterState.present) ? Colors.white : AppColors.getPrimaryTextColor(isDark))))),
                          ),
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [...'QWERTYUIOP'.split('').map((k) => keyWidget(k)).toList()]),
                          Row(mainAxisSize: MainAxisSize.min, children: [...'ASDFGHJKL'.split('').map((k) => keyWidget(k)).toList()]),
                          Row(mainAxisSize: MainAxisSize.min, children: [...'ZXCVBNM'.split('').map((k) => keyWidget(k)).toList()]),
                          const SizedBox(height: 12),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2.5), decoration: BoxDecoration(color: AppColors.getPrimaryButtonColor(isDark), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade500, width: 1)), child: InkWell(onTap: () => _onKeyTap('ENTER'), borderRadius: BorderRadius.circular(6), child: SizedBox(width: keySize * 2.2, height: keySize, child: Center(child: Text('ENTER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: keySize * 0.34, color: Colors.white)))))),
                            const SizedBox(width: 6),
                            // Backspace icon instead of text label
                            Container(margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2.5), decoration: BoxDecoration(color: AppColors.getPrimaryButtonColor(isDark), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade500, width: 1)), child: InkWell(onTap: () => _onKeyTap('BACK'), borderRadius: BorderRadius.circular(6), child: SizedBox(width: keySize * 2.2, height: keySize, child: Center(child: Icon(Icons.backspace_outlined, color: Colors.white, size: keySize * 0.48))))),
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
