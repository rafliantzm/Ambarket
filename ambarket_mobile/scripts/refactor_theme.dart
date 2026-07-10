// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib directory not found');
    return;
  }

  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int modifiedCount = 0;

  for (final file in files) {
    // Skip app_colors.dart and app_theme.dart
    if (file.path.contains('app_colors.dart') || file.path.contains('app_theme.dart')) {
      continue;
    }

    String content = file.readAsStringSync();
    bool modified = false;

    // Replace AppColors.colorName with context.colors.colorName
    final colorRegex = RegExp(r'AppColors\.([a-zA-Z0-9_]+)');
    if (colorRegex.hasMatch(content)) {
      content = content.replaceAllMapped(colorRegex, (match) {
        final colorName = match.group(1);
        // Exclude AppColors.light and AppColors.dark if any
        if (colorName == 'light' || colorName == 'dark') return match.group(0)!;
        return 'context.colors.$colorName';
      });
      modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
      modifiedCount++;
      print('Modified: ${file.path}');
    }
  }

  print('Modified $modifiedCount files.');
}
