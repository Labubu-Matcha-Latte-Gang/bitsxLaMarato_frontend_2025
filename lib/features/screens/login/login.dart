import 'package:flutter/material.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';
import '../../../utils/app_colors.dart';
import '../micro/mic.dart';
import '../../../services/api_service.dart';
import '../../../models/patient_models.dart';
import '../../../services/session_manager.dart';

class LoginScreen extends StatefulWidget {
  final bool isDarkMode;
  const LoginScreen({super.key, this.isDarkMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool isDarkMode;
  final _formKey = GlobalKey<FormState>();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final response = await ApiService.loginUser(request);

      final tokenSaved = await SessionManager.saveToken(response.accessToken);
      if (!tokenSaved) {
        _showErrorDialog('Error guardant la sessió');
        return;
      }

        if (tokenSaved) {
          // Mostrar mensaje de éxito y navegar
          final userName = response.user?.name ?? 'Usuario';
          final userSurname = response.user?.surname ?? '';
          _showSuccessDialog(
            'Sessió iniciada amb èxit!',
            'Benvingut/da $userName $userSurname'.trim(),
          );
        } else {
          _showErrorDialog('Error guardant la sessió');
        }
      } catch (e) {
        String errorMessage = 'Error en iniciar sessió';
        if (e is ApiException) {
          errorMessage = e.message;
        } else {
          errorMessage = 'Error de connexió: ${e.toString()}';
        }
        _showErrorDialog(errorMessage);
      } finally {
        if (mounted){
          setState(() {
            _isLoading = false;
          });
        }
      }

      if (!mounted) return;

      final userName = response.user?.name ?? 'Usuari';
      final userSurname = response.user?.surname ?? '';
      _showSuccessDialog(
        'Sessió iniciada amb èxit!',
        'Benvingut/da $userName $userSurname'.trim(),
      );
    } on ApiException catch (e) {
      _showErrorDialog(e.message);
    } catch (e) {
      _showErrorDialog('Error de connexió: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                // TODO: Arreglar la navegación a la pantalla principal
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MicScreen()
                  ),
                );
                print(
                    'Usuario logueado exitosamente - navegar a pantalla principal');
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

                // Logo grande en la parte superior
                Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  child: SizedBox(
                    height: 120,
                    width: 180,
                    child: Image.asset(
                      isDarkMode ? TImages.lightLogo : TImages.darkLogo,
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
            top: MediaQuery.of(context).size.height * 0.35,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
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
                          'Benvingut de nou!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPrimaryTextColor(isDarkMode),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Campo Email
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    AppColors.getSecondaryTextColor(isDarkMode),
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
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12),
                                  suffixIcon: Icon(
                                    Icons.email_outlined,
                                    color: AppColors.getPlaceholderTextColor(
                                        isDarkMode),
                                  ),
                                ),
                                style: TextStyle(
                                  color:
                                      AppColors.getInputTextColor(isDarkMode),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Campo Password
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    AppColors.getSecondaryTextColor(isDarkMode),
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
                                      color: AppColors.getPlaceholderTextColor(
                                          isDarkMode),
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
                                  color:
                                      AppColors.getInputTextColor(isDarkMode),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // Link "T'has oblidat de la contrasenya?"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                // TODO: Implementar recuperación de contraseña
                              },
                              child: Text(
                                'T\'has oblidat de la contrasenya?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.getTertiaryTextColor(
                                      isDarkMode),
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Botón LOGIN
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.getPrimaryButtonColor(isDarkMode),
                              foregroundColor:
                                  AppColors.getPrimaryButtonTextColor(
                                      isDarkMode),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : _submitLogin,
                            child: _isLoading ?
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.getPrimaryButtonTextColor(isDarkMode),
                                        ),
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Iniciant sessió...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ) :
                                const Text(
                                  'INICIA SESSIÓ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                            ),
                        ),

                        const SizedBox(height: 15),

                        // Link "Nou a LMLG? Registra't"
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');

                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Nou a LMLG? Registra\'t',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.getPrimaryTextColor(isDarkMode),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.getPrimaryTextColor(isDarkMode),
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
