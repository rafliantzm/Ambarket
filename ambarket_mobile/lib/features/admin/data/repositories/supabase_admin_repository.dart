import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/admin/domain/models/admin_audit_log_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_model.dart';
import 'package:ambarket_mobile/features/wallet/domain/models/seller_withdrawal_model.dart';
import 'package:ambarket_mobile/features/order/domain/models/refund_request_model.dart';
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
    final reportsCount = await _client
        .from('reports')
        .select('id')
        .eq('status', 'pending')
        .count(CountOption.exact);
    final usersCount = await _client
        .from('profiles')
        .select('id')
        .count(CountOption.exact);
    final productsCount = await _client
        .from('products')
        .select('id')
        .count(CountOption.exact);
    var pendingWithdrawals = 0;
    var pendingRefunds = 0;
    try {
      final rpcCount = await _client.rpc('count_admin_pending_withdrawals');
      pendingWithdrawals = (rpcCount as num?)?.toInt() ?? 0;
    } catch (_) {
      try {
        final withdrawalsCount = await _client
            .from('seller_withdrawals')
            .select('id')
            .eq('status', 'pending')
            .count(CountOption.exact);
        pendingWithdrawals = withdrawalsCount.count;
      } catch (_) {
        pendingWithdrawals = 0;
      }
    }

    try {
      final refundsCount = await _client
          .from('order_refund_requests')
          .select('id')
          .inFilter('status', ['submitted', 'seller_responded', 'under_review'])
          .count(CountOption.exact);
      pendingRefunds = refundsCount.count;
    } catch (_) {
      pendingRefunds = 0;
    }

    return {
      'pendingReports': reportsCount.count,
      'totalUsers': usersCount.count,
      'totalProducts': productsCount.count,
      'pendingWithdrawals': pendingWithdrawals,
      'pendingRefunds': pendingRefunds,
    };
  }

  @override
  Future<List<ReportModel>> fetchAllReports({
    int limit = 20,
    int offset = 0,
  }) async {
    _checkAdmin();
    final response = await _client
        .from('reports')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((json) => ReportModel.fromJson(json)).toList();
  }

  @override
  Future<List<ReportModel>> fetchReportsByStatus(
    String status, {
    int limit = 20,
    int offset = 0,
  }) async {
    _checkAdmin();
    final response = await _client
        .from('reports')
        .select()
        .eq('status', status)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((json) => ReportModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateReportStatus(String reportId, String status) async {
    _checkAdmin();
    await _client
        .from('reports')
        .update({
          'status': status,
          if (status == 'resolved' || status == 'rejected')
            'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId);
  }

  @override
  Future<List<ProductModel>> fetchAllProductsForAdmin({
    int limit = 20,
    int offset = 0,
  }) async {
    _checkAdmin();
    final response = await _client
        .from('products')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<List<ProductModel>> fetchProductsByStatusForAdmin(
    String status, {
    int limit = 20,
    int offset = 0,
  }) async {
    _checkAdmin();
    final response = await _client
        .from('products')
        .select()
        .eq('status', status)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<List<ProfileModel>> fetchAllUsersForAdmin({
    int limit = 20,
    int offset = 0,
  }) async {
    _checkAdmin();
    final response = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((json) => ProfileModel.fromJson(json)).toList();
  }

  @override
  Future<List<ReviewModel>> fetchAllReviewsForAdmin({
    int limit = 20,
    int offset = 0,
  }) async {
    _checkAdmin();
    final response = await _client
        .from('reviews')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((json) => ReviewModel.fromJson(json)).toList();
  }

  @override
  Future<List<SellerWithdrawalModel>> fetchAllWithdrawalsForAdmin({
    int limit = 20,
    int offset = 0,
  }) async {
    _checkAdmin();
    dynamic response;
    try {
      response = await _client.rpc(
        'fetch_admin_seller_withdrawals',
        params: {'p_limit': limit, 'p_offset': offset},
      );
    } catch (_) {
      response = await _client
          .from('seller_withdrawals')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
    }

    return (response as List)
        .map(
          (json) =>
              SellerWithdrawalModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<RefundRequestModel>> fetchRefundRequestsForAdmin({
    int limit = 30,
    int offset = 0,
  }) async {
    _checkAdmin();
    dynamic response;
    try {
      response = await _client.rpc(
        'fetch_admin_refund_requests',
        params: {'p_limit': limit, 'p_offset': offset},
      );
    } catch (_) {
      response = await _client
          .from('order_refund_requests')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
    }

    return (response as List)
        .map(
          (json) => RefundRequestModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> hideProduct(String productId, String note) async {
    _checkAdmin();
    await _client
        .from('products')
        .update({'status': 'hidden'})
        .eq('id', productId);
    await createAuditLog('product_hidden', 'product', productId, {
      'note': note,
    });
  }

  @override
  Future<void> rejectProduct(String productId, String note) async {
    _checkAdmin();
    await _client
        .from('products')
        .update({'status': 'rejected'})
        .eq('id', productId);
    await createAuditLog('product_rejected', 'product', productId, {
      'note': note,
    });
  }

  @override
  Future<void> restoreProduct(String productId) async {
    _checkAdmin();
    await _client
        .from('products')
        .update({'status': 'active'})
        .eq('id', productId);
    await createAuditLog('product_restored', 'product', productId, null);
  }

  @override
  Future<void> suspendUser(String userId, String reason) async {
    _checkAdmin();
    await _client
        .from('profiles')
        .update({
          'is_suspended': true,
          'suspension_reason': reason,
          'suspended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
    await createAuditLog('user_suspended', 'user', userId, {'reason': reason});
  }

  @override
  Future<void> unsuspendUser(String userId) async {
    _checkAdmin();
    await _client
        .from('profiles')
        .update({
          'is_suspended': false,
          'suspension_reason': null,
          'suspended_at': null,
        })
        .eq('id', userId);
    await createAuditLog('user_unsuspended', 'user', userId, null);
  }

  @override
  Future<void> hideReview(String reviewId, String note) async {
    _checkAdmin();
    await _client
        .from('reviews')
        .update({
          'is_hidden': true,
          'moderation_note': note,
          'moderated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reviewId);
    await createAuditLog('review_hidden', 'review', reviewId, {'note': note});
  }

  @override
  Future<void> restoreReview(String reviewId) async {
    _checkAdmin();
    await _client
        .from('reviews')
        .update({
          'is_hidden': false,
          'moderation_note': null,
          'moderated_at': null,
        })
        .eq('id', reviewId);
    await createAuditLog('review_restored', 'review', reviewId, null);
  }

  @override
  Future<void> updateWithdrawalStatus(
    String withdrawalId,
    String status,
  ) async {
    _checkAdmin();
    if (status != 'approved_dummy' && status != 'rejected_dummy') {
      throw Exception('Status penarikan tidak valid');
    }

    final withdrawal = await _client
        .from('seller_withdrawals')
        .select('seller_id, amount')
        .eq('id', withdrawalId)
        .single();

    await _client
        .from('seller_withdrawals')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', withdrawalId);

    final isApproved = status == 'approved_dummy';
    await createAuditLog(
      isApproved ? 'withdrawal_approved' : 'withdrawal_rejected',
      'withdrawal',
      withdrawalId,
      {'seller_id': withdrawal['seller_id'], 'amount': withdrawal['amount']},
    );

    try {
      await _client.rpc(
        'create_dummy_notification',
        params: {
          'p_user_id': withdrawal['seller_id'],
          'p_type': isApproved ? 'withdrawal_approved' : 'withdrawal_rejected',
          'p_title': isApproved ? 'Penarikan Disetujui' : 'Penarikan Ditolak',
          'p_body': isApproved
              ? 'Pengajuan penarikan dana dummy Anda sudah disetujui admin.'
              : 'Pengajuan penarikan dana dummy Anda ditolak admin.',
          'p_related_type': 'withdrawal',
          'p_related_id': withdrawalId,
        },
      );
    } catch (_) {
      // Status update remains authoritative even if notification delivery fails.
    }
  }

  @override
  Future<RefundRequestModel> resolveRefundRequest({
    required String refundId,
    required String decision,
    double approvedAmount = 0,
    String? adminNote,
  }) async {
    _checkAdmin();
    final response = await _client.rpc(
      'admin_resolve_refund',
      params: {
        'p_refund_id': refundId,
        'p_decision': decision,
        'p_approved_amount': approvedAmount,
        'p_admin_note': adminNote,
      },
    );

    final refund = RefundRequestModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
    await createAuditLog('refund_$decision', 'refund', refundId, {
      'order_id': refund.orderId,
      'approved_amount': refund.approvedAmount,
    });

    return refund;
  }

  @override
  Future<List<AdminAuditLogModel>> fetchAuditLogs({
    int limit = 20,
    int offset = 0,
  }) async {
    _checkAdmin();
    final response = await _client
        .from('admin_audit_logs')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((json) => AdminAuditLogModel.fromJson(json)).toList();
  }

  @override
  Future<void> createAuditLog(
    String action,
    String targetType,
    String targetId,
    Map<String, dynamic>? metadata,
  ) async {
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
