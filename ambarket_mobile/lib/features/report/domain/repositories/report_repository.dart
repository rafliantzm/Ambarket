import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_message_model.dart';

abstract class ReportRepository {
  Future<ReportModel> createReport({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  });

  Future<List<ReportModel>> fetchMyReports(String reporterId);
  Future<List<ReportModel>> fetchAdminReports({
    String? status,
    int limit = 20,
    int offset = 0,
  });
  Future<ReportModel> fetchReportDetail(String reportId);

  Future<List<ReportMessageModel>> fetchReportMessages(String reportId);
  Future<ReportMessageModel> sendReportMessage({
    required String reportId,
    required String senderId,
    required String message,
  });

  Future<ReportMessageModel> adminSendReportMessage({
    required String reportId,
    required String adminId,
    required String message,
  });

  Future<void> adminUpdateReportStatus(String reportId, String status);

  Future<void> adminSendFinalResolution({
    required String reportId,
    required String adminId,
    required String finalResolution,
    required String status,
  });
}
