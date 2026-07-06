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
        aspectRatio: 4 / 3,
        child: Container(
          color: AppColors.border,
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 64, color: AppColors.textMuted),
          ),
        ),
      );
    }

    final currentImage = widget.images[_currentIndex];

    return Column(
      children: [
        // Main Image
        AspectRatio(
          aspectRatio: 4 / 3,
          child: CachedNetworkImage(
            imageUrl: currentImage.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.surface,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surface,
              child: const Center(child: Icon(Icons.broken_image, size: 64, color: AppColors.textMuted)),
            ),
          ),
        ),
        
        // Thumbnails
        if (widget.images.length > 1)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: img.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.surface),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.broken_image, size: 24, color: AppColors.textMuted),
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
