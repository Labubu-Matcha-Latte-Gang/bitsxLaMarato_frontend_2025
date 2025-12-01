import 'package:flutter/material.dart';
import 'dart:math';
import '../../../utils/constants/image_strings.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.opacity,
  });
}

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> with TickerProviderStateMixin {
  bool isDarkMode = false;
  late AnimationController _animationController;
  List<Particle> particles = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )..repeat();
    
    _initializeParticles();
    _animationController.addListener(_updateParticles);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    particles.clear();
    for (int i = 0; i < 50; i++) {
      particles.add(Particle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        vx: (random.nextDouble() - 0.5) * 0.5,
        vy: (random.nextDouble() - 0.5) * 0.5,
        size: random.nextDouble() * 3 + 1,
        color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
        opacity: random.nextDouble() * 0.6 + 0.2,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (var particle in particles) {
        particle.x += particle.vx;
        particle.y += particle.vy;

        // Rebotar en los bordes
        if (particle.x < 0 || particle.x > 400) {
          particle.vx *= -1;
        }
        if (particle.y < 0 || particle.y > 800) {
          particle.vy *= -1;
        }

        // Mantener dentro de los límites
        particle.x = particle.x.clamp(0, 400);
        particle.y = particle.y.clamp(0, 800);
      }
    });
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
      // Actualizar colores de partículas
      for (var particle in particles) {
        particle.color = isDarkMode ? Colors.white : const Color(0xFF1E3A8A);
      }
    });
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
                    ? [const Color(0xFF1E2124), const Color(0xFF1E2124), const Color(0xFF1E2124)]
                    : [const Color(0xFF90E0EF), const Color(0xFF90E0EF), const Color(0xFF90E0EF)],
              ),
            ),
          ),
          
          // Sistema de partículas
          CustomPaint(
            painter: ParticlePainter(particles),
            size: Size.infinite,
          ),
          
          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Header con botón de tema
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800]?.withOpacity(0.8) : Colors.white.withOpacity(0.3),
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
                            isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                            color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                          ),
                          onPressed: _toggleTheme,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenido principal centrado
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo LMLG con imagen real
                        Container(
                          margin: const EdgeInsets.only(bottom: 40),
                          child: Column(
                            children: [
                              // Logo con imagen real
                              SizedBox(
                                height: 260,
                                width: 380,
                                child: Image.asset(
                                  isDarkMode ? TImages.lightLogoText : TImages.darkLogoText,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback en caso de que la imagen no se encuentre
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.local_hospital,
                                          size: 80,
                                          color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'LMLG',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                                            letterSpacing: 4,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Recuadro inferior con botones (35% de la pantalla)
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF282B30) : const Color(0xFFCAF0F8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 25.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Texto "Començem!" dentro del recuadro
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 25.0),
                          child: Text(
                            'Començem!',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDarkMode ? Colors.white70 : const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        // Columna con botones
                        Column(
                          children: [
                            // Botón LOGIN
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode 
                                      ? const Color(0xFF7289DA)  // Nuevo color para modo oscuro
                                      : const Color(0xFF0077B6), // Nuevo color para modo claro
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        appBar: AppBar(title: const Text('Login')),
                                        body: const Center(
                                          child: Text('Página de Login - En construcción'),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'ENTRAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Botón REGISTER
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode 
                                      ? const Color(0xFF7289DA)  // Nuevo color para modo oscuro
                                      : const Color(0xFF0077B6), // Nuevo color para modo claro
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  // TODO: Navegar a pantalla de registro
                                  print('REGISTER pressed');
                                },
                                child: const Text(
                                  'REGISTRAR-SE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

// Painter personalizado para las partículas
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      paint.color = particle.color.withOpacity(particle.opacity);
      
      // Dibujar partícula como círculo
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
      
      // Efecto de resplandor
      paint.color = particle.color.withOpacity(particle.opacity * 0.3);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
