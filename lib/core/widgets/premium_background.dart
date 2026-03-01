import 'package:flutter/material.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';

/// Fondo ultra premium: gradientes en profundidad, grid sutil, orbes de luz turquesa.
class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1) Base gradient profundo
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.4, 0.7, 1.0],
                colors: [
                  const Color(0xFF030712),
                  const Color(0xFF051018),
                  const Color(0xFF07121C),
                  const Color(0xFF050A12),
                ],
              ),
            ),
          ),
        ),
        // 2) Segunda capa: tinte turquesa suave desde esquinas
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.6, -0.8),
                end: Alignment(0.8, 0.6),
                stops: const [0.0, 0.35, 0.65, 1.0],
                colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.primary.withValues(alpha: 0.02),
                  AppColors.primaryDark.withValues(alpha: 0.03),
                  AppColors.secondary.withValues(alpha: 0.04),
                ],
              ),
            ),
          ),
        ),
        // 3) Orbes de luz (glow) - sensación premium
        Positioned.fill(
          child: CustomPaint(
            painter: _OrbsPainter(),
          ),
        ),
        // 4) Grid sutil tecnológico
        Positioned.fill(
          child: CustomPaint(
            painter: _GridPainter(),
          ),
        ),
        // 5) Vigneta suave en bordes
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                stops: const [0.5, 0.85, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrbsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Orb superior derecha - turquesa suave
    final r1 = size.width * 0.65;
    final c1 = Offset(size.width * 0.82, size.height * 0.15);
    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        AppColors.primary.withValues(alpha: 0.09),
        AppColors.primary.withValues(alpha: 0.02),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromCircle(center: c1, radius: r1));
    canvas.drawCircle(c1, r1, paint);

    // Orb inferior izquierda - secundario
    final r2 = size.width * 0.55;
    final c2 = Offset(size.width * 0.12, size.height * 0.92);
    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        AppColors.secondary.withValues(alpha: 0.07),
        AppColors.primaryDark.withValues(alpha: 0.02),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: c2, radius: r2));
    canvas.drawCircle(c2, r2, paint);

    // Orb centro-derecha (muy sutil)
    final r3 = size.width * 0.4;
    final c3 = Offset(size.width * 0.95, size.height * 0.55);
    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        AppColors.primary.withValues(alpha: 0.045),
        Colors.transparent,
      ],
      stops: const [0.0, 0.75],
    ).createShader(Rect.fromCircle(center: c3, radius: r3));
    canvas.drawCircle(c3, r3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 24.0;
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Líneas de acento más visibles pero muy suaves (cada 4)
    paint.color = AppColors.primary.withValues(alpha: 0.055);
    paint.strokeWidth = 0.8;
    for (double x = 0; x <= size.width + step * 4; x += step * 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height + step * 4; y += step * 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
