import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/admin/domain/models/admin_audit_log_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_model.dart';
import 'package:ambarket_mobile/features/admin/domain/repositories/admin_repository.dart';

class SupabaseAdminRepository implements AdminRepository {
  final SupabaseClient _client;

  SupabaseAdminRepository(this._client);

  void _checkAdmin() {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    // RLS will ultimately protect the data, but we can also rely on the client throwing early if we wanted to.
    // We'll let RLS handle the actual security rejection.
  }

  @override
  Future<Map<String, dynamic>> fetchAdminDashboardStats() async {
    _checkAdmin();
    // Simplified stats for MVP. In a real app, you'd use an RPC or specific counts.
    final reportsCount = await _client.from('reports').select('id').eq('status', 'pending').count(CountOption.exact);
    final usersCount = await _client.from('profiles').select('id').count(CountOption.exact);
    final productsCount = await _client.from('products').select('id').count(CountOption.exact);

    return {
      'pendingReports': reportsCount.count,
      'totalUsers': usersCount.count,
      'totalProducts': productsCount.count,
    };
  }

  @override
  Future<List<ReportModel>> fetchAllReports() async {
    _checkAdmin();
    final response = await _client.from('reports').select().order('created_at', ascending: false);
    return response.map((json) => ReportModel.fromJson(json)).toList();
  }

  @override
  Future<List<ReportModel>> fetchReportsByStatus(String status) async {
    _checkAdmin();
    final response = await _client.from('reports').select().eq('status', status).order('created_at', ascending: false);
    return response.map((json) => ReportModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateReportStatus(String reportId, String status) async {
    _checkAdmin();
    await _client.from('reports').update({
      'status': status,
      if (status == 'resolved' || status == 'rejected') 'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  @override
  Future<List<ProductModel>> fetchAllProductsForAdmin() async {
    _checkAdmin();
    final response = await _client.from('products').select().order('created_at', ascending: false);
    return response.map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<List<ProductModel>> fetchProductsByStatusForAdmin(String status) async {
    _checkAdmin();
    final response = await _client.from('products').select().eq('status', status).order('created_at', ascending: false);
    return response.map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<List<ProfileModel>> fetchAllUsersForAdmin() async {
    _checkAdmin();
    final response = await _client.from('profiles').select().order('created_at', ascending: false);
    return response.map((json) => ProfileModel.fromJson(json)).toList();
  }

  @override
  Future<List<ReviewModel>> fetchAllReviewsForAdmin() async {
    _checkAdmin();
    final response = await _client.from('reviews').select().order('created_at', ascending: false);
    return response.map((json) => ReviewModel.fromJson(json)).toList();
  }

  @override
  Future<void> hideProduct(String productId, String note) async {
    _checkAdmin();
    await _client.from('products').update({'status': 'hidden'}).eq('id', productId);
    await createAuditLog('product_hidden', 'product', productId, {'note': note});
  }

  @override
  Future<void> rejectProduct(String productId, String note) async {
    _checkAdmin();
    await _client.from('products').update({'status': 'rejected'}).eq('id', productId);
    await createAuditLog('product_rejected', 'product', productId, {'note': note});
  }

  @override
  Future<void> restoreProduct(String productId) async {
    _checkAdmin();
    await _client.from('products').update({'status': 'active'}).eq('id', productId);
    await createAuditLog('product_restored', 'product', productId, null);
  }

  @override
  Future<void> suspendUser(String userId, String reason) async {
    _checkAdmin();
    await _client.from('profiles').update({
      'is_suspended': true,
      'suspension_reason': reason,
      'suspended_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
    await createAuditLog('user_suspended', 'user', userId, {'reason': reason});
  }

  @override
  Future<void> unsuspendUser(String userId) async {
    _checkAdmin();
    await _client.from('profiles').update({
      'is_suspended': false,
      'suspension_reason': null,
      'suspended_at': null,
    }).eq('id', userId);
    await createAuditLog('user_unsuspended', 'user', userId, null);
  }

  @override
  Future<void> hideReview(String reviewId, String note) async {
    _checkAdmin();
    await _client.from('reviews').update({
      'is_hidden': true,
      'moderation_note': note,
      'moderated_at': DateTime.now().toIso8601String(),
    }).eq('id', reviewId);
    await createAuditLog('review_hidden', 'review', reviewId, {'note': note});
  }

  @override
  Future<void> restoreReview(String reviewId) async {
    _checkAdmin();
    await _client.from('reviews').update({
      'is_hidden': false,
      'moderation_note': null,
      'moderated_at': null,
    }).eq('id', reviewId);
    await createAuditLog('review_restored', 'review', reviewId, null);
  }

  @override
  Future<List<AdminAuditLogModel>> fetchAuditLogs() async {
    _checkAdmin();
    final response = await _client.from('admin_audit_logs').select().order('created_at', ascending: false).limit(50);
    return response.map((json) => AdminAuditLogModel.fromJson(json)).toList();
  }

  @override
  Future<void> createAuditLog(String action, String targetType, String targetId, Map<String, dynamic>? metadata) async {
    _checkAdmin();
    await _client.from('admin_audit_logs').insert({
      'admin_id': _client.auth.currentUser!.id,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'metadata': metadata,
    });
  }
}
