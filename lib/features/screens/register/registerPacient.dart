import 'package:flutter/material.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/effects/particle_system.dart';

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implementar lógica de registro de paciente
      print('Pacient register:');
      print('Diagnostic: ${_diagnosticController.text}');
      print('Sexe: ${_sexeController.text}');
      print('Tractament: ${_tractamentController.text}');
      print('Edat: ${_edatController.text}');
      print('Altura: ${_alturaController.text}');
      print('Pes: ${_pesController.text}');
      print('Nom: ${_nomController.text}');
      print('Cognom: ${_cognomController.text}');
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');
    }
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
                color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF7289DA) : Colors.white,
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
                  color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
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
                color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF7289DA) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _sexeController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                ),
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
                color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF7289DA) : Colors.white,
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
                  color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
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
                color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF7289DA) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: _currentPage == 0
                    ? Border.all(
                        color: isDarkMode
                            ? const Color(0xFF0077B6)
                            : const Color(0xFF0077B6),
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
                  color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
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
                color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF7289DA) : Colors.white,
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
                  color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
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
                color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF7289DA) : Colors.white,
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
                  color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
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
                      color:
                          isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? const Color(0xFF7289DA) : Colors.white,
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
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
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
                    'Cognom',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? const Color(0xFF7289DA) : Colors.white,
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
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
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
                color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF7289DA) : Colors.white,
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
                    color:
                        isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
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
                color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF7289DA) : Colors.white,
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
                      color:
                          isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        const Color(0xFF1E2124),
                        const Color(0xFF1E2124),
                        const Color(0xFF1E2124)
                      ]
                    : [
                        const Color(0xFF90E0EF),
                        const Color(0xFF90E0EF),
                        const Color(0xFF90E0EF)
                      ],
              ),
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
                          color: isDarkMode
                              ? Colors.grey[800]?.withOpacity(0.8)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      // Botón de tema
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[800]?.withOpacity(0.8)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
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
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
                          ),
                          onPressed: _toggleTheme,
                        ),
                      ),
                    ],
                  ),
                ),

                // Logo pequeño en la parte superior
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    height: 100,
                    width: 150,
                    child: Image.asset(
                      isDarkMode ? TImages.lightLogo : TImages.darkLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_hospital,
                          size: 40,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1E3A8A),
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
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF282B30)
                    : const Color(0xFFCAF0F8),
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
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
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
                                    ? (isDarkMode
                                        ? const Color(0xFF0077B6)
                                        : const Color(0xFF0077B6))
                                    : (isDarkMode
                                        ? Colors.white30
                                        : const Color(0xFF1E3A8A)
                                            .withOpacity(0.3)),
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
                                    backgroundColor: isDarkMode
                                        ? const Color(0xFF7289DA)
                                            .withOpacity(0.5)
                                        : const Color(0xFF0077B6)
                                            .withOpacity(0.5),
                                    foregroundColor: Colors.white,
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
                                        backgroundColor: isDarkMode
                                            ? const Color(0xFF7289DA)
                                            : const Color(0xFF0077B6),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: _nextPage,
                                      child: const Text(
                                        'REGISTER',
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
                                    backgroundColor: isDarkMode
                                        ? const Color(0xFF7289DA)
                                        : const Color(0xFF0077B6),
                                    foregroundColor: Colors.white,
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
                            Navigator.pop(context); // Volver atrás
                          },
                          child: Text(
                            'Ja tens un compte? Login',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.8)
                                  : const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: isDarkMode
                                  ? Colors.white.withOpacity(0.8)
                                  : const Color(0xFF1E3A8A),
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
