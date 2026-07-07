import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/supabase_notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(Supabase.instance.client);
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.fetchNotifications();
});

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.fetchUnreadCount();
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

final notificationActionControllerProvider = NotifierProvider<NotificationActionController, NotificationActionState>(() {
  return NotificationActionController();
});
