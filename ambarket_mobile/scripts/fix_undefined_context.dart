import 'dart:io';

void main() {
  final files = [
    'lib/features/profile/presentation/screens/profile_screen.dart',
    'lib/features/seller/presentation/screens/seller_dashboard_screen.dart',
    'lib/features/notification/presentation/screens/notifications_screen.dart',
    'lib/features/marketplace/presentation/widgets/product_detail/product_condition_section.dart',
    'lib/features/marketplace/presentation/widgets/product_detail/product_info_section.dart',
    'lib/core/widgets/app_animated_background.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;

    var content = file.readAsStringSync();

    // In profile_screen.dart
    if (path.contains('profile_screen.dart')) {
      content = content.replaceAll(
        'Widget _buildMenuTile({',
        'Widget _buildMenuTile(BuildContext context, {',
      );
      content = content.replaceAll(
        '_buildMenuTile(',
        '_buildMenuTile(context, ',
      );
      content = content.replaceAll(
        'Widget _buildMenuTile(BuildContext context, BuildContext context, {',
        'Widget _buildMenuTile(BuildContext context, {',
      );
    }

    // In seller_dashboard_screen.dart
    if (path.contains('seller_dashboard_screen.dart')) {
      content = content.replaceAll(
        'Widget _buildMetricTile({',
        'Widget _buildMetricTile(BuildContext context, {',
      );
      content = content.replaceAll(
        '_buildMetricTile(',
        '_buildMetricTile(context, ',
      );
    }

    // In notifications_screen.dart
    if (path.contains('notifications_screen.dart')) {
      content = content.replaceAll(
        'Widget _buildNotificationItem(NotificationModel notification) {',
        'Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {',
      );
      content = content.replaceAll(
        '_buildNotificationItem(notification)',
        '_buildNotificationItem(context, notification)',
      );
    }

    // In product_condition_section.dart and product_info_section.dart
    if (path.contains('product_condition_section.dart') ||
        path.contains('product_info_section.dart')) {
      content = content.replaceAll(
        'Widget _buildInfoRow(String label, String value, {bool highlight = false}) {',
        'Widget _buildInfoRow(BuildContext context, String label, String value, {bool highlight = false}) {',
      );
      content = content.replaceAll('_buildInfoRow(', '_buildInfoRow(context, ');
    }

    // In app_animated_background.dart
    if (path.contains('app_animated_background.dart')) {
      // context is undefined where we use context.colors outside of build!
      // wait, in app_animated_background.dart, we might have `colors: [context.colors.primary, ...]` in a field.
      // Let's replace context.colors with AppColors.dark in this specific file if it's outside build.
      // Actually, we can just change context.colors to AppColors.dark in this file because it's an animated background that might be hard to adapt.
      // But wait, we want it to adapt. Let's see what is on line 79.
    }

    file.writeAsStringSync(content);
  }
}
