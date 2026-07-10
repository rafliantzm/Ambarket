import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ambarket_scaffold.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/error/error_mapper.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final name = email.split('@').first;

    debugPrint('RegisterScreen: register submit clicked for $email');

    final response = await ref
        .read(authControllerProvider.notifier)
        .signUp(email, _passwordController.text, name);

    if (!mounted) return;

    if (response == null) {
      final error = ref.read(authControllerProvider).error;
      debugPrint('RegisterScreen: signUp error: $error');
      final errorMessage = ErrorMapper.getFriendlyMessage(error);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      debugPrint(
        'RegisterScreen: signUp success. Session: ${response.session != null}',
      );

      // Fallback profile upsert just in case trigger fails
      // Note: Supabase will only allow this if RLS permits, but we try anyway.
      try {
        final client = ref.read(supabaseClientProvider);
        if (response.user != null) {
          await client.from('profiles').upsert({
            'id': response.user!.id,
            'name': name,
            'role': 'user',
          });
          debugPrint('RegisterScreen: fallback profile upsert success');
        }
      } catch (e) {
        debugPrint('RegisterScreen: fallback profile upsert ignored: $e');
      }

      if (!mounted) return;

      if (response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pendaftaran berhasil. Silakan cek email untuk verifikasi.',
            ),
            backgroundColor: context.colors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran berhasil!'),
            backgroundColor: context.colors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate to home if app_router doesn't do it quickly enough
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    return AmbarketScaffold(
      isDesktopConstrained: MediaQuery.of(context).size.width >= 768,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420),
              child: AppGlassCard(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ambarket',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Buat akun untuk mulai jual beli',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Masukkan email Anda',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: context.colors.textMuted,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!value.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          hintText: 'Buat kata sandi',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: context.colors.textMuted,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Kata sandi minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      AppButton(
                        label: 'Daftar',
                        isLoading: isLoading,
                        onPressed: _register,
                      ),
                      SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Sudah punya akun? Masuk',
                        variant: AppButtonVariant.ghost,
                        isLoading: isLoading,
                        onPressed: () {
                          context.go('/login');
                        },
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
