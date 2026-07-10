import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppAnimatedBackground extends StatelessWidget {
  final Widget child;

  const AppAnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(color: context.colors.background, child: child);
  }
}
