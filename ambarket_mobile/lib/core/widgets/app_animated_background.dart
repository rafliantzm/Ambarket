import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppAnimatedBackground extends StatefulWidget {
  final Widget child;

  const AppAnimatedBackground({super.key, required this.child});

  @override
  State<AppAnimatedBackground> createState() => _AppAnimatedBackgroundState();
}

class _AppAnimatedBackgroundState extends State<AppAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    // Do not repeat in test environment to avoid pumpAndSettle timeouts
    if (!const bool.fromEnvironment('FLUTTER_TEST_ENV')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.background),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _GridPainter(progress: _controller.value),
              );
            },
          ),
        ),
        // A subtle radial gradient to focus the center and obscure edges
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  AppColors.background,
                ],
                radius: 1.2,
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final double progress;

  _GridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double gridSpacing = 40.0;
    final double offset = progress * gridSpacing;

    // Draw vertical lines
    for (double i = -gridSpacing; i < size.width + gridSpacing; i += gridSpacing) {
      canvas.drawLine(
        Offset(i + offset, 0),
        Offset(i + offset, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double i = -gridSpacing; i < size.height + gridSpacing; i += gridSpacing) {
      canvas.drawLine(
        Offset(0, i + offset),
        Offset(size.width, i + offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
