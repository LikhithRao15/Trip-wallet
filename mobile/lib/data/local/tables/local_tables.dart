import 'package:drift/drift.dart';

class LocalTrips extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get destination => text().nullable()();
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get adminId => text()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  TextColumn get settlementStatus => text().withDefault(const Constant('OPEN'))();
  TextColumn get cachedForUserId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalMembers extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get role => text()();
  TextColumn get status => text()();
  DateTimeColumn get joinedAt => dateTime().nullable()();
  TextColumn get cachedForUserId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalWallets extends Table {
  TextColumn get tripId => text()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  IntColumn get balancePaise => integer().withDefault(const Constant(0))();
  IntColumn get totalContributionsPaise => integer().withDefault(const Constant(0))();
  IntColumn get totalExpensesPaise => integer().withDefault(const Constant(0))();
  IntColumn get transactionCount => integer().withDefault(const Constant(0))();
  TextColumn get cachedForUserId => text()();

  @override
  Set<Column> get primaryKey => {tripId};
}

class LocalContributions extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get memberId => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get paymentMethod => text().withDefault(const Constant('CASH'))();
  TextColumn get status => text().withDefault(const Constant('CONFIRMED'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get cachedForUserId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get walletId => text()();
  TextColumn get paidBy => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get category => text()();
  TextColumn get description => text().nullable()();
  TextColumn get splitMode => text().withDefault(const Constant('EQUAL'))();
  TextColumn get status => text().withDefault(const Constant('CONFIRMED'))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get cachedForUserId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalExpenseSplits extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text()();
  TextColumn get memberId => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get cachedForUserId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalActivities extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get actorUserId => text()();
  TextColumn get actorName => text().nullable()();
  TextColumn get eventType => text()();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityId => text().nullable()();
  TextColumn get message => text()();
  TextColumn get metadataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get cachedForUserId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get tripId => text().nullable()();
  TextColumn get notificationType => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityId => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get cachedForUserId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalSyncMeta extends Table {
  TextColumn get syncKey => text()();
  TextColumn get cursor => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime()();
  TextColumn get cachedForUserId => text()();

  @override
  Set<Column> get primaryKey => {syncKey, cachedForUserId};
}
