import 'package:flutter_test/flutter_test.dart';
import 'package:ambarket_mobile/features/notification/domain/models/notification_model.dart';

void main() {
  test('NotificationModel.fromJson tolerates incomplete legacy rows', () {
    final notification = NotificationModel.fromJson({
      'id': 'n1',
      'user_id': 'u1',
      'type': null,
      'title': null,
      'body': '',
      'related_type': '',
      'related_id': null,
      'is_read': null,
      'created_at': null,
    });

    expect(notification.id, 'n1');
    expect(notification.type, 'general');
    expect(notification.title, 'Notifikasi');
    expect(notification.body, 'Ada pembaruan baru.');
    expect(notification.relatedType, isNull);
    expect(notification.isRead, isFalse);
  });
}
