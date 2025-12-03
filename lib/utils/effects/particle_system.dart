import 'package:flutter/material.dart';
import 'dart:math';

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

  void _initializeParticles() {
    particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      particles.add(Particle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        vx: (random.nextDouble() - 0.5) * widget.speed,
        vy: (random.nextDouble() - 0.5) * widget.speed,
        size: random.nextDouble() * (widget.maxSize - widget.minSize) +
            widget.minSize,
        color: _getParticleColor(),
        opacity: random.nextDouble() * (widget.maxOpacity - widget.minOpacity) +
            widget.minOpacity,
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

  void _updateParticleColors() {
    for (var particle in particles) {
      particle.color = _getParticleColor();
    }
  }

  Color _getParticleColor() {
    return widget.particleColor ??
        (widget.isDarkMode ? Colors.white : const Color(0xFF1E3A8A));
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(particles),
      size: Size.infinite,
    );
  }
}
