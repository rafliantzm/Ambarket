import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/error/error_mapper.dart';
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
  final _priceFormatter = CurrencyInputFormatter();
  final _priceFocusNode = FocusNode();
  final _messageFocusNode = FocusNode();
  bool _isSubmitting = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _priceFocusNode.dispose();
    _messageFocusNode.dispose();
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_isSubmitting) return;

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
    if (price >= widget.originalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga tawaran harus lebih rendah dari harga asli.'),
        ),
      );
      return;
    }

    final input = CreateOfferInput(
      productId: widget.productId,
      sellerId: widget.sellerId,
      offerPrice: price,
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
    );

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(createOfferControllerProvider.notifier).createOffer(input);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.getFriendlyMessage(error))),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }
    if (!mounted) return;

    final state = ref.read(createOfferControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.getFriendlyMessage(state.error!))),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tawaran berhasil dikirim')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final compact = mediaQuery.size.height < 720 || bottomInset > 0;
    final availableHeight =
        mediaQuery.size.height -
        bottomInset -
        mediaQuery.padding.top -
        AppSpacing.md;
    final maxSheetHeight = availableHeight.clamp(320.0, 640.0).toDouble();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: maxSheetHeight,
            ),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.none,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg + mediaQuery.padding.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Text(
                        'Tawar Harga',
                        style:
                            (compact
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.titleLarge)
                                ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                      Text(
                        widget.productName,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Harga Asli: ${_currencyFormat.format(widget.originalPrice)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                      TextFormField(
                        controller: _priceController,
                        focusNode: _priceFocusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        scrollPadding: const EdgeInsets.only(
                          bottom: AppSpacing.xl,
                        ),
                        enabled: !_isSubmitting,
                        inputFormatters: [_priceFormatter],
                        onFieldSubmitted: (_) {
                          _messageFocusNode.requestFocus();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Harga Tawaran (Rp) *',
                          prefixText: 'Rp ',
                          hintText: 'Misal: 50.000',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          final p = CurrencyParser.parse(val);
                          if (p <= 0) return 'Harga tidak valid';
                          if (p >= widget.originalPrice) {
                            return 'Harus lebih rendah dari harga asli';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                      TextFormField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.done,
                        scrollPadding: const EdgeInsets.only(
                          bottom: AppSpacing.xl,
                        ),
                        minLines: compact ? 1 : 2,
                        maxLines: compact ? 2 : 4,
                        onFieldSubmitted: (_) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Pesan (Opsional)',
                          hintText: 'Misal: Bisa COD besok?',
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Kirim Tawaran'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
