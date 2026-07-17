import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/admin/domain/models/admin_audit_log_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_model.dart';
import 'package:ambarket_mobile/features/wallet/domain/models/seller_withdrawal_model.dart';
import 'package:ambarket_mobile/features/order/domain/models/refund_request_model.dart';

abstract class AdminRepository {
  Future<Map<String, dynamic>> fetchAdminDashboardStats();
  Future<List<ReportModel>> fetchAllReports({int limit = 20, int offset = 0});
  Future<List<ReportModel>> fetchReportsByStatus(
    String status, {
    int limit = 20,
    int offset = 0,
  });
  Future<void> updateReportStatus(String reportId, String status);

  // Fetching Models
  Future<List<ProductModel>> fetchAllProductsForAdmin({
    int limit = 20,
    int offset = 0,
  });
  Future<List<ProductModel>> fetchProductsByStatusForAdmin(
    String status, {
    int limit = 20,
    int offset = 0,
  });
  Future<List<ProfileModel>> fetchAllUsersForAdmin({
    int limit = 20,
    int offset = 0,
  });
  Future<List<ReviewModel>> fetchAllReviewsForAdmin({
    int limit = 20,
    int offset = 0,
  });
  Future<List<SellerWithdrawalModel>> fetchAllWithdrawalsForAdmin({
    int limit = 20,
    int offset = 0,
  });
  Future<List<RefundRequestModel>> fetchRefundRequestsForAdmin({
    int limit = 30,
    int offset = 0,
  });

  // Moderation Actions
  Future<void> hideProduct(String productId, String note);
  Future<void> rejectProduct(String productId, String note);
  Future<void> restoreProduct(String productId);

  Future<void> suspendUser(String userId, String reason);
  Future<void> unsuspendUser(String userId);

  Future<void> hideReview(String reviewId, String note);
  Future<void> restoreReview(String reviewId);
  Future<void> updateWithdrawalStatus(String withdrawalId, String status);
  Future<RefundRequestModel> resolveRefundRequest({
    required String refundId,
    required String decision,
    double approvedAmount = 0,
    String? adminNote,
  });

  // Audit Logs
  Future<List<AdminAuditLogModel>> fetchAuditLogs({
    int limit = 20,
    int offset = 0,
  });
  Future<void> createAuditLog(
    String action,
    String targetType,
    String targetId,
    Map<String, dynamic>? metadata,
  );
}
