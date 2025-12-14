import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../utils/effects/particle_system.dart';
import '../../../../utils/app_colors.dart';
import '../../../../services/api_service.dart';
import '../../../../models/activity_models.dart' show ActivityCompleteRequest;

/// A simple 9x9 Sudoku page where the user fills blanks.
/// Maintains the same header/particle styling and AppColors from the app.
class SudokuHardPage extends StatefulWidget {
  final bool isDarkMode;
  final String? activityId;
  const SudokuHardPage({Key? key, this.isDarkMode = false, this.activityId}) : super(key: key);

  @override
  State<SudokuHardPage> createState() => _SudokuHardPageState();
}

class _SudokuHardPageState extends State<SudokuHardPage> {
  // A known puzzle and its solution (classic easy puzzle)
  final List<List<int>> _initial = const [
    [1,0,0,0,0,0,0,3,0],
    [0,0,2,0,0,0,0,0,0],
    [0,8,0,0,0,0,4,0,1],
    [0,0,4,1,0,0,0,0,5],
    [8,0,0,0,0,7,9,0,3],
    [0,5,0,0,0,2,1,0,0],
    [2,0,0,5,0,0,0,7,0],
    [0,0,0,0,4,0,0,0,0],
    [0,3,0,0,1,0,6,0,8],
  ];

  final List<List<int>> _solution = const [
    [1,9,5,6,8,4,7,3,2],
    [3,4,2,9,7,1,5,8,6],
    [7,8,6,3,2,5,4,9,1],
    [9,7,4,1,3,6,8,2,5],
    [8,2,1,4,5,7,9,6,3],
    [6,5,3,8,9,2,1,4,7],
    [2,1,9,5,6,8,3,7,4],
    [5,6,8,7,4,3,2,1,9],
    [4,3,7,2,1,9,6,5,8],
  ];

  late List<List<int?>> _board;
  late List<List<bool>> _fixed; // true if not editable
  int? _selectedRow;
  int? _selectedCol;
  bool _isDarkModeLocal = true;

  int numIncorrect = 0;
  DateTime? _gameStartTime;
  Duration _totalTime = Duration.zero;

  int totalSquares = 81;
  int filledSquares = 24;
  int? difference;
  double score = 0.0;

  double difficulty = 4.5; // Hard difficulty

  // Resolved activity id if not provided
  String? _resolvedActivityId;

  @override
  void initState() {
    super.initState();
    _isDarkModeLocal = widget.isDarkMode;
    _resetBoard();
    if (widget.activityId == null) {
      _resolveActivityIdByTitle();
    }
  }

  Future<String?> _ensureActivityId(String title) async {
    if (widget.activityId != null && widget.activityId!.isNotEmpty) return widget.activityId;
    if (_resolvedActivityId != null && _resolvedActivityId!.isNotEmpty) return _resolvedActivityId;
    try {
      final activity = await ApiService.getActivity(title);
      if (!mounted) return null;
      setState(() { _resolvedActivityId = activity.id; });
      return activity.id;
    } catch (e) {
      debugPrint('Failed to resolve activity id for $title: $e');
      return null;
    }
  }

  Future<void> _resolveActivityIdByTitle() async {
    try {
      final activity = await ApiService.getActivity('Sudoku (difícil)');
      if (!mounted) return;
      setState(() {
        _resolvedActivityId = activity.id;
      });
    } catch (e) {
      debugPrint('Failed to resolve Sudoku Hard activity id: $e');
    }
  }

  void _resetBoard() {
    _board = List.generate(9, (r) => List<int?>.filled(9, null));
    _fixed = List.generate(9, (r) => List<bool>.filled(9, false));
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = _initial[r][c];
        if (val != 0) {
          _board[r][c] = val;
          _fixed[r][c] = true;
        } else {
          _board[r][c] = null;
          _fixed[r][c] = false;
        }
      }
    }
    _selectedRow = null;
    _selectedCol = null;
    setState(() {});
  }

  void _toggleTheme() {
    setState(() => _isDarkModeLocal = !_isDarkModeLocal);
  }

  void _selectCell(int r, int c) {
    if (_fixed[r][c]) return; // can't select fixed cell
    setState(() {
      _selectedRow = r;
      _selectedCol = c;
    });
  }

  void _enterNumber(int? number) {
    if (_selectedRow == null || _selectedCol == null) return;
    final r = _selectedRow!;
    final c = _selectedCol!;
    if (_fixed[r][c]) return;
    setState(() {
      _board[r][c] = number;
    });
  }

  bool _isCompleteCorrect() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board[r][c] == null) return false;
        if (_board[r][c] != _solution[r][c]) return false;
      }
    }
    _recordGameTime();
    _calculateScore();
    return true;
  }

  Future<void> _submitScore(String activityId) async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.getSecondaryBackgroundColor(_isDarkModeLocal),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.getPrimaryButtonColor(_isDarkModeLocal),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enviant resultats...',
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(_isDarkModeLocal),
                ),
              ),
            ],
          ),
        ),
      );

      final request = ActivityCompleteRequest(
        id: activityId,
        score: score,
        secondsToFinish: _totalTime.inSeconds.toDouble(),
      );

      await ApiService.completeActivity(request);

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.getSecondaryBackgroundColor(_isDarkModeLocal),
          title: Text(
            'Resultats Enviats',
            style: TextStyle(
              color: AppColors.getPrimaryButtonColor(_isDarkModeLocal),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Els resultats s\'han registrat correctament.',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(_isDarkModeLocal),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                'D\'acord',
                style: TextStyle(
                  color: AppColors.getPrimaryButtonColor(_isDarkModeLocal),
                ),
              ),
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
          backgroundColor: AppColors.getSecondaryBackgroundColor(_isDarkModeLocal),
          title: Text(
            'Error',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(_isDarkModeLocal),
            ),
          ),
          content: Text(
            'No s\'ha pogut enviar els resultats: $e',
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(_isDarkModeLocal),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'D\'acord',
                style: TextStyle(
                  color: AppColors.getPrimaryButtonColor(_isDarkModeLocal),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _recordGameTime() {
    if (_gameStartTime != null) {
      final dur = DateTime.now().difference(_gameStartTime!);
      _totalTime = _totalTime + dur;
      _gameStartTime = null;
    }
  }

  void _calculateScore() {
    difference= totalSquares - filledSquares;

    score = max(0.0, 10*(difference! - numIncorrect)/difference! + (difficulty - 1.5) * 0.25);
  }

  void _checkSolution() {
    int wrong = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final entered = _board[r][c];
        if (entered != null && entered != _solution[r][c]) {
          wrong++;
        }
      }
    }

    numIncorrect += wrong;

    if (_isCompleteCorrect()) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Genial!', style: TextStyle(color: AppColors.getPrimaryTextColor(_isDarkModeLocal))),
          content: Text('Has completat el Sudoku!', style: TextStyle(color: AppColors.getSecondaryTextColor(_isDarkModeLocal))),
          backgroundColor: AppColors.getSecondaryBackgroundColor(_isDarkModeLocal),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final id = await _ensureActivityId('Sudoku (difícil)');
                if (id != null) {
                  await _submitScore(id);
                } else {
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text('Acceptar', style: TextStyle(color: AppColors.getPrimaryButtonColor(_isDarkModeLocal))),
            )
          ],
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Encara no', style: TextStyle(color: AppColors.getPrimaryTextColor(_isDarkModeLocal))),
          content: Text(wrong > 0 ? 'Hi ha $wrong valors incorrectes.' : 'Hi ha algunes cel·les buides.', style: TextStyle(color: AppColors.getSecondaryTextColor(_isDarkModeLocal))),
          backgroundColor: AppColors.getSecondaryBackgroundColor(_isDarkModeLocal),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Acceptar', style: TextStyle(color: AppColors.getPrimaryButtonColor(_isDarkModeLocal))),
            )
          ],
        ),
      );
    }
  }

  Widget _buildCell(int r, int c, double size) {
    final value = _board[r][c];
    final fixed = _fixed[r][c];
    final selected = _selectedRow == r && _selectedCol == c;
    final isWrong = value != null && value != _solution[r][c] && !fixed;

    Color bg = Colors.transparent;
    final primaryButtonColor = AppColors.getPrimaryButtonColor(_isDarkModeLocal);
    final primaryTextColor = AppColors.getPrimaryTextColor(_isDarkModeLocal);
    // Convert new fractional r/g/b values to 0-255 ints as recommended
    final int pbR = (primaryButtonColor.r * 255.0).round().clamp(0, 255);
    final int pbG = (primaryButtonColor.g * 255.0).round().clamp(0, 255);
    final int pbB = (primaryButtonColor.b * 255.0).round().clamp(0, 255);
    final int ptR = (primaryTextColor.r * 255.0).round().clamp(0, 255);
    final int ptG = (primaryTextColor.g * 255.0).round().clamp(0, 255);
    final int ptB = (primaryTextColor.b * 255.0).round().clamp(0, 255);

    if (selected)
      bg = Color.fromRGBO(pbR, pbG, pbB, 0.12);
    else if (fixed)
      bg = AppColors.getSecondaryBackgroundColor(_isDarkModeLocal);

    final borderSide = BorderSide(color: Color.fromRGBO(ptR, ptG, ptB, 0.12));

    return GestureDetector(
      onTap: () => _selectCell(r,c),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: borderSide,
            left: borderSide,
            right: ((c+1) % 3 == 0) ? BorderSide(color: AppColors.getPrimaryTextColor(_isDarkModeLocal)) : borderSide,
            bottom: ((r+1) % 3 == 0) ? BorderSide(color: AppColors.getPrimaryTextColor(_isDarkModeLocal)) : borderSide,
          ),
        ),
        // Ensure the entered number is always perfectly centered by using Center
        // and explicit TextAlign + a stable height on the TextStyle.
        child: value == null
            ? const SizedBox.shrink()
            : Text(
          '${value}',
          textAlign: TextAlign.center,
          style: TextStyle(
            // Scale font size with the cell size but keep it within readable bounds
            fontSize: (size * 0.6).clamp(12.0, 28.0),
            height: 1.0, // avoid extra line-height that can shift vertical centering
            fontWeight: fixed ? FontWeight.bold : FontWeight.w500,
            color: fixed
                ? AppColors.getPrimaryTextColor(_isDarkModeLocal)
                : (isWrong ? Colors.red : AppColors.getPrimaryTextColor(_isDarkModeLocal)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: AppColors.getBackgroundGradient(_isDarkModeLocal))),
          ParticleSystemWidget(isDarkMode: _isDarkModeLocal),
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
                          color: AppColors.getBlurContainerColor(_isDarkModeLocal),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: AppColors.getPrimaryTextColor(_isDarkModeLocal)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getBlurContainerColor(_isDarkModeLocal),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(_isDarkModeLocal ? Icons.wb_sunny : Icons.nightlight_round, color: AppColors.getPrimaryTextColor(_isDarkModeLocal)),
                          onPressed: _toggleTheme,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Sudoku', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.getPrimaryTextColor(_isDarkModeLocal))),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final size = min(constraints.maxWidth, constraints.maxHeight - 200);
                    final cellSize = size / 9;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: cellSize * 9,
                            height: cellSize * 9,
                            decoration: BoxDecoration(
                              color: AppColors.getSecondaryBackgroundColor(_isDarkModeLocal),
                              // Defined outer edge so the Sudoku grid has a clear boundary
                              border: Border.all(
                                color: (() {
                                  final c = AppColors.getPrimaryTextColor(_isDarkModeLocal);
                                  final int cr = (c.r * 255.0).round().clamp(0, 255);
                                  final int cg = (c.g * 255.0).round().clamp(0, 255);
                                  final int cb = (c.b * 255.0).round().clamp(0, 255);
                                  return Color.fromRGBO(cr, cg, cb, 0.25);
                                })(),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: AppColors.containerShadow, blurRadius: 6, offset: const Offset(0,2))],
                            ),
                            child: Column(
                              children: List.generate(9, (r) {
                                return Row(
                                  children: List.generate(9, (c) {
                                    return _buildCell(r,c, cellSize);
                                  }),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Number pad
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ...List.generate(9, (i) {
                                final n = i + 1;
                                return SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.getBlurContainerColor(_isDarkModeLocal),
                                      foregroundColor: AppColors.getPrimaryTextColor(_isDarkModeLocal),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _enterNumber(n),
                                    // Ensure the digit is perfectly centered inside the button
                                    child: Center(
                                      child: Text('$n', textAlign: TextAlign.center, style: TextStyle(color: AppColors.getPrimaryTextColor(_isDarkModeLocal))),
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(
                                width: 92,
                                height: 44,
                                child: Tooltip(
                                  message: 'Remove value from selected cell',
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.getPrimaryButtonColor(_isDarkModeLocal),
                                      foregroundColor: AppColors.getPrimaryButtonTextColor(_isDarkModeLocal),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _enterNumber(null),
                                    // Use a text label so it's clearer on all platforms
                                    child: Center(
                                      child: Text('Remove', textAlign: TextAlign.center, style: TextStyle(color: AppColors.getPrimaryButtonTextColor(_isDarkModeLocal))),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getPrimaryButtonColor(_isDarkModeLocal),
                                  foregroundColor: AppColors.getPrimaryButtonTextColor(_isDarkModeLocal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _checkSolution,
                                child: const Text('Check'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getSecondaryButtonColor(_isDarkModeLocal),
                                  foregroundColor: AppColors.getSecondaryButtonTextColor(_isDarkModeLocal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _resetBoard,
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
