import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final OfferModel offer;

  const CheckoutScreen({super.key, required this.offer});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(currentProfileProvider).value;
      if (profile != null) {
        if (profile.phone != null) _phoneController.text = profile.phone!;
        if (profile.address != null) _addressController.text = profile.address!;
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final currentProfile = ref.read(currentProfileProvider).value;
    if (currentProfile?.isSuspended == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun Anda sedang ditangguhkan.')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(orderActionControllerProvider.notifier).checkout(
      productId: widget.offer.productId,
      sellerId: widget.offer.sellerId,
      totalPrice: widget.offer.offerPrice,
      shippingAddress: _addressController.text.trim(),
      shippingPhone: _phoneController.text.trim(),
      offerId: widget.offer.id,
    );

    if (success != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dibuat!')),
      );
      // Pop checkout screen and return to offers or go to orders
      context.pop(true);
    } else if (mounted) {
      final error = ref.read(orderActionControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal membuat pesanan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionState = ref.watch(orderActionControllerProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan Pembelian', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.md),
                    if (widget.offer.product != null) ...[
                      Text(widget.offer.product!.title, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Harga:'),
                        Text(
                          currencyFormatter.format(widget.offer.offerPrice),
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Text('Informasi Pengiriman', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                hintText: 'Contoh: 081234567890',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor telepon wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap',
                hintText: 'Masukkan alamat pengiriman secara detail',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat pengiriman wajib diisi';
                }
                if (value.trim().length < 10) {
                  return 'Alamat terlalu singkat';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            FilledButton(
              onPressed: actionState.isLoading ? null : _submitOrder,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: actionState.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Buat Pesanan'),
            ),
          ],
        ),
      ),
    );
  }
}
