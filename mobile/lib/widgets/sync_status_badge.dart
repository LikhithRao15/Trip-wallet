import 'package:flutter/material.dart';
import '../data/sync/sync_manager.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not synced';
    final diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 30) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncManager = SyncManager.instance;

    return ValueListenableBuilder<SyncStatus>(
      valueListenable: syncManager.statusNotifier,
      builder: (context, status, _) {
        return ValueListenableBuilder<DateTime?>(
          valueListenable: syncManager.lastSyncedNotifier,
          builder: (context, lastSynced, _) {
            Color bgColor;
            Color textColor;
            IconData icon;
            String text;

            switch (status) {
              case SyncStatus.syncing:
                bgColor = Colors.amber.shade100;
                textColor = Colors.amber.shade900;
                icon = Icons.sync_rounded;
                text = 'Syncing...';
                break;
              case SyncStatus.offline:
                bgColor = Colors.grey.shade200;
                textColor = Colors.grey.shade800;
                icon = Icons.wifi_off_rounded;
                text = 'Offline • Synced ${_formatRelativeTime(lastSynced)}';
                break;
              case SyncStatus.failed:
                bgColor = Colors.red.shade100;
                textColor = Colors.red.shade900;
                icon = Icons.sync_problem_rounded;
                text = 'Sync failed';
                break;
              case SyncStatus.synced:
              case SyncStatus.idle:
                bgColor = Colors.green.shade50;
                textColor = Colors.green.shade800;
                icon = Icons.cloud_done_outlined;
                text = 'Synced ${_formatRelativeTime(lastSynced)}';
                break;
            }

            return InkWell(
              onTap: () => syncManager.syncAll(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: textColor),
                    const SizedBox(width: 5),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
