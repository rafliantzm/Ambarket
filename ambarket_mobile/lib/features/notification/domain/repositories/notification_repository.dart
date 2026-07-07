import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> fetchNotifications();
  Future<int> fetchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> createDummyNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedType,
    String? relatedId,
  });
}
