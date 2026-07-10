// ignore_for_file: avoid_print, unused_local_variable
import 'dart:io';

void main() {
  final filesToStrip = [
    'lib/core/widgets/app_empty_state.dart',
    'lib/core/widgets/app_error_state.dart',
    'lib/core/widgets/app_button.dart',
    'lib/features/auth/presentation/screens/login_screen.dart',
    'lib/features/auth/presentation/screens/register_screen.dart',
    'lib/features/cart/presentation/screens/cart_screen.dart',
    'lib/features/home/presentation/screens/home_screen.dart',
    'lib/featureshomepresentationwidgetshome_search_header.dart',
    'lib/features/marketplace/presentation/screens/products_list_screen.dart',
    'lib/features/marketplace/presentationscreensproduct_detail_screen.dart',
    'lib/features/marketplace/presentationwidgetsproduct_detailproduct_condition_section.dart',
    'lib/features/marketplace/presentationwidgetsproduct_detailproduct_image_gallery.dart',
    'lib/features/marketplace/presentationwidgetsproduct_detailproduct_info_section.dart',
    'lib/features/marketplace/presentationwidgetsproduct_detailproduct_purchase_panel.dart',
    'lib/features/marketplace/presentationwidgetsproduct_detailproduct_related_section.dart',
    'lib/features/marketplace/presentationwidgetsproduct_detailproduct_safety_section.dart',
    'lib/features/marketplace/presentationwidgetsproduct_detailproduct_seller_card.dart',
    'lib/features/notification/presentation/screens/notifications_screen.dart',
    'lib/features/order/presentation/screens/checkout_screen.dart',
    'lib/features/order/presentation/screens/order_tracking_screen.dart',
    'lib/features/order/presentation/screens/payment_dummy_screen.dart',
    'lib/features/profile/presentation/screens/profile_screen.dart',
    'lib/features/profile/presentation/screens/seller_public_profile_screen.dart',
    'lib/features/profile/presentation/screens/vouchers_screen.dart',
    'lib/features/seller/presentation/screens/seller_dashboard_screen.dart',
  ];

  // Also, let's just strip `const` from ALL files modified previously to be safe.
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('app_colors.dart') || file.path.contains('app_theme.dart')) continue;
    
    String content = file.readAsStringSync();
    if (content.contains('context.colors')) {
      // Find all `const ` and remove it. But wait! 
      // Do not remove `const` inside variable declarations like `static const _duration = ...` 
      // Or `const double padding = 16.0;`
      // We only want to remove const before Widget instantiations: `const Text`, `const Icon`, `const Padding`, `const EdgeInsets`, `const SizedBox`, `const BorderRadius`, `const BorderSide`, `const BoxDecoration`, `const TextStyle`
      
      final widgetRegex = RegExp(r'\bconst\s+(Text|Icon|Padding|EdgeInsets|SizedBox|BorderRadius|BorderSide|BoxDecoration|TextStyle|AppLoadingSkeleton|Row|Column|Container|Align|Center)\b');
      
      if (widgetRegex.hasMatch(content)) {
        content = content.replaceAllMapped(widgetRegex, (match) => match.group(1)!);
        file.writeAsStringSync(content);
        print('Stripped specific const from ${file.path}');
      }

      // Also remove `const ` in front of other common things that break with dynamic colors
      final generalRegex = RegExp(r'\bconst\s+(?=[\w]+\()');
      if (generalRegex.hasMatch(content)) {
          content = content.replaceAll(generalRegex, '');
          file.writeAsStringSync(content);
          print('Stripped general const from ${file.path}');
      }
    }
  }
}
