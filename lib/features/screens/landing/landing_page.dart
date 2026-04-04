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

  // ──────────────────── LOCALISATION ────────────────────
  String get _heroSubtitle => _isCatalan
      ? 'El teu company de salut cognitiva'
      : 'Your cognitive health companion';
  String get _aboutTitle =>
      _isCatalan ? 'Sobre el projecte' : 'About the project';
  String get _aboutBody => _isCatalan
      ? 'NeuroSight monitoritza i millora les capacitats cognitives dels '
        'pacients mitjançant jocs interactius, preguntes diàries i '
        'recomanacions personalitzades amb IA. Desenvolupat per al '
        'hackathon BitsxLaMarató 2025.'
      : 'NeuroSight monitors and improves patients\' cognitive abilities '
        'through interactive games, daily questions, and personalised '
        'AI-powered recommendations. Built for the BitsxLaMarató 2025 '
        'hackathon.';
  String get _metricsTitle =>
      _isCatalan ? 'Mètriques mesurades' : 'Measured metrics';
  String get _teamTitle => _isCatalan ? 'L\'equip' : 'The team';
  String get _ctaButton => _isCatalan ? 'ENTRA A L\'APP' : 'ENTER THE APP';

  static const _teamMembers = [
    _TeamMember('Erik Batiste', 'https://www.linkedin.com/in/erikbatisteviader/',
        'https://avatars.githubusercontent.com/u/96847443?s=80'),
    _TeamMember('Oriol Orbea', 'https://www.linkedin.com/in/oriol-orbea-suari/',
        'https://avatars.githubusercontent.com/u/145404641?s=80'),
    _TeamMember(
        'Ernest Rull',
        'https://www.linkedin.com/in/ernest-rull-turigas/',
        'https://avatars.githubusercontent.com/u/118774478?s=80'),
    _TeamMember('Kaleb Grove', 'https://www.linkedin.com/in/kaleb-grove/',
        'https://avatars.githubusercontent.com/u/72881364?s=80'),
  ];

  List<_Metric> get _metrics => [
        _Metric(
          icon: Icons.link,
          catName: 'Coherència Semàntica',
          enName: 'Semantic Coherence',
          catDesc:
              'Mesura si les oracions consecutives mantenen el fil argumental.',
          enDesc:
              'Measures whether consecutive sentences maintain the same thread.',
        ),
        _Metric(
          icon: Icons.alt_route,
          catName: 'Desviació Semàntica',
          enName: 'Semantic Deviation',
          catDesc:
              'Distància vectorial entre el tema sol·licitat i el discurs real.',
          enDesc:
              'Vector distance between the requested topic and actual speech.',
        ),
        _Metric(
          icon: Icons.lightbulb_outline,
          catName: 'Densitat d\'Idees',
          enName: 'Idea Density',
          catDesc:
              'Informació útil en relació al total de paraules emeses.',
          enDesc:
              'Useful information relative to total words produced.',
        ),
        _Metric(
          icon: Icons.swap_horiz,
          catName: 'Ràtio P/S',
          enName: 'P/N Ratio',
          catDesc:
              'Pronoms vs. substantius — indicador primerenc d\'anòmia.',
          enDesc:
              'Pronouns vs. nouns — early indicator of anomia.',
        ),
        _Metric(
          icon: Icons.auto_stories,
          catName: 'Riquesa Lèxica (TTR)',
          enName: 'Lexical Richness (TTR)',
          catDesc:
              'Diversitat de vocabulari: paraules úniques / total de paraules.',
          enDesc:
              'Vocabulary diversity: unique words / total words.',
        ),
        _Metric(
          icon: Icons.account_tree,
          catName: 'Complexitat Sintàctica',
          enName: 'Syntactic Complexity',
          catDesc:
              'Longitud mitjana de la frase i estructura gramatical.',
          enDesc:
              'Average sentence length and grammatical structure.',
        ),
        _Metric(
          icon: Icons.record_voice_over,
          catName: 'Fluïdesa Verbal',
          enName: 'Verbal Fluency',
          catDesc:
              'Continuïtat i ritme del discurs sense interrupcions atípiques.',
          enDesc:
              'Speech continuity and rhythm without atypical interruptions.',
        ),
        _Metric(
          icon: Icons.pause_circle_outline,
          catName: 'Pauses i Vacil·lacions',
          enName: 'Pauses & Hesitations',
          catDesc:
              'Silencis llargs i muletilles de dubte que reflecteixen esforç cognitiu.',
          enDesc:
              'Long silences and filler words reflecting cognitive effort.',
        ),
        _Metric(
          icon: Icons.speed,
          catName: 'Velocitat (WPM)',
          enName: 'Speed (WPM)',
          catDesc:
              'Paraules per minut — la ralentització indica boira mental.',
          enDesc:
              'Words per minute — slowdown indicates brain fog.',
        ),
      ];

  // ──────────────────── BUILD ────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final horizontalPadding = isWide ? screenWidth * 0.08 : 20.0;

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
            maxSize: 2.5,
            minSize: 1.0,
            speed: 0.35,
            maxOpacity: 0.45,
            minOpacity: 0.12,
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: isWide
                        ? _buildWideLayout()
                        : _buildNarrowLayout(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── WIDE (desktop) ────────────────────
  Widget _buildWideLayout() {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildHeroCompact(),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left column: About + Metrics
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildAboutCard(),
                    const SizedBox(height: 14),
                    Expanded(child: _buildMetricsCard()),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              // Right column: Team
              Expanded(
                flex: 4,
                child: _buildTeamCard(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildFooter()),
            SizedBox(
              width: 240,
              height: 48,
              child: _buildCtaButton(),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ──────────────────── NARROW (mobile) ────────────────────
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeroCompact(),
          const SizedBox(height: 20),
          _buildAboutCard(),
          const SizedBox(height: 16),
          _buildMetricsCard(),
          const SizedBox(height: 16),
          _buildTeamCard(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _buildCtaButton(),
          ),
          const SizedBox(height: 12),
          _buildFooter(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ──────────────────── HEADER ────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _pillButton(
            label: _isCatalan ? 'EN' : 'CAT',
            icon: Icons.language,
            onTap: _toggleLanguage,
          ),
          const Spacer(),
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
          horizontal: label != null ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.getBlurContainerColor(isDarkMode),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.containerShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: AppColors.getPrimaryTextColor(isDarkMode)),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────── HERO (compact) ────────────────────
  Widget _buildHeroCompact() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 64,
          child: Image.asset(
            isDarkMode ? TImages.lightLogoText : TImages.darkLogoText,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.local_hospital,
                size: 48,
                color: AppColors.getPrimaryTextColor(isDarkMode)),
          ),
        ),
        const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color:
                AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withAlpha(70),
            ),
          ),
          child: Text(
            'BitsxLaMarató 2025',
            style: TextStyle(
              color: AppColors.getPrimaryButtonColor(isDarkMode),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Flexible(
          child: Text(
            _heroSubtitle,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ──────────────────── ABOUT CARD ────────────────────
  Widget _buildAboutCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionHeader(Icons.psychology, _aboutTitle),
          const SizedBox(height: 10),
          Text(
            _aboutBody,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _featureChip(Icons.videogame_asset,
                  _isCatalan ? 'Jocs cognitius' : 'Cognitive games'),
              _featureChip(Icons.mic,
                  _isCatalan ? 'Anàlisi de veu' : 'Voice analysis'),
              _featureChip(Icons.auto_awesome,
                  _isCatalan ? 'IA personalitzada' : 'Personalised AI'),
              _featureChip(Icons.medical_services,
                  _isCatalan ? 'Panel mèdic' : 'Doctor panel'),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────── METRICS CARD ────────────────────
  Widget _buildMetricsCard() {
    final metrics = _metrics;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionHeader(Icons.analytics, _metricsTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: metrics.map((m) => _metricTile(m)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(_Metric m) {
    final name = _isCatalan ? m.catName : m.enName;
    final desc = _isCatalan ? m.catDesc : m.enDesc;
    return Tooltip(
      message: desc,
      preferBelow: true,
      textStyle: TextStyle(
        color: isDarkMode ? Colors.black87 : Colors.white,
        fontSize: 12,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withAlpha(230) : Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(40),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(m.icon,
                size: 16,
                color: AppColors.getPrimaryButtonColor(isDarkMode)),
            const SizedBox(width: 7),
            Text(
              name,
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── TEAM ────────────────────
  Widget _buildTeamCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.group, _teamTitle),
          const SizedBox(height: 16),
          ..._teamMembers.expand((m) => [
                _teamMemberTile(m),
                const SizedBox(height: 10),
              ]),
        ],
      ),
    );
  }

  Widget _teamMemberTile(_TeamMember member) {
    final initials = member.name.split(' ').map((w) => w[0]).join();
    return GestureDetector(
      onTap: () => _openUrl(member.linkedIn),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(30),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode)
                    .withAlpha(35),
                backgroundImage: NetworkImage(member.imageUrl),
                onBackgroundImageError: (_, __) {},
                child: Text(
                  initials,
                  style: TextStyle(
                    color: AppColors.getPrimaryButtonColor(isDarkMode),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        color: AppColors.getPrimaryTextColor(isDarkMode),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'LinkedIn',
                      style: TextStyle(
                        color: AppColors.getPrimaryButtonColor(isDarkMode),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new,
                  size: 16,
                  color: AppColors.getPrimaryButtonColor(isDarkMode)
                      .withAlpha(140)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow() {
    return Row(
      children: [
        Icon(Icons.group,
            size: 18,
            color: AppColors.getPrimaryButtonColor(isDarkMode)),
        const SizedBox(width: 8),
        Text(
          '${_teamTitle}:',
          style: TextStyle(
            color: AppColors.getPrimaryTextColor(isDarkMode),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        ..._teamMembers.expand((m) => [
              _teamChip(m),
              const SizedBox(width: 6),
            ]),
      ],
    );
  }

  Widget _buildTeamColumn() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionHeader(Icons.group, _teamTitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _teamMembers.map((m) => _teamChip(m)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _teamChip(_TeamMember member) {
    final initials =
        member.name.split(' ').map((w) => w[0]).join();
    return GestureDetector(
      onTap: () => _openUrl(member.linkedIn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.getSecondaryBackgroundColor(isDarkMode),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(40),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withAlpha(35),
              backgroundImage: NetworkImage(member.imageUrl),
              onBackgroundImageError: (_, __) {},
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              member.name,
              style: TextStyle(
                color: AppColors.getPrimaryTextColor(isDarkMode),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new,
                size: 11,
                color: AppColors.getPrimaryButtonColor(isDarkMode)),
          ],
        ),
      ),
    );
  }

  // ──────────────────── CTA ────────────────────
  Widget _buildCtaButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.getPrimaryButtonColor(isDarkMode),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
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
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _ctaButton,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    );
  }

  // ──────────────────── FOOTER ────────────────────
  Widget _buildFooter() {
    return Text(
      '© 2025 LMLG · BitsxLaMarató 2025',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.getTertiaryTextColor(isDarkMode),
        fontSize: 11,
      ),
    );
  }

  // ──────────────────── SHARED WIDGETS ────────────────────
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.containerShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: AppColors.getPrimaryButtonColor(isDarkMode),
              size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: AppColors.getPrimaryTextColor(isDarkMode),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: AppColors.getPrimaryButtonColor(isDarkMode)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
  final String imageUrl;
  const _TeamMember(this.name, this.linkedIn, this.imageUrl);
}

class _Metric {
  final IconData icon;
  final String catName;
  final String enName;
  final String catDesc;
  final String enDesc;
  const _Metric({
    required this.icon,
    required this.catName,
    required this.enName,
    required this.catDesc,
    required this.enDesc,
  });
}
