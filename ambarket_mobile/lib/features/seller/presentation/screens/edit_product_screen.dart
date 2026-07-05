import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../domain/models/create_product_input.dart';
import '../providers/seller_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;
  const EditProductScreen({super.key, required this.productId});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _brandController;
  late TextEditingController _locationController;
  late TextEditingController _defectsController;
  late TextEditingController _completenessController;
  late TextEditingController _usageDurationController;

  String? _selectedCategoryId;
  String _selectedCondition = 'good';
  String _selectedStatus = 'active';
  bool _isNegotiable = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _brandController = TextEditingController();
    _locationController = TextEditingController();
    _defectsController = TextEditingController();
    _completenessController = TextEditingController();
    _usageDurationController = TextEditingController();
  }

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

  void _initializeData(ProductModel product) {
    if (_isInitialized) return;
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toStringAsFixed(0);
    _brandController.text = product.brand ?? '';
    _locationController.text = product.location;
    _defectsController.text = product.defects ?? '';
    _completenessController.text = product.completeness ?? '';
    _usageDurationController.text = product.usageDuration ?? '';

    _selectedCategoryId = product.categoryId;
    _selectedCondition = product.condition;
    _selectedStatus = product.status;
    _isNegotiable = product.isNegotiable;
    _isInitialized = true;
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

    final input = UpdateProductInput(
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
      status: _selectedStatus,
    );

    try {
      await ref.read(productActionControllerProvider.notifier).updateProduct(widget.productId, input);
      if (mounted) {
        final state = ref.read(productActionControllerProvider);
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil diperbarui!')));
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
    final productAsync = ref.watch(sellerProductDetailProvider(widget.productId));
    final actionState = ref.watch(productActionControllerProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Produk'),
      ),
      body: productAsync.when(
        data: (product) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData(product));

          return SingleChildScrollView(
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
                        // Display primary image if exists
                        if (product.images.isNotEmpty) ...[
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(product.images.first.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text('Catatan: Ubah gambar belum didukung di versi ini.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Status Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          decoration: const InputDecoration(labelText: 'Status Produk'),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'sold', child: Text('Sold')),
                            DropdownMenuItem(value: 'archived', child: Text('Archived')),
                          ],
                          onChanged: isLoading ? null : (value) {
                            if (value != null) setState(() => _selectedStatus = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

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
                              : const Text('Simpan Perubahan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: AppSpacing.md),
              const Text('Produk tidak ditemukan atau Anda tidak memiliki akses.'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => context.go('/seller'),
                child: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
