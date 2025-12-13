import 'package:flutter/material.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../../../utils/app_colors.dart';
import 'patient_registration_service.dart';
import '../micro/mic.dart';
import '../login/login.dart';

class RegisterPacient extends StatefulWidget {
  final bool isDarkMode;
  const RegisterPacient({super.key, this.isDarkMode = false});

  @override
  State<RegisterPacient> createState() => _RegisterPacientState();
}

class _RegisterPacientState extends State<RegisterPacient> {
  late bool isDarkMode;
  final _formKey = GlobalKey<FormState>();

  // Controladores para la primera página
  final _diagnosticController = TextEditingController();
  final _sexeController = TextEditingController();
  final _tractamentController = TextEditingController();
  String? _selectedGender;

  // Controladores para la segunda página
  final _edatController = TextEditingController();
  final _alturaController = TextEditingController();
  final _pesController = TextEditingController();

  // Controladores para la tercera página
  final _nomController = TextEditingController();
  final _cognomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variable para controlar la página actual
  int _currentPage = 0;
  final int _totalPages = 3;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final PatientRegistrationService _registrationService =
      const PatientRegistrationService();

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    _diagnosticController.dispose();
    _sexeController.dispose();
    _tractamentController.dispose();
    _edatController.dispose();
    _alturaController.dispose();
    _pesController.dispose();
    _nomController.dispose();
    _cognomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      // Última página - enviar datos
      _submitForm();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MicScreen()),
      (_) => false,
    );
  }

  String _normalizeGender(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'male' || normalized == 'home') return 'male';
    if (normalized == 'female' || normalized == 'dona') return 'female';
    return '';
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final age = int.tryParse(_edatController.text);
      final height = double.tryParse(_alturaController.text);
      final weight = double.tryParse(_pesController.text);

      if (age == null || height == null || weight == null) {
        _showErrorDialog(
            'Si us plau, introdueix valors numèrics vàlids per a l\'edat, altura i pes.');
        return;
      }

      if (_nomController.text.trim().isEmpty ||
          _cognomController.text.trim().isEmpty) {
        _showErrorDialog(
            'Omple el nom i els cognoms per separat per continuar.');
        return;
      }

      if (_diagnosticController.text.trim().isEmpty ||
          _tractamentController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty) {
        _showErrorDialog('Si us plau, completa tots els camps obligatoris.');
        return;
      }

      final genderValue = _normalizeGender(_selectedGender);
      if (genderValue.isEmpty) {
        _showErrorDialog(
            'El camp sexe ha de tenir el valor "male" o "female" (Home/Dona).');
        return;
      }

      final formData = PatientRegistrationFormData(
        name: _nomController.text.trim(),
        surname: _cognomController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        ailments: _diagnosticController.text.trim(),
        gender: genderValue,
        age: age,
        treatments: _tractamentController.text.trim(),
        heightCm: height,
        weightKg: weight,
        doctors: const [],
      );

      print('DEBUG - Form data being sent:');
      print('  Name: ${formData.name}');
      print('  Surname: ${formData.surname}');
      print('  Email: ${formData.email}');
      print('  Password: ${formData.password}');
      print('  Ailments: ${formData.ailments}');
      print('  Gender: ${formData.gender}');
      print('  Age: ${formData.age}');
      print('  Treatments: ${formData.treatments}');
      print('  Height: ${formData.heightCm}');
      print('  Weight: ${formData.weightKg}');
      print('  Doctors: ${formData.doctors}');

      final result = await _registrationService.register(formData);

      if (result is PatientRegistrationSuccess) {
        final welcomeName = [
          result.response.name,
          result.response.surname,
        ].where((part) => part.trim().isNotEmpty).join(' ');

        _showSuccessDialog(
          'Compte creat i sessió iniciada!',
          'Benvingut/da $welcomeName',
        );
      } else if (result is PatientRegistrationFailure) {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog(
        'S\'ha produït un error inesperat en processar el registre: ${e.toString()}',
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Error',
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
            ),
          ),
          backgroundColor: AppColors.getSecondaryBackgroundColor(isDarkMode),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'D\'acord',
                style: TextStyle(
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: AppColors.getPrimaryTextColor(isDarkMode),
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
            ),
          ),
          backgroundColor: AppColors.getSecondaryBackgroundColor(isDarkMode),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _navigateToHome();
              },
              child: Text(
                'Començar',
                style: TextStyle(
                  color: AppColors.getPrimaryButtonColor(isDarkMode),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPage1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Campo Diagnòstic
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnòstic',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.getFieldBackgroundColor(isDarkMode),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _diagnosticController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: TextStyle(
                  color: AppColors.getInputTextColor(isDarkMode),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Campo Sexe
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sexe',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.getFieldBackgroundColor(isDarkMode),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: TextStyle(
                  color: AppColors.getInputTextColor(isDarkMode),
                ),
                dropdownColor:
                    AppColors.getSecondaryBackgroundColor(isDarkMode),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'male',
                    child: Text('Home'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'female',
                    child: Text('Dona'),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedGender = value;
                    _sexeController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (_selectedGender == null || _selectedGender!.isEmpty) {
                    return 'Si us plau, selecciona el sexe';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Campo Tractament
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tractament',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.getFieldBackgroundColor(isDarkMode),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _tractamentController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: TextStyle(
                  color: AppColors.getInputTextColor(isDarkMode),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Campo Edat
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edat',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.getFieldBackgroundColor(isDarkMode),
                borderRadius: BorderRadius.circular(12),
                border: _currentPage == 0
                    ? Border.all(
                        color: AppColors.getPrimaryButtonColor(isDarkMode),
                        width: 2,
                      )
                    : null,
              ),
              child: TextFormField(
                controller: _edatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: TextStyle(
                  color: AppColors.getInputTextColor(isDarkMode),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Campo Altura (cm)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Altura (cm)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.getFieldBackgroundColor(isDarkMode),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _alturaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: TextStyle(
                  color: AppColors.getInputTextColor(isDarkMode),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Campo Pes (kg)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pes (kg)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.getFieldBackgroundColor(isDarkMode),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _pesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: TextStyle(
                  color: AppColors.getInputTextColor(isDarkMode),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPage3() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row con Nom y Cognom
        Row(
          children: [
            // Campo Nom
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nom',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.getFieldBackgroundColor(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                      style: TextStyle(
                        color: AppColors.getInputTextColor(isDarkMode),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 15),

            // Campo Cognom
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cognoms',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.getFieldBackgroundColor(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _cognomController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                      style: TextStyle(
                        color: AppColors.getInputTextColor(isDarkMode),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // Campo Email
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.getFieldBackgroundColor(isDarkMode),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  suffixIcon: Icon(
                    Icons.email_outlined,
                    color: AppColors.getSecondaryTextColor(isDarkMode),
                  ),
                ),
                style: TextStyle(
                  color: AppColors.getInputTextColor(isDarkMode),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // Campo Password
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contrasenya',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.getFieldBackgroundColor(isDarkMode),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                style: TextStyle(
                  color: AppColors.getInputTextColor(isDarkMode),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.getBackgroundGradient(isDarkMode),
            ),
          ),

          // Sistema de partículas usando el widget reutilizable
          ParticleSystemWidget(
            isDarkMode: isDarkMode,
            particleCount: 50,
            maxSize: 3.0,
            minSize: 1.0,
            speed: 0.5,
            maxOpacity: 0.6,
            minOpacity: 0.2,
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Header con botón de tema y back
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón de back
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
                      // Botón de tema
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
                ),

                // Logo pequeño en la parte superior
                Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  child: SizedBox(
                    height: 120,
                    width: 180,
                    child: Image.asset(
                      isDarkMode ? TImages.lightLogoText : TImages.darkLogoText,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_hospital,
                          size: 60,
                          color: AppColors.getPrimaryTextColor(isDarkMode),
                        );
                      },
                    ),
                  ),
                ),

                // Spacer para empujar el contenido hacia arriba
                const Spacer(),
              ],
            ),
          ),

          // Recuadro de formulario posicionado desde arriba
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: MediaQuery.of(context).size.width >= 800
                ? MediaQuery.of(context).size.width * 0.25
                : 0,
            right: MediaQuery.of(context).size.width >= 800
                ? MediaQuery.of(context).size.width * 0.25
                : 0,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: AppColors.getSecondaryBackgroundColor(isDarkMode),
                borderRadius: const BorderRadius.all(Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 30.0, vertical: 25.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Título
                        Text(
                          'Registra\'t a LMLG!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Indicador de página
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_totalPages, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? AppColors.getPrimaryButtonColor(
                                        isDarkMode)
                                    : AppColors.getTertiaryTextColor(isDarkMode)
                                        .withOpacity(0.3),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 25),

                        // Contenido del carrusel
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentPage == 0
                              ? _buildPage1()
                              : _currentPage == 1
                                  ? _buildPage2()
                                  : _buildPage3(),
                        ),

                        const SizedBox(height: 30),

                        // Botones de navegación
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón anterior si estamos en página 2+
                            if (_currentPage > 0)
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.getPrimaryButtonColor(
                                                isDarkMode)
                                            .withOpacity(0.5),
                                    foregroundColor:
                                        AppColors.getPrimaryButtonTextColor(
                                            isDarkMode),
                                    shape: const CircleBorder(),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: _previousPage,
                                  child: const Icon(
                                    Icons.arrow_back,
                                    size: 24,
                                  ),
                                ),
                              ),

                            // Botón principal
                            if (_currentPage == _totalPages - 1)
                              // Botón REGISTER en la última página
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      left: _currentPage > 0 ? 15 : 0),
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.getPrimaryButtonColor(
                                                isDarkMode),
                                        foregroundColor:
                                            AppColors.getPrimaryButtonTextColor(
                                                isDarkMode),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: _isLoading ? null : _nextPage,
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2),
                                            )
                                          : const Text(
                                              'REGISTRA\'T',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              // Botón circular de flecha para navegación
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.getPrimaryButtonColor(
                                            isDarkMode),
                                    foregroundColor:
                                        AppColors.getPrimaryButtonTextColor(
                                            isDarkMode),
                                    shape: const CircleBorder(),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: _nextPage,
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // Link "Ja tens un compte? Login"
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) =>
                                    LoginScreen(isDarkMode: isDarkMode),
                              ),
                            );
                          },
                          child: Text(
                            'Ja tens un compte? Inicia sessió',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.getPrimaryTextColor(isDarkMode),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  AppColors.getPrimaryTextColor(isDarkMode),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
