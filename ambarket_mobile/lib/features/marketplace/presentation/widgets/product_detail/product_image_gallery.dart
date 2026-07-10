import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/product_image_model.dart';

class ProductImageGallery extends StatefulWidget {
  final List<ProductImageModel> images;

  const ProductImageGallery({super.key, required this.images});

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.images.isNotEmpty) {
      final primaryIndex = widget.images.indexWhere((img) => img.isPrimary);
      if (primaryIndex != -1) {
        _currentIndex = primaryIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: context.colors.border,
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              size: 64,
              color: context.colors.textMuted,
            ),
          ),
        ),
      );
    }

    final currentImage = widget.images[_currentIndex];

    return Column(
      children: [
        // Main Image
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black.withValues(
              alpha: 0.2,
            ), // Latar belakang gelap agar fit contain terlihat bagus
            child: CachedNetworkImage(
              imageUrl: currentImage.imageUrl,
              fit: BoxFit.contain,
              memCacheWidth: 1200,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (context, url) => Container(
                color: context.colors.surface,
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: context.colors.surface,
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Thumbnails
        if (widget.images.length > 1)
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              cacheExtent: 360,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final img = widget.images[index];
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? context.colors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: img.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        memCacheHeight: 120,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (context, url) =>
                            Container(color: context.colors.surface),
                        errorWidget: (context, url, error) => Container(
                          color: context.colors.surface,
                          child: Icon(
                            Icons.broken_image,
                            size: 24,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
