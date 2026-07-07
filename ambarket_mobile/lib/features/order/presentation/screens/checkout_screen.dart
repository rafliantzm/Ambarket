import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/checkout_models.dart';
import '../providers/checkout_provider.dart';
import '../providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String? productId; // If null, we checkout from cart (for simplicity, we assume single product checkout first based on routing)
  final String? cartItemId;
  final String? offerId;

  const CheckoutScreen({
    super.key,
    this.productId,
    this.cartItemId,
    this.offerId,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  ShippingMethodModel? _selectedShipping;
  PaymentMethodModel? _selectedPayment;
  VoucherModel? _selectedVoucher;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    // Prefill from profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(currentProfileProvider).value;
      if (profileState != null) {
        _nameController.text = profileState.name ?? '';
        _phoneController.text = profileState.phone ?? '';
        _addressController.text = profileState.address ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productId == null) {
      return const Scaffold(body: Center(child: Text('Checkout dari keranjang belum diimplementasi.')));
    }

    final productState = ref.watch(productDetailProvider(widget.productId!));
    final shippings = ref.watch(shippingMethodsProvider);
    final payments = ref.watch(paymentMethodsProvider);
    final vouchers = ref.watch(voucherDummyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: productState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (product) {
          final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
          final double productPrice = product.price; // or from offer if passed
          final double shippingCost = _selectedShipping?.cost ?? 0;
          double discount = 0;

          if (_selectedVoucher != null) {
            if (_selectedVoucher!.type == 'percent') {
              discount = productPrice * (_selectedVoucher!.discountPercent / 100);
              if (_selectedVoucher!.maxDiscount > 0 && discount > _selectedVoucher!.maxDiscount) {
                discount = _selectedVoucher!.maxDiscount;
              }
            } else if (_selectedVoucher!.type == 'flat_shipping') {
              discount = _selectedVoucher!.flatDiscount;
              if (discount > shippingCost) discount = shippingCost;
            }
          }

          final double subtotal = productPrice;
          final double serviceFee = 1000;
          double totalAmount = subtotal + shippingCost + serviceFee - discount;
          if (totalAmount < 0) totalAmount = 0;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 1. Alamat Pengiriman
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alamat Pengiriman', style: Theme.of(context).textTheme.titleLarge!),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nama Penerima', border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Nomor HP', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Alamat Lengkap', border: OutlineInputBorder()),
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Ringkasan Produk
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ringkasan Produk', style: Theme.of(context).textTheme.titleLarge!),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          if (product.images.isNotEmpty)
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                image: DecorationImage(
                                  image: NetworkImage(product.images.first.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.title, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
                                Text(currencyFormatter.format(product.price), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.accent)),
                                Text('Kondisi: ${product.condition == "new" ? "Baru" : "Bekas"}', style: Theme.of(context).textTheme.bodySmall!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Metode Pengiriman
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Metode Pengiriman', style: Theme.of(context).textTheme.titleLarge!),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Catatan: Pengiriman ini hanya simulasi (dummy).', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.accent)),
                      const SizedBox(height: AppSpacing.md),
                      ...shippings.map((method) {
                        final isSelected = _selectedShipping == method;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            onTap: () => setState(() => _selectedShipping = method),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                border: Border.all(color: isSelected ? AppColors.accent : Colors.white24),
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.local_shipping : Icons.local_shipping_outlined,
                                    color: isSelected ? AppColors.accent : Colors.white70,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(method.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                        Text(method.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    method.cost == 0 ? 'Gratis' : currencyFormatter.format(method.cost),
                                    style: TextStyle(color: isSelected ? AppColors.accent : Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Voucher Dummy
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Voucher', style: Theme.of(context).textTheme.titleLarge!),
                          if (_selectedVoucher != null)
                            TextButton(
                              onPressed: () => setState(() => _selectedVoucher = null),
                              child: const Text('Batalkan', style: TextStyle(color: AppColors.error)),
                            )
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...vouchers.map((v) {
                        final isSelected = _selectedVoucher == v;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            onTap: () => setState(() => _selectedVoucher = v),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                border: Border.all(color: isSelected ? Colors.green : Colors.white24),
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.discount,
                                    color: isSelected ? Colors.green : Colors.white70,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                        Text(
                                          v.type == 'percent'
                                              ? 'Diskon ${v.discountPercent}% (Maks ${currencyFormatter.format(v.maxDiscount)})'
                                              : 'Potongan Ongkir ${currencyFormatter.format(v.flatDiscount)}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Colors.green),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 5. Metode Pembayaran
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Metode Pembayaran', style: Theme.of(context).textTheme.titleLarge!),
                      ...payments.map((method) => InkWell(
                        onTap: () => setState(() => _selectedPayment = method),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _selectedPayment == method ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: _selectedPayment == method ? AppColors.accent : Colors.grey,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(method.name, style: Theme.of(context).textTheme.titleMedium),
                                    Text(method.description, style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 6. Payment Summary
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rincian Pembayaran', style: Theme.of(context).textTheme.titleLarge!),
                      const SizedBox(height: AppSpacing.md),
                      _buildSummaryRow(context, 'Subtotal Produk', subtotal, currencyFormatter),
                      _buildSummaryRow(context, 'Biaya Pengiriman', shippingCost, currencyFormatter),
                      _buildSummaryRow(context, 'Biaya Layanan', serviceFee, currencyFormatter),
                      if (discount > 0)
                        _buildSummaryRow(context, 'Diskon', -discount, currencyFormatter, color: Colors.green),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Pembayaran', style: Theme.of(context).textTheme.titleLarge!),
                          Text(
                            currencyFormatter.format(totalAmount),
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.accent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 7. CTA
                Consumer(
                  builder: (context, ref, child) {
                    final orderState = ref.watch(orderActionControllerProvider);
                    return AppButton(label: 'Buat Pesanan',
                      isLoading: orderState.isLoading,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_selectedShipping == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih metode pengiriman'), backgroundColor: Colors.red));
                            return;
                          }
                          if (_selectedPayment == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih metode pembayaran'), backgroundColor: Colors.red));
                            return;
                          }

                          final input = CheckoutInput(
                            productId: product.id,
                            offerId: widget.offerId,
                            receiverName: _nameController.text,
                            receiverPhone: _phoneController.text,
                            shippingAddress: _addressController.text,
                            shippingMethod: _selectedShipping!.id,
                            shippingCost: shippingCost,
                            paymentMethod: _selectedPayment!.id,
                            voucherCode: _selectedVoucher?.code,
                            discountAmount: discount,
                            serviceFee: serviceFee,
                            subtotal: subtotal,
                            totalAmount: totalAmount,
                          );

                          ref.read(orderActionControllerProvider.notifier).createOrder(input).then((order) {
                            if (order != null) {
                              if (context.mounted) {
                                context.go('/payment/${order.id}');
                              }
                            }
                          });
                        }
                      },
                    );
                  }
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, double amount, NumberFormat formatter, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70)),
          Text(formatter.format(amount), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: color ?? Colors.white)),
        ],
      ),
    );
  }
}

