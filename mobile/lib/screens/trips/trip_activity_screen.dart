import 'package:flutter/material.dart';
import '../../data/repositories/trip_repository.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';

class TripActivityScreen extends StatefulWidget {
  final String tripId;
  final String tripName;

  const TripActivityScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<TripActivityScreen> createState() => _TripActivityScreenState();
}

class _TripActivityScreenState extends State<TripActivityScreen> {
  final ActivityService _activityService = ActivityService();
  List<TripActivity> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'ALL',
    'EXPENSES',
    'CONTRIBUTIONS',
    'MEMBERS',
    'LIFECYCLE',
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _activityService.getTripActivity(
        widget.tripId,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _activities = res.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      final cached = await TripRepository.instance.getActivities(widget.tripId);
      if (mounted) {
        setState(() {
          _activities = cached;
          _isLoading = false;
          if (_activities.isEmpty) {
            _errorMessage = 'Offline • Connect to internet to view activities';
          }
        });
      }
    }
  }

  List<TripActivity> get _filteredActivities {
    if (_selectedCategory == 'ALL') return _activities;
    return _activities.where((a) {
      switch (_selectedCategory) {
        case 'EXPENSES':
          return a.eventType.startsWith('EXPENSE_');
        case 'CONTRIBUTIONS':
          return a.eventType.startsWith('CONTRIBUTION_');
        case 'MEMBERS':
          return a.eventType.startsWith('MEMBER_');
        case 'LIFECYCLE':
          return a.eventType.startsWith('TRIP_') || a.eventType.startsWith('SETTLEMENT_');
        default:
          return true;
      }
    }).toList();
  }

  IconData _getIconForEvent(String type) {
    switch (type) {
      case 'TRIP_CREATED':
        return Icons.flag_circle_rounded;
      case 'TRIP_CLOSED':
        return Icons.lock_outline_rounded;
      case 'MEMBER_ADDED':
      case 'MEMBER_REACTIVATED':
        return Icons.person_add_rounded;
      case 'MEMBER_REMOVED':
        return Icons.person_remove_rounded;
      case 'CONTRIBUTION_ADDED':
        return Icons.account_balance_wallet_rounded;
      case 'CONTRIBUTION_UPDATED':
        return Icons.edit_note_rounded;
      case 'EXPENSE_CREATED':
        return Icons.receipt_long_rounded;
      case 'EXPENSE_UPDATED':
        return Icons.edit_rounded;
      case 'EXPENSE_CANCELLED':
        return Icons.cancel_outlined;
      case 'SETTLEMENT_COMPLETED':
        return Icons.task_alt_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _getColorForEvent(String type) {
    switch (type) {
      case 'TRIP_CREATED':
        return Colors.indigo;
      case 'TRIP_CLOSED':
        return Colors.blueGrey;
      case 'MEMBER_ADDED':
      case 'MEMBER_REACTIVATED':
        return Colors.blue;
      case 'MEMBER_REMOVED':
        return Colors.orange;
      case 'CONTRIBUTION_ADDED':
        return Colors.green;
      case 'CONTRIBUTION_UPDATED':
        return Colors.teal;
      case 'EXPENSE_CREATED':
        return Colors.purple;
      case 'EXPENSE_UPDATED':
        return Colors.deepPurple;
      case 'EXPENSE_CANCELLED':
        return Colors.red;
      case 'SETTLEMENT_COMPLETED':
        return Colors.teal;
      default:
        return Colors.grey;
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
    final filtered = _filteredActivities;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tripName} Activity'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      cat[0] + cat.substring(1).toLowerCase(),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadActivities,
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
                                onPressed: _loadActivities,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history_toggle_off_rounded,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No activity recorded',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              itemBuilder: (context, index) {
                                final activity = filtered[index];
                                final iconColor = _getColorForEvent(activity.eventType);
                                final iconData = _getIconForEvent(activity.eventType);
                                final isLast = index == filtered.length - 1;

                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Timeline column
                                      Column(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: iconColor.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: iconColor.withValues(alpha: 0.4),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Icon(
                                              iconData,
                                              color: iconColor,
                                              size: 20,
                                            ),
                                          ),
                                          if (!isLast)
                                            Expanded(
                                              child: Container(
                                                width: 2,
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      // Content card
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 20.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.04),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    if (activity.actorName != null &&
                                                        activity.actorName!.isNotEmpty)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey.shade100,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          activity.actorName!,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.grey.shade800,
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      const SizedBox.shrink(),
                                                    Text(
                                                      _formatRelativeTime(activity.createdAt),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  activity.message,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
