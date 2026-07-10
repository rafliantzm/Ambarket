import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_message_model.dart';
import 'package:ambarket_mobile/features/report/domain/repositories/report_repository.dart';
import 'package:ambarket_mobile/features/report/data/repositories/supabase_report_repository.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return SupabaseReportRepository(Supabase.instance.client);
});

final myReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(reportRepositoryProvider).fetchMyReports(user.id);
});

class ReportStatusFilter extends Notifier<String> {
  @override
  String build() => 'all';

  void updateFilter(String value) {
    state = value;
  }
}

final reportStatusFilterProvider = NotifierProvider<ReportStatusFilter, String>(
  () {
    return ReportStatusFilter();
  },
);

class PaginatedAdminReportsState {
  final List<ReportModel> items;
  final bool hasMore;
  PaginatedAdminReportsState({required this.items, required this.hasMore});
}

class AdminReportsNotifier extends AsyncNotifier<PaginatedAdminReportsState> {
  static const int _limit = 20;
  int _offset = 0;

  @override
  FutureOr<PaginatedAdminReportsState> build() async => _fetchInitial();

  Future<PaginatedAdminReportsState> _fetchInitial() async {
    _offset = 0;
    final status = ref.watch(reportStatusFilterProvider);
    final items = await ref
        .read(reportRepositoryProvider)
        .fetchAdminReports(status: status, limit: _limit, offset: _offset);
    return PaginatedAdminReportsState(
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
      final status = ref.read(reportStatusFilterProvider);
      final newItems = await ref
          .read(reportRepositoryProvider)
          .fetchAdminReports(status: status, limit: _limit, offset: _offset);
      state = AsyncValue.data(
        PaginatedAdminReportsState(
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
    AsyncNotifierProvider<AdminReportsNotifier, PaginatedAdminReportsState>(
      () => AdminReportsNotifier(),
    );

final reportDetailProvider = FutureProvider.family<ReportModel, String>((
  ref,
  reportId,
) async {
  return ref.watch(reportRepositoryProvider).fetchReportDetail(reportId);
});

final reportMessagesProvider =
    FutureProvider.family<List<ReportMessageModel>, String>((
      ref,
      reportId,
    ) async {
      return ref.watch(reportRepositoryProvider).fetchReportMessages(reportId);
    });

class CreateReportState {
  final bool isLoading;
  final String? error;

  CreateReportState({this.isLoading = false, this.error});
}

class CreateReportController extends Notifier<CreateReportState> {
  @override
  CreateReportState build() {
    return CreateReportState();
  }

  Future<bool> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = CreateReportState(
        isLoading: false,
        error: 'Silakan login terlebih dahulu',
      );
      return false;
    }

    state = CreateReportState(isLoading: true, error: null);
    try {
      await ref
          .read(reportRepositoryProvider)
          .createReport(
            reporterId: user.id,
            targetType: targetType,
            targetId: targetId,
            reason: reason,
            description: description,
          );

      ref.invalidate(myReportsProvider);
      state = CreateReportState(isLoading: false);
      return true;
    } catch (e) {
      state = CreateReportState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final createReportControllerProvider =
    NotifierProvider<CreateReportController, CreateReportState>(() {
      return CreateReportController();
    });

class ReportActionState {
  final bool isLoading;
  final String? error;

  ReportActionState({this.isLoading = false, this.error});
}

class ReportActionController extends Notifier<ReportActionState> {
  @override
  ReportActionState build() {
    return ReportActionState();
  }

  Future<bool> sendMessage(String reportId, String message) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = ReportActionState(
        isLoading: false,
        error: 'Silakan login terlebih dahulu',
      );
      return false;
    }

    state = ReportActionState(isLoading: true, error: null);
    try {
      await ref
          .read(reportRepositoryProvider)
          .sendReportMessage(
            reportId: reportId,
            senderId: user.id,
            message: message,
          );
      ref.invalidate(reportMessagesProvider(reportId));
      state = ReportActionState(isLoading: false);
      return true;
    } catch (e) {
      state = ReportActionState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> adminSendMessage(String reportId, String message) async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.role != 'admin') {
      state = ReportActionState(isLoading: false, error: 'Akses ditolak');
      return false;
    }

    state = ReportActionState(isLoading: true, error: null);
    try {
      await ref
          .read(reportRepositoryProvider)
          .adminSendReportMessage(
            reportId: reportId,
            adminId: user.id,
            message: message,
          );
      ref.invalidate(reportMessagesProvider(reportId));
      state = ReportActionState(isLoading: false);
      return true;
    } catch (e) {
      state = ReportActionState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> adminUpdateStatus(String reportId, String status) async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.role != 'admin') {
      state = ReportActionState(isLoading: false, error: 'Akses ditolak');
      return false;
    }

    state = ReportActionState(isLoading: true, error: null);
    try {
      await ref
          .read(reportRepositoryProvider)
          .adminUpdateReportStatus(reportId, status);
      ref.invalidate(reportDetailProvider(reportId));
      ref.invalidate(adminReportsProvider);
      state = ReportActionState(isLoading: false);
      return true;
    } catch (e) {
      state = ReportActionState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> adminSendFinalResolution(
    String reportId,
    String finalResolution,
    String status,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.role != 'admin') {
      state = ReportActionState(isLoading: false, error: 'Akses ditolak');
      return false;
    }

    state = ReportActionState(isLoading: true, error: null);
    try {
      await ref
          .read(reportRepositoryProvider)
          .adminSendFinalResolution(
            reportId: reportId,
            adminId: user.id,
            finalResolution: finalResolution,
            status: status,
          );

      ref.invalidate(reportDetailProvider(reportId));
      ref.invalidate(adminReportsProvider);
      ref.invalidate(myReportsProvider);

      // Attempt to trigger notification (handled by postgres trigger in production)

      state = ReportActionState(isLoading: false);
      return true;
    } catch (e) {
      state = ReportActionState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final reportActionControllerProvider =
    NotifierProvider<ReportActionController, ReportActionState>(() {
      return ReportActionController();
    });
