import 'package:flutter/material.dart';
import '../../core/network/network_info.dart';
import '../../data/repositories/trip_repository.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final TripRepository _repository = TripRepository.instance;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _unreadOnly = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _notificationService.getNotifications(
        limit: 50,
        unreadOnly: _unreadOnly ? true : null,
      );
      if (mounted) {
        setState(() {
          _notifications = res.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      final cached = await _repository.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = _unreadOnly
              ? cached.where((n) => !n.isRead).toList()
              : cached;
          _isLoading = false;
          if (_notifications.isEmpty) {
            _errorMessage = 'Offline • Connect to internet to load notifications';
          }
        });
      }
    }
  }

  Future<void> _markAsRead(AppNotification notif) async {
    if (notif.isRead) return;

    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internet connection required to update notification state.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await _notificationService.markAsRead(notif.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notif.id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: notif.id,
            userId: notif.userId,
            tripId: notif.tripId,
            notificationType: notif.notificationType,
            title: notif.title,
            body: notif.body,
            entityType: notif.entityType,
            entityId: notif.entityId,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: notif.createdAt,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark read: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internet connection required to update notification state.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final count = await _notificationService.markAllAsRead();
      setState(() {
        _notifications = _notifications
            .map((n) => AppNotification(
                  id: n.id,
                  userId: n.userId,
                  tripId: n.tripId,
                  notificationType: n.notificationType,
                  title: n.title,
                  body: n.body,
                  entityType: n.entityType,
                  entityId: n.entityId,
                  isRead: true,
                  readAt: DateTime.now(),
                  createdAt: n.createdAt,
                ))
            .toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked $count notification(s) as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $e')),
        );
      }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'MEMBER_ADDED':
        return Icons.person_add_rounded;
      case 'MEMBER_REMOVED':
        return Icons.person_remove_rounded;
      case 'CONTRIBUTION_ADDED':
      case 'CONTRIBUTION_UPDATED':
        return Icons.account_balance_wallet_rounded;
      case 'EXPENSE_ADDED':
      case 'EXPENSE_UPDATED':
        return Icons.receipt_long_rounded;
      case 'EXPENSE_CANCELLED':
        return Icons.cancel_outlined;
      case 'SETTLEMENT_COMPLETED':
        return Icons.check_circle_outline_rounded;
      case 'TRIP_CLOSED':
        return Icons.lock_outline_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'MEMBER_ADDED':
        return Colors.blue;
      case 'MEMBER_REMOVED':
        return Colors.orange;
      case 'CONTRIBUTION_ADDED':
      case 'CONTRIBUTION_UPDATED':
        return Colors.green;
      case 'EXPENSE_ADDED':
      case 'EXPENSE_UPDATED':
        return Colors.indigo;
      case 'EXPENSE_CANCELLED':
        return Colors.red;
      case 'SETTLEMENT_COMPLETED':
        return Colors.teal;
      case 'TRIP_CLOSED':
        return Colors.deepPurple;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: _notifications.any((n) => !n.isRead) ? _markAllAsRead : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: !_unreadOnly,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _unreadOnly = false);
                      _loadNotifications();
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Unread'),
                  selected: _unreadOnly,
                  onSelected: (selected) {
                    setState(() => _unreadOnly = selected);
                    _loadNotifications();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadNotifications,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _unreadOnly
                                        ? 'No unread notifications'
                                        : 'No notifications yet',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _notifications.length,
                              separatorBuilder: (ctx, i) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final notif = _notifications[index];
                                final iconColor = _getColorForType(notif.notificationType);
                                final iconData = _getIconForType(notif.notificationType);

                                return Material(
                                  color: notif.isRead
                                      ? Theme.of(context).scaffoldBackgroundColor
                                      : Theme.of(context).primaryColor.withValues(alpha: 0.06),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: iconColor.withValues(alpha: 0.15),
                                      child: Icon(iconData, color: iconColor, size: 22),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontWeight: notif.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatRelativeTime(notif.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        notif.body,
                                        style: TextStyle(
                                          color: notif.isRead
                                              ? Colors.grey.shade700
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    trailing: notif.isRead
                                        ? null
                                        : Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                    onTap: () => _markAsRead(notif),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
