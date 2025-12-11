import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/effects/particle_system.dart';
import '../../../services/qr_api_service.dart';

class QRGeneratePage extends StatefulWidget {
  final bool initialDarkMode;

  const QRGeneratePage({
    super.key,
    this.initialDarkMode = false,
  });

  @override
  State<QRGeneratePage> createState() => _QRGeneratePageState();
}

enum _QRColorRole { fill, back }

class _QRGeneratePageState extends State<QRGeneratePage> {
  static const double _minContrastRatio = 3.0;

  late bool isDarkMode;
  bool _showQR = false;
  String? _qrCodeUrl;
  bool _isLoading = false;
  String? _errorMessage;
  Color _fillColor = Colors.black;
  Color _backColor = Colors.white;
  Color? _fillColorSuggestion;
  Color? _backColorSuggestion;
  _QRColorRole _lastEditedColor = _QRColorRole.fill;

  double get _currentContrastRatio =>
      _calculateContrastRatio(_fillColor, _backColor);

  bool get _isContrastValid => _currentContrastRatio >= _minContrastRatio;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _handleColorChanged(_QRColorRole role, Color newColor) {
    setState(() {
      if (role == _QRColorRole.fill) {
        _fillColor = newColor;
      } else {
        _backColor = newColor;
      }
      _lastEditedColor = role;
      _updateContrastFeedback(role);
    });
  }

  void _updateContrastFeedback(_QRColorRole updatedRole) {
    if (_currentContrastRatio < _minContrastRatio) {
      if (updatedRole == _QRColorRole.fill) {
        _backColorSuggestion = _suggestContrastingColor(_fillColor);
        _fillColorSuggestion = null;
      } else {
        _fillColorSuggestion = _suggestContrastingColor(_backColor);
        _backColorSuggestion = null;
      }
    } else {
      _fillColorSuggestion = null;
      _backColorSuggestion = null;
    }
  }

  Color _suggestContrastingColor(Color reference) {
    final hsl = HSLColor.fromColor(reference);
    final double targetLightness = reference.computeLuminance() > 0.5 ? 0.12 : 0.88;
    final double targetSaturation = hsl.saturation < 0.2 ? 0.35 : hsl.saturation;
    final HSLColor normalized = hsl
        .withLightness(targetLightness.clamp(0.0, 1.0))
        .withSaturation(targetSaturation.clamp(0.0, 1.0));
    return normalized.toColor();
  }

  double _calculateContrastRatio(Color a, Color b) {
    final double luminance1 = _calculateLuminance(a);
    final double luminance2 = _calculateLuminance(b);

    final double lighter = math.max(luminance1, luminance2);
    final double darker = math.min(luminance1, luminance2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  double _calculateLuminance(Color color) {
    double channelToLinear(int channel) {
      final double c = channel / 255.0;
      return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    final double r = channelToLinear(color.red);
    final double g = channelToLinear(color.green);
    final double b = channelToLinear(color.blue);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  String _colorToHex(Color color) {
    final String hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${hex.substring(2)}';
  }

  Future<void> _openColorPicker(_QRColorRole role) async {
    final Color initialColor = role == _QRColorRole.fill ? _fillColor : _backColor;

    final Color? selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) {
        Color tempColor = initialColor;
        return AlertDialog(
          backgroundColor: AppColors.getSecondaryBackgroundColor(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            role == _QRColorRole.fill ? 'Color de farciment' : 'Color de fons',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ColorPicker(
                      pickerColor: tempColor,
                      onColorChanged: (color) {
                        setStateDialog(() {
                          tempColor = color;
                        });
                      },
                      enableAlpha: false,
                      hexInputBar: true,
                      displayThumbColor: true,
                      portraitOnly: true,
                      pickerAreaBorderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 12),
                    _buildDialogPreview(tempColor),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel·lar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(tempColor),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );

    if (selectedColor != null) {
      _handleColorChanged(role, selectedColor);
    }
  }

  Widget _buildDialogPreview(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previsualització',
          style: TextStyle(
            color: AppColors.getSecondaryTextColor(isDarkMode),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getPrimaryTextColor(isDarkMode).withOpacity(0.15),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _colorToHex(color),
          style: TextStyle(
            color: AppColors.getPrimaryTextColor(isDarkMode),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _generateQR() async {
    if (!_isContrastValid) {
      setState(() {
        _updateContrastFeedback(_lastEditedColor);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ajusta els colors per garantir prou contrast abans de generar el QR.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await QRApiService.generateQRCode(
        fillColor: _colorToHex(_fillColor),
        backColor: _colorToHex(_backColor),
      );

      if (response['success'] == true) {
        setState(() {
          _showQR = true;
          _qrCodeUrl = response['qr_code'];
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR generat correctament')),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['error'] ?? 'Error al generar el QR';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${_errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Construye la imagen del QR soportando data URIs
  Widget _buildQRImage(String qrDataUri, bool isDarkMode) {
    try {
      // Extraer el formato y datos de la URI
      if (qrDataUri.startsWith('data:image/')) {
        // Encontrar la coma que separa header de datos
        final commaIndex = qrDataUri.indexOf(',');
        if (commaIndex != -1) {
          final data = qrDataUri.substring(commaIndex + 1);

          // Decodificar base64
          final decodedBytes = base64Decode(data);

          // Mostrar usando Image.memory
          return Image.memory(
            decodedBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Error al cargar QR',
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      }

      // Si no es data URI, intentar como URL normal
      return Image.network(
        qrDataUri,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'Error al cargar QR',
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Center(
        child: Text(
          'Error: $e',
          style: TextStyle(
            color: AppColors.getPrimaryTextColor(isDarkMode),
          ),
        ),
      );
    }
  }

  Widget _buildColorOptionCard({
    required _QRColorRole role,
    required String title,
    required String description,
    required double width,
  }) {
    final color = role == _QRColorRole.fill ? _fillColor : _backColor;
    final textColor = AppColors.getPrimaryTextColor(isDarkMode);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);

    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.getBlurContainerColor(isDarkMode),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openColorPicker(role),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.color_lens_outlined,
                      color: textColor.withOpacity(0.9),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildColorPreviewSwatch(role),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _colorToHex(color),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toca per editar i visualitzar el canvi.',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.tune,
                      color: textColor.withOpacity(0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreviewSwatch(_QRColorRole role) {
    final Color primary = role == _QRColorRole.fill ? _fillColor : _backColor;
    final Color secondary = role == _QRColorRole.fill ? _backColor : _fillColor;

    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getPrimaryTextColor(isDarkMode).withOpacity(0.08),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.getPrimaryTextColor(isDarkMode).withOpacity(0.18),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: secondary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContrastHelper() {
    final ratioLabel = Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Contrast actual: ${_currentContrastRatio.toStringAsFixed(2)}:1',
        style: TextStyle(
          color: AppColors.getSecondaryTextColor(isDarkMode),
          fontSize: 13,
        ),
      ),
    );

    if (_isContrastValid) {
      return ratioLabel;
    }

    final Color? suggestionColor = _lastEditedColor == _QRColorRole.fill
        ? _backColorSuggestion
        : _fillColorSuggestion;
    final _QRColorRole suggestionRole = _lastEditedColor == _QRColorRole.fill
        ? _QRColorRole.back
        : _QRColorRole.fill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ratioLabel,
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(isDarkMode ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cal més contrast per a un QR fàcil de llegir.',
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ajusta els colors o aplica la nostra proposta automàtica.',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                ),
              ),
              if (suggestionColor != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      _handleColorChanged(suggestionRole, suggestionColor),
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(
                    'Acceptar suggeriment ${_colorToHex(suggestionColor)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.getPrimaryTextColor(isDarkMode),
                    side: BorderSide(
                      color: AppColors.getPrimaryButtonColor(isDarkMode)
                          .withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
                  Row(
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
                      const Expanded(child: SizedBox()),
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
                            isDarkMode
                                ? Icons.wb_sunny
                                : Icons.nightlight_round,
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                          ),
                          onPressed: _toggleTheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Generar Informe Mèdic',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Genera un codi QR per obtenir el teu informe mèdic.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.getSecondaryTextColor(isDarkMode),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.getSecondaryBackgroundColor(
                                          isDarkMode)
                                      .withAlpha((0.9 * 255).round()),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.containerShadow,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: AppColors.getPrimaryButtonColor(
                                            isDarkMode)
                                        .withAlpha((0.2 * 255).round()),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    if (_isLoading)
                                      Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.getBlurContainerColor(
                                                  isDarkMode),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                AppColors.getPrimaryTextColor(
                                                        isDarkMode)
                                                    .withOpacity(0.2),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color:
                                                AppColors.getPrimaryButtonColor(
                                                    isDarkMode),
                                          ),
                                        ),
                                      )
                                    else if (_showQR && _qrCodeUrl != null)
                                      Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.getBlurContainerColor(
                                                  isDarkMode),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                AppColors.getPrimaryTextColor(
                                                    isDarkMode),
                                            width: 2,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: _buildQRImage(
                                              _qrCodeUrl!, isDarkMode),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.getBlurContainerColor(
                                                  isDarkMode),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                AppColors.getPrimaryTextColor(
                                                        isDarkMode)
                                                    .withOpacity(0.2),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.qr_code_2,
                                            size: 100,
                                            color:
                                                AppColors.getPrimaryTextColor(
                                                        isDarkMode)
                                                    .withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Codi QR per a informe mèdic',
                                      style: TextStyle(
                                        color: AppColors.getPrimaryTextColor(
                                            isDarkMode),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Fes clic al botó de sota per generar el teu codi QR personal.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.getSecondaryTextColor(
                                            isDarkMode),
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isWide = constraints.maxWidth >= 600;
                              final double gap = 16;
                              final double cardWidth = isWide
                                  ? ((constraints.maxWidth - gap) / 2)
                                  : constraints.maxWidth;

                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  _buildColorOptionCard(
                                    role: _QRColorRole.fill,
                                    title: 'Color de farciment',
                                    description:
                                        'S\'aplica als quadrats del codi i logotips.',
                                    width: cardWidth,
                                  ),
                                  _buildColorOptionCard(
                                    role: _QRColorRole.back,
                                    title: 'Color de fons',
                                    description:
                                        'Color del llenç del QR, ha de contrastar prou.',
                                    width: cardWidth,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildContrastHelper(),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _isLoading || !_isContrastValid
                                ? null
                                : _generateQR,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.getPrimaryButtonColor(
                                          isDarkMode),
                                  foregroundColor:
                                      AppColors.getPrimaryButtonTextColor(
                                          isDarkMode),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.getPrimaryButtonTextColor(
                                                isDarkMode),
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.qr_code),
                                label: Text(
                                  _isLoading ? 'Generant...' : 'Generar QR',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
