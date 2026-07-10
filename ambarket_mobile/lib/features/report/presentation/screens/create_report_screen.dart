import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ambarket_mobile/features/report/presentation/providers/report_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';
import 'package:ambarket_mobile/core/widgets/app_button.dart';
import 'package:ambarket_mobile/core/widgets/app_glass_card.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final String? initialTargetType;
  final String? initialTargetId;

  const CreateReportScreen({
    super.key,
    this.initialTargetType,
    this.initialTargetId,
  });

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetIdController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedTargetType = 'product';
  String _selectedReason = 'fraud';

  final _targetTypes = {
    'product': 'Produk',
    'user': 'Pengguna',
    'review': 'Ulasan',
  };

  final _reasons = {
    'fraud': 'Penipuan',
    'fake_product': 'Produk Palsu',
    'prohibited_item': 'Barang Terlarang',
    'inappropriate_content': 'Konten Tidak Pantas',
    'spam': 'Spam',
    'harassment': 'Pelecehan / Berbahaya',
    'other': 'Lainnya',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialTargetType != null &&
        _targetTypes.containsKey(widget.initialTargetType)) {
      _selectedTargetType = widget.initialTargetType!;
    }
    if (widget.initialTargetId != null) {
      _targetIdController.text = widget.initialTargetId!;
    }
  }

  @override
  void dispose() {
    _targetIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(createReportControllerProvider.notifier)
        .submitReport(
          targetType: _selectedTargetType,
          targetId: _targetIdController.text.trim(),
          reason: _selectedReason,
          description: _descriptionController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(); // Go back to previous screen
    } else if (mounted) {
      final error =
          ref.read(createReportControllerProvider).error ?? 'Terjadi kesalahan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppGlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Laporan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Jenis Laporan',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedTargetType,
                      items: _targetTypes.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTargetType = val);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _targetIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID Target',
                        hintText: 'Masukkan UUID dari target yang dilaporkan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'ID Target tidak boleh kosong';
                        }
                        if (val.trim().length < 10) {
                          return 'ID Target tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Alasan Laporan',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedReason,
                      items: _reasons.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedReason = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan Tambahan (Opsional)',
                        hintText: 'Jelaskan lebih detail masalah yang terjadi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Kirim Laporan',
                onPressed: state.isLoading ? () {} : _submit,
                isLoading: state.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
