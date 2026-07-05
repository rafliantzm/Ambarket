import 'package:ambarket_mobile/features/report/domain/models/report_model.dart';
import 'package:ambarket_mobile/features/admin/domain/models/admin_audit_log_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/review/domain/models/review_model.dart';

abstract class AdminRepository {
  Future<Map<String, dynamic>> fetchAdminDashboardStats();
  Future<List<ReportModel>> fetchAllReports();
  Future<List<ReportModel>> fetchReportsByStatus(String status);
  Future<void> updateReportStatus(String reportId, String status);
  
  // Fetching Models
  Future<List<ProductModel>> fetchAllProductsForAdmin();
  Future<List<ProductModel>> fetchProductsByStatusForAdmin(String status);
  Future<List<ProfileModel>> fetchAllUsersForAdmin();
  Future<List<ReviewModel>> fetchAllReviewsForAdmin();
  
  // Moderation Actions
  Future<void> hideProduct(String productId, String note);
  Future<void> rejectProduct(String productId, String note);
  Future<void> restoreProduct(String productId);
  
  Future<void> suspendUser(String userId, String reason);
  Future<void> unsuspendUser(String userId);
  
  Future<void> hideReview(String reviewId, String note);
  Future<void> restoreReview(String reviewId);
  
  // Audit Logs
  Future<List<AdminAuditLogModel>> fetchAuditLogs();
  Future<void> createAuditLog(String action, String targetType, String targetId, Map<String, dynamic>? metadata);
}
