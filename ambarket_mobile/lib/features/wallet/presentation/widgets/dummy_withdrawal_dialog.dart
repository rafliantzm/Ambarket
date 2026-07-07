import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/dummy_withdrawal_input.dart';
import '../providers/seller_wallet_provider.dart';

class DummyWithdrawalDialog extends ConsumerStatefulWidget {
  final double availableBalance;

  const DummyWithdrawalDialog({super.key, required this.availableBalance});

  @override
  ConsumerState<DummyWithdrawalDialog> createState() => _DummyWithdrawalDialogState();
}

class _DummyWithdrawalDialogState extends ConsumerState<DummyWithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > widget.availableBalance) return; // double check

    final input = DummyWithdrawalInput(
      amount: amount,
      bankName: _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      accountHolder: _accountHolderController.text.trim(),
      note: _noteController.text.trim(),
    );

    await ref.read(sellerWithdrawalActionControllerProvider.notifier).submitDummyWithdrawal(input);
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan penarikan dummy berhasil dibuat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(sellerWithdrawalActionControllerProvider).isLoading;
    final theme = Theme.of(context);
    final isZeroBalance = widget.availableBalance <= 0;

    return AlertDialog(
      title: const Text('Penarikan Dummy (Simulasi)'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo Tersedia: Rp${widget.availableBalance.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Nominal Penarikan (Rp)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Wajib diisi';
                  final numVal = double.tryParse(value);
                  if (numVal == null) return 'Angka tidak valid';
                  if (numVal <= 0) return 'Harus > 0';
                  if (numVal > widget.availableBalance) return 'Melebihi saldo';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Nama Bank (Cth: BCA, Mandiri)'),
                validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(labelText: 'Nomor Rekening'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _accountHolderController,
                decoration: const InputDecoration(labelText: 'Atas Nama'),
                validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Catatan (Opsional)'),
                maxLines: 2,
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
        AppButton(
          label: 'Ajukan',
          onPressed: (isLoading || isZeroBalance) ? null : _submit,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
