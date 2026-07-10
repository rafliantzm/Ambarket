import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({super.key});

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Preloved Berkualitas, Harga Bersahabat',
      'subtitle': 'Temukan barang preloved terbaik di Ambarket.',
      'icon': Icons.shopping_bag_outlined,
      'button': 'Mulai Belanja',
    },
    {
      'title': 'Tawar Harga Langsung ke Penjual',
      'subtitle': 'Dapatkan deal terbaik untuk barang impianmu.',
      'icon': Icons.handshake_outlined,
      'button': 'Pelajari',
    },
    {
      'title': 'Jual Barang Bekasmu Sekarang',
      'subtitle': 'Ubah barang tak terpakai menjadi uang tunai.',
      'icon': Icons.sell_outlined,
      'button': 'Mulai Jual',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180, // Increased height to prevent overflow
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              final isFirst = index == 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isFirst
                          ? [
                              context.colors.primary,
                              context.colors.accent.withValues(alpha: 0.8),
                            ]
                          : [
                              context.colors.surfaceHighlight,
                              context.colors.surface,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isFirst
                          ? Colors.white.withValues(alpha: 0.2)
                          : context.colors.border.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isFirst
                            ? context.colors.primary.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner['title'],
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: isFirst
                                        ? Colors.white
                                        : context.colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              banner['subtitle'],
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isFirst
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : context.colors.textSecondary,
                                    height: 1.3,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? Colors.white
                                    : context.colors.primary,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                banner['button'],
                                style: TextStyle(
                                  color: isFirst
                                      ? context.colors.primary
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        banner['icon'],
                        size: 72,
                        color: isFirst
                            ? Colors.white.withValues(alpha: 0.15)
                            : context.colors.primary.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? context.colors.primary
                    : context.colors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
