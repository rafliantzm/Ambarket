import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(Supabase.instance.client);
});

final notificationsProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
      final client = Supabase.instance.client;
      final user = ref.watch(currentUserProvider);
      if (user == null) return Stream.value([]);

      return client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .map((events) {
            final sortedEvents = List<Map<String, dynamic>>.from(events);
            sortedEvents.sort(
              (a, b) => DateTime.parse(
                b['created_at'],
              ).compareTo(DateTime.parse(a['created_at'])),
            );
            return sortedEvents
                .map((json) => NotificationModel.fromJson(json))
                .toList();
          });
    });

final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final client = Supabase.instance.client;
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  return client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((events) => events.where((e) => e['is_read'] == false).length);
});

class NotificationActionState {
  final bool isLoading;
  final String? error;
  NotificationActionState({this.isLoading = false, this.error});
}

class NotificationActionController extends Notifier<NotificationActionState> {
  @override
  NotificationActionState build() {
    return NotificationActionState();
  }

  Future<void> markAsRead(String id) async {
    state = NotificationActionState(isLoading: true);
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
      state = NotificationActionState(isLoading: false);
    } catch (e) {
      state = NotificationActionState(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    state = NotificationActionState(isLoading: true);
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
      state = NotificationActionState(isLoading: false);
    } catch (e) {
      state = NotificationActionState(isLoading: false, error: e.toString());
    }
  }
}

final notificationActionControllerProvider =
    NotifierProvider<NotificationActionController, NotificationActionState>(() {
      return NotificationActionController();
    });
