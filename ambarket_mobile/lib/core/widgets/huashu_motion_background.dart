import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum MotionQuality { high, balanced, static }

class HuashuMotionBackground extends StatefulWidget {
  final bool enableMotion;
  final MotionQuality qualityMode;

  const HuashuMotionBackground({
    super.key,
    this.enableMotion = true,
    this.qualityMode = MotionQuality.balanced,
  });

  @override
  State<HuashuMotionBackground> createState() => _HuashuMotionBackgroundState();
}

class _HuashuMotionBackgroundState extends State<HuashuMotionBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Node> _nodes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    if (widget.enableMotion && widget.qualityMode != MotionQuality.static) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nodes.isEmpty) {
      final size = MediaQuery.of(context).size;
      int nodeCount = 0;
      if (widget.qualityMode == MotionQuality.high) {
        nodeCount = (size.width * size.height / 30000).clamp(10, 40).toInt();
      } else if (widget.qualityMode == MotionQuality.balanced) {
        nodeCount = (size.width * size.height / 60000).clamp(5, 20).toInt();
      }

      for (int i = 0; i < nodeCount; i++) {
        _nodes.add(Node.random(size, _random));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled:
          widget.enableMotion && widget.qualityMode != MotionQuality.static,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (widget.enableMotion) {
              final size = MediaQuery.of(context).size;
              for (var node in _nodes) {
                node.update(size);
              }
            }
            return CustomPaint(
              painter: HuashuMotionPainter(
                nodes: _nodes,
                color: context.colors.primary.withValues(alpha: 0.1),
                gridColor: context.colors.border.withValues(alpha: 0.3),
                isAnimating:
                    widget.enableMotion &&
                    widget.qualityMode != MotionQuality.static,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class Node {
  double x;
  double y;
  double vx;
  double vy;

  Node(this.x, this.y, this.vx, this.vy);

  factory Node.random(Size size, Random random) {
    return Node(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
      (random.nextDouble() - 0.5) * 1.0, // slower
      (random.nextDouble() - 0.5) * 1.0, // slower
    );
  }

  void update(Size size) {
    x += vx;
    y += vy;
    if (x < 0 || x > size.width) vx *= -1;
    if (y < 0 || y > size.height) vy *= -1;
  }
}

class HuashuMotionPainter extends CustomPainter {
  final List<Node> nodes;
  final Color color;
  final Color gridColor;
  final bool isAnimating;

  HuashuMotionPainter({
    required this.nodes,
    required this.color,
    required this.gridColor,
    required this.isAnimating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle grid
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const double gridSize = 40.0;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const double connectionDistance = 150.0;

    for (int i = 0; i < nodes.length; i++) {
      final nodeA = nodes[i];
      canvas.drawCircle(Offset(nodeA.x, nodeA.y), 3, nodePaint);

      for (int j = i + 1; j < nodes.length; j++) {
        final nodeB = nodes[j];
        final distance = sqrt(
          pow(nodeA.x - nodeB.x, 2) + pow(nodeA.y - nodeB.y, 2),
        );

        if (distance < connectionDistance) {
          final alpha = (1 - (distance / connectionDistance)) * color.a;
          paint.color = color.withValues(alpha: alpha);
          canvas.drawLine(
            Offset(nodeA.x, nodeA.y),
            Offset(nodeB.x, nodeB.y),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant HuashuMotionPainter oldDelegate) {
    if (!isAnimating) return false;
    return true;
  }
}
