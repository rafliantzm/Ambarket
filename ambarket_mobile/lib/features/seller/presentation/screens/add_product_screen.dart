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
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/currency_parser.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/premium_surface_card.dart';
import '../../../../core/widgets/premium_text_field.dart';
import '../../../../core/widgets/premium_dropdown.dart';
import '../../../../core/widgets/premium_button.dart';

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
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
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

    final input = CreateProductInput(
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
      imageBytesList: _imageBytes != null ? [_imageBytes!] : [],
    );

    try {
      await ref
          .read(productActionControllerProvider.notifier)
          .createProduct(input);
      if (mounted) {
        final state = ref.read(productActionControllerProvider);
        if (state.hasError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil ditambahkan!')),
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
    final actionState = ref.watch(productActionControllerProvider);
    final isLoading = actionState.isLoading;

    return AmbarketScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tambah Produk',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.contain,
                                  cacheWidth: 800, // Optimize memory decode
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Tambah Foto Produk Utama',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Format: JPG/PNG, Max 5MB',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Basic Info Section
                    Text(
                      'Informasi Utama',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PremiumSurfaceCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
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
                            data: (categories) => StatefulBuilder(
                              builder: (context, setCategoryState) =>
                                  PremiumDropdown<String>(
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
                                            setCategoryState(() {
                                              _selectedCategoryId = value;
                                            });
                                          },
                                  ),
                            ),
                            loading: () => const CircularProgressIndicator(),
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
                          StatefulBuilder(
                            builder: (context, setNegoState) => SwitchListTile(
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
                                  : (val) {
                                      setNegoState(() => _isNegotiable = val);
                                      _isNegotiable = val;
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Details Section
                    Text(
                      'Detail Produk',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PremiumSurfaceCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          StatefulBuilder(
                            builder: (context, setConditionState) =>
                                PremiumDropdown<String>(
                                  value: _selectedCondition,
                                  labelText: 'Kondisi *',
                                  hint: 'Pilih kondisi',
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'new',
                                      child: Text('Baru'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'like_new',
                                      child: Text('Seperti Baru'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'good',
                                      child: Text('Baik'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'fair',
                                      child: Text('Cukup'),
                                    ),
                                  ],
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          setConditionState(() {
                                            _selectedCondition = value!;
                                          });
                                          _selectedCondition = value!;
                                        },
                                ),
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
                            hintText: 'Jelaskan produk Anda secara lengkap...',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Wajib diisi'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Optional Section
                    Text(
                      'Informasi Tambahan (Opsional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                      label: 'Simpan Produk',
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
