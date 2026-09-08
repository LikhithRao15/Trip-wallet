import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/token_storage.dart';
import '../../models/activity.dart';
import '../../models/contribution.dart';
import '../../models/expense.dart';
import '../../models/notification.dart';
import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../models/wallet_summary.dart';
import '../../services/auth_service.dart';
import '../local/app_database.dart';

enum SyncStatus { idle, syncing, synced, offline, failed }

class SyncManager {
  static SyncManager? _instance;
  static SyncManager get instance => _instance ??= SyncManager();

  final ApiClient _apiClient = ApiClient();
  final NetworkInfo _networkInfo = NetworkInfo.instance;
  final TokenStorage _tokenStorage = TokenStorage.instance;
  final AuthService _authService = AuthService();
  final AppDatabase _db = AppDatabase.instance;

  final ValueNotifier<SyncStatus> statusNotifier =
      ValueNotifier<SyncStatus>(SyncStatus.idle);
  final ValueNotifier<DateTime?> lastSyncedNotifier =
      ValueNotifier<DateTime?>(null);

  bool _isSyncing = false;

  SyncManager() {
    _networkInfo.onConnectivityChanged.listen((connected) {
      if (!connected) {
        statusNotifier.value = SyncStatus.offline;
      } else if (statusNotifier.value == SyncStatus.offline) {
        syncAll();
      }
    });
  }

  Future<String?> _getUserId() async {
    final user = await _authService.getCurrentUser();
    return user?['id']?.toString();
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    statusNotifier.value = SyncStatus.syncing;

    try {
      final isOnline = await _networkInfo.isConnected;
      if (!isOnline) {
        statusNotifier.value = SyncStatus.offline;
        _isSyncing = false;
        return;
      }

      await syncUser();

      statusNotifier.value = SyncStatus.synced;
      lastSyncedNotifier.value = DateTime.now();
    } catch (e) {
      statusNotifier.value = SyncStatus.failed;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncUser() async {
    final token = await _tokenStorage.getToken();
    final userId = await _getUserId();
    if (token == null || userId == null) return;

    final meta = await _db.getSyncMeta(userId, 'user_sync');
    final cursor = meta?.cursor;

    final uri = Uri.parse(ApiConstants.sync).replace(
      queryParameters: cursor != null && cursor.isNotEmpty
          ? {'cursor': cursor}
          : null,
    );

    final res = await _apiClient.get(uri.toString(), token: token);
    final data = Map<String, dynamic>.from(res);

    final rawTrips = data['trips'] as List? ?? [];
    final trips = rawTrips.map((t) => Trip.fromJson(t)).toList();
    if (trips.isNotEmpty) {
      await _db.saveTrips(userId, trips);
    }

    final rawNotifs = data['notifications'] as List? ?? [];
    final notifications =
        rawNotifs.map((n) => AppNotification.fromJson(n)).toList();
    if (notifications.isNotEmpty) {
      await _db.saveNotifications(userId, notifications);
    }

    final nextCursor = data['next_cursor'] as String?;
    final now = DateTime.now();
    await _db.saveSyncMeta(userId, 'user_sync', nextCursor, now);
    lastSyncedNotifier.value = now;
  }

  Future<bool> syncTrip(String tripId) async {
    final token = await _tokenStorage.getToken();
    final userId = await _getUserId();
    if (token == null || userId == null) return false;

    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      statusNotifier.value = SyncStatus.offline;
      return false;
    }

    final meta = await _db.getSyncMeta(userId, 'trip_$tripId');
    final cursor = meta?.cursor;

    final uri = Uri.parse('${ApiConstants.trips}/$tripId/sync').replace(
      queryParameters: cursor != null && cursor.isNotEmpty
          ? {'cursor': cursor}
          : null,
    );

    try {
      final res = await _apiClient.get(uri.toString(), token: token);
      final data = Map<String, dynamic>.from(res);

      final isUpToDate = data['up_to_date'] == true;
      final nextCursor = data['next_cursor'] as String?;
      final now = DateTime.now();

      if (!isUpToDate) {
        if (data['trip'] != null) {
          final trip = Trip.fromJson(data['trip']);
          await _db.saveTrip(userId, trip);
        }

        if (data['members'] != null) {
          final members = (data['members'] as List)
              .map((m) => TripMember.fromJson(m))
              .toList();
          await _db.saveMembers(userId, tripId, members);
        }

        if (data['wallet'] != null) {
          final wallet = WalletSummary.fromJson(data['wallet']);
          await _db.saveWallet(userId, tripId, wallet);
        }

        if (data['contributions'] != null) {
          final contribs = (data['contributions'] as List)
              .map((c) => Contribution.fromJson(c))
              .toList();
          await _db.saveContributions(userId, tripId, contribs);
        }

        if (data['expenses'] != null) {
          final expenses = (data['expenses'] as List)
              .map((e) => Expense.fromJson(e))
              .toList();
          await _db.saveExpenses(userId, tripId, expenses);
        }

        if (data['recent_activities'] != null) {
          final activities = (data['recent_activities'] as List)
              .map((a) => TripActivity.fromJson(a))
              .toList();
          await _db.saveActivities(userId, tripId, activities);
        }
      }

      await _db.saveSyncMeta(userId, 'trip_$tripId', nextCursor, now);
      lastSyncedNotifier.value = now;
      return true;
    } catch (_) {
      return false;
    }
  }
}
