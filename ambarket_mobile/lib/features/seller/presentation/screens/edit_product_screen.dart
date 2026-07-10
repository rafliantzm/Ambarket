import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../domain/models/create_product_input.dart';
import '../providers/seller_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/currency_parser.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/premium_surface_card.dart';
import '../../../../core/widgets/premium_text_field.dart';
import '../../../../core/widgets/premium_dropdown.dart';
import '../../../../core/widgets/premium_button.dart';

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
  Uint8List? _newImageBytes;

  final _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _newImageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    final currentProfile = ref.read(currentProfileProvider).value;
    if (currentProfile?.isSuspended == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun Anda sedang ditangguhkan.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih kategori')));
      return;
    }

    final price = CurrencyParser.parse(_priceController.text).toDouble();
    if (price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harga tidak valid')));
      return;
    }

    final input = UpdateProductInput(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: _selectedCategoryId!,
      price: price,
      condition: _selectedCondition,
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      location: _locationController.text.trim(),
      isNegotiable: _isNegotiable,
      defects: _defectsController.text.trim().isEmpty
          ? null
          : _defectsController.text.trim(),
      completeness: _completenessController.text.trim().isEmpty
          ? null
          : _completenessController.text.trim(),
      usageDuration: _usageDurationController.text.trim().isEmpty
          ? null
          : _usageDurationController.text.trim(),
      status: _selectedStatus,
      newImageBytesList: _newImageBytes != null ? [_newImageBytes!] : [],
    );

    try {
      await ref
          .read(productActionControllerProvider.notifier)
          .updateProduct(widget.productId, input);
      if (mounted) {
        final state = ref.read(productActionControllerProvider);
        if (state.hasError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil diperbarui!')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productAsync = ref.watch(
      sellerProductDetailProvider(widget.productId),
    );
    final actionState = ref.watch(productActionControllerProvider);
    final isLoading = actionState.isLoading;

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Edit Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: productAsync.when(
        data: (product) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _initializeData(product),
          );

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
                        GestureDetector(
                          onTap: isLoading ? null : _pickImage,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_newImageBytes != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _newImageBytes!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                                  )
                                else if (product.images.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: product.images.first.imageUrl,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                                  ),
                                Positioned(
                                  bottom: AppSpacing.sm,
                                  right: AppSpacing.sm,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        PremiumSurfaceCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              PremiumDropdown<String>(
                                value: _selectedStatus,
                                labelText: 'Status Produk',
                                hint: 'Pilih status',
                                items: const [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sold',
                                    child: Text('Sold'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'archived',
                                    child: Text('Archived'),
                                  ),
                                ],
                                onChanged: isLoading
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          setState(
                                            () => _selectedStatus = value,
                                          );
                                        }
                                      },
                              ),
                              const SizedBox(height: AppSpacing.md),

                              PremiumTextField(
                                controller: _titleController,
                                enabled: !isLoading,
                                labelText: 'Judul Produk *',
                                hintText: 'Mis: iPhone 13 Pro Max 256GB',
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),

                              categoriesAsync.when(
                                data: (categories) => PremiumDropdown<String>(
                                  value: _selectedCategoryId,
                                  labelText: 'Kategori *',
                                  hint: 'Pilih kategori',
                                  items: categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat.id,
                                      child: Text(cat.name),
                                    );
                                  }).toList(),
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedCategoryId = value;
                                          });
                                        },
                                ),
                                loading: () =>
                                    const CircularProgressIndicator(),
                                error: (err, stack) =>
                                    const Text('Gagal memuat kategori'),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              PremiumTextField(
                                controller: _priceController,
                                enabled: !isLoading,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyInputFormatter()],
                                labelText: 'Harga (Rp) *',
                                hintText: '0',
                                prefixText: 'Rp ',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  if (CurrencyParser.parse(value) <= 0) {
                                    return 'Harga tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SwitchListTile(
                                title: const Text(
                                  'Bisa Nego',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                contentPadding: EdgeInsets.zero,
                                value: _isNegotiable,
                                activeTrackColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                onChanged: isLoading
                                    ? null
                                    : (val) =>
                                          setState(() => _isNegotiable = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          'Detail Produk',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PremiumSurfaceCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              PremiumDropdown<String>(
                                value: _selectedCondition,
                                labelText: 'Kondisi *',
                                hint: 'Pilih kondisi barang',
                                items: const [
                                  DropdownMenuItem(
                                    value: 'like_new',
                                    child: Text('Like New'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'good',
                                    child: Text('Good'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fair',
                                    child: Text('Fair'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'need_repair',
                                    child: Text('Need Repair'),
                                  ),
                                ],
                                onChanged: isLoading
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          setState(
                                            () => _selectedCondition = value,
                                          );
                                        }
                                      },
                              ),
                              const SizedBox(height: AppSpacing.md),

                              PremiumTextField(
                                controller: _locationController,
                                enabled: !isLoading,
                                labelText: 'Lokasi *',
                                hintText: 'Kota atau daerah pengiriman',
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),

                              PremiumTextField(
                                controller: _descriptionController,
                                enabled: !isLoading,
                                maxLines: 5,
                                labelText: 'Deskripsi Lengkap *',
                                hintText:
                                    'Jelaskan produk Anda secara lengkap...',
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Optional fields
                        Text(
                          'Informasi Tambahan (Opsional)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PremiumSurfaceCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              PremiumTextField(
                                controller: _brandController,
                                enabled: !isLoading,
                                labelText: 'Merek',
                                hintText: 'Mis: Apple, Samsung',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              PremiumTextField(
                                controller: _usageDurationController,
                                enabled: !isLoading,
                                labelText: 'Lama Pemakaian',
                                hintText: 'Mis: 6 bulan',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              PremiumTextField(
                                controller: _completenessController,
                                enabled: !isLoading,
                                labelText: 'Kelengkapan',
                                hintText: 'Mis: Dus, Charger',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              PremiumTextField(
                                controller: _defectsController,
                                enabled: !isLoading,
                                labelText: 'Minus / Kerusakan',
                                hintText: 'Jelaskan jika ada minus',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                        PremiumButton(
                          onPressed: isLoading ? null : _submit,
                          isLoading: isLoading,
                          label: 'Simpan Perubahan',
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
              const Text(
                'Produk tidak ditemukan atau Anda tidak memiliki akses.',
              ),
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
