import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../activities/all_activities_page.dart';
import '../activities/recommended_activities_page.dart';
import 'qr_generate_page.dart';

class PatientMenuPage extends StatefulWidget {
  final bool initialDarkMode;

  const PatientMenuPage({
    super.key,
    this.initialDarkMode = false,
  });

  @override
  State<PatientMenuPage> createState() => _PatientMenuPageState();
}

class _PatientMenuPageState extends State<PatientMenuPage> {
  late bool isDarkMode;

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
                      // Left: back button container
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

                      // Center: placeholder to keep spacing for centered logo below
                      const Expanded(child: SizedBox()),

                      // Right: theme toggle container
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
                  const SizedBox(height: 16),

                  // Centered logo under the header (same style as LoginScreen)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        height: 80,
                        width: 160,
                        child: Image.asset(
                          isDarkMode ? TImages.lightLogo : TImages.darkLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.local_hospital,
                              size: 48,
                              color: AppColors.getPrimaryTextColor(isDarkMode),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Menú Principal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accedeix a les teves activitats i opcions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.getSecondaryTextColor(isDarkMode),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Column(
                            children: [
                              _ActionCard(
                                title: 'Activitats recomanades',
                                description:
                                    'Descobreix les activitats pensades per a tu segons el teu progrés.',
                                icon: Icons.auto_awesome,
                                isDarkMode: isDarkMode,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RecommendedActivitiesPage(
                                        initialDarkMode: isDarkMode,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _ActionCard(
                                title: 'Totes les activitats',
                                description:
                                    'Cerca, filtra i explora tot el catàleg d\'activitats disponibles.',
                                icon: Icons.view_list_outlined,
                                isDarkMode: isDarkMode,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AllActivitiesPage(
                                        initialDarkMode: isDarkMode,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _ActionCard(
                                title: 'QR per Informe Mèdic',
                                description:
                                    'Genera un codi QR per accedir als teus informes mèdics.',
                                icon: Icons.qr_code_2,
                                isDarkMode: isDarkMode,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => QRGeneratePage(
                                        initialDarkMode: isDarkMode,
                                      ),
                                    ),
                                  );
                                },
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: AppColors.getPrimaryButtonColor(isDarkMode)
          .withAlpha((0.2 * 255).round()),
      highlightColor: AppColors.getPrimaryButtonColor(isDarkMode)
          .withAlpha((0.1 * 255).round()),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.getSecondaryBackgroundColor(isDarkMode)
                  .withAlpha((0.95 * 255).round()),
              AppColors.getSecondaryBackgroundColor(isDarkMode)
                  .withAlpha((0.85 * 255).round()),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.containerShadow.withAlpha((0.5 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withAlpha((0.08 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppColors.getPrimaryButtonColor(isDarkMode)
                .withAlpha((0.15 * 255).round()),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.getPrimaryButtonColor(isDarkMode)
                          .withAlpha((0.25 * 255).round()),
                      AppColors.getPrimaryButtonColor(isDarkMode)
                          .withAlpha((0.15 * 255).round()),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.getPrimaryButtonColor(isDarkMode)
                        .withAlpha((0.3 * 255).round()),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                  size: 32,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.getSecondaryTextColor(isDarkMode),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.getPrimaryButtonColor(isDarkMode),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
