import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/admin/domain/models/admin_audit_log_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_model.dart';
import 'package:ambarket_mobile/features/wallet/domain/models/seller_withdrawal_model.dart';
import 'package:ambarket_mobile/features/order/domain/models/refund_request_model.dart';
import 'package:ambarket_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:ambarket_mobile/features/admin/data/repositories/supabase_admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return SupabaseAdminRepository(Supabase.instance.client);
});

final adminDashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      return ref.watch(adminRepositoryProvider).fetchAdminDashboardStats();
    });

class PaginatedReportsState {
  final List<ReportModel> items;
  final bool hasMore;
  PaginatedReportsState({required this.items, required this.hasMore});
}

class AdminReportsNotifier extends AsyncNotifier<PaginatedReportsState> {
  static const int _limit = 20;
  int _offset = 0;

  @override
  FutureOr<PaginatedReportsState> build() async => _fetchInitial();

  Future<PaginatedReportsState> _fetchInitial() async {
    _offset = 0;
    final items = await ref
        .read(adminRepositoryProvider)
        .fetchAllReports(limit: _limit, offset: _offset);
    return PaginatedReportsState(items: items, hasMore: items.length == _limit);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError || !(state.value?.hasMore ?? false)) {
      return;
    }

    _offset += _limit;
    state = const AsyncValue.loading();
    try {
      final newItems = await ref
          .read(adminRepositoryProvider)
          .fetchAllReports(limit: _limit, offset: _offset);
      state = AsyncValue.data(
        PaginatedReportsState(
          items: [...?state.value?.items, ...newItems],
          hasMore: newItems.length == _limit,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminReportsProvider =
    AsyncNotifierProvider<AdminReportsNotifier, PaginatedReportsState>(
      () => AdminReportsNotifier(),
    );

class PaginatedProductsState {
  final List<ProductModel> items;
  final bool hasMore;
  PaginatedProductsState({required this.items, required this.hasMore});
}

class AdminProductsNotifier extends AsyncNotifier<PaginatedProductsState> {
  static const int _limit = 20;
  int _offset = 0;

  @override
  FutureOr<PaginatedProductsState> build() async => _fetchInitial();

  Future<PaginatedProductsState> _fetchInitial() async {
    _offset = 0;
    final items = await ref
        .read(adminRepositoryProvider)
        .fetchAllProductsForAdmin(limit: _limit, offset: _offset);
    return PaginatedProductsState(
      items: items,
      hasMore: items.length == _limit,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError || !(state.value?.hasMore ?? false)) {
      return;
    }

    _offset += _limit;
    state = const AsyncValue.loading();
    try {
      final newItems = await ref
          .read(adminRepositoryProvider)
          .fetchAllProductsForAdmin(limit: _limit, offset: _offset);
      state = AsyncValue.data(
        PaginatedProductsState(
          items: [...?state.value?.items, ...newItems],
          hasMore: newItems.length == _limit,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminProductsProvider =
    AsyncNotifierProvider<AdminProductsNotifier, PaginatedProductsState>(
      () => AdminProductsNotifier(),
    );

class PaginatedUsersState {
  final List<ProfileModel> items;
  final bool hasMore;
  PaginatedUsersState({required this.items, required this.hasMore});
}

class AdminUsersNotifier extends AsyncNotifier<PaginatedUsersState> {
  static const int _limit = 20;
  int _offset = 0;

  @override
  FutureOr<PaginatedUsersState> build() async => _fetchInitial();

  Future<PaginatedUsersState> _fetchInitial() async {
    _offset = 0;
    final items = await ref
        .read(adminRepositoryProvider)
        .fetchAllUsersForAdmin(limit: _limit, offset: _offset);
    return PaginatedUsersState(items: items, hasMore: items.length == _limit);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError || !(state.value?.hasMore ?? false)) {
      return;
    }

    _offset += _limit;
    state = const AsyncValue.loading();
    try {
      final newItems = await ref
          .read(adminRepositoryProvider)
          .fetchAllUsersForAdmin(limit: _limit, offset: _offset);
      state = AsyncValue.data(
        PaginatedUsersState(
          items: [...?state.value?.items, ...newItems],
          hasMore: newItems.length == _limit,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, PaginatedUsersState>(
      () => AdminUsersNotifier(),
    );

class PaginatedReviewsState {
  final List<ReviewModel> items;
  final bool hasMore;
  PaginatedReviewsState({required this.items, required this.hasMore});
}

class AdminReviewsNotifier extends AsyncNotifier<PaginatedReviewsState> {
  static const int _limit = 20;
  int _offset = 0;

  @override
  FutureOr<PaginatedReviewsState> build() async => _fetchInitial();

  Future<PaginatedReviewsState> _fetchInitial() async {
    _offset = 0;
    final items = await ref
        .read(adminRepositoryProvider)
        .fetchAllReviewsForAdmin(limit: _limit, offset: _offset);
    return PaginatedReviewsState(items: items, hasMore: items.length == _limit);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError || !(state.value?.hasMore ?? false)) {
      return;
    }

    _offset += _limit;
    state = const AsyncValue.loading();
    try {
      final newItems = await ref
          .read(adminRepositoryProvider)
          .fetchAllReviewsForAdmin(limit: _limit, offset: _offset);
      state = AsyncValue.data(
        PaginatedReviewsState(
          items: [...?state.value?.items, ...newItems],
          hasMore: newItems.length == _limit,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminReviewsProvider =
    AsyncNotifierProvider<AdminReviewsNotifier, PaginatedReviewsState>(
      () => AdminReviewsNotifier(),
    );

class PaginatedWithdrawalsState {
  final List<SellerWithdrawalModel> items;
  final bool hasMore;
  PaginatedWithdrawalsState({required this.items, required this.hasMore});
}

class AdminWithdrawalsNotifier
    extends AsyncNotifier<PaginatedWithdrawalsState> {
  static const int _limit = 20;
  int _offset = 0;

  @override
  FutureOr<PaginatedWithdrawalsState> build() async => _fetchInitial();

  Future<PaginatedWithdrawalsState> _fetchInitial() async {
    _offset = 0;
    final items = await ref
        .read(adminRepositoryProvider)
        .fetchAllWithdrawalsForAdmin(limit: _limit, offset: _offset);
    return PaginatedWithdrawalsState(
      items: items,
      hasMore: items.length == _limit,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError || !(state.value?.hasMore ?? false)) {
      return;
    }

    final previousItems = state.value?.items ?? [];
    _offset += _limit;
    state = const AsyncValue.loading();
    try {
      final newItems = await ref
          .read(adminRepositoryProvider)
          .fetchAllWithdrawalsForAdmin(limit: _limit, offset: _offset);
      state = AsyncValue.data(
        PaginatedWithdrawalsState(
          items: [...previousItems, ...newItems],
          hasMore: newItems.length == _limit,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminWithdrawalsProvider =
    AsyncNotifierProvider<AdminWithdrawalsNotifier, PaginatedWithdrawalsState>(
      () => AdminWithdrawalsNotifier(),
    );

class PaginatedRefundsState {
  final List<RefundRequestModel> items;
  final bool hasMore;
  PaginatedRefundsState({required this.items, required this.hasMore});
}

class AdminRefundsNotifier extends AsyncNotifier<PaginatedRefundsState> {
  static const int _limit = 30;
  int _offset = 0;

  @override
  FutureOr<PaginatedRefundsState> build() async => _fetchInitial();

  Future<PaginatedRefundsState> _fetchInitial() async {
    _offset = 0;
    final items = await ref
        .read(adminRepositoryProvider)
        .fetchRefundRequestsForAdmin(limit: _limit, offset: _offset);
    return PaginatedRefundsState(items: items, hasMore: items.length == _limit);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError || !(state.value?.hasMore ?? false)) {
      return;
    }

    final previousItems = state.value?.items ?? [];
    _offset += _limit;
    state = const AsyncValue.loading();
    try {
      final newItems = await ref
          .read(adminRepositoryProvider)
          .fetchRefundRequestsForAdmin(limit: _limit, offset: _offset);
      state = AsyncValue.data(
        PaginatedRefundsState(
          items: [...previousItems, ...newItems],
          hasMore: newItems.length == _limit,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminRefundsProvider =
    AsyncNotifierProvider<AdminRefundsNotifier, PaginatedRefundsState>(
      () => AdminRefundsNotifier(),
    );

final adminAuditLogsProvider =
    FutureProvider.autoDispose<List<AdminAuditLogModel>>((ref) async {
      return ref.watch(adminRepositoryProvider).fetchAuditLogs(limit: 50);
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
      await ref
          .read(adminRepositoryProvider)
          .updateReportStatus(reportId, status);
      ref.invalidate(adminReportsProvider);
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

  Future<bool> approveWithdrawal(String withdrawalId) async {
    return _updateWithdrawalStatus(withdrawalId, 'approved_dummy');
  }

  Future<bool> rejectWithdrawal(String withdrawalId) async {
    return _updateWithdrawalStatus(withdrawalId, 'rejected_dummy');
  }

  Future<bool> _updateWithdrawalStatus(
    String withdrawalId,
    String status,
  ) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateWithdrawalStatus(withdrawalId, status);
      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminDashboardStatsProvider);
      ref.invalidate(adminAuditLogsProvider);
      state = AdminActionState(isLoading: false);
      return true;
    } catch (e) {
      state = AdminActionState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resolveRefund({
    required String refundId,
    required String decision,
    double approvedAmount = 0,
    String? adminNote,
  }) async {
    state = AdminActionState(isLoading: true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .resolveRefundRequest(
            refundId: refundId,
            decision: decision,
            approvedAmount: approvedAmount,
            adminNote: adminNote,
          );
      ref.invalidate(adminRefundsProvider);
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

final adminActionControllerProvider =
    NotifierProvider<AdminActionController, AdminActionState>(() {
      return AdminActionController();
    });
