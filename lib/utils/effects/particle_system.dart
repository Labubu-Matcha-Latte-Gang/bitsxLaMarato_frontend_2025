import 'package:flutter/material.dart';
import 'dart:math';
import '../app_colors.dart';

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

class ParticleSystemWidget extends StatefulWidget {
  final bool isDarkMode;
  final int particleCount;
  final Color? particleColor;
  final double maxSize;
  final double minSize;
  final double speed;
  final double maxOpacity;
  final double minOpacity;

  const ParticleSystemWidget({
    super.key,
    required this.isDarkMode,
    this.particleCount = 50,
    this.particleColor,
    this.maxSize = 3.0,
    this.minSize = 1.0,
    this.speed = 0.5,
    this.maxOpacity = 0.6,
    this.minOpacity = 0.2,
  });

  @override
  State<ParticleSystemWidget> createState() => _ParticleSystemWidgetState();
}

class _ParticleSystemWidgetState extends State<ParticleSystemWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<Particle> particles = [];
  final Random random = Random();
  Size? screenSize;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )..repeat();

    _animationController.addListener(_updateParticles);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newScreenSize = MediaQuery.of(context).size;
    if (screenSize != newScreenSize) {
      screenSize = newScreenSize;
      _initializeParticles();
    }
  }

  @override
  void didUpdateWidget(ParticleSystemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _updateParticleColors();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Calcular número de partículas basado en el tamaño de pantalla
  int _getResponsiveParticleCount() {
    if (screenSize == null) return widget.particleCount;
    final screenArea = screenSize!.width * screenSize!.height;
    final baseArea = 400 * 800; // Área base de referencia
    final ratio = screenArea / baseArea;

    // Ajustar el número de partículas según el área
    int responsiveCount = (widget.particleCount * ratio).round();

    // Limitar entre un mínimo y máximo razonable
    responsiveCount = responsiveCount.clamp(20, 150);

    return responsiveCount;
  }

  // Calcular velocidad basada en el tamaño de pantalla
  double _getResponsiveSpeed() {
    if (screenSize == null) return widget.speed;
    final screenDiagonal = screenSize!.shortestSide;
    final baseDiagonal = 400.0; // Diagonal base de referencia
    final ratio = screenDiagonal / baseDiagonal;

    return widget.speed * ratio;
  }

  // Calcular tamaño de partículas basado en el tamaño de pantalla
  (double minSize, double maxSize) _getResponsiveSizes() {
    if (screenSize == null) return (widget.minSize, widget.maxSize);
    final screenDiagonal = screenSize!.shortestSide;
    final baseDiagonal = 400.0;
    final ratio = (screenDiagonal / baseDiagonal).clamp(0.5, 2.0);

    return (
      widget.minSize * ratio,
      widget.maxSize * ratio,
    );
  }

  void _initializeParticles() {
    if (screenSize == null || screenSize == Size.zero) return;

    particles.clear();
    final responsiveCount = _getResponsiveParticleCount();
    final responsiveSpeed = _getResponsiveSpeed();
    final (minSize, maxSize) = _getResponsiveSizes();

    for (int i = 0; i < responsiveCount; i++) {
      particles.add(Particle(
        x: random.nextDouble() * screenSize!.width,
        y: random.nextDouble() * screenSize!.height,
        vx: (random.nextDouble() - 0.5) * responsiveSpeed,
        vy: (random.nextDouble() - 0.5) * responsiveSpeed,
        size: random.nextDouble() * (maxSize - minSize) + minSize,
        color: _getParticleColor(),
        opacity: random.nextDouble() * (widget.maxOpacity - widget.minOpacity) +
            widget.minOpacity,
      ));
    }
  }

  void _updateParticles() {
    if (screenSize == null || screenSize == Size.zero) return;

    setState(() {
      for (var particle in particles) {
        particle.x += particle.vx;
        particle.y += particle.vy;

        // Rebotar en los bordes con el tamaño real de la pantalla
        if (particle.x < 0 || particle.x > screenSize!.width) {
          particle.vx *= -1;
        }
        if (particle.y < 0 || particle.y > screenSize!.height) {
          particle.vy *= -1;
        }

        // Mantener dentro de los límites de la pantalla
        particle.x = particle.x.clamp(0, screenSize!.width);
        particle.y = particle.y.clamp(0, screenSize!.height);
      }
    });
  }

  void _updateParticleColors() {
    for (var particle in particles) {
      particle.color = _getParticleColor();
    }
  }

  Color _getParticleColor() {
    return widget.particleColor ??
        AppColors.getParticleColor(widget.isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(particles),
      size: Size.infinite,
    );
  }
}
