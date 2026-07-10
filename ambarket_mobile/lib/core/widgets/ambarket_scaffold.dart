import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'huashu_motion_background.dart';

class AmbarketScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showMotionBackground;
  final Color? backgroundColor;
  final bool isDesktopConstrained;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AmbarketScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showMotionBackground = false,
    this.backgroundColor,
    this.isDesktopConstrained = true,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    // If desktop constrained, we limit the maximum width of the content
    // and center it.
    Widget content = body;

    if (isDesktopConstrained) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: content,
        ),
      );
    }

    final scaffoldBody = showMotionBackground
        ? Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: HuashuMotionBackground(),
                ),
              ),
              Positioned.fill(child: content),
            ],
          )
        : content;

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor ?? context.colors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: scaffoldBody,
    );
  }
}
