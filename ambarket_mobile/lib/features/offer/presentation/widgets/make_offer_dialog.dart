import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/offer_model.dart';
import '../providers/offer_provider.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/currency_parser.dart';

class MakeOfferDialog extends ConsumerStatefulWidget {
  final String productId;
  final String sellerId;
  final double originalPrice;
  final String productName;

  const MakeOfferDialog({
    super.key,
    required this.productId,
    required this.sellerId,
    required this.originalPrice,
    required this.productName,
  });

  @override
  ConsumerState<MakeOfferDialog> createState() => _MakeOfferDialogState();
}

class _MakeOfferDialogState extends ConsumerState<MakeOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() async {
    final currentProfile = ref.read(currentProfileProvider).value;
    if (currentProfile?.isSuspended == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun Anda sedang ditangguhkan.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final price = CurrencyParser.parse(_priceController.text).toDouble();
    if (price <= 0) return;

    final input = CreateOfferInput(
      productId: widget.productId,
      sellerId: widget.sellerId,
      offerPrice: price,
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
    );

    await ref.read(createOfferControllerProvider.notifier).createOffer(input);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createOfferControllerProvider);
    final isLoading = state is AsyncLoading;

    ref.listen(createOfferControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      } else if (next is AsyncData && prev is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tawaran berhasil dikirim')),
        );
        Navigator.of(context).pop();
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tawar Harga', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Harga Asli: ${_currencyFormat.format(widget.originalPrice)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              enabled: !isLoading,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Harga Tawaran (Rp) *',
                prefixText: 'Rp ',
                hintText: 'Misal: 50.000',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                final p = CurrencyParser.parse(val);
                if (p <= 0) return 'Harga tidak valid';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _messageController,
              enabled: !isLoading,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Pesan (Opsional)',
                hintText: 'Misal: Bisa COD besok?',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kirim Tawaran'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
