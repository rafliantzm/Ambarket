import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    
    // Determine selected index based on location
    int currentIndex = 0;
    if (location.startsWith('/wishlist')) {
      currentIndex = 1;
    } else if (location.startsWith('/seller')) {
      currentIndex = 2;
    } else if (location.startsWith('/chats')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile') || location == '/buyer-orders' || location == '/reports') {
      currentIndex = 4;
    }

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: isDesktop ? _buildDesktopHeader(context, currentIndex) : null,
      body: child,
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(context, currentIndex),
    );
  }

  PreferredSizeWidget _buildDesktopHeader(BuildContext context, int currentIndex) {
    return AppBar(
      backgroundColor: AppColors.backgroundDarker.withValues(alpha: 0.9),
      title: Row(
        children: [
          const Text(
            'Ambarket',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 48),
          _desktopNavButton(context, 'Beranda', '/', currentIndex == 0),
          _desktopNavButton(context, 'Wishlist', '/wishlist', currentIndex == 1),
          _desktopNavButton(context, 'Jual Barang', '/seller', currentIndex == 2),
          _desktopNavButton(context, 'Chat', '/chats', currentIndex == 3),
          _desktopNavButton(context, 'Akun', '/profile', currentIndex == 4),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: Open Search
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _desktopNavButton(BuildContext context, String label, String route, bool isSelected) {
    return TextButton(
      onPressed: () => context.go(route),
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? AppColors.primary : AppColors.textMuted,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: NavigationBar(
        backgroundColor: AppColors.backgroundDarker,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/wishlist');
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
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Jual',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

