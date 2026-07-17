import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'app_reloader.dart';
import 'boot_loader_bridge.dart';

typedef SupabaseStartupInitializer = Future<void> Function(AppConfig config);

enum StartupStatus { ready, configurationError, initializationError }

class StartupResult {
  final StartupStatus status;
  final String? message;

  const StartupResult._(this.status, [this.message]);

  const StartupResult.ready() : this._(StartupStatus.ready);

  const StartupResult.configurationError(String message)
    : this._(StartupStatus.configurationError, message);

  const StartupResult.initializationError(String message)
    : this._(StartupStatus.initializationError, message);
}

Future<StartupResult> initializeAmbarketStartup(
  AppConfig config, {
  SupabaseStartupInitializer initializeSupabase = initializeSupabaseClient,
}) async {
  final validation = config.validate();
  if (!validation.isValid) {
    return StartupResult.configurationError(validation.message!);
  }

  try {
    await initializeSupabase(config);
    return const StartupResult.ready();
  } catch (_) {
    return const StartupResult.initializationError(
      'Ambarket gagal terhubung ke layanan aplikasi. Periksa koneksi dan konfigurasi, lalu coba kembali.',
    );
  }
}

Future<void> initializeSupabaseClient(AppConfig config) {
  return Supabase.initialize(
    url: config.supabaseUrl.trim(),
    publishableKey: config.supabasePublishableKey.trim(),
  );
}

class AmbarketStartupApp extends StatefulWidget {
  final StartupResult startupResult;

  const AmbarketStartupApp({super.key, required this.startupResult});

  @override
  State<AmbarketStartupApp> createState() => _AmbarketStartupAppState();
}

class _AmbarketStartupAppState extends State<AmbarketStartupApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyFlutterMounted();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startupResult.status == StartupStatus.ready) {
      return const ProviderScope(child: AmbarketApp());
    }

    final isConfigurationError =
        widget.startupResult.status == StartupStatus.configurationError;

    return MaterialApp(
      title: 'Ambarket',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: StartupErrorScreen(
        title: isConfigurationError
            ? 'Konfigurasi belum lengkap'
            : 'Ambarket belum dapat dimuat',
        message:
            widget.startupResult.message ??
            'Terjadi masalah saat menyiapkan aplikasi.',
        showReload: !isConfigurationError,
      ),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final bool showReload;

  const StartupErrorScreen({
    super.key,
    required this.title,
    required this.message,
    this.showReload = true,
  });

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF10B981);
    const brandDeep = Color(0xFF061512);

    return Scaffold(
      backgroundColor: brandDeep,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: brandGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: brandGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: brandGreen,
                          size: 38,
                        ),
                        Positioned(
                          bottom: 18,
                          child: Icon(
                            Icons.all_inclusive_rounded,
                            color: const Color(
                              0xFFBFF8E3,
                            ).withValues(alpha: 0.95),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFA1A1AA),
                      height: 1.45,
                    ),
                  ),
                  if (showReload) ...[
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: reloadApp,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Muat Ulang'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
