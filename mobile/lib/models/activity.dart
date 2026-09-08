class TripActivity {
  final String id;
  final String tripId;
  final String actorUserId;
  final String? actorName;
  final String eventType;
  final String? entityType;
  final String? entityId;
  final String message;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  TripActivity({
    required this.id,
    required this.tripId,
    required this.actorUserId,
    this.actorName,
    required this.eventType,
    this.entityType,
    this.entityId,
    required this.message,
    this.metadata,
    required this.createdAt,
  });

  factory TripActivity.fromJson(Map<String, dynamic> json) {
    return TripActivity(
      id: json['id'],
      tripId: json['trip_id'],
      actorUserId: json['actor_user_id'],
      actorName: json['actor_name'],
      eventType: json['event_type'] ?? 'GENERAL',
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      message: json['message'] ?? '',
      metadata: json['metadata_json'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class TripActivityListResult {
  final List<TripActivity> items;
  final int total;
  final int limit;
  final int offset;

  TripActivityListResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TripActivityListResult.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return TripActivityListResult(
      items: list.map((i) => TripActivity.fromJson(i)).toList(),
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
    );
  }
}
