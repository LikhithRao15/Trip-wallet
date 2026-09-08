class AppNotification {
  final String id;
  final String userId;
  final String? tripId;
  final String notificationType;
  final String title;
  final String body;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.tripId,
    required this.notificationType,
    required this.title,
    required this.body,
    this.entityType,
    this.entityId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      tripId: json['trip_id'],
      notificationType: json['notification_type'] ?? 'GENERAL',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class NotificationListResult {
  final List<AppNotification> items;
  final int total;
  final int unreadCount;
  final int limit;
  final int offset;

  NotificationListResult({
    required this.items,
    required this.total,
    required this.unreadCount,
    required this.limit,
    required this.offset,
  });

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return NotificationListResult(
      items: list.map((i) => AppNotification.fromJson(i)).toList(),
      total: json['total'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
    );
  }
}
