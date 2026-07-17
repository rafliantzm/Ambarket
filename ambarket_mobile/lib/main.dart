import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/config/app_config.dart';
import 'core/startup/app_startup.dart';

export 'app.dart' show AmbarketApp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  timeago.setLocaleMessages('id', timeago.IdMessages());

  final startupResult = await initializeAmbarketStartup(
    AppConfig.fromEnvironment,
  );

  runApp(AmbarketStartupApp(startupResult: startupResult));
}
