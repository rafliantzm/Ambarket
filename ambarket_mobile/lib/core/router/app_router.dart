import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

import '../../features/marketplace/presentation/screens/product_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/wishlist_screen.dart';

import '../../features/seller/presentation/screens/seller_dashboard_screen.dart';
import '../../features/seller/presentation/screens/add_product_screen.dart';
import '../../features/seller/presentation/screens/edit_product_screen.dart';

import 'package:ambarket_mobile/features/offer/presentation/screens/my_offers_screen.dart';
import 'package:ambarket_mobile/features/offer/domain/models/offer_model.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/checkout_screen.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/buyer_orders_screen.dart';

import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:ambarket_mobile/features/report/presentation/screens/my_reports_screen.dart';

import 'package:ambarket_mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_report_detail_screen.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_audit_logs_screen.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_products_screen.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:ambarket_mobile/features/admin/presentation/screens/admin_reviews_screen.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider).value;

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/offers',
        builder: (context, state) => const MyOffersScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const MyReportsScreen(),
      ),
      GoRoute(
        path: '/chats/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatDetailScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: '/seller',
        builder: (context, state) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: '/seller/products/new',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/seller/products/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditProductScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final offer = state.extra as OfferModel;
          return CheckoutScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/buyer-orders',
        builder: (context, state) => const BuyerOrdersScreen(),
      ),
      GoRoute(
        path: '/seller-orders',
        builder: (context, state) => const SellerOrdersScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/reports/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminReportDetailScreen(reportId: id);
        },
      ),
      GoRoute(
        path: '/admin/audit-logs',
        builder: (context, state) => const AdminAuditLogsScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/reviews',
        builder: (context, state) => const AdminReviewsScreen(),
      ),
    ],
    redirect: (context, state) {
      final session = authState?.session ?? Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';
      
      if (!isAuthenticated && !isGoingToLogin && !isGoingToRegister && !state.matchedLocation.startsWith('/products') && state.matchedLocation != '/') {
        return '/login';
      }
      
      if (isAuthenticated && (isGoingToLogin || isGoingToRegister)) {
        return '/';
      }

      if (state.matchedLocation.startsWith('/admin')) {
        final profileAsync = ref.read(currentProfileProvider);
        final profile = profileAsync.value;
        if (profile == null || profile.role != 'admin') {
          return '/';
        }
      }
      
      return null;
    },
  );
});
