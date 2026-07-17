import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(Supabase.instance.client);
});

const notificationRefreshInterval = Duration(seconds: 3);

final notificationsProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) async* {
      final repository = ref.watch(notificationRepositoryProvider);
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        yield [];
        return;
      }

      yield* watchNotificationList(repository);
    });

final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((
  ref,
) async* {
  final repository = ref.watch(notificationRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield 0;
    return;
  }

  yield* watchUnreadNotificationCount(repository);
});

List<NotificationModel> parseNotificationEvents(
  List<Map<String, dynamic>> events,
) {
  final notifications = events
      .map(NotificationModel.fromJson)
      .toList(growable: false);

  return sortNotifications(notifications);
}

Stream<List<NotificationModel>> watchNotificationList(
  NotificationRepository repository, {
  Duration refreshInterval = notificationRefreshInterval,
}) async* {
  var lastSignature = '';
  var hasYielded = false;

  while (true) {
    try {
      final notifications = await repository.fetchNotifications();
      final sorted = sortNotifications(notifications);
      final signature = _notificationSignature(sorted);

      if (!hasYielded || signature != lastSignature) {
        yield sorted;
        lastSignature = signature;
        hasYielded = true;
      }
    } catch (_) {
      if (!hasYielded) {
        yield const [];
        hasYielded = true;
      }
    }

    await Future<void>.delayed(refreshInterval);
  }
}

Stream<int> watchUnreadNotificationCount(
  NotificationRepository repository, {
  Duration refreshInterval = notificationRefreshInterval,
}) async* {
  int? lastCount;
  var hasYielded = false;

  while (true) {
    try {
      final count = await repository.fetchUnreadCount();

      if (!hasYielded || count != lastCount) {
        yield count;
        lastCount = count;
        hasYielded = true;
      }
    } catch (_) {
      if (!hasYielded) {
        yield 0;
        lastCount = 0;
        hasYielded = true;
      }
    }

    await Future<void>.delayed(refreshInterval);
  }
}

List<NotificationModel> sortNotifications(
  List<NotificationModel> notifications,
) {
  return [...notifications]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

String _notificationSignature(List<NotificationModel> notifications) {
  return notifications
      .map(
        (notification) =>
            '${notification.id}:${notification.isRead}:${notification.createdAt.microsecondsSinceEpoch}',
      )
      .join('|');
}

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
