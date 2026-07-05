import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';

abstract class ReportRepository {
  Future<ReportModel> createReport({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  });

  Future<List<ReportModel>> fetchMyReports(String reporterId);
}
