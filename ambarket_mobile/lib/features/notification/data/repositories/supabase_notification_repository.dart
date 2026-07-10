import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/error_mapper.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;

  SupabaseNotificationRepository(this._client);

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return [];

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == '42P01' || e.code == '404') {
        return [];
      }
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<int> fetchUnreadCount() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return 0;

      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false);

      return (response as List).length;
    } on PostgrestException catch (e) {
      if (e.code == '42P01' || e.code == '404') {
        return 0;
      }
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '42P01' || e.code == '404') return;
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      if (e.code == '42P01' || e.code == '404') return;
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }

  @override
  Future<void> createDummyNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedType,
    String? relatedId,
  }) async {
    try {
      await _client.rpc(
        'create_dummy_notification',
        params: {
          'p_user_id': userId,
          'p_type': type,
          'p_title': title,
          'p_body': body,
          'p_related_type': relatedType,
          'p_related_id': relatedId,
        },
      );
    } catch (e) {
      throw Exception(ErrorMapper.getFriendlyMessage(e));
    }
  }
}
