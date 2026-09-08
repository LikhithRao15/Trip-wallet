import '../../models/activity.dart';
import '../../models/contribution.dart';
import '../../models/expense.dart';
import '../../models/notification.dart';
import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../models/wallet_summary.dart';
import '../../services/auth_service.dart';
import '../local/app_database.dart';
import '../sync/sync_manager.dart';

class TripRepository {
  static TripRepository? _instance;
  static TripRepository get instance => _instance ??= TripRepository();

  final AppDatabase _db = AppDatabase.instance;
  final SyncManager _syncManager = SyncManager.instance;
  final AuthService _authService = AuthService();

  Future<String?> _getUserId() async {
    final user = await _authService.getCurrentUser();
    return user?['id']?.toString();
  }

  Future<List<Trip>> getTrips({bool forceRefresh = false}) async {
    final userId = await _getUserId();
    if (userId == null) return [];

    final cached = await _db.getTrips(userId);

    // If online, perform sync in background or immediately
    try {
      await _syncManager.syncUser();
      return await _db.getTrips(userId);
    } catch (_) {
      // If offline or network error, return cached data
      return cached;
    }
  }

  Future<Trip?> getTrip(String tripId) async {
    final userId = await _getUserId();
    if (userId == null) return null;

    final cached = await _db.getTrip(userId, tripId);
    try {
      await _syncManager.syncTrip(tripId);
      return await _db.getTrip(userId, tripId);
    } catch (_) {
      return cached;
    }
  }

  Future<WalletSummary?> getWallet(String tripId) async {
    final userId = await _getUserId();
    if (userId == null) return null;

    final cached = await _db.getWallet(userId, tripId);
    try {
      await _syncManager.syncTrip(tripId);
      return await _db.getWallet(userId, tripId);
    } catch (_) {
      return cached;
    }
  }

  Future<List<TripMember>> getMembers(String tripId) async {
    final userId = await _getUserId();
    if (userId == null) return [];

    final cached = await _db.getMembers(userId, tripId);
    try {
      await _syncManager.syncTrip(tripId);
      return await _db.getMembers(userId, tripId);
    } catch (_) {
      return cached;
    }
  }

  Future<List<Contribution>> getContributions(String tripId) async {
    final userId = await _getUserId();
    if (userId == null) return [];

    final cached = await _db.getContributions(userId, tripId);
    try {
      await _syncManager.syncTrip(tripId);
      return await _db.getContributions(userId, tripId);
    } catch (_) {
      return cached;
    }
  }

  Future<List<Expense>> getExpenses(String tripId) async {
    final userId = await _getUserId();
    if (userId == null) return [];

    final cached = await _db.getExpenses(userId, tripId);
    try {
      await _syncManager.syncTrip(tripId);
      return await _db.getExpenses(userId, tripId);
    } catch (_) {
      return cached;
    }
  }

  Future<List<TripActivity>> getActivities(String tripId) async {
    final userId = await _getUserId();
    if (userId == null) return [];

    final cached = await _db.getActivities(userId, tripId);
    try {
      await _syncManager.syncTrip(tripId);
      return await _db.getActivities(userId, tripId);
    } catch (_) {
      return cached;
    }
  }

  Future<List<AppNotification>> getNotifications() async {
    final userId = await _getUserId();
    if (userId == null) return [];

    final cached = await _db.getNotifications(userId);
    try {
      await _syncManager.syncUser();
      return await _db.getNotifications(userId);
    } catch (_) {
      return cached;
    }
  }

  Future<DateTime?> getLastSyncedAt(String syncKey) async {
    final userId = await _getUserId();
    if (userId == null) return null;
    final meta = await _db.getSyncMeta(userId, syncKey);
    return meta?.lastSyncedAt;
  }
}
