import 'package:flutter/material.dart';
import 'dart:convert';
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

class _QRGeneratePageState extends State<QRGeneratePage> {
  late bool isDarkMode;
  bool _showQR = false;
  String? _qrCodeUrl;
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> _generateQR() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await QRApiService.generateQRCode();

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
              print('❌ Error al decodificar QR: $error');
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
          print('❌ Error al cargar imagen de red: $error');
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
      print('❌ Error en _buildQRImage: $e');
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
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _generateQR,
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
