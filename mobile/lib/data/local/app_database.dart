import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../models/activity.dart';
import '../../models/contribution.dart';
import '../../models/expense.dart';
import '../../models/notification.dart';
import '../../models/trip.dart';
import '../../models/trip_member.dart';
import '../../models/wallet_summary.dart';
import 'tables/local_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LocalTrips,
  LocalMembers,
  LocalWallets,
  LocalContributions,
  LocalExpenses,
  LocalExpenseSplits,
  LocalActivities,
  LocalNotifications,
  LocalSyncMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'trip_wallet'));

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase();

  @override
  int get schemaVersion => 1;

  // ==========================================
  // TRIPS
  // ==========================================
  Future<void> saveTrips(String userId, List<Trip> trips) async {
    await batch((b) {
      for (final t in trips) {
        b.insert(
          localTrips,
          LocalTripsCompanion(
            id: Value(t.id),
            name: Value(t.name),
            description: Value(t.description),
            destination: Value(t.destination),
            startDate: Value(t.startDate),
            endDate: Value(t.endDate),
            currency: Value(t.currency),
            adminId: Value(t.adminId),
            status: Value(t.status),
            settlementStatus: Value(t.settlementStatus),
            cachedForUserId: Value(userId),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> saveTrip(String userId, Trip trip) async {
    await saveTrips(userId, [trip]);
  }

  Future<List<Trip>> getTrips(String userId) async {
    final rows = await (select(localTrips)
          ..where((t) => t.cachedForUserId.equals(userId)))
        .get();

    return rows
        .map((r) => Trip(
              id: r.id,
              name: r.name,
              description: r.description,
              destination: r.destination,
              startDate: r.startDate,
              endDate: r.endDate,
              currency: r.currency,
              adminId: r.adminId,
              status: r.status,
              settlementStatus: r.settlementStatus,
            ))
        .toList();
  }

  Future<Trip?> getTrip(String userId, String tripId) async {
    final row = await (select(localTrips)
          ..where((t) => t.cachedForUserId.equals(userId) & t.id.equals(tripId)))
        .getSingleOrNull();

    if (row == null) return null;

    return Trip(
      id: row.id,
      name: row.name,
      description: row.description,
      destination: row.destination,
      startDate: row.startDate,
      endDate: row.endDate,
      currency: row.currency,
      adminId: row.adminId,
      status: row.status,
      settlementStatus: row.settlementStatus,
    );
  }

  // ==========================================
  // MEMBERS
  // ==========================================
  Future<void> saveMembers(String userId, String tripId, List<TripMember> members) async {
    await batch((b) {
      for (final m in members) {
        b.insert(
          localMembers,
          LocalMembersCompanion(
            id: Value(m.id),
            tripId: Value(tripId),
            userId: Value(m.userId),
            name: Value(m.name),
            email: Value(m.email),
            role: Value(m.role),
            status: Value(m.status),
            joinedAt: Value(m.joinedAt != null ? DateTime.tryParse(m.joinedAt!) : null),
            cachedForUserId: Value(userId),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<TripMember>> getMembers(String userId, String tripId) async {
    final rows = await (select(localMembers)
          ..where((m) => m.cachedForUserId.equals(userId) & m.tripId.equals(tripId)))
        .get();

    return rows
        .map((r) => TripMember(
              id: r.id,
              userId: r.userId,
              name: r.name,
              email: r.email,
              role: r.role,
              status: r.status,
              joinedAt: r.joinedAt?.toIso8601String(),
            ))
        .toList();
  }

  // ==========================================
  // WALLET
  // ==========================================
  Future<void> saveWallet(String userId, String tripId, WalletSummary wallet) async {
    await into(localWallets).insert(
      LocalWalletsCompanion(
        tripId: Value(tripId),
        currency: Value(wallet.currency),
        balancePaise: Value(wallet.balancePaise),
        totalContributionsPaise: Value(wallet.totalContributionsPaise),
        totalExpensesPaise: Value(wallet.totalExpensesPaise),
        transactionCount: Value(wallet.transactionCount),
        cachedForUserId: Value(userId),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<WalletSummary?> getWallet(String userId, String tripId) async {
    final row = await (select(localWallets)
          ..where((w) => w.cachedForUserId.equals(userId) & w.tripId.equals(tripId)))
        .getSingleOrNull();

    if (row == null) return null;

    return WalletSummary(
      currency: row.currency,
      balancePaise: row.balancePaise,
      totalContributionsPaise: row.totalContributionsPaise,
      totalExpensesPaise: row.totalExpensesPaise,
      transactionCount: row.transactionCount,
    );
  }

  // ==========================================
  // CONTRIBUTIONS
  // ==========================================
  Future<void> saveContributions(
      String userId, String tripId, List<Contribution> contributions) async {
    await batch((b) {
      for (final c in contributions) {
        b.insert(
          localContributions,
          LocalContributionsCompanion(
            id: Value(c.id),
            tripId: Value(tripId),
            memberId: Value(c.memberId),
            amountPaise: Value(c.amountPaise),
            paymentMethod: Value(c.paymentMethod),
            status: Value(c.status),
            note: Value(c.note),
            createdAt: Value(DateTime.parse(c.createdAt)),
            cachedForUserId: Value(userId),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<Contribution>> getContributions(String userId, String tripId) async {
    final rows = await (select(localContributions)
          ..where((c) => c.cachedForUserId.equals(userId) & c.tripId.equals(tripId))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();

    return rows
        .map((r) => Contribution(
              id: r.id,
              tripId: r.tripId,
              memberId: r.memberId,
              amountPaise: r.amountPaise,
              paymentMethod: r.paymentMethod,
              status: r.status,
              createdAt: r.createdAt.toIso8601String(),
              note: r.note,
            ))
        .toList();
  }

  // ==========================================
  // EXPENSES
  // ==========================================
  Future<void> saveExpenses(String userId, String tripId, List<Expense> expenses) async {
    await batch((b) {
      for (final e in expenses) {
        b.insert(
          localExpenses,
          LocalExpensesCompanion(
            id: Value(e.id),
            tripId: Value(tripId),
            walletId: Value(e.walletId),
            paidBy: Value(e.paidBy),
            amountPaise: Value(e.amountPaise),
            category: Value(e.category),
            description: Value(e.description),
            splitMode: Value(e.splitMode),
            status: Value(e.status),
            createdAt: Value(DateTime.parse(e.createdAt)),
            cachedForUserId: Value(userId),
          ),
          mode: InsertMode.insertOrReplace,
        );

        for (final s in e.splits) {
          b.insert(
            localExpenseSplits,
            LocalExpenseSplitsCompanion(
              id: Value('${e.id}_${s.memberId}'),
              expenseId: Value(e.id),
              memberId: Value(s.memberId),
              amountPaise: Value(s.amountPaise),
              cachedForUserId: Value(userId),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  Future<List<Expense>> getExpenses(String userId, String tripId) async {
    final rows = await (select(localExpenses)
          ..where((e) => e.cachedForUserId.equals(userId) & e.tripId.equals(tripId))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .get();

    final result = <Expense>[];
    for (final r in rows) {
      final splitRows = await (select(localExpenseSplits)
            ..where((s) => s.expenseId.equals(r.id)))
          .get();

      final splits = splitRows
          .map((s) => ExpenseSplit(
                memberId: s.memberId,
                amountPaise: s.amountPaise,
              ))
          .toList();

      result.add(Expense(
        id: r.id,
        tripId: r.tripId,
        walletId: r.walletId,
        paidBy: r.paidBy,
        amountPaise: r.amountPaise,
        category: r.category,
        description: r.description,
        splitMode: r.splitMode,
        status: r.status,
        createdAt: r.createdAt.toIso8601String(),
        splits: splits,
      ));
    }
    return result;
  }

  // ==========================================
  // ACTIVITIES
  // ==========================================
  Future<void> saveActivities(
      String userId, String tripId, List<TripActivity> activities) async {
    await batch((b) {
      for (final a in activities) {
        b.insert(
          localActivities,
          LocalActivitiesCompanion(
            id: Value(a.id),
            tripId: Value(tripId),
            actorUserId: Value(a.actorUserId),
            actorName: Value(a.actorName),
            eventType: Value(a.eventType),
            entityType: Value(a.entityType),
            entityId: Value(a.entityId),
            message: Value(a.message),
            metadataJson: Value(a.metadata?.toString()),
            createdAt: Value(a.createdAt),
            cachedForUserId: Value(userId),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<TripActivity>> getActivities(String userId, String tripId) async {
    final rows = await (select(localActivities)
          ..where((a) => a.cachedForUserId.equals(userId) & a.tripId.equals(tripId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();

    return rows
        .map((r) => TripActivity(
              id: r.id,
              tripId: r.tripId,
              actorUserId: r.actorUserId,
              actorName: r.actorName,
              eventType: r.eventType,
              entityType: r.entityType,
              entityId: r.entityId,
              message: r.message,
              metadata: null,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================
  Future<void> saveNotifications(
      String userId, List<AppNotification> notifications) async {
    await batch((b) {
      for (final n in notifications) {
        b.insert(
          localNotifications,
          LocalNotificationsCompanion(
            id: Value(n.id),
            userId: Value(n.userId),
            tripId: Value(n.tripId),
            notificationType: Value(n.notificationType),
            title: Value(n.title),
            body: Value(n.body),
            entityType: Value(n.entityType),
            entityId: Value(n.entityId),
            isRead: Value(n.isRead),
            readAt: Value(n.readAt),
            createdAt: Value(n.createdAt),
            cachedForUserId: Value(userId),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<AppNotification>> getNotifications(String userId) async {
    final rows = await (select(localNotifications)
          ..where((n) => n.cachedForUserId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .get();

    return rows
        .map((r) => AppNotification(
              id: r.id,
              userId: r.userId,
              tripId: r.tripId,
              notificationType: r.notificationType,
              title: r.title,
              body: r.body,
              entityType: r.entityType,
              entityId: r.entityId,
              isRead: r.isRead,
              readAt: r.readAt,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  Future<void> markNotificationRead(String userId, String notificationId) async {
    await (update(localNotifications)
          ..where((n) => n.cachedForUserId.equals(userId) & n.id.equals(notificationId)))
        .write(LocalNotificationsCompanion(
      isRead: const Value(true),
      readAt: Value(DateTime.now()),
    ));
  }

  Future<void> markAllNotificationsRead(String userId) async {
    await (update(localNotifications)
          ..where((n) => n.cachedForUserId.equals(userId)))
        .write(LocalNotificationsCompanion(
      isRead: const Value(true),
      readAt: Value(DateTime.now()),
    ));
  }

  // ==========================================
  // SYNC METADATA (CURSORS)
  // ==========================================
  Future<void> saveSyncMeta(
      String userId, String syncKey, String? cursor, DateTime lastSyncedAt) async {
    await into(localSyncMeta).insert(
      LocalSyncMetaCompanion(
        syncKey: Value(syncKey),
        cursor: Value(cursor),
        lastSyncedAt: Value(lastSyncedAt),
        cachedForUserId: Value(userId),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<LocalSyncMetaData?> getSyncMeta(String userId, String syncKey) async {
    return await (select(localSyncMeta)
          ..where((s) => s.cachedForUserId.equals(userId) & s.syncKey.equals(syncKey)))
        .getSingleOrNull();
  }

  // ==========================================
  // LOGOUT PURGE & CACHE ISOLATION
  // ==========================================
  Future<void> clearUserCache(String userId) async {
    await (delete(localTrips)..where((t) => t.cachedForUserId.equals(userId))).go();
    await (delete(localMembers)..where((m) => m.cachedForUserId.equals(userId))).go();
    await (delete(localWallets)..where((w) => w.cachedForUserId.equals(userId))).go();
    await (delete(localContributions)..where((c) => c.cachedForUserId.equals(userId))).go();
    await (delete(localExpenses)..where((e) => e.cachedForUserId.equals(userId))).go();
    await (delete(localExpenseSplits)..where((s) => s.cachedForUserId.equals(userId))).go();
    await (delete(localActivities)..where((a) => a.cachedForUserId.equals(userId))).go();
    await (delete(localNotifications)..where((n) => n.cachedForUserId.equals(userId))).go();
    await (delete(localSyncMeta)..where((s) => s.cachedForUserId.equals(userId))).go();
  }

  Future<void> clearAllCache() async {
    await delete(localTrips).go();
    await delete(localMembers).go();
    await delete(localWallets).go();
    await delete(localContributions).go();
    await delete(localExpenses).go();
    await delete(localExpenseSplits).go();
    await delete(localActivities).go();
    await delete(localNotifications).go();
    await delete(localSyncMeta).go();
  }
}
