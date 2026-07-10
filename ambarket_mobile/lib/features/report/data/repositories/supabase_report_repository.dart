import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_message_model.dart';
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
      final response = await _client
          .from('reports')
          .insert({
            'reporter_id': reporterId,
            'target_type': targetType,
            'target_id': targetId,
            'reason': reason,
            'description': description,
          })
          .select()
          .single();

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

  @override
  Future<List<ReportModel>> fetchAdminReports({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client.from('reports').select();
    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((json) => ReportModel.fromJson(json)).toList();
  }

  @override
  Future<ReportModel> fetchReportDetail(String reportId) async {
    final response = await _client
        .from('reports')
        .select()
        .eq('id', reportId)
        .single();
    return ReportModel.fromJson(response);
  }

  @override
  Future<List<ReportMessageModel>> fetchReportMessages(String reportId) async {
    final response = await _client
        .from('report_messages')
        .select()
        .eq('report_id', reportId)
        .order('created_at', ascending: true);
    return response.map((json) => ReportMessageModel.fromJson(json)).toList();
  }

  @override
  Future<ReportMessageModel> sendReportMessage({
    required String reportId,
    required String senderId,
    required String message,
  }) async {
    final response = await _client
        .from('report_messages')
        .insert({
          'report_id': reportId,
          'sender_id': senderId,
          'sender_role': 'user',
          'message': message,
        })
        .select()
        .single();
    return ReportMessageModel.fromJson(response);
  }

  @override
  Future<ReportMessageModel> adminSendReportMessage({
    required String reportId,
    required String adminId,
    required String message,
  }) async {
    final response = await _client
        .from('report_messages')
        .insert({
          'report_id': reportId,
          'sender_id': adminId,
          'sender_role': 'admin',
          'message': message,
        })
        .select()
        .single();
    return ReportMessageModel.fromJson(response);
  }

  @override
  Future<void> adminUpdateReportStatus(String reportId, String status) async {
    await _client.from('reports').update({'status': status}).eq('id', reportId);
  }

  @override
  Future<void> adminSendFinalResolution({
    required String reportId,
    required String adminId,
    required String finalResolution,
    required String status,
  }) async {
    await _client
        .from('reports')
        .update({
          'status': status,
          'final_resolution': finalResolution,
          'resolved_by': adminId,
          'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId);
  }
}
