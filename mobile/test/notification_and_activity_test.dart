import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/notification.dart';
import 'package:mobile/models/activity.dart';

void main() {
  group('Notification Models (Phase 2.5)', () {
    test('deserializes AppNotification and NotificationListResult correctly', () {
      final json = {
        'items': [
          {
            'id': 'n-1',
            'user_id': 'u-bob',
            'trip_id': 't-1',
            'notification_type': 'EXPENSE_ADDED',
            'title': 'New Expense',
            'body': 'Alice added Hotel ₹500.00',
            'entity_type': 'EXPENSE',
            'entity_id': 'e-1',
            'is_read': false,
            'read_at': null,
            'created_at': '2026-09-08T10:00:00Z',
          },
          {
            'id': 'n-2',
            'user_id': 'u-bob',
            'trip_id': 't-1',
            'notification_type': 'CONTRIBUTION_ADDED',
            'title': 'Contribution Recorded',
            'body': '₹200.00 contribution recorded',
            'entity_type': 'CONTRIBUTION',
            'entity_id': 'c-1',
            'is_read': true,
            'read_at': '2026-09-08T11:00:00Z',
            'created_at': '2026-09-08T09:00:00Z',
          }
        ],
        'total': 2,
        'unread_count': 1,
        'limit': 20,
        'offset': 0,
      };

      final result = NotificationListResult.fromJson(json);

      expect(result.total, 2);
      expect(result.unreadCount, 1);
      expect(result.items.length, 2);

      final n1 = result.items[0];
      expect(n1.id, 'n-1');
      expect(n1.userId, 'u-bob');
      expect(n1.notificationType, 'EXPENSE_ADDED');
      expect(n1.title, 'New Expense');
      expect(n1.isRead, false);
      expect(n1.readAt, isNull);

      final n2 = result.items[1];
      expect(n2.id, 'n-2');
      expect(n2.isRead, true);
      expect(n2.readAt, isNotNull);
    });

    test('handles default values in AppNotification gracefully', () {
      final notif = AppNotification.fromJson({
        'id': 'n-min',
        'user_id': 'u-1',
      });

      expect(notif.id, 'n-min');
      expect(notif.userId, 'u-1');
      expect(notif.notificationType, 'GENERAL');
      expect(notif.title, '');
      expect(notif.body, '');
      expect(notif.isRead, false);
      expect(notif.tripId, isNull);
      expect(notif.readAt, isNull);
    });
  });

  group('Trip Activity Models (Phase 2.5)', () {
    test('deserializes TripActivity and TripActivityListResult correctly', () {
      final json = {
        'items': [
          {
            'id': 'act-1',
            'trip_id': 't-1',
            'actor_user_id': 'u-alice',
            'actor_name': 'Alice Admin',
            'event_type': 'EXPENSE_CREATED',
            'entity_type': 'EXPENSE',
            'entity_id': 'e-1',
            'message': 'Alice Admin added expense Cabin ₹150.00',
            'metadata_json': {'amount_paise': 15000},
            'created_at': '2026-09-08T12:00:00Z',
          },
          {
            'id': 'act-2',
            'trip_id': 't-1',
            'actor_user_id': 'u-alice',
            'actor_name': null,
            'event_type': 'TRIP_CREATED',
            'entity_type': 'TRIP',
            'entity_id': 't-1',
            'message': 'Trip created',
            'metadata_json': null,
            'created_at': '2026-09-08T08:00:00Z',
          }
        ],
        'total': 2,
        'limit': 20,
        'offset': 0,
      };

      final result = TripActivityListResult.fromJson(json);

      expect(result.total, 2);
      expect(result.items.length, 2);

      final a1 = result.items[0];
      expect(a1.id, 'act-1');
      expect(a1.actorName, 'Alice Admin');
      expect(a1.eventType, 'EXPENSE_CREATED');
      expect(a1.entityType, 'EXPENSE');
      expect(a1.message, contains('Cabin'));
      expect(a1.metadata?['amount_paise'], 15000);

      final a2 = result.items[1];
      expect(a2.id, 'act-2');
      expect(a2.actorName, isNull);
      expect(a2.eventType, 'TRIP_CREATED');
    });
  });
}
