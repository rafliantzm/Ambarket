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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text);

    if (mounted && !success) {
      final error = ref.read(authControllerProvider).error;
      final errorMessage = ErrorMapper.getFriendlyMessage(error);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: context.colors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loginWithGoogle() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();

    if (mounted && !success) {
      final error = ref.read(authControllerProvider).error;
      final errorMessage = ErrorMapper.getFriendlyMessage(error);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: context.colors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final emailCtrl = TextEditingController(text: _emailController.text);
        bool isSending = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.colors.surface,
              title: Text(
                'Reset Kata Sandi',
                style: TextStyle(color: context.colors.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Masukkan email akun Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: context.colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'contoh@email.com',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: context.colors.textMuted),
                  ),
                ),
                AppButton(
                  label: 'Kirim',
                  isLoading: isSending,
                  onPressed: () async {
                    final email = emailCtrl.text.trim();
                    if (email.isEmpty || !email.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Masukkan email yang valid')),
                      );
                      return;
                    }

                    setState(() => isSending = true);
                    try {
                      await ref
                          .read(supabaseClientProvider)
                          .auth
                          .resetPasswordForEmail(email);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tautan reset kata sandi telah dikirim jika email terdaftar.',
                            ),
                            backgroundColor: context.colors.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Gagal mengirim email: ${ErrorMapper.getFriendlyMessage(e)}',
                            ),
                            backgroundColor: context.colors.accent,
                          ),
                        );
                        setState(() => isSending = false);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
                        'Masuk ke akun Anda',
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
                          hintText: 'Masukkan kata sandi Anda',
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
                        label: 'Masuk',
                        isLoading: isLoading,
                        onPressed: _login,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: context.colors.border),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text(
                              'atau',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: context.colors.border),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Masuk dengan Google',
                        icon: Icons.g_mobiledata_rounded,
                        variant: AppButtonVariant.outline,
                        isLoading: isLoading,
                        onPressed: _loginWithGoogle,
                      ),
                      SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Belum punya akun? Daftar',
                        variant: AppButtonVariant.ghost,
                        isLoading: isLoading,
                        onPressed: () {
                          context.go('/register');
                        },
                      ),
                      TextButton(
                        onPressed: isLoading ? null : _showForgotPasswordDialog,
                        child: Text(
                          'Lupa kata sandi?',
                          style: TextStyle(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
