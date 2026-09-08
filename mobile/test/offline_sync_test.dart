import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:mobile/data/local/app_database.dart';
import 'package:mobile/data/sync/sync_manager.dart';
import 'package:mobile/models/contribution.dart';
import 'package:mobile/models/expense.dart';
import 'package:mobile/models/trip.dart';
import 'package:mobile/models/trip_member.dart';
import 'package:mobile/models/wallet_summary.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Create an in-memory database for testing
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Local Cache & Database Operations', () {
    test('Can save and retrieve local trips filtered by user_id', () async {
      const userA = 'user-uuid-111';
      const userB = 'user-uuid-222';

      final tripA = Trip(
        id: 'trip-1',
        name: 'Goa Trip',
        currency: 'INR',
        status: 'ACTIVE',
        adminId: userA,
      );

      final tripB = Trip(
        id: 'trip-2',
        name: 'Manali Trip',
        currency: 'INR',
        status: 'ACTIVE',
        adminId: userB,
      );

      await db.saveTrip(userA, tripA);
      await db.saveTrip(userB, tripB);

      final userATrips = await db.getTrips(userA);
      expect(userATrips.length, 1);
      expect(userATrips.first.name, 'Goa Trip');

      final userBTrips = await db.getTrips(userB);
      expect(userBTrips.length, 1);
      expect(userBTrips.first.name, 'Manali Trip');
    });

    test('Can save and retrieve wallet, members, contributions, and expenses', () async {
      const userId = 'user-uuid-111';
      const tripId = 'trip-1';

      // Save trip
      await db.saveTrip(
        userId,
        Trip(
          id: tripId,
          name: 'Goa Trip',
          currency: 'INR',
          status: 'ACTIVE',
          adminId: userId,
        ),
      );

      // Save wallet
      await db.saveWallet(
        userId,
        tripId,
        WalletSummary(
          currency: 'INR',
          balancePaise: 50000,
          totalContributionsPaise: 100000,
          totalExpensesPaise: 50000,
          transactionCount: 2,
        ),
      );

      final wallet = await db.getWallet(userId, tripId);
      expect(wallet, isNotNull);
      expect(wallet!.balancePaise, 50000);
      expect(wallet.totalExpensesPaise, 50000);

      // Save member
      await db.saveMembers(
        userId,
        tripId,
        [
          TripMember(
            id: 'member-1',
            userId: userId,
            name: 'Alice',
            email: 'alice@test.com',
            role: 'ADMIN',
            status: 'ACTIVE',
          ),
        ],
      );

      final members = await db.getMembers(userId, tripId);
      expect(members.length, 1);
      expect(members.first.name, 'Alice');

      // Save contribution
      await db.saveContributions(
        userId,
        tripId,
        [
          Contribution(
            id: 'contrib-1',
            tripId: tripId,
            memberId: 'member-1',
            amountPaise: 100000,
            paymentMethod: 'UPI',
            status: 'CONFIRMED',
            createdAt: '2026-09-08T10:00:00.000Z',
          ),
        ],
      );

      final contributions = await db.getContributions(userId, tripId);
      expect(contributions.length, 1);
      expect(contributions.first.amountPaise, 100000);

      // Save expense with split
      await db.saveExpenses(
        userId,
        tripId,
        [
          Expense(
            id: 'exp-1',
            tripId: tripId,
            walletId: 'wallet-1',
            paidBy: userId,
            amountPaise: 50000,
            category: 'FOOD',
            splitMode: 'EQUAL',
            status: 'SETTLED',
            createdAt: '2026-09-08T10:00:00.000Z',
            splits: [
              ExpenseSplit(
                memberId: userId,
                amountPaise: 50000,
              ),
            ],
          ),
        ],
      );

      final expenses = await db.getExpenses(userId, tripId);
      expect(expenses.length, 1);
      expect(expenses.first.amountPaise, 50000);
      expect(expenses.first.splits.length, 1);
      expect(expenses.first.splits.first.amountPaise, 50000);
    });

    test('clearUserCache purges all data for that specific user only', () async {
      const userA = 'user-uuid-111';
      const userB = 'user-uuid-222';

      await db.saveTrip(
        userA,
        Trip(
          id: 'trip-1',
          name: 'Trip A',
          currency: 'INR',
          status: 'ACTIVE',
          adminId: userA,
        ),
      );

      await db.saveTrip(
        userB,
        Trip(
          id: 'trip-2',
          name: 'Trip B',
          currency: 'INR',
          status: 'ACTIVE',
          adminId: userB,
        ),
      );

      await db.saveSyncMeta(userA, 'user_sync', 'cursor-111', DateTime.now());
      await db.saveSyncMeta(userB, 'user_sync', 'cursor-222', DateTime.now());

      // Purge User A
      await db.clearUserCache(userA);

      final userATrips = await db.getTrips(userA);
      expect(userATrips, isEmpty);
      final metaA = await db.getSyncMeta(userA, 'user_sync');
      expect(metaA, isNull);

      // User B data must remain completely intact
      final userBTrips = await db.getTrips(userB);
      expect(userBTrips.length, 1);
      expect(userBTrips.first.name, 'Trip B');
      final metaB = await db.getSyncMeta(userB, 'user_sync');
      expect(metaB, isNotNull);
      expect(metaB!.cursor, 'cursor-222');
    });

    test('SyncStatus enum states verify correctly', () {
      expect(SyncStatus.idle, isNotNull);
      expect(SyncStatus.synced, isNotNull);
      expect(SyncStatus.syncing, isNotNull);
      expect(SyncStatus.offline, isNotNull);
      expect(SyncStatus.failed, isNotNull);
    });
  });
}
