import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
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
      state = CreateReportState(isLoading: false, error: 'Silakan login terlebih dahulu');
      return false;
    }

    state = CreateReportState(isLoading: true, error: null);
    try {
      await ref.read(reportRepositoryProvider).createReport(
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
      state = CreateReportState(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final createReportControllerProvider = NotifierProvider<CreateReportController, CreateReportState>(() {
  return CreateReportController();
});
