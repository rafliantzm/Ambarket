import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(starValue) : null,
          child: Icon(
            starValue <= rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
        );
      }),
    );
  }
}
