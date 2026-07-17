import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/order_model.dart';
import '../providers/order_provider.dart';

class RefundRequestDialog extends ConsumerStatefulWidget {
  const RefundRequestDialog({super.key, required this.order});

  final OrderModel order;

  @override
  ConsumerState<RefundRequestDialog> createState() =>
      _RefundRequestDialogState();
}

class _RefundRequestDialogState extends ConsumerState<RefundRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _evidenceController = TextEditingController();
  String _reason = 'Barang tidak sesuai deskripsi';

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.order.totalPrice.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final isLoading = ref.watch(
      orderActionControllerProvider.select((state) => state.isLoading),
    );

    return AlertDialog(
      title: const Text('Ajukan Refund'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Maksimal: ${currency.format(widget.order.totalPrice)}'),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'Alasan'),
                items: const [
                  DropdownMenuItem(
                    value: 'Barang tidak sesuai deskripsi',
                    child: Text('Barang tidak sesuai deskripsi'),
                  ),
                  DropdownMenuItem(
                    value: 'Barang rusak',
                    child: Text('Barang rusak'),
                  ),
                  DropdownMenuItem(
                    value: 'Barang tidak sampai',
                    child: Text('Barang tidak sampai'),
                  ),
                  DropdownMenuItem(
                    value: 'Seller tidak respons',
                    child: Text('Seller tidak respons'),
                  ),
                  DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                ],
                onChanged: isLoading
                    ? null
                    : (value) => setState(() {
                        _reason = value ?? _reason;
                      }),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal refund',
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  if (amount <= 0) return 'Nominal wajib diisi';
                  if (amount > widget.order.totalPrice) {
                    return 'Nominal melebihi total pesanan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Kronologi / keterangan',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 10) {
                    return 'Jelaskan masalah minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _evidenceController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Link bukti opsional',
                  hintText: 'Pisahkan beberapa link dengan koma',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajukan'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final evidenceUrls = _evidenceController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final success = await ref
        .read(orderActionControllerProvider.notifier)
        .requestRefund(
          order: widget.order,
          reason: _reason,
          description: _descriptionController.text.trim(),
          requestedAmount: _parseAmount(_amountController.text),
          evidenceUrls: evidenceUrls,
        );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan refund berhasil dikirim ke admin.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(orderActionControllerProvider).error ??
                'Gagal mengajukan refund.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}
