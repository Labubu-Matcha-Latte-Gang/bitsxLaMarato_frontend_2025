import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/user_models.dart';
import '../../../services/api_service.dart';
import '../../../services/session_manager.dart';
import '../../../utils/doctor_colors.dart';
import '../initialPage/initialPage.dart';
import 'doctor_patient_detail_page.dart';

class DoctorHomePage extends StatefulWidget {
  final bool initialDarkMode;

  const DoctorHomePage({
    super.key,
    this.initialDarkMode = false,
  });

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  bool isDarkMode = false;
  bool _loadingPatients = false;
  bool _searching = false;
  bool _mutatingPatient = false;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isLoggingOut = false;

  List<PatientDataResponse> _assignedPatients = [];
  List<UserProfile> _searchResults = [];
  Set<String> _selectedEmails = {};
  UserProfile? _doctorProfile;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final profile = await ApiService.getAndCacheCurrentUser();
      if (!mounted) return;
      setState(() {
        _doctorProfile = profile;
      });
      final emails = profile.role.patients;
      await _loadAssignedPatients(emails);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      // No extra state to toggle here; keeping setState minimal.
    }
  }

  Future<void> _loadAssignedPatients(List<String> emails) async {
    setState(() {
      _loadingPatients = true;
      _errorMessage = null;
    });

    final List<PatientDataResponse> loaded = [];
    for (final email in emails) {
      try {
        final data = await ApiService.getPatientData(email);
        loaded.add(data);
      } catch (e) {
        _showSnack(
          'No s\'ha pogut carregar $email. Revisa la connexió o els permisos.',
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _assignedPatients = loaded;
      _selectedEmails =
          _selectedEmails.where((email) => emails.contains(email)).toSet();
      _loadingPatients = false;
    });
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Future<void> _confirmAndLogout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tancar sessió'),
            content: const Text(
              'Vols sortir de l\'aplicació? Es tancarà la sessió actual.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel·lar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Tancar sessió'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout) return;

    setState(() => _isLoggingOut = true);
    final success = await SessionManager.logout();
    if (!mounted) return;

    setState(() => _isLoggingOut = false);

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const InitialPage()),
        (route) => false,
      );
    } else {
      _showSnack(
        'No s\'ha pogut tancar la sessió. Torna-ho a provar.',
        isError: true,
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(value.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searching = true;
    });

    try {
      final result = await ApiService.searchPatientsForDoctor(
        query,
        limit: 12,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = result.results;
      });
    } catch (e) {
      _showSnack(
        'No s\'han pogut cercar pacients: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  Future<void> _assignPatient(String email) async {
    setState(() {
      _mutatingPatient = true;
    });
    try {
      final profile = await ApiService.assignPatientsToDoctor([email]);
      await _loadAssignedPatients(profile.role.patients);
      setState(() {
        _searchResults = [];
        _searchController.clear();
      });
      _showSnack('Pacient afegit correctament.');
    } catch (e) {
      _showSnack(
        'No s\'ha pogut afegir el pacient: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _mutatingPatient = false;
        });
      }
    }
  }

  Future<void> _removePatient(String email) async {
    setState(() {
      _mutatingPatient = true;
    });
    try {
      final profile = await ApiService.unassignPatientsFromDoctor([email]);
      await _loadAssignedPatients(profile.role.patients);
      _showSnack('Pacient eliminat de la teva llista.');
    } catch (e) {
      _showSnack(
        'No s\'ha pogut eliminar el pacient: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _mutatingPatient = false;
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

  void _toggleSelection(String email) {
    setState(() {
      if (_selectedEmails.contains(email)) {
        _selectedEmails.remove(email);
      } else {
        _selectedEmails.add(email);
      }
    });
  }

  void _openComparison() {
    if (_selectedEmails.length < 2) {
      _showSnack(
        'Selecciona com a mínim dos pacients per comparar.',
        isError: true,
      );
      return;
    }

    final selected = _assignedPatients
        .where((p) => _selectedEmails.contains(p.patient.email))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorPatientsComparisonSheet(
        patients: selected,
        isDarkMode: isDarkMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = DoctorColors.background(isDarkMode);
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: DoctorColors.headerGradient(isDarkMode),
            ),
            height: 220,
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _bootstrap,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildHeroCard(),
                  const SizedBox(height: 16),
                  _buildSearchCard(),
                  const SizedBox(height: 18),
                  _buildPatientsSection(),
                  const SizedBox(height: 16),
                  _buildCompareButton(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorBanner(_errorMessage!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Espai del metge',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestiona i compara els teus pacients',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Tancar sessió',
                onPressed: _isLoggingOut ? null : _confirmAndLogout,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                  color: Colors.white,
                ),
                onPressed: _toggleTheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    final cardColor = DoctorColors.surface(isDarkMode);
    final profile = _doctorProfile;
    final fullName = [
      profile?.name,
      profile?.surname,
    ]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .join(' ');
    final genderRaw = profile?.role.gender?.toLowerCase();
    String greetingTitle = 'Doctor/a';
    if (genderRaw != null) {
      if (genderRaw == 'female' || genderRaw == 'dona') {
        greetingTitle = 'Doctora';
      } else if (genderRaw == 'male' || genderRaw == 'home') {
        greetingTitle = 'Doctor';
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: DoctorColors.cardShadow(isDarkMode),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: DoctorColors.border(isDarkMode),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor:
                DoctorColors.secondary(isDarkMode).withOpacity(0.12),
            child: Icon(
              Icons.medical_services_outlined,
              color: DoctorColors.primary(isDarkMode),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty
                      ? '$greetingTitle $fullName'
                      : 'Espai del metge',
                  style: TextStyle(
                    color: DoctorColors.textPrimary(isDarkMode),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigna pacients, visualitza els seus informes i compara dades en un sol lloc.',
                  style: TextStyle(
                    color: DoctorColors.textSecondary(isDarkMode),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    final cardColor = DoctorColors.surface(isDarkMode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cerca pacients',
                style: TextStyle(
                  color: DoctorColors.textPrimary(isDarkMode),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (_searching)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Introdueix nom o cognom (mínim 2 caràcters)',
              filled: true,
              fillColor:
                  DoctorColors.lightAccent.withOpacity(isDarkMode ? 0.08 : 0.6),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._searchResults
                .map(
                  (p) => _SearchResultTile(
                    profile: p,
                    isDarkMode: isDarkMode,
                    onAdd:
                        _mutatingPatient ? null : () => _assignPatient(p.email),
                  ),
                )
                .toList(),
          ],
          if (!_searching &&
              _searchResults.isEmpty &&
              _searchController.text.length >= 2)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Cap coincidència amb aquest filtre.',
                style: TextStyle(
                  color: DoctorColors.textSecondary(isDarkMode),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientsSection() {
    final cardColor = DoctorColors.surface(isDarkMode);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Els meus pacients',
                style: TextStyle(
                  color: DoctorColors.textPrimary(isDarkMode),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (_loadingPatients)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_assignedPatients.isEmpty && !_loadingPatients)
            Text(
              'Encara no tens pacients assignats. Afegeix-los des del cercador.',
              style: TextStyle(
                color: DoctorColors.textSecondary(isDarkMode),
              ),
            ),
          if (_assignedPatients.isNotEmpty)
            ..._assignedPatients
                .map(
                  (patient) => _PatientCard(
                    data: patient,
                    isDarkMode: isDarkMode,
                    selected: _selectedEmails.contains(patient.patient.email),
                    onSelect: () => _toggleSelection(patient.patient.email),
                    onRemove: _mutatingPatient
                        ? null
                        : () => _removePatient(patient.patient.email),
                    onOpenDetail: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DoctorPatientDetailPage(
                          patientEmail: patient.patient.email,
                          initialDarkMode: isDarkMode,
                          initialData: patient,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  Widget _buildCompareButton() {
    final enabled = _selectedEmails.length >= 2;
    return ElevatedButton.icon(
      onPressed: enabled ? _openComparison : null,
      icon: const Icon(Icons.table_chart),
      style: ElevatedButton.styleFrom(
        backgroundColor: DoctorColors.primary(isDarkMode),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      label: Text(
        enabled
            ? 'Comparar ${_selectedEmails.length} pacients'
            : 'Selecciona almenys dos pacients per comparar',
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.critical(isDarkMode).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DoctorColors.critical(isDarkMode).withOpacity(0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: DoctorColors.critical(isDarkMode)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: DoctorColors.textPrimary(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final UserProfile profile;
  final bool isDarkMode;
  final VoidCallback? onAdd;

  const _SearchResultTile({
    required this.profile,
    required this.isDarkMode,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.background(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DoctorColors.border(isDarkMode)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                DoctorColors.secondary(isDarkMode).withOpacity(0.12),
            child: Icon(
              Icons.person_add_alt,
              color: DoctorColors.primary(isDarkMode),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.name} ${profile.surname}',
                  style: TextStyle(
                    color: DoctorColors.textPrimary(isDarkMode),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  profile.email,
                  style: TextStyle(
                    color: DoctorColors.textSecondary(isDarkMode),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorColors.primary(isDarkMode),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Afegir'),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientDataResponse data;
  final bool isDarkMode;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;
  final VoidCallback onOpenDetail;

  const _PatientCard({
    required this.data,
    required this.isDarkMode,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final profile = data.patient;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DoctorColors.background(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? DoctorColors.primary(isDarkMode)
              : DoctorColors.border(isDarkMode),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => onSelect(),
                activeColor: DoctorColors.primary(isDarkMode),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.name} ${profile.surname}',
                      style: TextStyle(
                        color: DoctorColors.textPrimary(isDarkMode),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      profile.email,
                      style: TextStyle(
                        color: DoctorColors.textSecondary(isDarkMode),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.open_in_new,
                  color: DoctorColors.primary(isDarkMode),
                ),
                onPressed: onOpenDetail,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _InfoChip(
                label: translateGenderToCatalan(data.patient.role.gender) ??
                    'Sense gènere',
                icon: Icons.transgender,
                isDarkMode: isDarkMode,
              ),
              if (data.patient.role.age != null)
                _InfoChip(
                  label: '${data.patient.role.age} anys',
                  icon: Icons.cake_outlined,
                  isDarkMode: isDarkMode,
                ),
              if (data.patient.role.weightKg != null)
                _InfoChip(
                  label: '${data.patient.role.weightKg?.toStringAsFixed(1)} kg',
                  icon: Icons.monitor_weight_outlined,
                  isDarkMode: isDarkMode,
                ),
              if (data.patient.role.heightCm != null)
                _InfoChip(
                  label: '${data.patient.role.heightCm?.toStringAsFixed(0)} cm',
                  icon: Icons.height,
                  isDarkMode: isDarkMode,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onRemove,
                icon: Icon(Icons.link_off,
                    color: DoctorColors.critical(isDarkMode)),
                label: Text(
                  'Desvincular',
                  style: TextStyle(
                    color: DoctorColors.critical(isDarkMode),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDarkMode;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: DoctorColors.primary(isDarkMode),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: DoctorColors.textPrimary(isDarkMode),
        ),
      ),
      backgroundColor: DoctorColors.surface(isDarkMode),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: DoctorColors.border(isDarkMode)),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class DoctorPatientsComparisonSheet extends StatelessWidget {
  final List<PatientDataResponse> patients;
  final bool isDarkMode;

  const DoctorPatientsComparisonSheet({
    super.key,
    required this.patients,
    required this.isDarkMode,
  });

  double _averageScore(PatientDataResponse data) {
    if (data.scores.isEmpty) return 0;
    final total = data.scores.fold<double>(
      0,
      (sum, score) => sum + score.score,
    );
    return total / data.scores.length;
  }

  @override
  Widget build(BuildContext context) {
    final bg = DoctorColors.surface(isDarkMode);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: DoctorColors.border(isDarkMode)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DoctorColors.textSecondary(isDarkMode).withOpacity(0.4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comparativa de pacients',
              style: TextStyle(
                color: DoctorColors.textPrimary(isDarkMode),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: TextStyle(
                  color: DoctorColors.textPrimary(isDarkMode),
                  fontWeight: FontWeight.bold,
                ),
                dataTextStyle: TextStyle(
                  color: DoctorColors.textSecondary(isDarkMode),
                ),
                columns: [
                  const DataColumn(label: Text('Dada')),
                  ...patients.map(
                    (p) => DataColumn(
                      label: Text(
                        p.patient.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                rows: [
                  _buildRow(
                    'Edat',
                    patients.map((p) => p.patient.role.age?.toString() ?? '—'),
                  ),
                  _buildRow(
                    'Pes (kg)',
                    patients.map((p) =>
                        p.patient.role.weightKg?.toStringAsFixed(1) ?? '—'),
                  ),
                  _buildRow(
                    'Alçada (cm)',
                    patients.map((p) =>
                        p.patient.role.heightCm?.toStringAsFixed(0) ?? '—'),
                  ),
                  _buildRow(
                    'Mitjana puntuacions',
                    patients
                        .map((p) => _averageScore(p).toStringAsFixed(1))
                        .toList(),
                  ),
                  _buildRow(
                    'Última puntuació',
                    patients
                        .map((p) => p.scores.isNotEmpty
                            ? p.scores.first.score.toStringAsFixed(1)
                            : '—')
                        .toList(),
                  ),
                  _buildRow(
                    'Preguntes contestades',
                    patients.map((p) => p.questions.length.toString()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(String label, Iterable<String> values) {
    return DataRow(
      cells: [
        DataCell(Text(label)),
        ...values.map((v) => DataCell(Text(v))).toList(),
      ],
    );
  }
}
