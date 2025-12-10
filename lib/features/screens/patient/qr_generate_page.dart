import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/effects/particle_system.dart';

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
  String _qrData = "https://example.com/report/12345";
  bool _showQR = false;

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

  void _generateQR() {
    setState(() {
      _showQR = true;
      _qrData =
          "https://medical-report.com/patient/${DateTime.now().millisecondsSinceEpoch}";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR generat correctament')),
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
                                    if (_showQR)
                                      Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: AppColors
                                              .getBlurContainerColor(isDarkMode),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors
                                                .getPrimaryTextColor(isDarkMode),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.qr_code_2,
                                            size: 100,
                                            color: AppColors
                                                .getPrimaryTextColor(isDarkMode),
                                          ),
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
                                onPressed: _generateQR,
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
                                icon: const Icon(Icons.qr_code),
                                label: const Text(
                                  'Generar QR',
                                  style: TextStyle(
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
