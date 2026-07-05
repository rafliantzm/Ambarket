import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/report/domain/repositories/report_repository.dart';

class SupabaseReportRepository implements ReportRepository {
  final SupabaseClient _client;

  SupabaseReportRepository(this._client);

  @override
  Future<ReportModel> createReport({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _client.from('reports').insert({
        'reporter_id': reporterId,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        'description': description,
      }).select().single();

      return ReportModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Anda sudah pernah melaporkan item ini sebelumnya.');
      }
      rethrow;
    }
  }

  @override
  Future<List<ReportModel>> fetchMyReports(String reporterId) async {
    final response = await _client
        .from('reports')
        .select()
        .eq('reporter_id', reporterId)
        .order('created_at', ascending: false);

    return response.map((json) => ReportModel.fromJson(json)).toList();
  }
}
