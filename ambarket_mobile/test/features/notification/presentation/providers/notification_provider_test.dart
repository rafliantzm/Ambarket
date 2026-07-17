import 'package:ambarket_mobile/features/notification/presentation/providers/notification_provider.dart';
import 'package:ambarket_mobile/features/notification/domain/models/notification_model.dart';
import 'package:ambarket_mobile/features/notification/domain/repositories/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationRepository implements NotificationRepository {
  final List<Object> notificationResponses;
  final List<Object> unreadResponses;
  int notificationIndex = 0;
  int unreadIndex = 0;

  _FakeNotificationRepository({
    this.notificationResponses = const [],
    this.unreadResponses = const [],
  });

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    final response = notificationResponses[notificationIndex++];
    if (response is Exception) {
      throw response;
    }
    return response as List<NotificationModel>;
  }

  @override
  Future<int> fetchUnreadCount() async {
    final response = unreadResponses[unreadIndex++];
    if (response is Exception) {
      throw response;
    }
    return response as int;
  }

  @override
  Future<void> createDummyNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedType,
    String? relatedId,
  }) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String id) async {}
}

void main() {
  test('parseNotificationEvents tolerates legacy rows and sorts safely', () {
    final notifications = parseNotificationEvents([
      {
        'id': 'old',
        'user_id': 'u1',
        'type': null,
        'title': null,
        'body': null,
        'is_read': false,
        'created_at': null,
      },
      {
        'id': 'new',
        'user_id': 'u1',
        'type': 'order_shipped',
        'title': 'Pesanan Dikirim',
        'body': 'Barang sedang dikirim.',
        'is_read': false,
        'created_at': '2026-07-12T08:00:00Z',
      },
    ]);

    expect(notifications, hasLength(2));
    expect(notifications.first.id, 'new');
    expect(notifications.last.title, 'Notifikasi');
  });

  test(
    'watchNotificationList keeps polling after a transient fetch error',
    () async {
      final oldNotification = NotificationModel(
        id: 'old',
        userId: 'u1',
        type: 'order_created',
        title: 'Pesanan Dibuat',
        body: 'Pesanan dibuat.',
        isRead: false,
        createdAt: DateTime(2026, 7, 12, 8),
      );
      final newNotification = NotificationModel(
        id: 'new',
        userId: 'u1',
        type: 'payment_paid',
        title: 'Pembayaran Diterima',
        body: 'Pembayaran diterima.',
        isRead: false,
        createdAt: DateTime(2026, 7, 12, 9),
      );
      final repository = _FakeNotificationRepository(
        notificationResponses: [
          [oldNotification],
          Exception('RealtimeSubscribeException(channelError)'),
          [newNotification, oldNotification],
        ],
      );

      await expectLater(
        watchNotificationList(
          repository,
          refreshInterval: const Duration(milliseconds: 1),
        ).take(2),
        emitsInOrder([
          predicate<List<NotificationModel>>(
            (items) => items.length == 1 && items.first.id == 'old',
          ),
          predicate<List<NotificationModel>>(
            (items) => items.length == 2 && items.first.id == 'new',
          ),
          emitsDone,
        ]),
      );
    },
  );

  test('watchNotificationList recovers after initial fetch failure', () async {
    final notification = NotificationModel(
      id: 'new',
      userId: 'u1',
      type: 'order_created',
      title: 'Pesanan Dibuat',
      body: 'Pesanan dibuat.',
      isRead: false,
      createdAt: DateTime(2026, 7, 12, 9),
    );
    final repository = _FakeNotificationRepository(
      notificationResponses: [
        Exception('RealtimeSubscribeException(channelError)'),
        [notification],
      ],
    );

    await expectLater(
      watchNotificationList(
        repository,
        refreshInterval: const Duration(milliseconds: 1),
      ).take(2),
      emitsInOrder([
        isEmpty,
        predicate<List<NotificationModel>>(
          (items) => items.length == 1 && items.first.id == 'new',
        ),
        emitsDone,
      ]),
    );
  });

  test(
    'watchUnreadNotificationCount keeps polling after transient errors',
    () async {
      final repository = _FakeNotificationRepository(
        unreadResponses: [1, Exception('temporary'), 2],
      );

      await expectLater(
        watchUnreadNotificationCount(
          repository,
          refreshInterval: const Duration(milliseconds: 1),
        ).take(2),
        emitsInOrder([1, 2, emitsDone]),
      );
    },
  );

  test(
    'watchUnreadNotificationCount recovers after initial fetch failure',
    () async {
      final repository = _FakeNotificationRepository(
        unreadResponses: [Exception('temporary'), 3],
      );

      await expectLater(
        watchUnreadNotificationCount(
          repository,
          refreshInterval: const Duration(milliseconds: 1),
        ).take(2),
        emitsInOrder([0, 3, emitsDone]),
      );
    },
  );
}
