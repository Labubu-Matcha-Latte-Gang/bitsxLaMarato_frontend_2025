import 'package:flutter/material.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../../../utils/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../models/patient_models.dart';
import '../login/login.dart';

class RegisterDoctor extends StatefulWidget {
  final bool isDarkMode;
  const RegisterDoctor({super.key, this.isDarkMode = false});

  @override
  State<RegisterDoctor> createState() => _RegisterDoctorState();
}

class _RegisterDoctorState extends State<RegisterDoctor> {
  late bool isDarkMode;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Crear el request para la API
        final request = DoctorRegistrationRequest(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          patients: [], // Por defecto sin pacientes asignados
        );

        print('DEBUG - Doctor Form data being sent:');
        print('  Name: ${request.name}');
        print('  Surname: ${request.surname}');
        print('  Email: ${request.email}');
        print('  Password: ${request.password}');
        print('  Patients: ${request.patients}');

        // Llamar a la API
        final response = await ApiService.registerDoctor(request);

        // Si llega aquí, el registro fue exitoso
        _showSuccessDialog(
          'Metge registrat amb èxit!',
          'Benvingut/da Dr. ${response.name} ${response.surname}',
        );
      } catch (e) {
        String errorMessage = 'Error en registrar el metge';
        if (e is ApiException) {
          errorMessage = e.message;
        } else {
          errorMessage = 'Error de connexió: ${e.toString()}';
        }
        _showErrorDialog(errorMessage);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
                // Navegar a la pantalla de login
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(isDarkMode: isDarkMode),
                  ),
                );
              },
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
                  margin: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 80,
                    width: 120,
                    child: Image.asset(
                      isDarkMode ? TImages.lightLogo : TImages.darkLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_hospital,
                          size: 40,
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

          // Recuadro de formulario posicionado a 1/6 desde el final
          Positioned(
            bottom: MediaQuery.of(context).size.height / 8,
            left: 0,
            right: 0,
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
                    horizontal: 30.0, vertical: 20.0),
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

                        const SizedBox(height: 20),

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
                                      color: AppColors.getSecondaryTextColor(
                                          isDarkMode),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: AppColors.getFieldBackgroundColor(
                                          isDarkMode),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 12),
                                      ),
                                      style: TextStyle(
                                        color: AppColors.getInputTextColor(
                                            isDarkMode),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Si us plau, introdueix el nom';
                                        }
                                        return null;
                                      },
                                    ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Si us plau, introdueix el cognom';
                                        }
                                        return null;
                                      },
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
                                    'Cognom',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.getSecondaryTextColor(
                                          isDarkMode),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color(0xFF7289DA)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextFormField(
                                      controller: _surnameController,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 12),
                                      ),
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : const Color(0xFF1E3A8A),
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
                                color: isDarkMode
                                    ? Colors.white70
                                    : const Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF7289DA)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12),
                                  suffixIcon: Icon(
                                    Icons.email_outlined,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : const Color(0xFF1E3A8A),
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1E3A8A),
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
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : const Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF7289DA)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : const Color(0xFF1E3A8A),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Botón REGISTER
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? const Color(0xFF7289DA)
                                  : const Color(0xFF0077B6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _submitForm();
                                    }
                                  },
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'REGISTER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Link "Ja tens un compte? Login"
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Volver atrás
                          },
                          child: Text(
                            'Ja tens un compte? Login',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white60
                                  : const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
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
