import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/widgets/ambarket_scaffold.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    // Determine selected index based on location
    int currentIndex = 0;
    if (location.startsWith('/cart')) {
      currentIndex = 1;
    } else if (location.startsWith('/seller')) {
      currentIndex = 2;
    } else if (location.startsWith('/chats')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile') ||
        location == '/buyer-orders' ||
        location == '/reports') {
      currentIndex = 4;
    }

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return AmbarketScaffold(
      isDesktopConstrained: isDesktop,
      showMotionBackground: false,
      appBar: isDesktop ? _buildDesktopHeader(context, currentIndex) : null,
      bottomNavigationBar: isDesktop
          ? null
          : _buildBottomNav(context, currentIndex),
      body: child,
    );
  }

  PreferredSizeWidget _buildDesktopHeader(
    BuildContext context,
    int currentIndex,
  ) {
    return AppBar(
      backgroundColor: context.colors.backgroundDarker.withValues(alpha: 0.9),
      title: Row(
        children: [
          Text(
            'Ambarket',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          SizedBox(width: 48),
          _desktopNavButton(context, 'Beranda', '/', currentIndex == 0),
          _desktopNavButton(context, 'Keranjang', '/cart', currentIndex == 1),
          _desktopNavButton(
            context,
            'Jual Barang',
            '/seller',
            currentIndex == 2,
          ),
          _desktopNavButton(context, 'Chat', '/chats', currentIndex == 3),
          _desktopNavButton(context, 'Akun', '/profile', currentIndex == 4),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            // TODO: Open Search
          },
        ),
        SizedBox(width: 16),
      ],
    );
  }

  Widget _desktopNavButton(
    BuildContext context,
    String label,
    String route,
    bool isSelected,
  ) {
    return TextButton(
      onPressed: () => context.go(route),
      style: TextButton.styleFrom(
        foregroundColor: isSelected
            ? context.colors.primary
            : context.colors.textMuted,
        textStyle: TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.border.withValues(alpha: 0.7)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 64,
          elevation: 0,
          backgroundColor: context.colors.surface,
          indicatorColor: context.colors.primary.withValues(alpha: 0.14),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                context.go('/cart');
                break;
              case 2:
                context.go('/seller');
                break;
              case 3:
                context.go('/chats');
                break;
              case 4:
                context.go('/profile');
                break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Keranjang',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline, size: 28),
              selectedIcon: Icon(Icons.add_circle, size: 28),
              label: 'Jual',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.chat_bubble_text),
              selectedIcon: Icon(CupertinoIcons.chat_bubble_text_fill),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
