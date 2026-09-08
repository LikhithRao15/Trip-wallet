// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalTripsTable extends LocalTrips
    with TableInfo<$LocalTripsTable, LocalTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _adminIdMeta = const VerificationMeta(
    'adminId',
  );
  @override
  late final GeneratedColumn<String> adminId = GeneratedColumn<String>(
    'admin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _settlementStatusMeta = const VerificationMeta(
    'settlementStatus',
  );
  @override
  late final GeneratedColumn<String> settlementStatus = GeneratedColumn<String>(
    'settlement_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('OPEN'),
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    destination,
    startDate,
    endDate,
    currency,
    adminId,
    status,
    settlementStatus,
    cachedForUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('admin_id')) {
      context.handle(
        _adminIdMeta,
        adminId.isAcceptableOrUnknown(data['admin_id']!, _adminIdMeta),
      );
    } else if (isInserting) {
      context.missing(_adminIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('settlement_status')) {
      context.handle(
        _settlementStatusMeta,
        settlementStatus.isAcceptableOrUnknown(
          data['settlement_status']!,
          _settlementStatusMeta,
        ),
      );
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedForUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      adminId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}admin_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      settlementStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settlement_status'],
      )!,
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      )!,
    );
  }

  @override
  $LocalTripsTable createAlias(String alias) {
    return $LocalTripsTable(attachedDatabase, alias);
  }
}

class LocalTrip extends DataClass implements Insertable<LocalTrip> {
  final String id;
  final String name;
  final String? description;
  final String? destination;
  final String? startDate;
  final String? endDate;
  final String currency;
  final String adminId;
  final String status;
  final String settlementStatus;
  final String cachedForUserId;
  const LocalTrip({
    required this.id,
    required this.name,
    this.description,
    this.destination,
    this.startDate,
    this.endDate,
    required this.currency,
    required this.adminId,
    required this.status,
    required this.settlementStatus,
    required this.cachedForUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    map['currency'] = Variable<String>(currency);
    map['admin_id'] = Variable<String>(adminId);
    map['status'] = Variable<String>(status);
    map['settlement_status'] = Variable<String>(settlementStatus);
    map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    return map;
  }

  LocalTripsCompanion toCompanion(bool nullToAbsent) {
    return LocalTripsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      currency: Value(currency),
      adminId: Value(adminId),
      status: Value(status),
      settlementStatus: Value(settlementStatus),
      cachedForUserId: Value(cachedForUserId),
    );
  }

  factory LocalTrip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrip(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      destination: serializer.fromJson<String?>(json['destination']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      currency: serializer.fromJson<String>(json['currency']),
      adminId: serializer.fromJson<String>(json['adminId']),
      status: serializer.fromJson<String>(json['status']),
      settlementStatus: serializer.fromJson<String>(json['settlementStatus']),
      cachedForUserId: serializer.fromJson<String>(json['cachedForUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'destination': serializer.toJson<String?>(destination),
      'startDate': serializer.toJson<String?>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'currency': serializer.toJson<String>(currency),
      'adminId': serializer.toJson<String>(adminId),
      'status': serializer.toJson<String>(status),
      'settlementStatus': serializer.toJson<String>(settlementStatus),
      'cachedForUserId': serializer.toJson<String>(cachedForUserId),
    };
  }

  LocalTrip copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> destination = const Value.absent(),
    Value<String?> startDate = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    String? currency,
    String? adminId,
    String? status,
    String? settlementStatus,
    String? cachedForUserId,
  }) => LocalTrip(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    destination: destination.present ? destination.value : this.destination,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    currency: currency ?? this.currency,
    adminId: adminId ?? this.adminId,
    status: status ?? this.status,
    settlementStatus: settlementStatus ?? this.settlementStatus,
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
  );
  LocalTrip copyWithCompanion(LocalTripsCompanion data) {
    return LocalTrip(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      currency: data.currency.present ? data.currency.value : this.currency,
      adminId: data.adminId.present ? data.adminId.value : this.adminId,
      status: data.status.present ? data.status.value : this.status,
      settlementStatus: data.settlementStatus.present
          ? data.settlementStatus.value
          : this.settlementStatus,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrip(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('destination: $destination, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('currency: $currency, ')
          ..write('adminId: $adminId, ')
          ..write('status: $status, ')
          ..write('settlementStatus: $settlementStatus, ')
          ..write('cachedForUserId: $cachedForUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    destination,
    startDate,
    endDate,
    currency,
    adminId,
    status,
    settlementStatus,
    cachedForUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrip &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.destination == this.destination &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.currency == this.currency &&
          other.adminId == this.adminId &&
          other.status == this.status &&
          other.settlementStatus == this.settlementStatus &&
          other.cachedForUserId == this.cachedForUserId);
}

class LocalTripsCompanion extends UpdateCompanion<LocalTrip> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> destination;
  final Value<String?> startDate;
  final Value<String?> endDate;
  final Value<String> currency;
  final Value<String> adminId;
  final Value<String> status;
  final Value<String> settlementStatus;
  final Value<String> cachedForUserId;
  final Value<int> rowid;
  const LocalTripsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.destination = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.currency = const Value.absent(),
    this.adminId = const Value.absent(),
    this.status = const Value.absent(),
    this.settlementStatus = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTripsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.destination = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.currency = const Value.absent(),
    required String adminId,
    this.status = const Value.absent(),
    this.settlementStatus = const Value.absent(),
    required String cachedForUserId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       adminId = Value(adminId),
       cachedForUserId = Value(cachedForUserId);
  static Insertable<LocalTrip> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? destination,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? currency,
    Expression<String>? adminId,
    Expression<String>? status,
    Expression<String>? settlementStatus,
    Expression<String>? cachedForUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (destination != null) 'destination': destination,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (currency != null) 'currency': currency,
      if (adminId != null) 'admin_id': adminId,
      if (status != null) 'status': status,
      if (settlementStatus != null) 'settlement_status': settlementStatus,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTripsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? destination,
    Value<String?>? startDate,
    Value<String?>? endDate,
    Value<String>? currency,
    Value<String>? adminId,
    Value<String>? status,
    Value<String>? settlementStatus,
    Value<String>? cachedForUserId,
    Value<int>? rowid,
  }) {
    return LocalTripsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currency: currency ?? this.currency,
      adminId: adminId ?? this.adminId,
      status: status ?? this.status,
      settlementStatus: settlementStatus ?? this.settlementStatus,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (adminId.present) {
      map['admin_id'] = Variable<String>(adminId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (settlementStatus.present) {
      map['settlement_status'] = Variable<String>(settlementStatus.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTripsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('destination: $destination, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('currency: $currency, ')
          ..write('adminId: $adminId, ')
          ..write('status: $status, ')
          ..write('settlementStatus: $settlementStatus, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMembersTable extends LocalMembers
    with TableInfo<$LocalMembersTable, LocalMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    userId,
    name,
    email,
    role,
    status,
    joinedAt,
    cachedForUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedForUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      ),
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      )!,
    );
  }

  @override
  $LocalMembersTable createAlias(String alias) {
    return $LocalMembersTable(attachedDatabase, alias);
  }
}

class LocalMember extends DataClass implements Insertable<LocalMember> {
  final String id;
  final String tripId;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final String cachedForUserId;
  const LocalMember({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
    required this.cachedForUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['role'] = Variable<String>(role);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || joinedAt != null) {
      map['joined_at'] = Variable<DateTime>(joinedAt);
    }
    map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    return map;
  }

  LocalMembersCompanion toCompanion(bool nullToAbsent) {
    return LocalMembersCompanion(
      id: Value(id),
      tripId: Value(tripId),
      userId: Value(userId),
      name: Value(name),
      email: Value(email),
      role: Value(role),
      status: Value(status),
      joinedAt: joinedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(joinedAt),
      cachedForUserId: Value(cachedForUserId),
    );
  }

  factory LocalMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMember(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      role: serializer.fromJson<String>(json['role']),
      status: serializer.fromJson<String>(json['status']),
      joinedAt: serializer.fromJson<DateTime?>(json['joinedAt']),
      cachedForUserId: serializer.fromJson<String>(json['cachedForUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'role': serializer.toJson<String>(role),
      'status': serializer.toJson<String>(status),
      'joinedAt': serializer.toJson<DateTime?>(joinedAt),
      'cachedForUserId': serializer.toJson<String>(cachedForUserId),
    };
  }

  LocalMember copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? name,
    String? email,
    String? role,
    String? status,
    Value<DateTime?> joinedAt = const Value.absent(),
    String? cachedForUserId,
  }) => LocalMember(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    status: status ?? this.status,
    joinedAt: joinedAt.present ? joinedAt.value : this.joinedAt,
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
  );
  LocalMember copyWithCompanion(LocalMembersCompanion data) {
    return LocalMember(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      role: data.role.present ? data.role.value : this.role,
      status: data.status.present ? data.status.value : this.status,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMember(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('cachedForUserId: $cachedForUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    userId,
    name,
    email,
    role,
    status,
    joinedAt,
    cachedForUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMember &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.email == this.email &&
          other.role == this.role &&
          other.status == this.status &&
          other.joinedAt == this.joinedAt &&
          other.cachedForUserId == this.cachedForUserId);
}

class LocalMembersCompanion extends UpdateCompanion<LocalMember> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> email;
  final Value<String> role;
  final Value<String> status;
  final Value<DateTime?> joinedAt;
  final Value<String> cachedForUserId;
  final Value<int> rowid;
  const LocalMembersCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMembersCompanion.insert({
    required String id,
    required String tripId,
    required String userId,
    required String name,
    required String email,
    required String role,
    required String status,
    this.joinedAt = const Value.absent(),
    required String cachedForUserId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       userId = Value(userId),
       name = Value(name),
       email = Value(email),
       role = Value(role),
       status = Value(status),
       cachedForUserId = Value(cachedForUserId);
  static Insertable<LocalMember> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? role,
    Expression<String>? status,
    Expression<DateTime>? joinedAt,
    Expression<String>? cachedForUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? email,
    Value<String>? role,
    Value<String>? status,
    Value<DateTime?>? joinedAt,
    Value<String>? cachedForUserId,
    Value<int>? rowid,
  }) {
    return LocalMembersCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMembersCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalWalletsTable extends LocalWallets
    with TableInfo<$LocalWalletsTable, LocalWallet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _balancePaiseMeta = const VerificationMeta(
    'balancePaise',
  );
  @override
  late final GeneratedColumn<int> balancePaise = GeneratedColumn<int>(
    'balance_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalContributionsPaiseMeta =
      const VerificationMeta('totalContributionsPaise');
  @override
  late final GeneratedColumn<int> totalContributionsPaise =
      GeneratedColumn<int>(
        'total_contributions_paise',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _totalExpensesPaiseMeta =
      const VerificationMeta('totalExpensesPaise');
  @override
  late final GeneratedColumn<int> totalExpensesPaise = GeneratedColumn<int>(
    'total_expenses_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _transactionCountMeta = const VerificationMeta(
    'transactionCount',
  );
  @override
  late final GeneratedColumn<int> transactionCount = GeneratedColumn<int>(
    'transaction_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tripId,
    currency,
    balancePaise,
    totalContributionsPaise,
    totalExpensesPaise,
    transactionCount,
    cachedForUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWallet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('balance_paise')) {
      context.handle(
        _balancePaiseMeta,
        balancePaise.isAcceptableOrUnknown(
          data['balance_paise']!,
          _balancePaiseMeta,
        ),
      );
    }
    if (data.containsKey('total_contributions_paise')) {
      context.handle(
        _totalContributionsPaiseMeta,
        totalContributionsPaise.isAcceptableOrUnknown(
          data['total_contributions_paise']!,
          _totalContributionsPaiseMeta,
        ),
      );
    }
    if (data.containsKey('total_expenses_paise')) {
      context.handle(
        _totalExpensesPaiseMeta,
        totalExpensesPaise.isAcceptableOrUnknown(
          data['total_expenses_paise']!,
          _totalExpensesPaiseMeta,
        ),
      );
    }
    if (data.containsKey('transaction_count')) {
      context.handle(
        _transactionCountMeta,
        transactionCount.isAcceptableOrUnknown(
          data['transaction_count']!,
          _transactionCountMeta,
        ),
      );
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedForUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tripId};
  @override
  LocalWallet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWallet(
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      balancePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_paise'],
      )!,
      totalContributionsPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_contributions_paise'],
      )!,
      totalExpensesPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_expenses_paise'],
      )!,
      transactionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_count'],
      )!,
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      )!,
    );
  }

  @override
  $LocalWalletsTable createAlias(String alias) {
    return $LocalWalletsTable(attachedDatabase, alias);
  }
}

class LocalWallet extends DataClass implements Insertable<LocalWallet> {
  final String tripId;
  final String currency;
  final int balancePaise;
  final int totalContributionsPaise;
  final int totalExpensesPaise;
  final int transactionCount;
  final String cachedForUserId;
  const LocalWallet({
    required this.tripId,
    required this.currency,
    required this.balancePaise,
    required this.totalContributionsPaise,
    required this.totalExpensesPaise,
    required this.transactionCount,
    required this.cachedForUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    map['currency'] = Variable<String>(currency);
    map['balance_paise'] = Variable<int>(balancePaise);
    map['total_contributions_paise'] = Variable<int>(totalContributionsPaise);
    map['total_expenses_paise'] = Variable<int>(totalExpensesPaise);
    map['transaction_count'] = Variable<int>(transactionCount);
    map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    return map;
  }

  LocalWalletsCompanion toCompanion(bool nullToAbsent) {
    return LocalWalletsCompanion(
      tripId: Value(tripId),
      currency: Value(currency),
      balancePaise: Value(balancePaise),
      totalContributionsPaise: Value(totalContributionsPaise),
      totalExpensesPaise: Value(totalExpensesPaise),
      transactionCount: Value(transactionCount),
      cachedForUserId: Value(cachedForUserId),
    );
  }

  factory LocalWallet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWallet(
      tripId: serializer.fromJson<String>(json['tripId']),
      currency: serializer.fromJson<String>(json['currency']),
      balancePaise: serializer.fromJson<int>(json['balancePaise']),
      totalContributionsPaise: serializer.fromJson<int>(
        json['totalContributionsPaise'],
      ),
      totalExpensesPaise: serializer.fromJson<int>(json['totalExpensesPaise']),
      transactionCount: serializer.fromJson<int>(json['transactionCount']),
      cachedForUserId: serializer.fromJson<String>(json['cachedForUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'currency': serializer.toJson<String>(currency),
      'balancePaise': serializer.toJson<int>(balancePaise),
      'totalContributionsPaise': serializer.toJson<int>(
        totalContributionsPaise,
      ),
      'totalExpensesPaise': serializer.toJson<int>(totalExpensesPaise),
      'transactionCount': serializer.toJson<int>(transactionCount),
      'cachedForUserId': serializer.toJson<String>(cachedForUserId),
    };
  }

  LocalWallet copyWith({
    String? tripId,
    String? currency,
    int? balancePaise,
    int? totalContributionsPaise,
    int? totalExpensesPaise,
    int? transactionCount,
    String? cachedForUserId,
  }) => LocalWallet(
    tripId: tripId ?? this.tripId,
    currency: currency ?? this.currency,
    balancePaise: balancePaise ?? this.balancePaise,
    totalContributionsPaise:
        totalContributionsPaise ?? this.totalContributionsPaise,
    totalExpensesPaise: totalExpensesPaise ?? this.totalExpensesPaise,
    transactionCount: transactionCount ?? this.transactionCount,
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
  );
  LocalWallet copyWithCompanion(LocalWalletsCompanion data) {
    return LocalWallet(
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      currency: data.currency.present ? data.currency.value : this.currency,
      balancePaise: data.balancePaise.present
          ? data.balancePaise.value
          : this.balancePaise,
      totalContributionsPaise: data.totalContributionsPaise.present
          ? data.totalContributionsPaise.value
          : this.totalContributionsPaise,
      totalExpensesPaise: data.totalExpensesPaise.present
          ? data.totalExpensesPaise.value
          : this.totalExpensesPaise,
      transactionCount: data.transactionCount.present
          ? data.transactionCount.value
          : this.transactionCount,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWallet(')
          ..write('tripId: $tripId, ')
          ..write('currency: $currency, ')
          ..write('balancePaise: $balancePaise, ')
          ..write('totalContributionsPaise: $totalContributionsPaise, ')
          ..write('totalExpensesPaise: $totalExpensesPaise, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('cachedForUserId: $cachedForUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tripId,
    currency,
    balancePaise,
    totalContributionsPaise,
    totalExpensesPaise,
    transactionCount,
    cachedForUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWallet &&
          other.tripId == this.tripId &&
          other.currency == this.currency &&
          other.balancePaise == this.balancePaise &&
          other.totalContributionsPaise == this.totalContributionsPaise &&
          other.totalExpensesPaise == this.totalExpensesPaise &&
          other.transactionCount == this.transactionCount &&
          other.cachedForUserId == this.cachedForUserId);
}

class LocalWalletsCompanion extends UpdateCompanion<LocalWallet> {
  final Value<String> tripId;
  final Value<String> currency;
  final Value<int> balancePaise;
  final Value<int> totalContributionsPaise;
  final Value<int> totalExpensesPaise;
  final Value<int> transactionCount;
  final Value<String> cachedForUserId;
  final Value<int> rowid;
  const LocalWalletsCompanion({
    this.tripId = const Value.absent(),
    this.currency = const Value.absent(),
    this.balancePaise = const Value.absent(),
    this.totalContributionsPaise = const Value.absent(),
    this.totalExpensesPaise = const Value.absent(),
    this.transactionCount = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalWalletsCompanion.insert({
    required String tripId,
    this.currency = const Value.absent(),
    this.balancePaise = const Value.absent(),
    this.totalContributionsPaise = const Value.absent(),
    this.totalExpensesPaise = const Value.absent(),
    this.transactionCount = const Value.absent(),
    required String cachedForUserId,
    this.rowid = const Value.absent(),
  }) : tripId = Value(tripId),
       cachedForUserId = Value(cachedForUserId);
  static Insertable<LocalWallet> custom({
    Expression<String>? tripId,
    Expression<String>? currency,
    Expression<int>? balancePaise,
    Expression<int>? totalContributionsPaise,
    Expression<int>? totalExpensesPaise,
    Expression<int>? transactionCount,
    Expression<String>? cachedForUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (currency != null) 'currency': currency,
      if (balancePaise != null) 'balance_paise': balancePaise,
      if (totalContributionsPaise != null)
        'total_contributions_paise': totalContributionsPaise,
      if (totalExpensesPaise != null)
        'total_expenses_paise': totalExpensesPaise,
      if (transactionCount != null) 'transaction_count': transactionCount,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalWalletsCompanion copyWith({
    Value<String>? tripId,
    Value<String>? currency,
    Value<int>? balancePaise,
    Value<int>? totalContributionsPaise,
    Value<int>? totalExpensesPaise,
    Value<int>? transactionCount,
    Value<String>? cachedForUserId,
    Value<int>? rowid,
  }) {
    return LocalWalletsCompanion(
      tripId: tripId ?? this.tripId,
      currency: currency ?? this.currency,
      balancePaise: balancePaise ?? this.balancePaise,
      totalContributionsPaise:
          totalContributionsPaise ?? this.totalContributionsPaise,
      totalExpensesPaise: totalExpensesPaise ?? this.totalExpensesPaise,
      transactionCount: transactionCount ?? this.transactionCount,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (balancePaise.present) {
      map['balance_paise'] = Variable<int>(balancePaise.value);
    }
    if (totalContributionsPaise.present) {
      map['total_contributions_paise'] = Variable<int>(
        totalContributionsPaise.value,
      );
    }
    if (totalExpensesPaise.present) {
      map['total_expenses_paise'] = Variable<int>(totalExpensesPaise.value);
    }
    if (transactionCount.present) {
      map['transaction_count'] = Variable<int>(transactionCount.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWalletsCompanion(')
          ..write('tripId: $tripId, ')
          ..write('currency: $currency, ')
          ..write('balancePaise: $balancePaise, ')
          ..write('totalContributionsPaise: $totalContributionsPaise, ')
          ..write('totalExpensesPaise: $totalExpensesPaise, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalContributionsTable extends LocalContributions
    with TableInfo<$LocalContributionsTable, LocalContribution> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalContributionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CASH'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CONFIRMED'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    memberId,
    amountPaise,
    paymentMethod,
    status,
    note,
    createdAt,
    cachedForUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_contributions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalContribution> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedForUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalContribution map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalContribution(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      )!,
    );
  }

  @override
  $LocalContributionsTable createAlias(String alias) {
    return $LocalContributionsTable(attachedDatabase, alias);
  }
}

class LocalContribution extends DataClass
    implements Insertable<LocalContribution> {
  final String id;
  final String tripId;
  final String memberId;
  final int amountPaise;
  final String paymentMethod;
  final String status;
  final String? note;
  final DateTime createdAt;
  final String cachedForUserId;
  const LocalContribution({
    required this.id,
    required this.tripId,
    required this.memberId,
    required this.amountPaise,
    required this.paymentMethod,
    required this.status,
    this.note,
    required this.createdAt,
    required this.cachedForUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['member_id'] = Variable<String>(memberId);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    return map;
  }

  LocalContributionsCompanion toCompanion(bool nullToAbsent) {
    return LocalContributionsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      memberId: Value(memberId),
      amountPaise: Value(amountPaise),
      paymentMethod: Value(paymentMethod),
      status: Value(status),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      cachedForUserId: Value(cachedForUserId),
    );
  }

  factory LocalContribution.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalContribution(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      cachedForUserId: serializer.fromJson<String>(json['cachedForUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'memberId': serializer.toJson<String>(memberId),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'cachedForUserId': serializer.toJson<String>(cachedForUserId),
    };
  }

  LocalContribution copyWith({
    String? id,
    String? tripId,
    String? memberId,
    int? amountPaise,
    String? paymentMethod,
    String? status,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    String? cachedForUserId,
  }) => LocalContribution(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    memberId: memberId ?? this.memberId,
    amountPaise: amountPaise ?? this.amountPaise,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    status: status ?? this.status,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
  );
  LocalContribution copyWithCompanion(LocalContributionsCompanion data) {
    return LocalContribution(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalContribution(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('memberId: $memberId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedForUserId: $cachedForUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    memberId,
    amountPaise,
    paymentMethod,
    status,
    note,
    createdAt,
    cachedForUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalContribution &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.memberId == this.memberId &&
          other.amountPaise == this.amountPaise &&
          other.paymentMethod == this.paymentMethod &&
          other.status == this.status &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.cachedForUserId == this.cachedForUserId);
}

class LocalContributionsCompanion extends UpdateCompanion<LocalContribution> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> memberId;
  final Value<int> amountPaise;
  final Value<String> paymentMethod;
  final Value<String> status;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<String> cachedForUserId;
  final Value<int> rowid;
  const LocalContributionsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalContributionsCompanion.insert({
    required String id,
    required String tripId,
    required String memberId,
    required int amountPaise,
    this.paymentMethod = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required String cachedForUserId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       memberId = Value(memberId),
       amountPaise = Value(amountPaise),
       createdAt = Value(createdAt),
       cachedForUserId = Value(cachedForUserId);
  static Insertable<LocalContribution> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? memberId,
    Expression<int>? amountPaise,
    Expression<String>? paymentMethod,
    Expression<String>? status,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<String>? cachedForUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (memberId != null) 'member_id': memberId,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalContributionsCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? memberId,
    Value<int>? amountPaise,
    Value<String>? paymentMethod,
    Value<String>? status,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<String>? cachedForUserId,
    Value<int>? rowid,
  }) {
    return LocalContributionsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      memberId: memberId ?? this.memberId,
      amountPaise: amountPaise ?? this.amountPaise,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalContributionsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('memberId: $memberId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExpensesTable extends LocalExpenses
    with TableInfo<$LocalExpensesTable, LocalExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidByMeta = const VerificationMeta('paidBy');
  @override
  late final GeneratedColumn<String> paidBy = GeneratedColumn<String>(
    'paid_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _splitModeMeta = const VerificationMeta(
    'splitMode',
  );
  @override
  late final GeneratedColumn<String> splitMode = GeneratedColumn<String>(
    'split_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EQUAL'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CONFIRMED'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    walletId,
    paidBy,
    amountPaise,
    category,
    description,
    splitMode,
    status,
    createdAt,
    cachedForUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalExpense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('paid_by')) {
      context.handle(
        _paidByMeta,
        paidBy.isAcceptableOrUnknown(data['paid_by']!, _paidByMeta),
      );
    } else if (isInserting) {
      context.missing(_paidByMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('split_mode')) {
      context.handle(
        _splitModeMeta,
        splitMode.isAcceptableOrUnknown(data['split_mode']!, _splitModeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedForUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExpense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      )!,
      paidBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_by'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      splitMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      )!,
    );
  }

  @override
  $LocalExpensesTable createAlias(String alias) {
    return $LocalExpensesTable(attachedDatabase, alias);
  }
}

class LocalExpense extends DataClass implements Insertable<LocalExpense> {
  final String id;
  final String tripId;
  final String walletId;
  final String paidBy;
  final int amountPaise;
  final String category;
  final String? description;
  final String splitMode;
  final String status;
  final DateTime createdAt;
  final String cachedForUserId;
  const LocalExpense({
    required this.id,
    required this.tripId,
    required this.walletId,
    required this.paidBy,
    required this.amountPaise,
    required this.category,
    this.description,
    required this.splitMode,
    required this.status,
    required this.createdAt,
    required this.cachedForUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['wallet_id'] = Variable<String>(walletId);
    map['paid_by'] = Variable<String>(paidBy);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['split_mode'] = Variable<String>(splitMode);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    return map;
  }

  LocalExpensesCompanion toCompanion(bool nullToAbsent) {
    return LocalExpensesCompanion(
      id: Value(id),
      tripId: Value(tripId),
      walletId: Value(walletId),
      paidBy: Value(paidBy),
      amountPaise: Value(amountPaise),
      category: Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      splitMode: Value(splitMode),
      status: Value(status),
      createdAt: Value(createdAt),
      cachedForUserId: Value(cachedForUserId),
    );
  }

  factory LocalExpense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExpense(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      walletId: serializer.fromJson<String>(json['walletId']),
      paidBy: serializer.fromJson<String>(json['paidBy']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      splitMode: serializer.fromJson<String>(json['splitMode']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      cachedForUserId: serializer.fromJson<String>(json['cachedForUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'walletId': serializer.toJson<String>(walletId),
      'paidBy': serializer.toJson<String>(paidBy),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String?>(description),
      'splitMode': serializer.toJson<String>(splitMode),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'cachedForUserId': serializer.toJson<String>(cachedForUserId),
    };
  }

  LocalExpense copyWith({
    String? id,
    String? tripId,
    String? walletId,
    String? paidBy,
    int? amountPaise,
    String? category,
    Value<String?> description = const Value.absent(),
    String? splitMode,
    String? status,
    DateTime? createdAt,
    String? cachedForUserId,
  }) => LocalExpense(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    walletId: walletId ?? this.walletId,
    paidBy: paidBy ?? this.paidBy,
    amountPaise: amountPaise ?? this.amountPaise,
    category: category ?? this.category,
    description: description.present ? description.value : this.description,
    splitMode: splitMode ?? this.splitMode,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
  );
  LocalExpense copyWithCompanion(LocalExpensesCompanion data) {
    return LocalExpense(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      paidBy: data.paidBy.present ? data.paidBy.value : this.paidBy,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      splitMode: data.splitMode.present ? data.splitMode.value : this.splitMode,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpense(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('walletId: $walletId, ')
          ..write('paidBy: $paidBy, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('splitMode: $splitMode, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedForUserId: $cachedForUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    walletId,
    paidBy,
    amountPaise,
    category,
    description,
    splitMode,
    status,
    createdAt,
    cachedForUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExpense &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.walletId == this.walletId &&
          other.paidBy == this.paidBy &&
          other.amountPaise == this.amountPaise &&
          other.category == this.category &&
          other.description == this.description &&
          other.splitMode == this.splitMode &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.cachedForUserId == this.cachedForUserId);
}

class LocalExpensesCompanion extends UpdateCompanion<LocalExpense> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> walletId;
  final Value<String> paidBy;
  final Value<int> amountPaise;
  final Value<String> category;
  final Value<String?> description;
  final Value<String> splitMode;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<String> cachedForUserId;
  final Value<int> rowid;
  const LocalExpensesCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.walletId = const Value.absent(),
    this.paidBy = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.splitMode = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExpensesCompanion.insert({
    required String id,
    required String tripId,
    required String walletId,
    required String paidBy,
    required int amountPaise,
    required String category,
    this.description = const Value.absent(),
    this.splitMode = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required String cachedForUserId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       walletId = Value(walletId),
       paidBy = Value(paidBy),
       amountPaise = Value(amountPaise),
       category = Value(category),
       createdAt = Value(createdAt),
       cachedForUserId = Value(cachedForUserId);
  static Insertable<LocalExpense> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? walletId,
    Expression<String>? paidBy,
    Expression<int>? amountPaise,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? splitMode,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<String>? cachedForUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (walletId != null) 'wallet_id': walletId,
      if (paidBy != null) 'paid_by': paidBy,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (splitMode != null) 'split_mode': splitMode,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? walletId,
    Value<String>? paidBy,
    Value<int>? amountPaise,
    Value<String>? category,
    Value<String?>? description,
    Value<String>? splitMode,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<String>? cachedForUserId,
    Value<int>? rowid,
  }) {
    return LocalExpensesCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      walletId: walletId ?? this.walletId,
      paidBy: paidBy ?? this.paidBy,
      amountPaise: amountPaise ?? this.amountPaise,
      category: category ?? this.category,
      description: description ?? this.description,
      splitMode: splitMode ?? this.splitMode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (paidBy.present) {
      map['paid_by'] = Variable<String>(paidBy.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (splitMode.present) {
      map['split_mode'] = Variable<String>(splitMode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpensesCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('walletId: $walletId, ')
          ..write('paidBy: $paidBy, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('splitMode: $splitMode, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExpenseSplitsTable extends LocalExpenseSplits
    with TableInfo<$LocalExpenseSplitsTable, LocalExpenseSplit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExpenseSplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseId,
    memberId,
    amountPaise,
    cachedForUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_expense_splits';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalExpenseSplit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedForUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalExpenseSplit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExpenseSplit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      )!,
    );
  }

  @override
  $LocalExpenseSplitsTable createAlias(String alias) {
    return $LocalExpenseSplitsTable(attachedDatabase, alias);
  }
}

class LocalExpenseSplit extends DataClass
    implements Insertable<LocalExpenseSplit> {
  final String id;
  final String expenseId;
  final String memberId;
  final int amountPaise;
  final String cachedForUserId;
  const LocalExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.amountPaise,
    required this.cachedForUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    return map;
  }

  LocalExpenseSplitsCompanion toCompanion(bool nullToAbsent) {
    return LocalExpenseSplitsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      memberId: Value(memberId),
      amountPaise: Value(amountPaise),
      cachedForUserId: Value(cachedForUserId),
    );
  }

  factory LocalExpenseSplit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExpenseSplit(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      cachedForUserId: serializer.fromJson<String>(json['cachedForUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expenseId': serializer.toJson<String>(expenseId),
      'memberId': serializer.toJson<String>(memberId),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'cachedForUserId': serializer.toJson<String>(cachedForUserId),
    };
  }

  LocalExpenseSplit copyWith({
    String? id,
    String? expenseId,
    String? memberId,
    int? amountPaise,
    String? cachedForUserId,
  }) => LocalExpenseSplit(
    id: id ?? this.id,
    expenseId: expenseId ?? this.expenseId,
    memberId: memberId ?? this.memberId,
    amountPaise: amountPaise ?? this.amountPaise,
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
  );
  LocalExpenseSplit copyWithCompanion(LocalExpenseSplitsCompanion data) {
    return LocalExpenseSplit(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpenseSplit(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('cachedForUserId: $cachedForUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, expenseId, memberId, amountPaise, cachedForUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExpenseSplit &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.amountPaise == this.amountPaise &&
          other.cachedForUserId == this.cachedForUserId);
}

class LocalExpenseSplitsCompanion extends UpdateCompanion<LocalExpenseSplit> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<int> amountPaise;
  final Value<String> cachedForUserId;
  final Value<int> rowid;
  const LocalExpenseSplitsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExpenseSplitsCompanion.insert({
    required String id,
    required String expenseId,
    required String memberId,
    required int amountPaise,
    required String cachedForUserId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       expenseId = Value(expenseId),
       memberId = Value(memberId),
       amountPaise = Value(amountPaise),
       cachedForUserId = Value(cachedForUserId);
  static Insertable<LocalExpenseSplit> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<int>? amountPaise,
    Expression<String>? cachedForUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExpenseSplitsCompanion copyWith({
    Value<String>? id,
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<int>? amountPaise,
    Value<String>? cachedForUserId,
    Value<int>? rowid,
  }) {
    return LocalExpenseSplitsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      amountPaise: amountPaise ?? this.amountPaise,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExpenseSplitsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalActivitiesTable extends LocalActivities
    with TableInfo<$LocalActivitiesTable, LocalActivity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorUserIdMeta = const VerificationMeta(
    'actorUserId',
  );
  @override
  late final GeneratedColumn<String> actorUserId = GeneratedColumn<String>(
    'actor_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorNameMeta = const VerificationMeta(
    'actorName',
  );
  @override
  late final GeneratedColumn<String> actorName = GeneratedColumn<String>(
    'actor_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    actorUserId,
    actorName,
    eventType,
    entityType,
    entityId,
    message,
    metadataJson,
    createdAt,
    cachedForUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalActivity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('actor_user_id')) {
      context.handle(
        _actorUserIdMeta,
        actorUserId.isAcceptableOrUnknown(
          data['actor_user_id']!,
          _actorUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actorUserIdMeta);
    }
    if (data.containsKey('actor_name')) {
      context.handle(
        _actorNameMeta,
        actorName.isAcceptableOrUnknown(data['actor_name']!, _actorNameMeta),
      );
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedForUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalActivity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalActivity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      actorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_user_id'],
      )!,
      actorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_name'],
      ),
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      ),
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      )!,
    );
  }

  @override
  $LocalActivitiesTable createAlias(String alias) {
    return $LocalActivitiesTable(attachedDatabase, alias);
  }
}

class LocalActivity extends DataClass implements Insertable<LocalActivity> {
  final String id;
  final String tripId;
  final String actorUserId;
  final String? actorName;
  final String eventType;
  final String? entityType;
  final String? entityId;
  final String message;
  final String? metadataJson;
  final DateTime createdAt;
  final String cachedForUserId;
  const LocalActivity({
    required this.id,
    required this.tripId,
    required this.actorUserId,
    this.actorName,
    required this.eventType,
    this.entityType,
    this.entityId,
    required this.message,
    this.metadataJson,
    required this.createdAt,
    required this.cachedForUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['actor_user_id'] = Variable<String>(actorUserId);
    if (!nullToAbsent || actorName != null) {
      map['actor_name'] = Variable<String>(actorName);
    }
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    return map;
  }

  LocalActivitiesCompanion toCompanion(bool nullToAbsent) {
    return LocalActivitiesCompanion(
      id: Value(id),
      tripId: Value(tripId),
      actorUserId: Value(actorUserId),
      actorName: actorName == null && nullToAbsent
          ? const Value.absent()
          : Value(actorName),
      eventType: Value(eventType),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      message: Value(message),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      createdAt: Value(createdAt),
      cachedForUserId: Value(cachedForUserId),
    );
  }

  factory LocalActivity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalActivity(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      actorUserId: serializer.fromJson<String>(json['actorUserId']),
      actorName: serializer.fromJson<String?>(json['actorName']),
      eventType: serializer.fromJson<String>(json['eventType']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      message: serializer.fromJson<String>(json['message']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      cachedForUserId: serializer.fromJson<String>(json['cachedForUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'actorUserId': serializer.toJson<String>(actorUserId),
      'actorName': serializer.toJson<String?>(actorName),
      'eventType': serializer.toJson<String>(eventType),
      'entityType': serializer.toJson<String?>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'message': serializer.toJson<String>(message),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'cachedForUserId': serializer.toJson<String>(cachedForUserId),
    };
  }

  LocalActivity copyWith({
    String? id,
    String? tripId,
    String? actorUserId,
    Value<String?> actorName = const Value.absent(),
    String? eventType,
    Value<String?> entityType = const Value.absent(),
    Value<String?> entityId = const Value.absent(),
    String? message,
    Value<String?> metadataJson = const Value.absent(),
    DateTime? createdAt,
    String? cachedForUserId,
  }) => LocalActivity(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    actorUserId: actorUserId ?? this.actorUserId,
    actorName: actorName.present ? actorName.value : this.actorName,
    eventType: eventType ?? this.eventType,
    entityType: entityType.present ? entityType.value : this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    message: message ?? this.message,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
    createdAt: createdAt ?? this.createdAt,
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
  );
  LocalActivity copyWithCompanion(LocalActivitiesCompanion data) {
    return LocalActivity(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      actorUserId: data.actorUserId.present
          ? data.actorUserId.value
          : this.actorUserId,
      actorName: data.actorName.present ? data.actorName.value : this.actorName,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      message: data.message.present ? data.message.value : this.message,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalActivity(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('actorName: $actorName, ')
          ..write('eventType: $eventType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('message: $message, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedForUserId: $cachedForUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    actorUserId,
    actorName,
    eventType,
    entityType,
    entityId,
    message,
    metadataJson,
    createdAt,
    cachedForUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalActivity &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.actorUserId == this.actorUserId &&
          other.actorName == this.actorName &&
          other.eventType == this.eventType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.message == this.message &&
          other.metadataJson == this.metadataJson &&
          other.createdAt == this.createdAt &&
          other.cachedForUserId == this.cachedForUserId);
}

class LocalActivitiesCompanion extends UpdateCompanion<LocalActivity> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> actorUserId;
  final Value<String?> actorName;
  final Value<String> eventType;
  final Value<String?> entityType;
  final Value<String?> entityId;
  final Value<String> message;
  final Value<String?> metadataJson;
  final Value<DateTime> createdAt;
  final Value<String> cachedForUserId;
  final Value<int> rowid;
  const LocalActivitiesCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.actorName = const Value.absent(),
    this.eventType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.message = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalActivitiesCompanion.insert({
    required String id,
    required String tripId,
    required String actorUserId,
    this.actorName = const Value.absent(),
    required String eventType,
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    required String message,
    this.metadataJson = const Value.absent(),
    required DateTime createdAt,
    required String cachedForUserId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       actorUserId = Value(actorUserId),
       eventType = Value(eventType),
       message = Value(message),
       createdAt = Value(createdAt),
       cachedForUserId = Value(cachedForUserId);
  static Insertable<LocalActivity> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? actorUserId,
    Expression<String>? actorName,
    Expression<String>? eventType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? message,
    Expression<String>? metadataJson,
    Expression<DateTime>? createdAt,
    Expression<String>? cachedForUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (actorName != null) 'actor_name': actorName,
      if (eventType != null) 'event_type': eventType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (message != null) 'message': message,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalActivitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? actorUserId,
    Value<String?>? actorName,
    Value<String>? eventType,
    Value<String?>? entityType,
    Value<String?>? entityId,
    Value<String>? message,
    Value<String?>? metadataJson,
    Value<DateTime>? createdAt,
    Value<String>? cachedForUserId,
    Value<int>? rowid,
  }) {
    return LocalActivitiesCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      actorUserId: actorUserId ?? this.actorUserId,
      actorName: actorName ?? this.actorName,
      eventType: eventType ?? this.eventType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      message: message ?? this.message,
      metadataJson: metadataJson ?? this.metadataJson,
      createdAt: createdAt ?? this.createdAt,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (actorUserId.present) {
      map['actor_user_id'] = Variable<String>(actorUserId.value);
    }
    if (actorName.present) {
      map['actor_name'] = Variable<String>(actorName.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('actorName: $actorName, ')
          ..write('eventType: $eventType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('message: $message, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNotificationsTable extends LocalNotifications
    with TableInfo<$LocalNotificationsTable, LocalNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationTypeMeta = const VerificationMeta(
    'notificationType',
  );
  @override
  late final GeneratedColumn<String> notificationType = GeneratedColumn<String>(
    'notification_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    tripId,
    notificationType,
    title,
    body,
    entityType,
    entityId,
    isRead,
    readAt,
    createdAt,
    cachedForUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalNotification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    }
    if (data.containsKey('notification_type')) {
      context.handle(
        _notificationTypeMeta,
        notificationType.isAcceptableOrUnknown(
          data['notification_type']!,
          _notificationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedForUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNotification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      ),
      notificationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      ),
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      )!,
    );
  }

  @override
  $LocalNotificationsTable createAlias(String alias) {
    return $LocalNotificationsTable(attachedDatabase, alias);
  }
}

class LocalNotification extends DataClass
    implements Insertable<LocalNotification> {
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
  final String cachedForUserId;
  const LocalNotification({
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
    required this.cachedForUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<String>(tripId);
    }
    map['notification_type'] = Variable<String>(notificationType);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    return map;
  }

  LocalNotificationsCompanion toCompanion(bool nullToAbsent) {
    return LocalNotificationsCompanion(
      id: Value(id),
      userId: Value(userId),
      tripId: tripId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripId),
      notificationType: Value(notificationType),
      title: Value(title),
      body: Value(body),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      isRead: Value(isRead),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      createdAt: Value(createdAt),
      cachedForUserId: Value(cachedForUserId),
    );
  }

  factory LocalNotification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNotification(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      tripId: serializer.fromJson<String?>(json['tripId']),
      notificationType: serializer.fromJson<String>(json['notificationType']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      cachedForUserId: serializer.fromJson<String>(json['cachedForUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'tripId': serializer.toJson<String?>(tripId),
      'notificationType': serializer.toJson<String>(notificationType),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'entityType': serializer.toJson<String?>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'isRead': serializer.toJson<bool>(isRead),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'cachedForUserId': serializer.toJson<String>(cachedForUserId),
    };
  }

  LocalNotification copyWith({
    String? id,
    String? userId,
    Value<String?> tripId = const Value.absent(),
    String? notificationType,
    String? title,
    String? body,
    Value<String?> entityType = const Value.absent(),
    Value<String?> entityId = const Value.absent(),
    bool? isRead,
    Value<DateTime?> readAt = const Value.absent(),
    DateTime? createdAt,
    String? cachedForUserId,
  }) => LocalNotification(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    tripId: tripId.present ? tripId.value : this.tripId,
    notificationType: notificationType ?? this.notificationType,
    title: title ?? this.title,
    body: body ?? this.body,
    entityType: entityType.present ? entityType.value : this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    isRead: isRead ?? this.isRead,
    readAt: readAt.present ? readAt.value : this.readAt,
    createdAt: createdAt ?? this.createdAt,
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
  );
  LocalNotification copyWithCompanion(LocalNotificationsCompanion data) {
    return LocalNotification(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      notificationType: data.notificationType.present
          ? data.notificationType.value
          : this.notificationType,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotification(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tripId: $tripId, ')
          ..write('notificationType: $notificationType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('isRead: $isRead, ')
          ..write('readAt: $readAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedForUserId: $cachedForUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    tripId,
    notificationType,
    title,
    body,
    entityType,
    entityId,
    isRead,
    readAt,
    createdAt,
    cachedForUserId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNotification &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.tripId == this.tripId &&
          other.notificationType == this.notificationType &&
          other.title == this.title &&
          other.body == this.body &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.isRead == this.isRead &&
          other.readAt == this.readAt &&
          other.createdAt == this.createdAt &&
          other.cachedForUserId == this.cachedForUserId);
}

class LocalNotificationsCompanion extends UpdateCompanion<LocalNotification> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> tripId;
  final Value<String> notificationType;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> entityType;
  final Value<String?> entityId;
  final Value<bool> isRead;
  final Value<DateTime?> readAt;
  final Value<DateTime> createdAt;
  final Value<String> cachedForUserId;
  final Value<int> rowid;
  const LocalNotificationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.tripId = const Value.absent(),
    this.notificationType = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.isRead = const Value.absent(),
    this.readAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNotificationsCompanion.insert({
    required String id,
    required String userId,
    this.tripId = const Value.absent(),
    required String notificationType,
    required String title,
    required String body,
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.isRead = const Value.absent(),
    this.readAt = const Value.absent(),
    required DateTime createdAt,
    required String cachedForUserId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       notificationType = Value(notificationType),
       title = Value(title),
       body = Value(body),
       createdAt = Value(createdAt),
       cachedForUserId = Value(cachedForUserId);
  static Insertable<LocalNotification> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? tripId,
    Expression<String>? notificationType,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<bool>? isRead,
    Expression<DateTime>? readAt,
    Expression<DateTime>? createdAt,
    Expression<String>? cachedForUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (tripId != null) 'trip_id': tripId,
      if (notificationType != null) 'notification_type': notificationType,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (isRead != null) 'is_read': isRead,
      if (readAt != null) 'read_at': readAt,
      if (createdAt != null) 'created_at': createdAt,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? tripId,
    Value<String>? notificationType,
    Value<String>? title,
    Value<String>? body,
    Value<String?>? entityType,
    Value<String?>? entityId,
    Value<bool>? isRead,
    Value<DateTime?>? readAt,
    Value<DateTime>? createdAt,
    Value<String>? cachedForUserId,
    Value<int>? rowid,
  }) {
    return LocalNotificationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      body: body ?? this.body,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (notificationType.present) {
      map['notification_type'] = Variable<String>(notificationType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tripId: $tripId, ')
          ..write('notificationType: $notificationType, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('isRead: $isRead, ')
          ..write('readAt: $readAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncMetaTable extends LocalSyncMeta
    with TableInfo<$LocalSyncMetaTable, LocalSyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncKeyMeta = const VerificationMeta(
    'syncKey',
  );
  @override
  late final GeneratedColumn<String> syncKey = GeneratedColumn<String>(
    'sync_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedForUserIdMeta = const VerificationMeta(
    'cachedForUserId',
  );
  @override
  late final GeneratedColumn<String> cachedForUserId = GeneratedColumn<String>(
    'cached_for_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    syncKey,
    cursor,
    lastSyncedAt,
    cachedForUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_key')) {
      context.handle(
        _syncKeyMeta,
        syncKey.isAcceptableOrUnknown(data['sync_key']!, _syncKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_syncKeyMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    if (data.containsKey('cached_for_user_id')) {
      context.handle(
        _cachedForUserIdMeta,
        cachedForUserId.isAcceptableOrUnknown(
          data['cached_for_user_id']!,
          _cachedForUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cachedForUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {syncKey, cachedForUserId};
  @override
  LocalSyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncMetaData(
      syncKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_key'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
      cachedForUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_for_user_id'],
      )!,
    );
  }

  @override
  $LocalSyncMetaTable createAlias(String alias) {
    return $LocalSyncMetaTable(attachedDatabase, alias);
  }
}

class LocalSyncMetaData extends DataClass
    implements Insertable<LocalSyncMetaData> {
  final String syncKey;
  final String? cursor;
  final DateTime lastSyncedAt;
  final String cachedForUserId;
  const LocalSyncMetaData({
    required this.syncKey,
    this.cursor,
    required this.lastSyncedAt,
    required this.cachedForUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sync_key'] = Variable<String>(syncKey);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    map['cached_for_user_id'] = Variable<String>(cachedForUserId);
    return map;
  }

  LocalSyncMetaCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncMetaCompanion(
      syncKey: Value(syncKey),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      lastSyncedAt: Value(lastSyncedAt),
      cachedForUserId: Value(cachedForUserId),
    );
  }

  factory LocalSyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncMetaData(
      syncKey: serializer.fromJson<String>(json['syncKey']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
      cachedForUserId: serializer.fromJson<String>(json['cachedForUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncKey': serializer.toJson<String>(syncKey),
      'cursor': serializer.toJson<String?>(cursor),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
      'cachedForUserId': serializer.toJson<String>(cachedForUserId),
    };
  }

  LocalSyncMetaData copyWith({
    String? syncKey,
    Value<String?> cursor = const Value.absent(),
    DateTime? lastSyncedAt,
    String? cachedForUserId,
  }) => LocalSyncMetaData(
    syncKey: syncKey ?? this.syncKey,
    cursor: cursor.present ? cursor.value : this.cursor,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
  );
  LocalSyncMetaData copyWithCompanion(LocalSyncMetaCompanion data) {
    return LocalSyncMetaData(
      syncKey: data.syncKey.present ? data.syncKey.value : this.syncKey,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      cachedForUserId: data.cachedForUserId.present
          ? data.cachedForUserId.value
          : this.cachedForUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncMetaData(')
          ..write('syncKey: $syncKey, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('cachedForUserId: $cachedForUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(syncKey, cursor, lastSyncedAt, cachedForUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncMetaData &&
          other.syncKey == this.syncKey &&
          other.cursor == this.cursor &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.cachedForUserId == this.cachedForUserId);
}

class LocalSyncMetaCompanion extends UpdateCompanion<LocalSyncMetaData> {
  final Value<String> syncKey;
  final Value<String?> cursor;
  final Value<DateTime> lastSyncedAt;
  final Value<String> cachedForUserId;
  final Value<int> rowid;
  const LocalSyncMetaCompanion({
    this.syncKey = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.cachedForUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncMetaCompanion.insert({
    required String syncKey,
    this.cursor = const Value.absent(),
    required DateTime lastSyncedAt,
    required String cachedForUserId,
    this.rowid = const Value.absent(),
  }) : syncKey = Value(syncKey),
       lastSyncedAt = Value(lastSyncedAt),
       cachedForUserId = Value(cachedForUserId);
  static Insertable<LocalSyncMetaData> custom({
    Expression<String>? syncKey,
    Expression<String>? cursor,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? cachedForUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (syncKey != null) 'sync_key': syncKey,
      if (cursor != null) 'cursor': cursor,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (cachedForUserId != null) 'cached_for_user_id': cachedForUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncMetaCompanion copyWith({
    Value<String>? syncKey,
    Value<String?>? cursor,
    Value<DateTime>? lastSyncedAt,
    Value<String>? cachedForUserId,
    Value<int>? rowid,
  }) {
    return LocalSyncMetaCompanion(
      syncKey: syncKey ?? this.syncKey,
      cursor: cursor ?? this.cursor,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      cachedForUserId: cachedForUserId ?? this.cachedForUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncKey.present) {
      map['sync_key'] = Variable<String>(syncKey.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (cachedForUserId.present) {
      map['cached_for_user_id'] = Variable<String>(cachedForUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncMetaCompanion(')
          ..write('syncKey: $syncKey, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('cachedForUserId: $cachedForUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalTripsTable localTrips = $LocalTripsTable(this);
  late final $LocalMembersTable localMembers = $LocalMembersTable(this);
  late final $LocalWalletsTable localWallets = $LocalWalletsTable(this);
  late final $LocalContributionsTable localContributions =
      $LocalContributionsTable(this);
  late final $LocalExpensesTable localExpenses = $LocalExpensesTable(this);
  late final $LocalExpenseSplitsTable localExpenseSplits =
      $LocalExpenseSplitsTable(this);
  late final $LocalActivitiesTable localActivities = $LocalActivitiesTable(
    this,
  );
  late final $LocalNotificationsTable localNotifications =
      $LocalNotificationsTable(this);
  late final $LocalSyncMetaTable localSyncMeta = $LocalSyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTrips,
    localMembers,
    localWallets,
    localContributions,
    localExpenses,
    localExpenseSplits,
    localActivities,
    localNotifications,
    localSyncMeta,
  ];
}

typedef $$LocalTripsTableCreateCompanionBuilder = LocalTripsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<String?> destination,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<String> currency,
  required String adminId,
  Value<String> status,
  Value<String> settlementStatus,
  required String cachedForUserId,
  Value<int> rowid,
});
typedef $$LocalTripsTableUpdateCompanionBuilder = LocalTripsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String?> destination,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<String> currency,
  Value<String> adminId,
  Value<String> status,
  Value<String> settlementStatus,
  Value<String> cachedForUserId,
  Value<int> rowid,
});

class $$LocalTripsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adminId => $composableBuilder(
    column: $table.adminId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settlementStatus => $composableBuilder(
    column: $table.settlementStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTripsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adminId => $composableBuilder(
    column: $table.adminId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settlementStatus => $composableBuilder(
    column: $table.settlementStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get adminId =>
      $composableBuilder(column: $table.adminId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get settlementStatus => $composableBuilder(
    column: $table.settlementStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );
}

class $$LocalTripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTripsTable,
          LocalTrip,
          $$LocalTripsTableFilterComposer,
          $$LocalTripsTableOrderingComposer,
          $$LocalTripsTableAnnotationComposer,
          $$LocalTripsTableCreateCompanionBuilder,
          $$LocalTripsTableUpdateCompanionBuilder,
          (
            LocalTrip,
            BaseReferences<_$AppDatabase, $LocalTripsTable, LocalTrip>,
          ),
          LocalTrip,
          PrefetchHooks Function()
        > {
  $$LocalTripsTableTableManager(_$AppDatabase db, $LocalTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> adminId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> settlementStatus = const Value.absent(),
                Value<String> cachedForUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion(
                id: id,
                name: name,
                description: description,
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                currency: currency,
                adminId: adminId,
                status: status,
                settlementStatus: settlementStatus,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> currency = const Value.absent(),
                required String adminId,
                Value<String> status = const Value.absent(),
                Value<String> settlementStatus = const Value.absent(),
                required String cachedForUserId,
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion.insert(
                id: id,
                name: name,
                description: description,
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                currency: currency,
                adminId: adminId,
                status: status,
                settlementStatus: settlementStatus,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalTripsTable, LocalTrip>(table),
                  BaseReferences<_$AppDatabase, $LocalTripsTable, LocalTrip>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTripsTable,
      LocalTrip,
      $$LocalTripsTableFilterComposer,
      $$LocalTripsTableOrderingComposer,
      $$LocalTripsTableAnnotationComposer,
      $$LocalTripsTableCreateCompanionBuilder,
      $$LocalTripsTableUpdateCompanionBuilder,
      (LocalTrip, BaseReferences<_$AppDatabase, $LocalTripsTable, LocalTrip>),
      LocalTrip,
      PrefetchHooks Function()
    >;
typedef $$LocalMembersTableCreateCompanionBuilder =
    LocalMembersCompanion Function({
      required String id,
      required String tripId,
      required String userId,
      required String name,
      required String email,
      required String role,
      required String status,
      Value<DateTime?> joinedAt,
      required String cachedForUserId,
      Value<int> rowid,
    });
typedef $$LocalMembersTableUpdateCompanionBuilder =
    LocalMembersCompanion Function({
      Value<String> id,
      Value<String> tripId,
      Value<String> userId,
      Value<String> name,
      Value<String> email,
      Value<String> role,
      Value<String> status,
      Value<DateTime?> joinedAt,
      Value<String> cachedForUserId,
      Value<int> rowid,
    });

class $$LocalMembersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMembersTable> {
  $$LocalMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMembersTable> {
  $$LocalMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMembersTable> {
  $$LocalMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );
}

class $$LocalMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMembersTable,
          LocalMember,
          $$LocalMembersTableFilterComposer,
          $$LocalMembersTableOrderingComposer,
          $$LocalMembersTableAnnotationComposer,
          $$LocalMembersTableCreateCompanionBuilder,
          $$LocalMembersTableUpdateCompanionBuilder,
          (
            LocalMember,
            BaseReferences<_$AppDatabase, $LocalMembersTable, LocalMember>,
          ),
          LocalMember,
          PrefetchHooks Function()
        > {
  $$LocalMembersTableTableManager(_$AppDatabase db, $LocalMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> joinedAt = const Value.absent(),
                Value<String> cachedForUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMembersCompanion(
                id: id,
                tripId: tripId,
                userId: userId,
                name: name,
                email: email,
                role: role,
                status: status,
                joinedAt: joinedAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String userId,
                required String name,
                required String email,
                required String role,
                required String status,
                Value<DateTime?> joinedAt = const Value.absent(),
                required String cachedForUserId,
                Value<int> rowid = const Value.absent(),
              }) => LocalMembersCompanion.insert(
                id: id,
                tripId: tripId,
                userId: userId,
                name: name,
                email: email,
                role: role,
                status: status,
                joinedAt: joinedAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMembersTable, LocalMember>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalMembersTable,
                    LocalMember
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMembersTable,
      LocalMember,
      $$LocalMembersTableFilterComposer,
      $$LocalMembersTableOrderingComposer,
      $$LocalMembersTableAnnotationComposer,
      $$LocalMembersTableCreateCompanionBuilder,
      $$LocalMembersTableUpdateCompanionBuilder,
      (
        LocalMember,
        BaseReferences<_$AppDatabase, $LocalMembersTable, LocalMember>,
      ),
      LocalMember,
      PrefetchHooks Function()
    >;
typedef $$LocalWalletsTableCreateCompanionBuilder =
    LocalWalletsCompanion Function({
      required String tripId,
      Value<String> currency,
      Value<int> balancePaise,
      Value<int> totalContributionsPaise,
      Value<int> totalExpensesPaise,
      Value<int> transactionCount,
      required String cachedForUserId,
      Value<int> rowid,
    });
typedef $$LocalWalletsTableUpdateCompanionBuilder =
    LocalWalletsCompanion Function({
      Value<String> tripId,
      Value<String> currency,
      Value<int> balancePaise,
      Value<int> totalContributionsPaise,
      Value<int> totalExpensesPaise,
      Value<int> transactionCount,
      Value<String> cachedForUserId,
      Value<int> rowid,
    });

class $$LocalWalletsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalWalletsTable> {
  $$LocalWalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balancePaise => $composableBuilder(
    column: $table.balancePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalContributionsPaise => $composableBuilder(
    column: $table.totalContributionsPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalExpensesPaise => $composableBuilder(
    column: $table.totalExpensesPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalWalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalWalletsTable> {
  $$LocalWalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balancePaise => $composableBuilder(
    column: $table.balancePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalContributionsPaise => $composableBuilder(
    column: $table.totalContributionsPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalExpensesPaise => $composableBuilder(
    column: $table.totalExpensesPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalWalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalWalletsTable> {
  $$LocalWalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get balancePaise => $composableBuilder(
    column: $table.balancePaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalContributionsPaise => $composableBuilder(
    column: $table.totalContributionsPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalExpensesPaise => $composableBuilder(
    column: $table.totalExpensesPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionCount => $composableBuilder(
    column: $table.transactionCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );
}

class $$LocalWalletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalWalletsTable,
          LocalWallet,
          $$LocalWalletsTableFilterComposer,
          $$LocalWalletsTableOrderingComposer,
          $$LocalWalletsTableAnnotationComposer,
          $$LocalWalletsTableCreateCompanionBuilder,
          $$LocalWalletsTableUpdateCompanionBuilder,
          (
            LocalWallet,
            BaseReferences<_$AppDatabase, $LocalWalletsTable, LocalWallet>,
          ),
          LocalWallet,
          PrefetchHooks Function()
        > {
  $$LocalWalletsTableTableManager(_$AppDatabase db, $LocalWalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalWalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tripId = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> balancePaise = const Value.absent(),
                Value<int> totalContributionsPaise = const Value.absent(),
                Value<int> totalExpensesPaise = const Value.absent(),
                Value<int> transactionCount = const Value.absent(),
                Value<String> cachedForUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWalletsCompanion(
                tripId: tripId,
                currency: currency,
                balancePaise: balancePaise,
                totalContributionsPaise: totalContributionsPaise,
                totalExpensesPaise: totalExpensesPaise,
                transactionCount: transactionCount,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tripId,
                Value<String> currency = const Value.absent(),
                Value<int> balancePaise = const Value.absent(),
                Value<int> totalContributionsPaise = const Value.absent(),
                Value<int> totalExpensesPaise = const Value.absent(),
                Value<int> transactionCount = const Value.absent(),
                required String cachedForUserId,
                Value<int> rowid = const Value.absent(),
              }) => LocalWalletsCompanion.insert(
                tripId: tripId,
                currency: currency,
                balancePaise: balancePaise,
                totalContributionsPaise: totalContributionsPaise,
                totalExpensesPaise: totalExpensesPaise,
                transactionCount: transactionCount,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalWalletsTable, LocalWallet>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalWalletsTable,
                    LocalWallet
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalWalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalWalletsTable,
      LocalWallet,
      $$LocalWalletsTableFilterComposer,
      $$LocalWalletsTableOrderingComposer,
      $$LocalWalletsTableAnnotationComposer,
      $$LocalWalletsTableCreateCompanionBuilder,
      $$LocalWalletsTableUpdateCompanionBuilder,
      (
        LocalWallet,
        BaseReferences<_$AppDatabase, $LocalWalletsTable, LocalWallet>,
      ),
      LocalWallet,
      PrefetchHooks Function()
    >;
typedef $$LocalContributionsTableCreateCompanionBuilder =
    LocalContributionsCompanion Function({
      required String id,
      required String tripId,
      required String memberId,
      required int amountPaise,
      Value<String> paymentMethod,
      Value<String> status,
      Value<String?> note,
      required DateTime createdAt,
      required String cachedForUserId,
      Value<int> rowid,
    });
typedef $$LocalContributionsTableUpdateCompanionBuilder =
    LocalContributionsCompanion Function({
      Value<String> id,
      Value<String> tripId,
      Value<String> memberId,
      Value<int> amountPaise,
      Value<String> paymentMethod,
      Value<String> status,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<String> cachedForUserId,
      Value<int> rowid,
    });

class $$LocalContributionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalContributionsTable> {
  $$LocalContributionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalContributionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalContributionsTable> {
  $$LocalContributionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalContributionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalContributionsTable> {
  $$LocalContributionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );
}

class $$LocalContributionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalContributionsTable,
          LocalContribution,
          $$LocalContributionsTableFilterComposer,
          $$LocalContributionsTableOrderingComposer,
          $$LocalContributionsTableAnnotationComposer,
          $$LocalContributionsTableCreateCompanionBuilder,
          $$LocalContributionsTableUpdateCompanionBuilder,
          (
            LocalContribution,
            BaseReferences<
              _$AppDatabase,
              $LocalContributionsTable,
              LocalContribution
            >,
          ),
          LocalContribution,
          PrefetchHooks Function()
        > {
  $$LocalContributionsTableTableManager(
    _$AppDatabase db,
    $LocalContributionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalContributionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalContributionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalContributionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> cachedForUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalContributionsCompanion(
                id: id,
                tripId: tripId,
                memberId: memberId,
                amountPaise: amountPaise,
                paymentMethod: paymentMethod,
                status: status,
                note: note,
                createdAt: createdAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String memberId,
                required int amountPaise,
                Value<String> paymentMethod = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required String cachedForUserId,
                Value<int> rowid = const Value.absent(),
              }) => LocalContributionsCompanion.insert(
                id: id,
                tripId: tripId,
                memberId: memberId,
                amountPaise: amountPaise,
                paymentMethod: paymentMethod,
                status: status,
                note: note,
                createdAt: createdAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalContributionsTable, LocalContribution>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalContributionsTable,
                    LocalContribution
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalContributionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalContributionsTable,
      LocalContribution,
      $$LocalContributionsTableFilterComposer,
      $$LocalContributionsTableOrderingComposer,
      $$LocalContributionsTableAnnotationComposer,
      $$LocalContributionsTableCreateCompanionBuilder,
      $$LocalContributionsTableUpdateCompanionBuilder,
      (
        LocalContribution,
        BaseReferences<
          _$AppDatabase,
          $LocalContributionsTable,
          LocalContribution
        >,
      ),
      LocalContribution,
      PrefetchHooks Function()
    >;
typedef $$LocalExpensesTableCreateCompanionBuilder =
    LocalExpensesCompanion Function({
      required String id,
      required String tripId,
      required String walletId,
      required String paidBy,
      required int amountPaise,
      required String category,
      Value<String?> description,
      Value<String> splitMode,
      Value<String> status,
      required DateTime createdAt,
      required String cachedForUserId,
      Value<int> rowid,
    });
typedef $$LocalExpensesTableUpdateCompanionBuilder =
    LocalExpensesCompanion Function({
      Value<String> id,
      Value<String> tripId,
      Value<String> walletId,
      Value<String> paidBy,
      Value<int> amountPaise,
      Value<String> category,
      Value<String?> description,
      Value<String> splitMode,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<String> cachedForUserId,
      Value<int> rowid,
    });

class $$LocalExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get walletId => $composableBuilder(
    column: $table.walletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paidBy => $composableBuilder(
    column: $table.paidBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitMode => $composableBuilder(
    column: $table.splitMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get walletId => $composableBuilder(
    column: $table.walletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paidBy => $composableBuilder(
    column: $table.paidBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitMode => $composableBuilder(
    column: $table.splitMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExpensesTable> {
  $$LocalExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get walletId =>
      $composableBuilder(column: $table.walletId, builder: (column) => column);

  GeneratedColumn<String> get paidBy =>
      $composableBuilder(column: $table.paidBy, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get splitMode =>
      $composableBuilder(column: $table.splitMode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );
}

class $$LocalExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalExpensesTable,
          LocalExpense,
          $$LocalExpensesTableFilterComposer,
          $$LocalExpensesTableOrderingComposer,
          $$LocalExpensesTableAnnotationComposer,
          $$LocalExpensesTableCreateCompanionBuilder,
          $$LocalExpensesTableUpdateCompanionBuilder,
          (
            LocalExpense,
            BaseReferences<_$AppDatabase, $LocalExpensesTable, LocalExpense>,
          ),
          LocalExpense,
          PrefetchHooks Function()
        > {
  $$LocalExpensesTableTableManager(_$AppDatabase db, $LocalExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> walletId = const Value.absent(),
                Value<String> paidBy = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> splitMode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> cachedForUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExpensesCompanion(
                id: id,
                tripId: tripId,
                walletId: walletId,
                paidBy: paidBy,
                amountPaise: amountPaise,
                category: category,
                description: description,
                splitMode: splitMode,
                status: status,
                createdAt: createdAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String walletId,
                required String paidBy,
                required int amountPaise,
                required String category,
                Value<String?> description = const Value.absent(),
                Value<String> splitMode = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                required String cachedForUserId,
                Value<int> rowid = const Value.absent(),
              }) => LocalExpensesCompanion.insert(
                id: id,
                tripId: tripId,
                walletId: walletId,
                paidBy: paidBy,
                amountPaise: amountPaise,
                category: category,
                description: description,
                splitMode: splitMode,
                status: status,
                createdAt: createdAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalExpensesTable, LocalExpense>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalExpensesTable,
                    LocalExpense
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalExpensesTable,
      LocalExpense,
      $$LocalExpensesTableFilterComposer,
      $$LocalExpensesTableOrderingComposer,
      $$LocalExpensesTableAnnotationComposer,
      $$LocalExpensesTableCreateCompanionBuilder,
      $$LocalExpensesTableUpdateCompanionBuilder,
      (
        LocalExpense,
        BaseReferences<_$AppDatabase, $LocalExpensesTable, LocalExpense>,
      ),
      LocalExpense,
      PrefetchHooks Function()
    >;
typedef $$LocalExpenseSplitsTableCreateCompanionBuilder =
    LocalExpenseSplitsCompanion Function({
      required String id,
      required String expenseId,
      required String memberId,
      required int amountPaise,
      required String cachedForUserId,
      Value<int> rowid,
    });
typedef $$LocalExpenseSplitsTableUpdateCompanionBuilder =
    LocalExpenseSplitsCompanion Function({
      Value<String> id,
      Value<String> expenseId,
      Value<String> memberId,
      Value<int> amountPaise,
      Value<String> cachedForUserId,
      Value<int> rowid,
    });

class $$LocalExpenseSplitsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExpenseSplitsTable> {
  $$LocalExpenseSplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalExpenseSplitsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExpenseSplitsTable> {
  $$LocalExpenseSplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalExpenseSplitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExpenseSplitsTable> {
  $$LocalExpenseSplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );
}

class $$LocalExpenseSplitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalExpenseSplitsTable,
          LocalExpenseSplit,
          $$LocalExpenseSplitsTableFilterComposer,
          $$LocalExpenseSplitsTableOrderingComposer,
          $$LocalExpenseSplitsTableAnnotationComposer,
          $$LocalExpenseSplitsTableCreateCompanionBuilder,
          $$LocalExpenseSplitsTableUpdateCompanionBuilder,
          (
            LocalExpenseSplit,
            BaseReferences<
              _$AppDatabase,
              $LocalExpenseSplitsTable,
              LocalExpenseSplit
            >,
          ),
          LocalExpenseSplit,
          PrefetchHooks Function()
        > {
  $$LocalExpenseSplitsTableTableManager(
    _$AppDatabase db,
    $LocalExpenseSplitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExpenseSplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalExpenseSplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalExpenseSplitsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> cachedForUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalExpenseSplitsCompanion(
                id: id,
                expenseId: expenseId,
                memberId: memberId,
                amountPaise: amountPaise,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String expenseId,
                required String memberId,
                required int amountPaise,
                required String cachedForUserId,
                Value<int> rowid = const Value.absent(),
              }) => LocalExpenseSplitsCompanion.insert(
                id: id,
                expenseId: expenseId,
                memberId: memberId,
                amountPaise: amountPaise,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalExpenseSplitsTable, LocalExpenseSplit>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalExpenseSplitsTable,
                    LocalExpenseSplit
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalExpenseSplitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalExpenseSplitsTable,
      LocalExpenseSplit,
      $$LocalExpenseSplitsTableFilterComposer,
      $$LocalExpenseSplitsTableOrderingComposer,
      $$LocalExpenseSplitsTableAnnotationComposer,
      $$LocalExpenseSplitsTableCreateCompanionBuilder,
      $$LocalExpenseSplitsTableUpdateCompanionBuilder,
      (
        LocalExpenseSplit,
        BaseReferences<
          _$AppDatabase,
          $LocalExpenseSplitsTable,
          LocalExpenseSplit
        >,
      ),
      LocalExpenseSplit,
      PrefetchHooks Function()
    >;
typedef $$LocalActivitiesTableCreateCompanionBuilder =
    LocalActivitiesCompanion Function({
      required String id,
      required String tripId,
      required String actorUserId,
      Value<String?> actorName,
      required String eventType,
      Value<String?> entityType,
      Value<String?> entityId,
      required String message,
      Value<String?> metadataJson,
      required DateTime createdAt,
      required String cachedForUserId,
      Value<int> rowid,
    });
typedef $$LocalActivitiesTableUpdateCompanionBuilder =
    LocalActivitiesCompanion Function({
      Value<String> id,
      Value<String> tripId,
      Value<String> actorUserId,
      Value<String?> actorName,
      Value<String> eventType,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<String> message,
      Value<String?> metadataJson,
      Value<DateTime> createdAt,
      Value<String> cachedForUserId,
      Value<int> rowid,
    });

class $$LocalActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalActivitiesTable> {
  $$LocalActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorName => $composableBuilder(
    column: $table.actorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalActivitiesTable> {
  $$LocalActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorName => $composableBuilder(
    column: $table.actorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalActivitiesTable> {
  $$LocalActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorName =>
      $composableBuilder(column: $table.actorName, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );
}

class $$LocalActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalActivitiesTable,
          LocalActivity,
          $$LocalActivitiesTableFilterComposer,
          $$LocalActivitiesTableOrderingComposer,
          $$LocalActivitiesTableAnnotationComposer,
          $$LocalActivitiesTableCreateCompanionBuilder,
          $$LocalActivitiesTableUpdateCompanionBuilder,
          (
            LocalActivity,
            BaseReferences<_$AppDatabase, $LocalActivitiesTable, LocalActivity>,
          ),
          LocalActivity,
          PrefetchHooks Function()
        > {
  $$LocalActivitiesTableTableManager(
    _$AppDatabase db,
    $LocalActivitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> actorUserId = const Value.absent(),
                Value<String?> actorName = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> cachedForUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalActivitiesCompanion(
                id: id,
                tripId: tripId,
                actorUserId: actorUserId,
                actorName: actorName,
                eventType: eventType,
                entityType: entityType,
                entityId: entityId,
                message: message,
                metadataJson: metadataJson,
                createdAt: createdAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String actorUserId,
                Value<String?> actorName = const Value.absent(),
                required String eventType,
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                required String message,
                Value<String?> metadataJson = const Value.absent(),
                required DateTime createdAt,
                required String cachedForUserId,
                Value<int> rowid = const Value.absent(),
              }) => LocalActivitiesCompanion.insert(
                id: id,
                tripId: tripId,
                actorUserId: actorUserId,
                actorName: actorName,
                eventType: eventType,
                entityType: entityType,
                entityId: entityId,
                message: message,
                metadataJson: metadataJson,
                createdAt: createdAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalActivitiesTable, LocalActivity>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalActivitiesTable,
                    LocalActivity
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalActivitiesTable,
      LocalActivity,
      $$LocalActivitiesTableFilterComposer,
      $$LocalActivitiesTableOrderingComposer,
      $$LocalActivitiesTableAnnotationComposer,
      $$LocalActivitiesTableCreateCompanionBuilder,
      $$LocalActivitiesTableUpdateCompanionBuilder,
      (
        LocalActivity,
        BaseReferences<_$AppDatabase, $LocalActivitiesTable, LocalActivity>,
      ),
      LocalActivity,
      PrefetchHooks Function()
    >;
typedef $$LocalNotificationsTableCreateCompanionBuilder =
    LocalNotificationsCompanion Function({
      required String id,
      required String userId,
      Value<String?> tripId,
      required String notificationType,
      required String title,
      required String body,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<bool> isRead,
      Value<DateTime?> readAt,
      required DateTime createdAt,
      required String cachedForUserId,
      Value<int> rowid,
    });
typedef $$LocalNotificationsTableUpdateCompanionBuilder =
    LocalNotificationsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> tripId,
      Value<String> notificationType,
      Value<String> title,
      Value<String> body,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<bool> isRead,
      Value<DateTime?> readAt,
      Value<DateTime> createdAt,
      Value<String> cachedForUserId,
      Value<int> rowid,
    });

class $$LocalNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalNotificationsTable> {
  $$LocalNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationType => $composableBuilder(
    column: $table.notificationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalNotificationsTable> {
  $$LocalNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationType => $composableBuilder(
    column: $table.notificationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalNotificationsTable> {
  $$LocalNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get notificationType => $composableBuilder(
    column: $table.notificationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );
}

class $$LocalNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalNotificationsTable,
          LocalNotification,
          $$LocalNotificationsTableFilterComposer,
          $$LocalNotificationsTableOrderingComposer,
          $$LocalNotificationsTableAnnotationComposer,
          $$LocalNotificationsTableCreateCompanionBuilder,
          $$LocalNotificationsTableUpdateCompanionBuilder,
          (
            LocalNotification,
            BaseReferences<
              _$AppDatabase,
              $LocalNotificationsTable,
              LocalNotification
            >,
          ),
          LocalNotification,
          PrefetchHooks Function()
        > {
  $$LocalNotificationsTableTableManager(
    _$AppDatabase db,
    $LocalNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalNotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<String> notificationType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> cachedForUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalNotificationsCompanion(
                id: id,
                userId: userId,
                tripId: tripId,
                notificationType: notificationType,
                title: title,
                body: body,
                entityType: entityType,
                entityId: entityId,
                isRead: isRead,
                readAt: readAt,
                createdAt: createdAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> tripId = const Value.absent(),
                required String notificationType,
                required String title,
                required String body,
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                required DateTime createdAt,
                required String cachedForUserId,
                Value<int> rowid = const Value.absent(),
              }) => LocalNotificationsCompanion.insert(
                id: id,
                userId: userId,
                tripId: tripId,
                notificationType: notificationType,
                title: title,
                body: body,
                entityType: entityType,
                entityId: entityId,
                isRead: isRead,
                readAt: readAt,
                createdAt: createdAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalNotificationsTable, LocalNotification>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalNotificationsTable,
                    LocalNotification
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalNotificationsTable,
      LocalNotification,
      $$LocalNotificationsTableFilterComposer,
      $$LocalNotificationsTableOrderingComposer,
      $$LocalNotificationsTableAnnotationComposer,
      $$LocalNotificationsTableCreateCompanionBuilder,
      $$LocalNotificationsTableUpdateCompanionBuilder,
      (
        LocalNotification,
        BaseReferences<
          _$AppDatabase,
          $LocalNotificationsTable,
          LocalNotification
        >,
      ),
      LocalNotification,
      PrefetchHooks Function()
    >;
typedef $$LocalSyncMetaTableCreateCompanionBuilder =
    LocalSyncMetaCompanion Function({
      required String syncKey,
      Value<String?> cursor,
      required DateTime lastSyncedAt,
      required String cachedForUserId,
      Value<int> rowid,
    });
typedef $$LocalSyncMetaTableUpdateCompanionBuilder =
    LocalSyncMetaCompanion Function({
      Value<String> syncKey,
      Value<String?> cursor,
      Value<DateTime> lastSyncedAt,
      Value<String> cachedForUserId,
      Value<int> rowid,
    });

class $$LocalSyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSyncMetaTable> {
  $$LocalSyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncKey => $composableBuilder(
    column: $table.syncKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSyncMetaTable> {
  $$LocalSyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncKey => $composableBuilder(
    column: $table.syncKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSyncMetaTable> {
  $$LocalSyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncKey =>
      $composableBuilder(column: $table.syncKey, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cachedForUserId => $composableBuilder(
    column: $table.cachedForUserId,
    builder: (column) => column,
  );
}

class $$LocalSyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSyncMetaTable,
          LocalSyncMetaData,
          $$LocalSyncMetaTableFilterComposer,
          $$LocalSyncMetaTableOrderingComposer,
          $$LocalSyncMetaTableAnnotationComposer,
          $$LocalSyncMetaTableCreateCompanionBuilder,
          $$LocalSyncMetaTableUpdateCompanionBuilder,
          (
            LocalSyncMetaData,
            BaseReferences<
              _$AppDatabase,
              $LocalSyncMetaTable,
              LocalSyncMetaData
            >,
          ),
          LocalSyncMetaData,
          PrefetchHooks Function()
        > {
  $$LocalSyncMetaTableTableManager(_$AppDatabase db, $LocalSyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> syncKey = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<String> cachedForUserId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncMetaCompanion(
                syncKey: syncKey,
                cursor: cursor,
                lastSyncedAt: lastSyncedAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String syncKey,
                Value<String?> cursor = const Value.absent(),
                required DateTime lastSyncedAt,
                required String cachedForUserId,
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncMetaCompanion.insert(
                syncKey: syncKey,
                cursor: cursor,
                lastSyncedAt: lastSyncedAt,
                cachedForUserId: cachedForUserId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSyncMetaTable, LocalSyncMetaData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSyncMetaTable,
                    LocalSyncMetaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSyncMetaTable,
      LocalSyncMetaData,
      $$LocalSyncMetaTableFilterComposer,
      $$LocalSyncMetaTableOrderingComposer,
      $$LocalSyncMetaTableAnnotationComposer,
      $$LocalSyncMetaTableCreateCompanionBuilder,
      $$LocalSyncMetaTableUpdateCompanionBuilder,
      (
        LocalSyncMetaData,
        BaseReferences<_$AppDatabase, $LocalSyncMetaTable, LocalSyncMetaData>,
      ),
      LocalSyncMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalTripsTableTableManager get localTrips =>
      $$LocalTripsTableTableManager(_db, _db.localTrips);
  $$LocalMembersTableTableManager get localMembers =>
      $$LocalMembersTableTableManager(_db, _db.localMembers);
  $$LocalWalletsTableTableManager get localWallets =>
      $$LocalWalletsTableTableManager(_db, _db.localWallets);
  $$LocalContributionsTableTableManager get localContributions =>
      $$LocalContributionsTableTableManager(_db, _db.localContributions);
  $$LocalExpensesTableTableManager get localExpenses =>
      $$LocalExpensesTableTableManager(_db, _db.localExpenses);
  $$LocalExpenseSplitsTableTableManager get localExpenseSplits =>
      $$LocalExpenseSplitsTableTableManager(_db, _db.localExpenseSplits);
  $$LocalActivitiesTableTableManager get localActivities =>
      $$LocalActivitiesTableTableManager(_db, _db.localActivities);
  $$LocalNotificationsTableTableManager get localNotifications =>
      $$LocalNotificationsTableTableManager(_db, _db.localNotifications);
  $$LocalSyncMetaTableTableManager get localSyncMeta =>
      $$LocalSyncMetaTableTableManager(_db, _db.localSyncMeta);
}
