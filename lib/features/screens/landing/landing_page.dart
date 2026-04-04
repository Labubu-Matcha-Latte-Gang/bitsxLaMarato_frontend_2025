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
      ? 'LMLG NeuroSight és una plataforma innovadora d\'intel·ligència '
        'artificial dissenyada per a la detecció integrada i el seguiment '
        'longitudinal del dèficit cognitiu en pacients oncològics — el '
        '"Brain Fog" que experimenten entre el 15% i el 50% dels pacients '
        'amb càncer.\n\n'
        'Ofereix un Perfil Cognitiu Unificat que combina tres fonts de '
        'dades: anàlisi de la parla mitjançant el nostre motor NLP amb 9 '
        'mètriques lingüístiques clau, tests cognitius gamificats que '
        'mesuren memòria i atenció, i un diari subjectiu que recull el '
        'feedback diari del pacient.\n\n'
        'Amb aquesta anàlisi multi-modal, NeuroSight no només detecta el '
        'dèficit sinó que proposa recursos psicoeducatius i tasques de '
        'rehabilitació cognitiva personalitzada, tancant el cicle des de '
        'l\'avaluació fins a la intervenció — tot des de casa del pacient.'
      : 'LMLG NeuroSight is an innovative AI-powered platform designed for '
        'integrated detection and longitudinal monitoring of cognitive '
        'deficit in oncology patients — the "Brain Fog" experienced by '
        '15–50% of cancer patients.\n\n'
        'It provides a Unified Cognitive Profile combining three data '
        'sources: speech analysis through our NLP engine with 9 key '
        'linguistic metrics, gamified cognitive tests measuring memory '
        'and attention, and a subjective diary capturing the patient\'s '
        'daily feedback.\n\n'
        'Through this multi-modal analysis, NeuroSight not only detects '
        'deficit but proposes psychoeducational resources and personalised '
        'cognitive rehabilitation tasks, closing the loop from assessment '
        'to intervention — all from the patient\'s home.';
  String get _metricsTitle =>
      _isCatalan ? 'Mètriques mesurades' : 'Measured metrics';
  String get _teamTitle => _isCatalan ? 'L\'equip' : 'The team';
  String get _ctaButton => _isCatalan ? 'ENTRA A L\'APP' : 'ENTER THE APP';

  static const _teamMembers = [
    _TeamMember(
      'Erik Batiste',
      'https://www.linkedin.com/in/erikbatisteviader/',
      'https://avatars.githubusercontent.com/u/96847443?s=160',
      'DevOps & Backend',
      'Infraestructura, CI/CD, contenidorització i integració de serveis al núvol.',
      'Infrastructure, CI/CD, containerisation and cloud service integration.',
    ),
    _TeamMember(
      'Oriol Orbea',
      'https://www.linkedin.com/in/oriol-orbea-suari/',
      'https://avatars.githubusercontent.com/u/145404641?s=160',
      'Backend & Full Stack',
      'Arquitectura del backend amb Python/Flask, API RESTful i integració Frontend.',
      'Backend architecture with Python/Flask, RESTful API and Frontend integration.',
    ),
    _TeamMember(
      'Ernest Rull',
      'https://www.linkedin.com/in/ernest-rull-turigas/',
      'https://avatars.githubusercontent.com/u/118774478?s=160',
      'Lead Frontend',
      'Arquitectura UI amb Flutter, tests cognitius gamificats i sistema de rols.',
      'UI architecture with Flutter, gamified cognitive tests and role system.',
    ),
    _TeamMember(
      'Kaleb Grove',
      'https://www.linkedin.com/in/kaleb-grove/',
      'https://avatars.githubusercontent.com/u/72881364?s=160',
      'Frontend & Games',
      'Disseny d\'interfície, jocs interactius i experiència d\'usuari amb Flutter.',
      'Interface design, interactive games and user experience with Flutter.',
    ),
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
    final metrics = _metrics;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeroCompact(),
          const SizedBox(height: 20),
          _buildAboutCard(),
          const SizedBox(height: 16),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _sectionHeader(Icons.analytics, _metricsTitle),
                const SizedBox(height: 12),
                ...metrics.map((m) => _metricRow(m)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTeamWrap(),
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
          height: 80,
          child: Image.asset(
            isDarkMode ? TImages.lightLogoText : TImages.darkLogoText,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.local_hospital,
                size: 56,
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
    final leftCol = metrics.sublist(0, 5);
    final rightCol = metrics.sublist(5);
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.analytics, _metricsTitle),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: leftCol.map((m) => _metricRow(m)).toList(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: rightCol.map((m) => _metricRow(m)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(_Metric m) {
    final name = _isCatalan ? m.catName : m.enName;
    final desc = _isCatalan ? m.catDesc : m.enDesc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color:
                  AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(18),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(m.icon,
                size: 15,
                color: AppColors.getPrimaryButtonColor(isDarkMode)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: AppColors.getTertiaryTextColor(isDarkMode),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _teamVerticalCard(_teamMembers[0])),
                const SizedBox(width: 10),
                Expanded(child: _teamVerticalCard(_teamMembers[1])),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _teamVerticalCard(_teamMembers[2])),
                const SizedBox(width: 10),
                Expanded(child: _teamVerticalCard(_teamMembers[3])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamVerticalCard(_TeamMember member) {
    final desc = _isCatalan ? member.catDesc : member.enDesc;
    return GestureDetector(
      onTap: () => _openUrl(member.linkedIn),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getPrimaryButtonColor(isDarkMode)
                  .withAlpha(30),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 36,
                backgroundColor:
                    AppColors.getPrimaryButtonColor(isDarkMode)
                        .withAlpha(35),
                backgroundImage: NetworkImage(member.imageUrl),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(height: 12),
              Text(
                member.name,
                style: TextStyle(
                  color: AppColors.getPrimaryTextColor(isDarkMode),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                member.role,
                style: TextStyle(
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: TextStyle(
                  color: AppColors.getTertiaryTextColor(isDarkMode),
                  fontSize: 11,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new,
                      size: 12,
                      color: AppColors.getPrimaryButtonColor(isDarkMode)
                          .withAlpha(140)),
                  const SizedBox(width: 4),
                  Text(
                    'LinkedIn',
                    style: TextStyle(
                      color: AppColors.getPrimaryButtonColor(isDarkMode)
                          .withAlpha(140),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamWrap() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionHeader(Icons.group, _teamTitle),
          const SizedBox(height: 14),
          ..._teamMembers.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _teamMobileTile(m),
              )),
        ],
      ),
    );
  }

  Widget _teamMobileTile(_TeamMember member) {
    final desc = _isCatalan ? member.catDesc : member.enDesc;
    return GestureDetector(
      onTap: () => _openUrl(member.linkedIn),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                AppColors.getPrimaryButtonColor(isDarkMode).withAlpha(30),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  AppColors.getPrimaryButtonColor(isDarkMode)
                      .withAlpha(35),
              backgroundImage: NetworkImage(member.imageUrl),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      color: AppColors.getPrimaryTextColor(isDarkMode),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    member.role,
                    style: TextStyle(
                      color: AppColors.getPrimaryButtonColor(isDarkMode),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      color: AppColors.getTertiaryTextColor(isDarkMode),
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new,
                size: 14,
                color: AppColors.getPrimaryButtonColor(isDarkMode)
                    .withAlpha(140)),
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
  final String role;
  final String catDesc;
  final String enDesc;
  const _TeamMember(
      this.name, this.linkedIn, this.imageUrl, this.role, this.catDesc, this.enDesc);
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
