import 'dart:convert';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import '../../../models/user_models.dart';
import '../../../services/api_service.dart';
import '../../../services/qr_api_service.dart';
import '../../../utils/doctor_colors.dart';

class DoctorPatientDetailPage extends StatefulWidget {
  final String patientEmail;
  final bool initialDarkMode;
  final PatientDataResponse? initialData;

  const DoctorPatientDetailPage({
    super.key,
    required this.patientEmail,
    this.initialDarkMode = false,
    this.initialData,
  });

  @override
  State<DoctorPatientDetailPage> createState() =>
      _DoctorPatientDetailPageState();
}

enum _QRColorRole { fill, back }

class _DoctorPatientDetailPageState extends State<DoctorPatientDetailPage> {
  static const double _minContrastRatio = 3.0;

  bool isDarkMode = false;
  bool _loadingData = true;
  bool _downloadingPdf = false;
  bool _generatingQr = false;
  bool _qrFullscreen = false;
  String? _errorMessage;
  PatientDataResponse? _data;
  bool _qrPreviewReady = false;

  Color _fillColor = Colors.black;
  Color _backColor = Colors.white;
  Color? _fillSuggestion;
  Color? _backSuggestion;
  _QRColorRole _lastEditedColor = _QRColorRole.fill;
  String? _qrDataUri;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _data = widget.initialData;
    _loadingData = widget.initialData == null;
    _loadPatientData();
  }

  double get _contrastRatio => _calculateContrastRatio(_fillColor, _backColor);

  bool get _isContrastValid => _contrastRatio >= _minContrastRatio;

  Future<void> _loadPatientData() async {
    setState(() {
      _loadingData = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getPatientData(widget.patientEmail);
      if (!mounted) return;
      setState(() {
        _data = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
      }
    }
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _toggleQrFullscreen() {
    setState(() {
      _qrFullscreen = !_qrFullscreen;
    });
  }
  Future<void> _downloadReport() async {
    setState(() {
      _downloadingPdf = true;
    });

    try {
      final bytes = await ApiService.downloadPatientReport(widget.patientEmail);
      if (!mounted) return;

      final filename =
          'informe_.pdf';
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..download = filename
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnack('Informe descarregat al navegador.');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('/');
        await file.writeAsBytes(bytes, flush: true);
        await OpenFilex.open(file.path);
        _showSnack('Informe desat a ');
      }
    } catch (e) {
      _showSnack(
        'No s\'ha pogut obtenir el PDF: ',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingPdf = false;
        });
      }
    }
  }

  Future<void> _generateQr() async {
    if (!_isContrastValid) {
      _updateContrastFeedback(_lastEditedColor);
      _showSnack(
        'Cal més contrast entre colors abans de generar el QR.',
        isError: true,
      );
      return;
    }

    setState(() {
      _generatingQr = true;
      _qrDataUri = null;
      _qrPreviewReady = false;
    });

    try {
      final response = await QRApiService.generateQRCode(
        format: 'png',
        fillColor: _colorToHex(_fillColor),
        backColor: _colorToHex(_backColor),
        patientEmail: widget.patientEmail,
      );

      if (response['success'] == true) {
        setState(() {
          _qrDataUri = response['qr_code'] as String?;
          _qrPreviewReady = _qrDataUri != null;
        });
        _showSnack('QR generat correctament.');
      } else {
        setState(() {
          _qrPreviewReady = false;
        });
        _showSnack(
          'No s\'ha pogut generar el QR.',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _qrPreviewReady = false;
      });
      _showSnack(
        'Error en generar el QR: ',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _generatingQr = false;
        });
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? DoctorColors.critical(isDarkMode)
            : DoctorColors.primary(isDarkMode),
      ),
    );
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
    if (_contrastRatio < _minContrastRatio) {
      if (updatedRole == _QRColorRole.fill) {
        _backSuggestion = _suggestContrastingColor(_fillColor);
        _fillSuggestion = null;
      } else {
        _fillSuggestion = _suggestContrastingColor(_backColor);
        _backSuggestion = null;
      }
    } else {
      _fillSuggestion = null;
      _backSuggestion = null;
    }
  }

  Color _suggestContrastingColor(Color reference) {
    final hsl = HSLColor.fromColor(reference);
    final double targetLightness =
        reference.computeLuminance() > 0.5 ? 0.12 : 0.88;
    final double targetSaturation =
        hsl.saturation < 0.2 ? 0.35 : hsl.saturation;
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
    final String hex =
        color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${hex.substring(2)}';
  }
  @override
  Widget build(BuildContext context) {
    final bg = DoctorColors.background(isDarkMode);
    final patient = _data?.patient;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: DoctorColors.textPrimary(isDarkMode),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          patient != null
                              ? ' '
                              : 'Detall del pacient',
                          style: TextStyle(
                            color: DoctorColors.textPrimary(isDarkMode),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                          color: DoctorColors.textPrimary(isDarkMode),
                        ),
                        onPressed: _toggleTheme,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loadingData
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(),
                ),
              ],
            ),
          ),
          if (_qrFullscreen && _qrDataUri != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleQrFullscreen,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: _buildQrFrame(
                    math.min(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height,
                    ),
                    _buildQrImage(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(
            color: DoctorColors.textSecondary(isDarkMode),
          ),
        ),
      );
    }

    final patient = _data?.patient;
    if (patient == null) {
      return Center(
        child: Text(
          'No s\'ha pogut carregar el pacient.',
          style: TextStyle(
            color: DoctorColors.textSecondary(isDarkMode),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _buildPatientInfo(patient),
          const SizedBox(height: 12),
          _buildStatsGrid(),
          const SizedBox(height: 12),
          _buildActionsRow(),
          const SizedBox(height: 16),
          _buildQrSection(),
          const SizedBox(height: 16),
          _buildScoresSection(),
          const SizedBox(height: 12),
          _buildQuestionsSection(),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(UserProfile patient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DoctorColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DoctorColors.border(isDarkMode)),
        boxShadow: [
          BoxShadow(
            color: DoctorColors.cardShadow(isDarkMode),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor:
                DoctorColors.secondary(isDarkMode).withOpacity(0.12),
            child: Icon(
              Icons.person_outline,
              color: DoctorColors.primary(isDarkMode),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ' ',
                  style: TextStyle(
                    color: DoctorColors.textPrimary(isDarkMode),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  patient.email,
                  style: TextStyle(
                    color: DoctorColors.textSecondary(isDarkMode),
                    fontSize: 13,
                  ),
                ),
                if (patient.role.ailments != null &&
                    patient.role.ailments!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      patient.role.ailments!,
                      style: TextStyle(
                        color: DoctorColors.textSecondary(isDarkMode),
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

  Widget _buildStatsGrid() {
    final role = _data!.patient.role;
    final genderLabel = translateGenderToCatalan(role.gender) ?? '—';
    final cards = <Widget>[
      _StatCard(
        title: 'Edat',
        value: role.age?.toString() ?? '—',
        icon: Icons.cake_outlined,
        isDarkMode: isDarkMode,
      ),
      _StatCard(
        title: 'Sexe',
        value: genderLabel,
        icon: Icons.transgender,
        isDarkMode: isDarkMode,
      ),
      _StatCard(
        title: 'Pes',
        value: role.weightKg != null
            ? ' kg'
            : '—',
        icon: Icons.monitor_weight_outlined,
        isDarkMode: isDarkMode,
      ),
      _StatCard(
        title: 'Alçada',
        value: role.heightCm != null
            ? ' cm'
            : '—',
        icon: Icons.height,
        isDarkMode: isDarkMode,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: cards,
    );
  }

  Widget _buildActionsRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _downloadingPdf ? null : _downloadReport,
            icon: _downloadingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(
              _downloadingPdf ? 'Descarregant...' : 'Descarregar informe',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorColors.primary(isDarkMode),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: _loadPatientData,
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(
            backgroundColor:
                DoctorColors.secondary(isDarkMode).withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildQrSection() {
    final double qrDimension =
        (MediaQuery.of(context).size.width * 0.55).clamp(220.0, 320.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DoctorColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DoctorColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Codi QR personalitzat',
                style: TextStyle(
                  color: DoctorColors.textPrimary(isDarkMode),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_generatingQr)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: _hasGeneratedQr ? _toggleQrFullscreen : null,
              child: _buildQrFrame(qrDimension, _buildQrPreview(qrDimension)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _hasGeneratedQr
                ? 'Toca sobre la previsualització per veure el QR a mida completa.'
                : 'Després de generar el codi el veuràs aquí.',
            style: TextStyle(
              color: DoctorColors.textSecondary(isDarkMode),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              final cardWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _buildColorOptionCard(
                    role: _QRColorRole.fill,
                    title: 'Color de farciment',
                    description: 'Aplica\'t al patró del QR.',
                    width: cardWidth,
                  ),
                  _buildColorOptionCard(
                    role: _QRColorRole.back,
                    title: 'Color de fons',
                    description: 'Color del llenç per assegurar la lectura.',
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _buildContrastHelper(),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _generatingQr ? null : _generateQr,
            icon: _generatingQr
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_2),
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorColors.primary(isDarkMode),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: Text(_generatingQr ? 'Generant...' : 'Generar QR'),
          ),
        ],
      ),
    );
  }
  Widget _buildQrFrame(double dimension, Widget child) {
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: DoctorColors.background(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DoctorColors.border(isDarkMode),
          width: 2,
        ),
      ),
      child: child,
    );
  }

  Widget _buildQrImage() {
    if (_qrDataUri == null) {
      return Center(
        child: Icon(
          Icons.qr_code_2,
          size: 96,
          color: DoctorColors.textSecondary(isDarkMode),
        ),
      );
    }

    try {
      final commaIndex = _qrDataUri!.indexOf(',');
      final bool isDataUri = _qrDataUri!.startsWith('data:') && commaIndex != -1;
      if (isDataUri) {
        final String header = _qrDataUri!.substring(5, commaIndex);
        final String dataPart = _qrDataUri!.substring(commaIndex + 1);
        final String mimeType = header.split(';').first.toLowerCase();
        final bool isBase64 = header.contains(';base64');
        final String normalizedData = isBase64
            ? dataPart.replaceAll(RegExp(r'\s'), '')
            : Uri.decodeComponent(dataPart);
        final Uint8List decodedBytes = isBase64
            ? base64Decode(normalizedData)
            : Uint8List.fromList(utf8.encode(normalizedData));

        if (mimeType.contains('svg')) {
          return SvgPicture.memory(
            decodedBytes,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  DoctorColors.primary(isDarkMode),
                ),
                strokeWidth: 2,
              ),
            ),
          );
        }

        return Image.memory(
          decodedBytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _qrError(),
        );
      }

      return Image.network(
        _qrDataUri!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _qrError(),
      );
    } catch (_) {
      return _qrError();
    }
  }

  Widget _qrError() {
    return Center(
      child: Text(
        'No s\'ha pogut mostrar el QR',
        style: TextStyle(
          color: DoctorColors.textSecondary(isDarkMode),
        ),
      ),
    );
  }

  bool get _hasGeneratedQr => _qrPreviewReady && _qrDataUri != null;

  Widget _buildQrPreview(double dimension) {
    if (_generatingQr) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            DoctorColors.primary(isDarkMode),
          ),
          strokeWidth: 3,
        ),
      );
    }

    if (_hasGeneratedQr) {
      return _buildQrImage();
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_2,
            size: math.min(dimension * 0.45, 120),
            color: DoctorColors.textSecondary(isDarkMode),
          ),
          const SizedBox(height: 8),
          Text(
            'Genera un codi QR per veure la previsualització.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DoctorColors.textSecondary(isDarkMode),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptionCard({
    required _QRColorRole role,
    required String title,
    required String description,
    required double width,
  }) {
    final color = role == _QRColorRole.fill ? _fillColor : _backColor;
    final textColor = DoctorColors.textPrimary(isDarkMode);
    final secondaryTextColor = DoctorColors.textSecondary(isDarkMode);

    return SizedBox(
      width: width,
      child: Material(
        color: DoctorColors.background(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openColorPicker(role),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.color_lens, color: textColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
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
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildColorPreviewSwatch(role),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _colorToHex(color),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Toca per editar',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.tune, color: textColor),
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
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: secondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DoctorColors.border(isDarkMode),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: DoctorColors.border(isDarkMode).withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildContrastHelper() {
    final ratioLabel = Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Contrast actual: :1',
        style: TextStyle(
          color: DoctorColors.textSecondary(isDarkMode),
          fontSize: 13,
        ),
      ),
    );

    if (_isContrastValid) {
      return ratioLabel;
    }

    final Color? suggestionColor = _lastEditedColor == _QRColorRole.fill
        ? _backSuggestion
        : _fillSuggestion;
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(isDarkMode ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
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
                      'Cal augmentar el contrast per garantir la lectura del QR.',
                      style: TextStyle(
                        color: DoctorColors.textPrimary(isDarkMode),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ajusta els colors o aplica la nostra proposta automàtica.',
                style: TextStyle(
                  color: DoctorColors.textSecondary(isDarkMode),
                ),
              ),
              if (suggestionColor != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _handleColorChanged(
                    suggestionRole,
                    suggestionColor,
                  ),
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text('Acceptar '),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openColorPicker(_QRColorRole role) async {
    final Color initialColor =
        role == _QRColorRole.fill ? _fillColor : _backColor;

    final Color? selectedColor = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ColorPickerSheet(
          initialColor: initialColor,
          isDarkMode: isDarkMode,
          pairedColor: role == _QRColorRole.fill ? _backColor : _fillColor,
          title: role == _QRColorRole.fill
              ? 'Color de farciment'
              : 'Color de fons',
          role: role,
        );
      },
    );

    if (selectedColor != null) {
      _handleColorChanged(role, selectedColor);
    }
  }

  Widget _buildScoresSection() {
    final scores = _data?.scores ?? [];
    if (scores.isEmpty) {
      return _EmptyCard(
        message: 'Sense puntuacions registrades.',
        isDarkMode: isDarkMode,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DoctorColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DoctorColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Puntuacions recents',
            style: TextStyle(
              color: DoctorColors.textPrimary(isDarkMode),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...scores.take(5).map(
                (s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.analytics_outlined,
                    color: DoctorColors.primary(isDarkMode),
                  ),
                  title: Text(
                    s.activityTitle,
                    style: TextStyle(
                      color: DoctorColors.textPrimary(isDarkMode),
                    ),
                  ),
                  subtitle: Text(
                    'Puntuació:  · ',
                    style: TextStyle(
                      color: DoctorColors.textSecondary(isDarkMode),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    final questions = _data?.questions ?? [];
    if (questions.isEmpty) {
      return _EmptyCard(
        message: 'Sense qüestionaris contestats.',
        isDarkMode: isDarkMode,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DoctorColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DoctorColors.border(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Respostes de preguntes',
            style: TextStyle(
              color: DoctorColors.textPrimary(isDarkMode),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...questions.take(3).map(
                (q) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.question_answer_outlined,
                    color: DoctorColors.secondary(isDarkMode),
                  ),
                  title: Text(
                    q.question.text ?? 'Pregunta',
                    style: TextStyle(
                      color: DoctorColors.textPrimary(isDarkMode),
                    ),
                  ),
                  subtitle: Text(
                    'Respost el ',
                    style: TextStyle(
                      color: DoctorColors.textSecondary(isDarkMode),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDarkMode;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DoctorColors.border(isDarkMode)),
      ),
      child: Row(
        children: [
          Icon(icon, color: DoctorColors.primary(isDarkMode)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: DoctorColors.textSecondary(isDarkMode),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: DoctorColors.textPrimary(isDarkMode),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final bool isDarkMode;

  const _EmptyCard({
    required this.message,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DoctorColors.border(isDarkMode)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: DoctorColors.textSecondary(isDarkMode),
        ),
      ),
    );
  }
}

class _ColorPickerSheet extends StatefulWidget {
  final Color initialColor;
  final bool isDarkMode;
  final Color pairedColor;
  final String title;
  final _QRColorRole role;

  const _ColorPickerSheet({
    required this.initialColor,
    required this.isDarkMode,
    required this.pairedColor,
    required this.title,
    required this.role,
  });

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSLColor _hslColor;

  @override
  void initState() {
    super.initState();
    _hslColor = HSLColor.fromColor(widget.initialColor);
  }

  Color get _currentColor => _hslColor.toColor();

  String get _hexValue {
    final String hex =
        _currentColor.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#';
  }

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = DoctorColors.surface(widget.isDarkMode);
    final Color textColor = DoctorColors.textPrimary(widget.isDarkMode);
    final Color secondaryTextColor =
        DoctorColors.textSecondary(widget.isDarkMode);

    final Color backgroundColor = widget.role == _QRColorRole.back
        ? _currentColor
        : widget.pairedColor;
    final Color foregroundColor = widget.role == _QRColorRole.fill
        ? _currentColor
        : widget.pairedColor;

    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: DoctorColors.border(widget.isDarkMode),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ColorPreviewCard(
                  background: backgroundColor,
                  foreground: foregroundColor,
                  hexValue: _hexValue,
                  role: widget.role,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  isDarkMode: widget.isDarkMode,
                ),
                const SizedBox(height: 16),
                _GradientSlider(
                  label: 'Tonalitat',
                  valueLabel: '°',
                  value: _hslColor.hue,
                  min: 0,
                  max: 360,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFA500),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hslColor = _hslColor.withHue(value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _GradientSlider(
                  label: 'Saturació',
                  valueLabel: '%',
                  value: _hslColor.saturation,
                  min: 0,
                  max: 1,
                  gradient: LinearGradient(
                    colors: [
                      HSLColor.fromAHSL(
                        1,
                        _hslColor.hue,
                        0,
                        _hslColor.lightness,
                      ).toColor(),
                      HSLColor.fromAHSL(
                        1,
                        _hslColor.hue,
                        1,
                        _hslColor.lightness,
                      ).toColor(),
                    ],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hslColor =
                          _hslColor.withSaturation(value.clamp(0.0, 1.0));
                    });
                  },
                ),
                const SizedBox(height: 12),
                _GradientSlider(
                  label: 'Lluminositat',
                  valueLabel: '%',
                  value: _hslColor.lightness,
                  min: 0,
                  max: 1,
                  gradient: LinearGradient(
                    colors: [
                      HSLColor.fromAHSL(
                        1,
                        _hslColor.hue,
                        _hslColor.saturation,
                        0,
                      ).toColor(),
                      HSLColor.fromAHSL(
                        1,
                        _hslColor.hue,
                        _hslColor.saturation,
                        0.5,
                      ).toColor(),
                      HSLColor.fromAHSL(
                        1,
                        _hslColor.hue,
                        _hslColor.saturation,
                        1,
                      ).toColor(),
                    ],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hslColor =
                          _hslColor.withLightness(value.clamp(0.0, 1.0));
                    });
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancel·lar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_currentColor),
                        child: const Text('Aplicar'),
                      ),
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
}

class _ColorPreviewCard extends StatelessWidget {
  final Color background;
  final Color foreground;
  final String hexValue;
  final _QRColorRole role;
  final Color textColor;
  final Color secondaryTextColor;
  final bool isDarkMode;

  const _ColorPreviewCard({
    required this.background,
    required this.foreground,
    required this.hexValue,
    required this.role,
    required this.textColor,
    required this.secondaryTextColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final String detailText = role == _QRColorRole.fill
        ? 'Aplicat al patró del QR.'
        : 'Aplicat al fons del QR.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.background(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: textColor.withOpacity(0.15),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.qr_code_2,
                size: 36,
                color: foreground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hexValue,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detailText,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
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

class _GradientSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final LinearGradient gradient;
  final ValueChanged<double> onChanged;

  const _GradientSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.gradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color thumbColor =
        isDark ? Colors.white : Colors.black.withOpacity(0.85);
    final Color overlayColor = thumbColor.withOpacity(0.15);
    final Color frameColor =
        (isDark ? Colors.white : Colors.black).withOpacity(0.12);
    final SliderThemeData sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 16,
      activeTrackColor: Colors.transparent,
      inactiveTrackColor: Colors.transparent,
      thumbColor: thumbColor,
      overlayColor: overlayColor,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: frameColor,
                ),
              ),
            ),
            SliderTheme(
              data: sliderTheme,
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
