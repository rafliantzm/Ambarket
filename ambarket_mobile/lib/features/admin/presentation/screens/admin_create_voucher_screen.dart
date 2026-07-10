import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/currency_parser.dart';
import '../../../profile/data/repositories/supabase_voucher_repository.dart';
import '../../../profile/presentation/providers/voucher_provider.dart';
import '../providers/admin_voucher_provider.dart';

class AdminCreateVoucherScreen extends ConsumerStatefulWidget {
  const AdminCreateVoucherScreen({super.key});

  @override
  ConsumerState<AdminCreateVoucherScreen> createState() =>
      _AdminCreateVoucherScreenState();
}

class _AdminCreateVoucherScreenState
    extends ConsumerState<AdminCreateVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _maxDiscountController = TextEditingController();

  String _selectedType = 'percent';
  DateTime? _selectedExpiresAt;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _discountValueController.dispose();
    _minPurchaseController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(voucherRepositoryProvider);

      await repository.createVoucher(
        title: _titleController.text,
        description: _descriptionController.text,
        code: _codeController.text.toUpperCase(),
        type: _selectedType,
        discountValue: _selectedType == 'percent'
            ? double.tryParse(_discountValueController.text) ?? 0
            : CurrencyParser.parse(_discountValueController.text).toDouble(),
        minPurchase: CurrencyParser.parse(
          _minPurchaseController.text,
        ).toDouble(),
        maxDiscount: CurrencyParser.parse(
          _maxDiscountController.text,
        ).toDouble(),
        expiresAt: _selectedExpiresAt,
      );

      // refresh admin list
      ref.invalidate(adminVoucherProvider);
      ref.invalidate(voucherProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kupon berhasil dibuat & Notifikasi telah dikirim!'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat kupon: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Kupon Baru')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Kupon',
                        hintText: 'Misal: Diskon Gila 50%',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Kode Kupon',
                        hintText: 'Misal: GILA50',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 2,
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Kupon',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'percent',
                          child: Text('Persentase (%)'),
                        ),
                        DropdownMenuItem(
                          value: 'flat',
                          child: Text('Nominal (Rp)'),
                        ),
                        DropdownMenuItem(
                          value: 'flat_shipping',
                          child: Text('Potongan Ongkir (Rp)'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedType = value!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _discountValueController,
                      decoration: InputDecoration(
                        labelText: _selectedType == 'percent'
                            ? 'Nilai Diskon (%)'
                            : 'Nilai Diskon (Rp)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: _selectedType == 'percent'
                          ? []
                          : [CurrencyInputFormatter()],
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _minPurchaseController,
                      decoration: const InputDecoration(
                        labelText: 'Minimal Belanja (Rp)',
                        hintText: 'Opsional (default: 0)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                    ),
                    if (_selectedType == 'percent') ...[
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _maxDiscountController,
                        decoration: const InputDecoration(
                          labelText: 'Maksimal Diskon (Rp)',
                          hintText: 'Opsional',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    // Expiration Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Batas Waktu Kupon'),
                      subtitle: Text(
                        _selectedExpiresAt == null
                            ? 'Tanpa batas waktu (Selamanya)'
                            : DateFormat(
                                'dd MMM yyyy, HH:mm',
                              ).format(_selectedExpiresAt!),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedExpiresAt != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _selectedExpiresAt = null),
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              _selectedExpiresAt ??
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedExpiresAt != null
                                ? TimeOfDay.fromDateTime(_selectedExpiresAt!)
                                : TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedExpiresAt = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Simpan & Broadcast Notifikasi',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
