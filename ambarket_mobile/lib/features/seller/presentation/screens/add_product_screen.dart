import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import '../../domain/models/create_product_input.dart';
import '../providers/seller_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _locationController = TextEditingController();
  final _defectsController = TextEditingController();
  final _completenessController = TextEditingController();
  final _usageDurationController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedCondition = 'good';
  bool _isNegotiable = false;
  Uint8List? _imageBytes;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _locationController.dispose();
    _defectsController.dispose();
    _completenessController.dispose();
    _usageDurationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    final currentProfile = ref.read(currentProfileProvider).value;
    if (currentProfile?.isSuspended == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun Anda sedang ditangguhkan.')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori')));
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga tidak valid')));
      return;
    }

    final input = CreateProductInput(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: _selectedCategoryId!,
      price: price,
      condition: _selectedCondition,
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      location: _locationController.text.trim(),
      isNegotiable: _isNegotiable,
      defects: _defectsController.text.trim().isEmpty ? null : _defectsController.text.trim(),
      completeness: _completenessController.text.trim().isEmpty ? null : _completenessController.text.trim(),
      usageDuration: _usageDurationController.text.trim().isEmpty ? null : _usageDurationController.text.trim(),
      imageBytesList: _imageBytes != null ? [_imageBytes!] : [],
    );

    try {
      await ref.read(productActionControllerProvider.notifier).createProduct(input);
      if (mounted) {
        final state = ref.read(productActionControllerProvider);
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil ditambahkan!')));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final actionState = ref.watch(productActionControllerProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: isLoading ? null : _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 48, color: Theme.of(context).colorScheme.outline),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text('Tambah Gambar Utama', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Basic Info
                    TextFormField(
                      controller: _titleController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Judul Produk *'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    categoriesAsync.when(
                      data: (categories) => DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Kategori *'),
                        items: categories.map((cat) {
                          return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                        }).toList(),
                        onChanged: isLoading ? null : (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => const Text('Gagal memuat kategori'),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _priceController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga (Rp) *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                        if (double.tryParse(value) == null) return 'Harus berupa angka';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      title: const Text('Bisa Nego'),
                      value: _isNegotiable,
                      onChanged: isLoading ? null : (val) => setState(() => _isNegotiable = val),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Condition Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCondition,
                      decoration: const InputDecoration(labelText: 'Kondisi *'),
                      items: const [
                        DropdownMenuItem(value: 'like_new', child: Text('Like New')),
                        DropdownMenuItem(value: 'good', child: Text('Good')),
                        DropdownMenuItem(value: 'fair', child: Text('Fair')),
                        DropdownMenuItem(value: 'need_repair', child: Text('Need Repair')),
                      ],
                      onChanged: isLoading ? null : (value) {
                        if (value != null) setState(() => _selectedCondition = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _locationController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Lokasi *'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _descriptionController,
                      enabled: !isLoading,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi *',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Optional fields
                    const Text('Informasi Tambahan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _brandController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Merek'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _usageDurationController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Lama Pemakaian (mis. 6 bulan)'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _completenessController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Kelengkapan (mis. Dus, Charger)'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _defectsController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Minus / Kerusakan'),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Simpan Produk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
