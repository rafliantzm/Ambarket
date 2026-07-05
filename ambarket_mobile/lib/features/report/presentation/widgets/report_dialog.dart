import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/report/presentation/providers/report_provider.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:ambarket_mobile/core/theme/app_spacing.dart';

class ReportDialog extends ConsumerStatefulWidget {
  final String targetType; // 'product', 'user', 'review'
  final String targetId;
  final String title;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.title,
  });

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();

  final Map<String, String> _reasons = {
    'fraud': 'Penipuan',
    'fake_product': 'Produk Palsu / Ilegal',
    'prohibited_item': 'Barang Terlarang',
    'inappropriate_content': 'Konten Tidak Pantas',
    'spam': 'Spam / Mengganggu',
    'harassment': 'Pelecehan / Ujaran Kebencian',
    'other': 'Lainnya',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    final currentProfile = ref.read(currentProfileProvider).value;
    if (currentProfile?.isSuspended == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun Anda sedang ditangguhkan.')));
      return;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih alasan pelaporan')),
      );
      return;
    }

    final success = await ref.read(createReportControllerProvider.notifier).submitReport(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: _selectedReason!,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim. Terima kasih!')),
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(createReportControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal mengirim laporan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportControllerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporkan ${widget.title}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Pilih alasan pelaporan:'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _reasons.entries.map((entry) {
                  return ChoiceChip(
                    label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                    selected: _selectedReason == entry.key,
                    onSelected: (selected) {
                      setState(() {
                        _selectedReason = selected ? entry.key : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Keterangan Tambahan (Opsional)'),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan lebih detail...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: state.isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Kirim Laporan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
