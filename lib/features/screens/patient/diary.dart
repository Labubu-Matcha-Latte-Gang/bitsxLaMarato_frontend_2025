import 'package:flutter/material.dart';
import '../../../models/question_models.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/effects/particle_system.dart';

class DiaryPage extends StatefulWidget {
  final bool initialDarkMode;

  const DiaryPage({
    super.key,
    this.initialDarkMode = false,
  });

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late bool isDarkMode;
  bool _isLoading = true;
  Question? _diaryQuestion;
  String? _errorMessage;
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _loadDiaryQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaryQuestion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final question = await ApiService.getDiaryQuestion();
      setState(() {
        _diaryQuestion = question;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error desconegut: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _submitAnswer() {
    // Placeholder per la funcionalitat d'enviar la resposta
    final answer = _answerController.text.trim();
    
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Si us plau, escriu una resposta abans de continuar.'),
          backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
        ),
      );
      return;
    }

    // TODO: Implementar la crida a l'API per enviar la resposta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resposta guardada: $answer'),
        backgroundColor: Colors.green,
      ),
    );
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
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
                          tooltip: 'Tornar',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Diari Personal',
                          style: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _isLoading
                            ? _buildLoadingState()
                            : _errorMessage != null
                                ? _buildErrorState()
                                : _buildQuestionContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.getPrimaryButtonColor(isDarkMode),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregant pregunta del diari...',
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getSecondaryBackgroundColor(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.containerShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _loadDiaryQuestion,
              icon: const Icon(Icons.refresh),
              label: const Text('Tornar a intentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent() {
    if (_diaryQuestion == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getSecondaryBackgroundColor(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.containerShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimaryButtonColor(isDarkMode)
                        .withAlpha((0.12 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.question_answer,
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pregunta del Diari',
                        style: TextStyle(
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tipus: ${_diaryQuestion!.questionType} • Dificultat: ${_diaryQuestion!.difficulty.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getBackgroundColor(isDarkMode)
                    .withAlpha((0.5 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.getPrimaryButtonColor(isDarkMode)
                      .withAlpha((0.2 * 255).round()),
                  width: 1.5,
                ),
              ),
              child: Text(
                _diaryQuestion!.text,
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Answer input (placeholder)
            Text(
              'La teva resposta',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              maxLines: 5,
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Escriu la teva resposta aquí...',
                hintStyle: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                ),
                filled: true,
                fillColor: AppColors.getBackgroundColor(isDarkMode)
                    .withAlpha((0.5 * 255).round()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getPrimaryButtonColor(isDarkMode)
                        .withAlpha((0.2 * 255).round()),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getPrimaryButtonColor(isDarkMode)
                        .withAlpha((0.2 * 255).round()),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _submitAnswer,
              icon: const Icon(Icons.send),
              label: const Text(
                'Enviar Resposta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
