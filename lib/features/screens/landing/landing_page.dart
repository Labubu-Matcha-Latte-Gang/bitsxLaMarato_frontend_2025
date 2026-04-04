import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../../../services/session_manager.dart';
import '../initialPage/initialPage.dart';

class LandingPage extends StatefulWidget {
  final bool initialDarkMode;

  const LandingPage({super.key, this.initialDarkMode = true});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late bool isDarkMode;
  bool _isCatalan = true;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final saved = await SessionManager.getThemeMode();
    if (saved != null && mounted) {
      setState(() => isDarkMode = saved);
    }
  }

  void _toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
    SessionManager.saveThemeMode(isDarkMode);
  }

  void _toggleLanguage() {
    setState(() => _isCatalan = !_isCatalan);
  }

  // ──────────────────── LOCALISATION HELPERS ────────────────────
  String get _heroTitle => _isCatalan ? 'NeuroSight' : 'NeuroSight';
  String get _heroSubtitle => _isCatalan
      ? 'El teu company de salut cognitiva'
      : 'Your cognitive health companion';
  String get _aboutTitle => _isCatalan ? 'Sobre el projecte' : 'About the project';
  String get _aboutBody => _isCatalan
      ? 'NeuroSight és una aplicació de salut cognitiva dissenyada per '
        'monitoritzar i millorar les capacitats cognitives dels pacients '
        'mitjançant jocs interactius, preguntes diàries i recomanacions '
        'personalitzades amb intel·ligència artificial.\n\n'
        'Desenvolupat per al hackathon BitsxLaMarató 2025, el projecte '
        'combina tecnologia punta amb un disseny centrat en l\'usuari per '
        'oferir eines útils tant a pacients com a professionals de la salut.'
      : 'NeuroSight is a cognitive health application designed to '
        'monitor and improve patients\' cognitive abilities through '
        'interactive games, daily questions, and personalised '
        'AI-powered recommendations.\n\n'
        'Built for the BitsxLaMarató 2025 hackathon, the project '
        'combines cutting-edge technology with user-centred design to '
        'provide useful tools for both patients and healthcare professionals.';
  String get _teamTitle => _isCatalan ? 'L\'equip' : 'The team';
  String get _ctaButton => _isCatalan ? 'ENTRA A L\'APP' : 'ENTER THE APP';
  String get _hackathonBadge => 'BitsxLaMarató 2025';

  static const _teamMembers = [
    _TeamMember('Erik Batiste', 'https://www.linkedin.com/in/erikbatisteviader/'),
    _TeamMember('Oriol Orbea', 'https://www.linkedin.com/in/oriol-orbea-suari/'),
    _TeamMember('Ernest Rull', 'https://www.linkedin.com/in/ernest-rull-turigas/'),
    _TeamMember('Kaleb Grove', 'https://www.linkedin.com/in/kaleb-grove/'),
  ];

  // ──────────────────── BUILD ────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;
    final horizontalPadding = isWide ? screenWidth * 0.15 : 24.0;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.getBackgroundGradient(isDarkMode),
            ),
          ),

          // Particle system
          ParticleSystemWidget(
            isDarkMode: isDarkMode,
            particleCount: 60,
            maxSize: 3.0,
            minSize: 1.0,
            speed: 0.4,
            maxOpacity: 0.5,
            minOpacity: 0.15,
          ),

          // Main scrollable content
          SafeArea(
            child: Column(
              children: [
                // Header bar
                _buildHeader(isWide),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildHeroSection(isWide),
                          const SizedBox(height: 48),
                          _buildAboutSection(isWide),
                          const SizedBox(height: 48),
                          _buildTeamSection(isWide),
                          const SizedBox(height: 48),
                          _buildCtaSection(),
                          const SizedBox(height: 40),
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ],
                      ),
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

  // ──────────────────── HEADER ────────────────────
  Widget _buildHeader(bool isWide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Language toggle
          _pillButton(
            label: _isCatalan ? 'EN' : 'CAT',
            icon: Icons.language,
            onTap: _toggleLanguage,
          ),
          const Spacer(),
          // Theme toggle
          _pillButton(
            icon: isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            onTap: _toggleTheme,
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    String? label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.getBlurContainerColor(isDarkMode),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.containerShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.getPrimaryTextColor(isDarkMode)),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────── HERO SECTION ────────────────────
  Widget _buildHeroSection(bool isWide) {
    return Column(
      children: [
        // Logo
        SizedBox(
          height: isWide ? 120 : 90,
          child: Image.asset(
            isDarkMode ? TImages.lightLogoText : TImages.darkLogoText,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.local_hospital,
              size: 60,
              color: AppColors.getPrimaryTextColor(isDarkMode),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Hackathon badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(80),
            ),
          ),
          child: Text(
            _hackathonBadge,
            style: TextStyle(
              color: AppColors.getPrimaryButtonColor(isDarkMode),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tagline
        Text(
          _heroSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.getSecondaryTextColor(isDarkMode),
            fontSize: isWide ? 20 : 16,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ──────────────────── ABOUT SECTION ────────────────────
  Widget _buildAboutSection(bool isWide) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _aboutTitle,
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _aboutBody,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // Feature highlights
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _featureChip(Icons.videogame_asset, _isCatalan ? 'Jocs cognitius' : 'Cognitive games'),
              _featureChip(Icons.mic, _isCatalan ? 'Anàlisi de veu' : 'Voice analysis'),
              _featureChip(Icons.auto_awesome, _isCatalan ? 'IA personalitzada' : 'Personalised AI'),
              _featureChip(Icons.medical_services, _isCatalan ? 'Panel mèdic' : 'Doctor panel'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.getPrimaryButtonColor(isDarkMode)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── TEAM SECTION ────────────────────
  Widget _buildTeamSection(bool isWide) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.group,
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _teamTitle,
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          isWide ? _teamRow() : _teamColumn(),
        ],
      ),
    );
  }

  Widget _teamRow() {
    return Row(
      children: _teamMembers
          .map((m) => Expanded(child: _teamCard(m)))
          .toList(),
    );
  }

  Widget _teamColumn() {
    return Column(
      children: _teamMembers
          .map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _teamCard(m),
              ))
          .toList(),
    );
  }

  Widget _teamCard(_TeamMember member) {
    final initials = member.name.split(' ').map((w) => w[0]).join();
    return GestureDetector(
      onTap: () => _openUrl(member.linkedIn),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getBackgroundColor(isDarkMode).withAlpha(
            isDarkMode ? 120 : 180,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(40),
          ),
        ),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(40),
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              member.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                ),
                const SizedBox(width: 4),
                Text(
                  'LinkedIn',
                  style: TextStyle(
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── CTA SECTION ────────────────────
  Widget _buildCtaSection() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InitialPage(initialDarkMode: isDarkMode),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _ctaButton,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  // ──────────────────── FOOTER ────────────────────
  Widget _buildFooter() {
    return Text(
      _isCatalan
          ? '© 2025 LMLG · BitsxLaMarató 2025'
          : '© 2025 LMLG · BitsxLaMarató 2025',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.getTertiaryTextColor(isDarkMode),
        fontSize: 12,
      ),
    );
  }

  // ──────────────────── REUSABLE WIDGETS ────────────────────
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.containerShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _TeamMember {
  final String name;
  final String linkedIn;
  const _TeamMember(this.name, this.linkedIn);
}
