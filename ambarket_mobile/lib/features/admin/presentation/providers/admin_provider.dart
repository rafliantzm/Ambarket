import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/admin/domain/models/admin_audit_log_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_model.dart';
import 'package:ambarket_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:ambarket_mobile/features/admin/data/repositories/supabase_admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return SupabaseAdminRepository(Supabase.instance.client);
});

final adminDashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAdminDashboardStats();
});

final adminReportsProvider = FutureProvider.autoDispose<List<ReportModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAllReports();
});

final adminReportsByStatusProvider = FutureProvider.family.autoDispose<List<ReportModel>, String>((ref, status) async {
  return ref.watch(adminRepositoryProvider).fetchReportsByStatus(status);
});

final adminProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAllProductsForAdmin();
});

final adminUsersProvider = FutureProvider.autoDispose<List<ProfileModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAllUsersForAdmin();
});

final adminReviewsProvider = FutureProvider.autoDispose<List<ReviewModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAllReviewsForAdmin();
});

final adminAuditLogsProvider = FutureProvider.autoDispose<List<AdminAuditLogModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAuditLogs();
});

class AdminActionState {
  final bool isLoading;
  final String? error;
  AdminActionState({this.isLoading = false, this.error});
}

class AdminActionController extends Notifier<AdminActionState> {
  @override
  AdminActionState build() => AdminActionState();

  Future<bool> updateReportStatus(String reportId, String status) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref.read(adminRepositoryProvider).updateReportStatus(reportId, status);
      ref.invalidate(adminReportsProvider);
      ref.invalidate(adminReportsByStatusProvider);
      ref.invalidate(adminDashboardStatsProvider);
      state = AdminActionState(isLoading: false);
      return true;
    } catch (e) {
      state = AdminActionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> hideProduct(String productId, String note) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref.read(adminRepositoryProvider).hideProduct(productId, note);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminDashboardStatsProvider);
      ref.invalidate(adminAuditLogsProvider);
      state = AdminActionState(isLoading: false);
      return true;
    } catch (e) {
      state = AdminActionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> rejectProduct(String productId, String note) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref.read(adminRepositoryProvider).rejectProduct(productId, note);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminDashboardStatsProvider);
      ref.invalidate(adminAuditLogsProvider);
      state = AdminActionState(isLoading: false);
      return true;
    } catch (e) {
      state = AdminActionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> restoreProduct(String productId) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref.read(adminRepositoryProvider).restoreProduct(productId);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminDashboardStatsProvider);
      ref.invalidate(adminAuditLogsProvider);
      state = AdminActionState(isLoading: false);
      return true;
    } catch (e) {
      state = AdminActionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> suspendUser(String userId, String reason) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref.read(adminRepositoryProvider).suspendUser(userId, reason);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminDashboardStatsProvider);
      ref.invalidate(adminAuditLogsProvider);
      state = AdminActionState(isLoading: false);
      return true;
    } catch (e) {
      state = AdminActionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> unsuspendUser(String userId) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref.read(adminRepositoryProvider).unsuspendUser(userId);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminDashboardStatsProvider);
      ref.invalidate(adminAuditLogsProvider);
      state = AdminActionState(isLoading: false);
      return true;
    } catch (e) {
      state = AdminActionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> hideReview(String reviewId, String note) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref.read(adminRepositoryProvider).hideReview(reviewId, note);
      ref.invalidate(adminReviewsProvider);
      ref.invalidate(adminDashboardStatsProvider);
      ref.invalidate(adminAuditLogsProvider);
      state = AdminActionState(isLoading: false);
      return true;
    } catch (e) {
      state = AdminActionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> restoreReview(String reviewId) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref.read(adminRepositoryProvider).restoreReview(reviewId);
      ref.invalidate(adminReviewsProvider);
      ref.invalidate(adminDashboardStatsProvider);
      ref.invalidate(adminAuditLogsProvider);
      state = AdminActionState(isLoading: false);
      return true;
    } catch (e) {
      state = AdminActionState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final adminActionControllerProvider = NotifierProvider<AdminActionController, AdminActionState>(() {
  return AdminActionController();
});
