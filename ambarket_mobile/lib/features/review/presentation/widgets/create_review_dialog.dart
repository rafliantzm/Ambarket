import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/review/presentation/widgets/rating_stars.dart';
import 'package:ambarket_mobile/features/review/presentation/providers/review_provider.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

class CreateReviewDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String productId;
  final String reviewedUserId;

  const CreateReviewDialog({
    super.key,
    required this.orderId,
    required this.productId,
    required this.reviewedUserId,
  });

  @override
  ConsumerState<CreateReviewDialog> createState() => _CreateReviewDialogState();
}

class _CreateReviewDialogState extends ConsumerState<CreateReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() async {
    final currentProfile = ref.read(currentProfileProvider).value;
    if (currentProfile?.isSuspended == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun Anda sedang ditangguhkan.')));
      return;
    }

    final success = await ref.read(createReviewControllerProvider.notifier).submitReview(
      orderId: widget.orderId,
      productId: widget.productId,
      reviewedUserId: widget.reviewedUserId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );

    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ulasan berhasil dikirim!')),
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(createReviewControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal mengirim ulasan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReviewControllerProvider);

    return AlertDialog(
      title: const Text('Beri Ulasan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seberapa puas Anda dengan penjual ini?'),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: RatingStars(
                rating: _rating,
                size: 40,
                onChanged: (newRating) {
                  setState(() {
                    _rating = newRating;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Komentar (Opsional)'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Tuliskan pengalaman Anda...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Kirim Ulasan'),
        ),
      ],
    );
  }
}
