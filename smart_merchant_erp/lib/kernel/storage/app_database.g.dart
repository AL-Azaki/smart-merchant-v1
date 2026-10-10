// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, UserAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 5,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    passwordHash,
    firstName,
    lastName,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTableTable createAlias(String alias) {
    return $UsersTableTable(attachedDatabase, alias);
  }
}

class UserAccount extends DataClass implements Insertable<UserAccount> {
  final String id;
  final String email;
  final String passwordHash;
  final String firstName;
  final String lastName;
  final bool isActive;
  final DateTime createdAt;
  const UserAccount({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersTableCompanion toCompanion(bool nullToAbsent) {
    return UsersTableCompanion(
      id: Value(id),
      email: Value(email),
      passwordHash: Value(passwordHash),
      firstName: Value(firstName),
      lastName: Value(lastName),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory UserAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserAccount(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserAccount copyWith({
    String? id,
    String? email,
    String? passwordHash,
    String? firstName,
    String? lastName,
    bool? isActive,
    DateTime? createdAt,
  }) => UserAccount(
    id: id ?? this.id,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  UserAccount copyWithCompanion(UsersTableCompanion data) {
    return UserAccount(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserAccount(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    passwordHash,
    firstName,
    lastName,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserAccount &&
          other.id == this.id &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class UsersTableCompanion extends UpdateCompanion<UserAccount> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UsersTableCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersTableCompanion.insert({
    this.id = const Value.absent(),
    required String email,
    required String passwordHash,
    required String firstName,
    required String lastName,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : email = Value(email),
       passwordHash = Value(passwordHash),
       firstName = Value(firstName),
       lastName = Value(lastName);
  static Insertable<UserAccount> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? passwordHash,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UsersTableCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTableTable extends AccountsTable
    with TableInfo<$AccountsTableTable, BusinessAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users_table (id)',
    ),
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessTypeMeta = const VerificationMeta(
    'businessType',
  );
  @override
  late final GeneratedColumn<String> businessType = GeneratedColumn<String>(
    'business_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultCurrencyMeta = const VerificationMeta(
    'defaultCurrency',
  );
  @override
  late final GeneratedColumn<String> defaultCurrency = GeneratedColumn<String>(
    'default_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    businessName,
    businessType,
    defaultCurrency,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('business_type')) {
      context.handle(
        _businessTypeMeta,
        businessType.isAcceptableOrUnknown(
          data['business_type']!,
          _businessTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessTypeMeta);
    }
    if (data.containsKey('default_currency')) {
      context.handle(
        _defaultCurrencyMeta,
        defaultCurrency.isAcceptableOrUnknown(
          data['default_currency']!,
          _defaultCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultCurrencyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      businessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_type'],
      )!,
      defaultCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_currency'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountsTableTable createAlias(String alias) {
    return $AccountsTableTable(attachedDatabase, alias);
  }
}

class BusinessAccount extends DataClass implements Insertable<BusinessAccount> {
  final String id;
  final String ownerId;
  final String businessName;
  final String businessType;
  final String defaultCurrency;
  final DateTime createdAt;
  const BusinessAccount({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.businessType,
    required this.defaultCurrency,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['business_name'] = Variable<String>(businessName);
    map['business_type'] = Variable<String>(businessType);
    map['default_currency'] = Variable<String>(defaultCurrency);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsTableCompanion toCompanion(bool nullToAbsent) {
    return AccountsTableCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      businessName: Value(businessName),
      businessType: Value(businessType),
      defaultCurrency: Value(defaultCurrency),
      createdAt: Value(createdAt),
    );
  }

  factory BusinessAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessAccount(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      businessName: serializer.fromJson<String>(json['businessName']),
      businessType: serializer.fromJson<String>(json['businessType']),
      defaultCurrency: serializer.fromJson<String>(json['defaultCurrency']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'businessName': serializer.toJson<String>(businessName),
      'businessType': serializer.toJson<String>(businessType),
      'defaultCurrency': serializer.toJson<String>(defaultCurrency),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BusinessAccount copyWith({
    String? id,
    String? ownerId,
    String? businessName,
    String? businessType,
    String? defaultCurrency,
    DateTime? createdAt,
  }) => BusinessAccount(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    businessName: businessName ?? this.businessName,
    businessType: businessType ?? this.businessType,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    createdAt: createdAt ?? this.createdAt,
  );
  BusinessAccount copyWithCompanion(AccountsTableCompanion data) {
    return BusinessAccount(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      businessType: data.businessType.present
          ? data.businessType.value
          : this.businessType,
      defaultCurrency: data.defaultCurrency.present
          ? data.defaultCurrency.value
          : this.defaultCurrency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessAccount(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('businessName: $businessName, ')
          ..write('businessType: $businessType, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    businessName,
    businessType,
    defaultCurrency,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessAccount &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.businessName == this.businessName &&
          other.businessType == this.businessType &&
          other.defaultCurrency == this.defaultCurrency &&
          other.createdAt == this.createdAt);
}

class AccountsTableCompanion extends UpdateCompanion<BusinessAccount> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> businessName;
  final Value<String> businessType;
  final Value<String> defaultCurrency;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsTableCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.businessName = const Value.absent(),
    this.businessType = const Value.absent(),
    this.defaultCurrency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsTableCompanion.insert({
    this.id = const Value.absent(),
    required String ownerId,
    required String businessName,
    required String businessType,
    required String defaultCurrency,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       businessName = Value(businessName),
       businessType = Value(businessType),
       defaultCurrency = Value(defaultCurrency);
  static Insertable<BusinessAccount> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? businessName,
    Expression<String>? businessType,
    Expression<String>? defaultCurrency,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (businessName != null) 'business_name': businessName,
      if (businessType != null) 'business_type': businessType,
      if (defaultCurrency != null) 'default_currency': defaultCurrency,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? businessName,
    Value<String>? businessType,
    Value<String>? defaultCurrency,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AccountsTableCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (businessType.present) {
      map['business_type'] = Variable<String>(businessType.value);
    }
    if (defaultCurrency.present) {
      map['default_currency'] = Variable<String>(defaultCurrency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsTableCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('businessName: $businessName, ')
          ..write('businessType: $businessType, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTableTable extends SubscriptionsTable
    with TableInfo<$SubscriptionsTableTable, SubscriptionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts_table (id)',
    ),
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
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    status,
    planId,
    startDate,
    endDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubscriptionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
    );
  }

  @override
  $SubscriptionsTableTable createAlias(String alias) {
    return $SubscriptionsTableTable(attachedDatabase, alias);
  }
}

class SubscriptionData extends DataClass
    implements Insertable<SubscriptionData> {
  final String id;
  final String accountId;
  final String status;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  const SubscriptionData({
    required this.id,
    required this.accountId,
    required this.status,
    required this.planId,
    required this.startDate,
    required this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['status'] = Variable<String>(status);
    map['plan_id'] = Variable<String>(planId);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    return map;
  }

  SubscriptionsTableCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsTableCompanion(
      id: Value(id),
      accountId: Value(accountId),
      status: Value(status),
      planId: Value(planId),
      startDate: Value(startDate),
      endDate: Value(endDate),
    );
  }

  factory SubscriptionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionData(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      status: serializer.fromJson<String>(json['status']),
      planId: serializer.fromJson<String>(json['planId']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'status': serializer.toJson<String>(status),
      'planId': serializer.toJson<String>(planId),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
    };
  }

  SubscriptionData copyWith({
    String? id,
    String? accountId,
    String? status,
    String? planId,
    DateTime? startDate,
    DateTime? endDate,
  }) => SubscriptionData(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    status: status ?? this.status,
    planId: planId ?? this.planId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
  );
  SubscriptionData copyWithCompanion(SubscriptionsTableCompanion data) {
    return SubscriptionData(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      status: data.status.present ? data.status.value : this.status,
      planId: data.planId.present ? data.planId.value : this.planId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionData(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('status: $status, ')
          ..write('planId: $planId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, accountId, status, planId, startDate, endDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionData &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.status == this.status &&
          other.planId == this.planId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class SubscriptionsTableCompanion extends UpdateCompanion<SubscriptionData> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> status;
  final Value<String> planId;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<int> rowid;
  const SubscriptionsTableCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.status = const Value.absent(),
    this.planId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsTableCompanion.insert({
    this.id = const Value.absent(),
    required String accountId,
    required String status,
    required String planId,
    required DateTime startDate,
    required DateTime endDate,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       status = Value(status),
       planId = Value(planId),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<SubscriptionData> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? status,
    Expression<String>? planId,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (status != null) 'status': status,
      if (planId != null) 'plan_id': planId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? status,
    Value<String>? planId,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<int>? rowid,
  }) {
    return SubscriptionsTableCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      status: status ?? this.status,
      planId: planId ?? this.planId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsTableCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('status: $status, ')
          ..write('planId: $planId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTableTable extends CustomersTable
    with TableInfo<$CustomersTableTable, CustomerModel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 30),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
    'credit_limit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _defaultCurrencyIdMeta = const VerificationMeta(
    'defaultCurrencyId',
  );
  @override
  late final GeneratedColumn<String> defaultCurrencyId =
      GeneratedColumn<String>(
        'default_currency_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<double> openingBalance = GeneratedColumn<double>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _openingBalanceTypeMeta =
      const VerificationMeta('openingBalanceType');
  @override
  late final GeneratedColumn<String> openingBalanceType =
      GeneratedColumn<String>(
        'opening_balance_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    customerName,
    phone,
    email,
    address,
    creditLimit,
    defaultCurrencyId,
    openingBalance,
    openingBalanceType,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerModel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('default_currency_id')) {
      context.handle(
        _defaultCurrencyIdMeta,
        defaultCurrencyId.isAcceptableOrUnknown(
          data['default_currency_id']!,
          _defaultCurrencyIdMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance_type')) {
      context.handle(
        _openingBalanceTypeMeta,
        openingBalanceType.isAcceptableOrUnknown(
          data['opening_balance_type']!,
          _openingBalanceTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerModel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerModel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      )!,
      defaultCurrencyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_currency_id'],
      ),
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opening_balance'],
      )!,
      openingBalanceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_balance_type'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CustomersTableTable createAlias(String alias) {
    return $CustomersTableTable(attachedDatabase, alias);
  }
}

class CustomerModel extends DataClass implements Insertable<CustomerModel> {
  final String id;
  final String businessId;
  final String customerName;
  final String? phone;
  final String? email;
  final String? address;
  final double creditLimit;
  final String? defaultCurrencyId;
  final double openingBalance;
  final String? openingBalanceType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const CustomerModel({
    required this.id,
    required this.businessId,
    required this.customerName,
    this.phone,
    this.email,
    this.address,
    required this.creditLimit,
    this.defaultCurrencyId,
    required this.openingBalance,
    this.openingBalanceType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['customer_name'] = Variable<String>(customerName);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['credit_limit'] = Variable<double>(creditLimit);
    if (!nullToAbsent || defaultCurrencyId != null) {
      map['default_currency_id'] = Variable<String>(defaultCurrencyId);
    }
    map['opening_balance'] = Variable<double>(openingBalance);
    if (!nullToAbsent || openingBalanceType != null) {
      map['opening_balance_type'] = Variable<String>(openingBalanceType);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CustomersTableCompanion toCompanion(bool nullToAbsent) {
    return CustomersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      customerName: Value(customerName),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      creditLimit: Value(creditLimit),
      defaultCurrencyId: defaultCurrencyId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultCurrencyId),
      openingBalance: Value(openingBalance),
      openingBalanceType: openingBalanceType == null && nullToAbsent
          ? const Value.absent()
          : Value(openingBalanceType),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CustomerModel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerModel(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      creditLimit: serializer.fromJson<double>(json['creditLimit']),
      defaultCurrencyId: serializer.fromJson<String?>(
        json['defaultCurrencyId'],
      ),
      openingBalance: serializer.fromJson<double>(json['openingBalance']),
      openingBalanceType: serializer.fromJson<String?>(
        json['openingBalanceType'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'customerName': serializer.toJson<String>(customerName),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'creditLimit': serializer.toJson<double>(creditLimit),
      'defaultCurrencyId': serializer.toJson<String?>(defaultCurrencyId),
      'openingBalance': serializer.toJson<double>(openingBalance),
      'openingBalanceType': serializer.toJson<String?>(openingBalanceType),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CustomerModel copyWith({
    String? id,
    String? businessId,
    String? customerName,
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> address = const Value.absent(),
    double? creditLimit,
    Value<String?> defaultCurrencyId = const Value.absent(),
    double? openingBalance,
    Value<String?> openingBalanceType = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => CustomerModel(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    customerName: customerName ?? this.customerName,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    address: address.present ? address.value : this.address,
    creditLimit: creditLimit ?? this.creditLimit,
    defaultCurrencyId: defaultCurrencyId.present
        ? defaultCurrencyId.value
        : this.defaultCurrencyId,
    openingBalance: openingBalance ?? this.openingBalance,
    openingBalanceType: openingBalanceType.present
        ? openingBalanceType.value
        : this.openingBalanceType,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CustomerModel copyWithCompanion(CustomersTableCompanion data) {
    return CustomerModel(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      defaultCurrencyId: data.defaultCurrencyId.present
          ? data.defaultCurrencyId.value
          : this.defaultCurrencyId,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      openingBalanceType: data.openingBalanceType.present
          ? data.openingBalanceType.value
          : this.openingBalanceType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerModel(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('customerName: $customerName, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('defaultCurrencyId: $defaultCurrencyId, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingBalanceType: $openingBalanceType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    customerName,
    phone,
    email,
    address,
    creditLimit,
    defaultCurrencyId,
    openingBalance,
    openingBalanceType,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerModel &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.customerName == this.customerName &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.creditLimit == this.creditLimit &&
          other.defaultCurrencyId == this.defaultCurrencyId &&
          other.openingBalance == this.openingBalance &&
          other.openingBalanceType == this.openingBalanceType &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CustomersTableCompanion extends UpdateCompanion<CustomerModel> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> customerName;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<double> creditLimit;
  final Value<String?> defaultCurrencyId;
  final Value<double> openingBalance;
  final Value<String?> openingBalanceType;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CustomersTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.defaultCurrencyId = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.openingBalanceType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersTableCompanion.insert({
    this.id = const Value.absent(),
    required String businessId,
    required String customerName,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.defaultCurrencyId = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.openingBalanceType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       customerName = Value(customerName);
  static Insertable<CustomerModel> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? customerName,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<double>? creditLimit,
    Expression<String>? defaultCurrencyId,
    Expression<double>? openingBalance,
    Expression<String>? openingBalanceType,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (customerName != null) 'customer_name': customerName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (defaultCurrencyId != null) 'default_currency_id': defaultCurrencyId,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (openingBalanceType != null)
        'opening_balance_type': openingBalanceType,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? customerName,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? address,
    Value<double>? creditLimit,
    Value<String?>? defaultCurrencyId,
    Value<double>? openingBalance,
    Value<String?>? openingBalanceType,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CustomersTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      defaultCurrencyId: defaultCurrencyId ?? this.defaultCurrencyId,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceType: openingBalanceType ?? this.openingBalanceType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (defaultCurrencyId.present) {
      map['default_currency_id'] = Variable<String>(defaultCurrencyId.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<double>(openingBalance.value);
    }
    if (openingBalanceType.present) {
      map['opening_balance_type'] = Variable<String>(openingBalanceType.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('customerName: $customerName, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('defaultCurrencyId: $defaultCurrencyId, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingBalanceType: $openingBalanceType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesInvoicesTableTable extends SalesInvoicesTable
    with TableInfo<$SalesInvoicesTableTable, SalesInvoiceModel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesInvoicesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceDateMeta = const VerificationMeta(
    'invoiceDate',
  );
  @override
  late final GeneratedColumn<DateTime> invoiceDate = GeneratedColumn<DateTime>(
    'invoice_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyIdMeta = const VerificationMeta(
    'currencyId',
  );
  @override
  late final GeneratedColumn<String> currencyId = GeneratedColumn<String>(
    'currency_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.00000000),
  );
  static const VerificationMeta _subTotalMeta = const VerificationMeta(
    'subTotal',
  );
  @override
  late final GeneratedColumn<double> subTotal = GeneratedColumn<double>(
    'sub_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _discountTotalMeta = const VerificationMeta(
    'discountTotal',
  );
  @override
  late final GeneratedColumn<double> discountTotal = GeneratedColumn<double>(
    'discount_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _taxTotalMeta = const VerificationMeta(
    'taxTotal',
  );
  @override
  late final GeneratedColumn<double> taxTotal = GeneratedColumn<double>(
    'tax_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _grandTotalMeta = const VerificationMeta(
    'grandTotal',
  );
  @override
  late final GeneratedColumn<double> grandTotal = GeneratedColumn<double>(
    'grand_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _baseSubtotalMeta = const VerificationMeta(
    'baseSubtotal',
  );
  @override
  late final GeneratedColumn<double> baseSubtotal = GeneratedColumn<double>(
    'base_subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _baseDiscountTotalMeta = const VerificationMeta(
    'baseDiscountTotal',
  );
  @override
  late final GeneratedColumn<double> baseDiscountTotal =
      GeneratedColumn<double>(
        'base_discount_total',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.00),
      );
  static const VerificationMeta _baseTaxTotalMeta = const VerificationMeta(
    'baseTaxTotal',
  );
  @override
  late final GeneratedColumn<double> baseTaxTotal = GeneratedColumn<double>(
    'base_tax_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _baseGrandTotalMeta = const VerificationMeta(
    'baseGrandTotal',
  );
  @override
  late final GeneratedColumn<double> baseGrandTotal = GeneratedColumn<double>(
    'base_grand_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Unpaid'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Draft'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    branchId,
    customerId,
    invoiceNumber,
    invoiceDate,
    dueDate,
    currencyId,
    exchangeRate,
    subTotal,
    discountTotal,
    taxTotal,
    grandTotal,
    baseSubtotal,
    baseDiscountTotal,
    baseTaxTotal,
    baseGrandTotal,
    paymentStatus,
    status,
    notes,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales_invoices_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalesInvoiceModel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('invoice_date')) {
      context.handle(
        _invoiceDateMeta,
        invoiceDate.isAcceptableOrUnknown(
          data['invoice_date']!,
          _invoiceDateMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('currency_id')) {
      context.handle(
        _currencyIdMeta,
        currencyId.isAcceptableOrUnknown(data['currency_id']!, _currencyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyIdMeta);
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
        ),
      );
    }
    if (data.containsKey('sub_total')) {
      context.handle(
        _subTotalMeta,
        subTotal.isAcceptableOrUnknown(data['sub_total']!, _subTotalMeta),
      );
    }
    if (data.containsKey('discount_total')) {
      context.handle(
        _discountTotalMeta,
        discountTotal.isAcceptableOrUnknown(
          data['discount_total']!,
          _discountTotalMeta,
        ),
      );
    }
    if (data.containsKey('tax_total')) {
      context.handle(
        _taxTotalMeta,
        taxTotal.isAcceptableOrUnknown(data['tax_total']!, _taxTotalMeta),
      );
    }
    if (data.containsKey('grand_total')) {
      context.handle(
        _grandTotalMeta,
        grandTotal.isAcceptableOrUnknown(data['grand_total']!, _grandTotalMeta),
      );
    }
    if (data.containsKey('base_subtotal')) {
      context.handle(
        _baseSubtotalMeta,
        baseSubtotal.isAcceptableOrUnknown(
          data['base_subtotal']!,
          _baseSubtotalMeta,
        ),
      );
    }
    if (data.containsKey('base_discount_total')) {
      context.handle(
        _baseDiscountTotalMeta,
        baseDiscountTotal.isAcceptableOrUnknown(
          data['base_discount_total']!,
          _baseDiscountTotalMeta,
        ),
      );
    }
    if (data.containsKey('base_tax_total')) {
      context.handle(
        _baseTaxTotalMeta,
        baseTaxTotal.isAcceptableOrUnknown(
          data['base_tax_total']!,
          _baseTaxTotalMeta,
        ),
      );
    }
    if (data.containsKey('base_grand_total')) {
      context.handle(
        _baseGrandTotalMeta,
        baseGrandTotal.isAcceptableOrUnknown(
          data['base_grand_total']!,
          _baseGrandTotalMeta,
        ),
      );
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {businessId, branchId, invoiceNumber},
  ];
  @override
  SalesInvoiceModel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalesInvoiceModel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      )!,
      invoiceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}invoice_date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      currencyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_id'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      subTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sub_total'],
      )!,
      discountTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_total'],
      )!,
      taxTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_total'],
      )!,
      grandTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grand_total'],
      )!,
      baseSubtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_subtotal'],
      )!,
      baseDiscountTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_discount_total'],
      )!,
      baseTaxTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_tax_total'],
      )!,
      baseGrandTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_grand_total'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SalesInvoicesTableTable createAlias(String alias) {
    return $SalesInvoicesTableTable(attachedDatabase, alias);
  }
}

class SalesInvoiceModel extends DataClass
    implements Insertable<SalesInvoiceModel> {
  final String id;
  final String businessId;
  final String branchId;
  final String? customerId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String currencyId;
  final double exchangeRate;
  final double subTotal;
  final double discountTotal;
  final double taxTotal;
  final double grandTotal;
  final double baseSubtotal;
  final double baseDiscountTotal;
  final double baseTaxTotal;
  final double baseGrandTotal;
  final String paymentStatus;
  final String status;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SalesInvoiceModel({
    required this.id,
    required this.businessId,
    required this.branchId,
    this.customerId,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.currencyId,
    required this.exchangeRate,
    required this.subTotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.baseSubtotal,
    required this.baseDiscountTotal,
    required this.baseTaxTotal,
    required this.baseGrandTotal,
    required this.paymentStatus,
    required this.status,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['branch_id'] = Variable<String>(branchId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['invoice_date'] = Variable<DateTime>(invoiceDate);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['currency_id'] = Variable<String>(currencyId);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    map['sub_total'] = Variable<double>(subTotal);
    map['discount_total'] = Variable<double>(discountTotal);
    map['tax_total'] = Variable<double>(taxTotal);
    map['grand_total'] = Variable<double>(grandTotal);
    map['base_subtotal'] = Variable<double>(baseSubtotal);
    map['base_discount_total'] = Variable<double>(baseDiscountTotal);
    map['base_tax_total'] = Variable<double>(baseTaxTotal);
    map['base_grand_total'] = Variable<double>(baseGrandTotal);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SalesInvoicesTableCompanion toCompanion(bool nullToAbsent) {
    return SalesInvoicesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      branchId: Value(branchId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      invoiceNumber: Value(invoiceNumber),
      invoiceDate: Value(invoiceDate),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      currencyId: Value(currencyId),
      exchangeRate: Value(exchangeRate),
      subTotal: Value(subTotal),
      discountTotal: Value(discountTotal),
      taxTotal: Value(taxTotal),
      grandTotal: Value(grandTotal),
      baseSubtotal: Value(baseSubtotal),
      baseDiscountTotal: Value(baseDiscountTotal),
      baseTaxTotal: Value(baseTaxTotal),
      baseGrandTotal: Value(baseGrandTotal),
      paymentStatus: Value(paymentStatus),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SalesInvoiceModel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalesInvoiceModel(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      invoiceDate: serializer.fromJson<DateTime>(json['invoiceDate']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      currencyId: serializer.fromJson<String>(json['currencyId']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      subTotal: serializer.fromJson<double>(json['subTotal']),
      discountTotal: serializer.fromJson<double>(json['discountTotal']),
      taxTotal: serializer.fromJson<double>(json['taxTotal']),
      grandTotal: serializer.fromJson<double>(json['grandTotal']),
      baseSubtotal: serializer.fromJson<double>(json['baseSubtotal']),
      baseDiscountTotal: serializer.fromJson<double>(json['baseDiscountTotal']),
      baseTaxTotal: serializer.fromJson<double>(json['baseTaxTotal']),
      baseGrandTotal: serializer.fromJson<double>(json['baseGrandTotal']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'branchId': serializer.toJson<String>(branchId),
      'customerId': serializer.toJson<String?>(customerId),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'invoiceDate': serializer.toJson<DateTime>(invoiceDate),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'currencyId': serializer.toJson<String>(currencyId),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'subTotal': serializer.toJson<double>(subTotal),
      'discountTotal': serializer.toJson<double>(discountTotal),
      'taxTotal': serializer.toJson<double>(taxTotal),
      'grandTotal': serializer.toJson<double>(grandTotal),
      'baseSubtotal': serializer.toJson<double>(baseSubtotal),
      'baseDiscountTotal': serializer.toJson<double>(baseDiscountTotal),
      'baseTaxTotal': serializer.toJson<double>(baseTaxTotal),
      'baseGrandTotal': serializer.toJson<double>(baseGrandTotal),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SalesInvoiceModel copyWith({
    String? id,
    String? businessId,
    String? branchId,
    Value<String?> customerId = const Value.absent(),
    String? invoiceNumber,
    DateTime? invoiceDate,
    Value<DateTime?> dueDate = const Value.absent(),
    String? currencyId,
    double? exchangeRate,
    double? subTotal,
    double? discountTotal,
    double? taxTotal,
    double? grandTotal,
    double? baseSubtotal,
    double? baseDiscountTotal,
    double? baseTaxTotal,
    double? baseGrandTotal,
    String? paymentStatus,
    String? status,
    Value<String?> notes = const Value.absent(),
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SalesInvoiceModel(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId,
    customerId: customerId.present ? customerId.value : this.customerId,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    invoiceDate: invoiceDate ?? this.invoiceDate,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    currencyId: currencyId ?? this.currencyId,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    subTotal: subTotal ?? this.subTotal,
    discountTotal: discountTotal ?? this.discountTotal,
    taxTotal: taxTotal ?? this.taxTotal,
    grandTotal: grandTotal ?? this.grandTotal,
    baseSubtotal: baseSubtotal ?? this.baseSubtotal,
    baseDiscountTotal: baseDiscountTotal ?? this.baseDiscountTotal,
    baseTaxTotal: baseTaxTotal ?? this.baseTaxTotal,
    baseGrandTotal: baseGrandTotal ?? this.baseGrandTotal,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SalesInvoiceModel copyWithCompanion(SalesInvoicesTableCompanion data) {
    return SalesInvoiceModel(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      invoiceDate: data.invoiceDate.present
          ? data.invoiceDate.value
          : this.invoiceDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      currencyId: data.currencyId.present
          ? data.currencyId.value
          : this.currencyId,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      subTotal: data.subTotal.present ? data.subTotal.value : this.subTotal,
      discountTotal: data.discountTotal.present
          ? data.discountTotal.value
          : this.discountTotal,
      taxTotal: data.taxTotal.present ? data.taxTotal.value : this.taxTotal,
      grandTotal: data.grandTotal.present
          ? data.grandTotal.value
          : this.grandTotal,
      baseSubtotal: data.baseSubtotal.present
          ? data.baseSubtotal.value
          : this.baseSubtotal,
      baseDiscountTotal: data.baseDiscountTotal.present
          ? data.baseDiscountTotal.value
          : this.baseDiscountTotal,
      baseTaxTotal: data.baseTaxTotal.present
          ? data.baseTaxTotal.value
          : this.baseTaxTotal,
      baseGrandTotal: data.baseGrandTotal.present
          ? data.baseGrandTotal.value
          : this.baseGrandTotal,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalesInvoiceModel(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('currencyId: $currencyId, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('subTotal: $subTotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('taxTotal: $taxTotal, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('baseSubtotal: $baseSubtotal, ')
          ..write('baseDiscountTotal: $baseDiscountTotal, ')
          ..write('baseTaxTotal: $baseTaxTotal, ')
          ..write('baseGrandTotal: $baseGrandTotal, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    branchId,
    customerId,
    invoiceNumber,
    invoiceDate,
    dueDate,
    currencyId,
    exchangeRate,
    subTotal,
    discountTotal,
    taxTotal,
    grandTotal,
    baseSubtotal,
    baseDiscountTotal,
    baseTaxTotal,
    baseGrandTotal,
    paymentStatus,
    status,
    notes,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalesInvoiceModel &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.customerId == this.customerId &&
          other.invoiceNumber == this.invoiceNumber &&
          other.invoiceDate == this.invoiceDate &&
          other.dueDate == this.dueDate &&
          other.currencyId == this.currencyId &&
          other.exchangeRate == this.exchangeRate &&
          other.subTotal == this.subTotal &&
          other.discountTotal == this.discountTotal &&
          other.taxTotal == this.taxTotal &&
          other.grandTotal == this.grandTotal &&
          other.baseSubtotal == this.baseSubtotal &&
          other.baseDiscountTotal == this.baseDiscountTotal &&
          other.baseTaxTotal == this.baseTaxTotal &&
          other.baseGrandTotal == this.baseGrandTotal &&
          other.paymentStatus == this.paymentStatus &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SalesInvoicesTableCompanion extends UpdateCompanion<SalesInvoiceModel> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> branchId;
  final Value<String?> customerId;
  final Value<String> invoiceNumber;
  final Value<DateTime> invoiceDate;
  final Value<DateTime?> dueDate;
  final Value<String> currencyId;
  final Value<double> exchangeRate;
  final Value<double> subTotal;
  final Value<double> discountTotal;
  final Value<double> taxTotal;
  final Value<double> grandTotal;
  final Value<double> baseSubtotal;
  final Value<double> baseDiscountTotal;
  final Value<double> baseTaxTotal;
  final Value<double> baseGrandTotal;
  final Value<String> paymentStatus;
  final Value<String> status;
  final Value<String?> notes;
  final Value<String> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SalesInvoicesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.invoiceDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.currencyId = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.subTotal = const Value.absent(),
    this.discountTotal = const Value.absent(),
    this.taxTotal = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.baseSubtotal = const Value.absent(),
    this.baseDiscountTotal = const Value.absent(),
    this.baseTaxTotal = const Value.absent(),
    this.baseGrandTotal = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesInvoicesTableCompanion.insert({
    this.id = const Value.absent(),
    required String businessId,
    required String branchId,
    this.customerId = const Value.absent(),
    required String invoiceNumber,
    this.invoiceDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    required String currencyId,
    this.exchangeRate = const Value.absent(),
    this.subTotal = const Value.absent(),
    this.discountTotal = const Value.absent(),
    this.taxTotal = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.baseSubtotal = const Value.absent(),
    this.baseDiscountTotal = const Value.absent(),
    this.baseTaxTotal = const Value.absent(),
    this.baseGrandTotal = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    required String createdBy,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       branchId = Value(branchId),
       invoiceNumber = Value(invoiceNumber),
       currencyId = Value(currencyId),
       createdBy = Value(createdBy);
  static Insertable<SalesInvoiceModel> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<String>? customerId,
    Expression<String>? invoiceNumber,
    Expression<DateTime>? invoiceDate,
    Expression<DateTime>? dueDate,
    Expression<String>? currencyId,
    Expression<double>? exchangeRate,
    Expression<double>? subTotal,
    Expression<double>? discountTotal,
    Expression<double>? taxTotal,
    Expression<double>? grandTotal,
    Expression<double>? baseSubtotal,
    Expression<double>? baseDiscountTotal,
    Expression<double>? baseTaxTotal,
    Expression<double>? baseGrandTotal,
    Expression<String>? paymentStatus,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (customerId != null) 'customer_id': customerId,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (invoiceDate != null) 'invoice_date': invoiceDate,
      if (dueDate != null) 'due_date': dueDate,
      if (currencyId != null) 'currency_id': currencyId,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (subTotal != null) 'sub_total': subTotal,
      if (discountTotal != null) 'discount_total': discountTotal,
      if (taxTotal != null) 'tax_total': taxTotal,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (baseSubtotal != null) 'base_subtotal': baseSubtotal,
      if (baseDiscountTotal != null) 'base_discount_total': baseDiscountTotal,
      if (baseTaxTotal != null) 'base_tax_total': baseTaxTotal,
      if (baseGrandTotal != null) 'base_grand_total': baseGrandTotal,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesInvoicesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? branchId,
    Value<String?>? customerId,
    Value<String>? invoiceNumber,
    Value<DateTime>? invoiceDate,
    Value<DateTime?>? dueDate,
    Value<String>? currencyId,
    Value<double>? exchangeRate,
    Value<double>? subTotal,
    Value<double>? discountTotal,
    Value<double>? taxTotal,
    Value<double>? grandTotal,
    Value<double>? baseSubtotal,
    Value<double>? baseDiscountTotal,
    Value<double>? baseTaxTotal,
    Value<double>? baseGrandTotal,
    Value<String>? paymentStatus,
    Value<String>? status,
    Value<String?>? notes,
    Value<String>? createdBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SalesInvoicesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      currencyId: currencyId ?? this.currencyId,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      subTotal: subTotal ?? this.subTotal,
      discountTotal: discountTotal ?? this.discountTotal,
      taxTotal: taxTotal ?? this.taxTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      baseSubtotal: baseSubtotal ?? this.baseSubtotal,
      baseDiscountTotal: baseDiscountTotal ?? this.baseDiscountTotal,
      baseTaxTotal: baseTaxTotal ?? this.baseTaxTotal,
      baseGrandTotal: baseGrandTotal ?? this.baseGrandTotal,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (invoiceDate.present) {
      map['invoice_date'] = Variable<DateTime>(invoiceDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (currencyId.present) {
      map['currency_id'] = Variable<String>(currencyId.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (subTotal.present) {
      map['sub_total'] = Variable<double>(subTotal.value);
    }
    if (discountTotal.present) {
      map['discount_total'] = Variable<double>(discountTotal.value);
    }
    if (taxTotal.present) {
      map['tax_total'] = Variable<double>(taxTotal.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<double>(grandTotal.value);
    }
    if (baseSubtotal.present) {
      map['base_subtotal'] = Variable<double>(baseSubtotal.value);
    }
    if (baseDiscountTotal.present) {
      map['base_discount_total'] = Variable<double>(baseDiscountTotal.value);
    }
    if (baseTaxTotal.present) {
      map['base_tax_total'] = Variable<double>(baseTaxTotal.value);
    }
    if (baseGrandTotal.present) {
      map['base_grand_total'] = Variable<double>(baseGrandTotal.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesInvoicesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('customerId: $customerId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('currencyId: $currencyId, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('subTotal: $subTotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('taxTotal: $taxTotal, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('baseSubtotal: $baseSubtotal, ')
          ..write('baseDiscountTotal: $baseDiscountTotal, ')
          ..write('baseTaxTotal: $baseTaxTotal, ')
          ..write('baseGrandTotal: $baseGrandTotal, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CurrenciesTableTable extends CurrenciesTable
    with TableInfo<$CurrenciesTableTable, CurrencyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrenciesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decimalPlacesMeta = const VerificationMeta(
    'decimalPlaces',
  );
  @override
  late final GeneratedColumn<int> decimalPlaces = GeneratedColumn<int>(
    'decimal_places',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _isBaseCurrencyMeta = const VerificationMeta(
    'isBaseCurrency',
  );
  @override
  late final GeneratedColumn<bool> isBaseCurrency = GeneratedColumn<bool>(
    'is_base_currency',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_base_currency" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    nameAr,
    symbol,
    decimalPlaces,
    exchangeRate,
    isBaseCurrency,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currencies_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurrencyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('decimal_places')) {
      context.handle(
        _decimalPlacesMeta,
        decimalPlaces.isAcceptableOrUnknown(
          data['decimal_places']!,
          _decimalPlacesMeta,
        ),
      );
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
        ),
      );
    }
    if (data.containsKey('is_base_currency')) {
      context.handle(
        _isBaseCurrencyMeta,
        isBaseCurrency.isAcceptableOrUnknown(
          data['is_base_currency']!,
          _isBaseCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CurrencyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurrencyData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      decimalPlaces: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}decimal_places'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      isBaseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_base_currency'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $CurrenciesTableTable createAlias(String alias) {
    return $CurrenciesTableTable(attachedDatabase, alias);
  }
}

class CurrencyData extends DataClass implements Insertable<CurrencyData> {
  final String id;
  final String code;
  final String nameAr;
  final String symbol;
  final int decimalPlaces;

  /// Exchange rate relative to base currency (Base Currency rate is always 1.0)
  final double exchangeRate;
  final bool isBaseCurrency;
  final bool isActive;
  const CurrencyData({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.symbol,
    required this.decimalPlaces,
    required this.exchangeRate,
    required this.isBaseCurrency,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name_ar'] = Variable<String>(nameAr);
    map['symbol'] = Variable<String>(symbol);
    map['decimal_places'] = Variable<int>(decimalPlaces);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    map['is_base_currency'] = Variable<bool>(isBaseCurrency);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  CurrenciesTableCompanion toCompanion(bool nullToAbsent) {
    return CurrenciesTableCompanion(
      id: Value(id),
      code: Value(code),
      nameAr: Value(nameAr),
      symbol: Value(symbol),
      decimalPlaces: Value(decimalPlaces),
      exchangeRate: Value(exchangeRate),
      isBaseCurrency: Value(isBaseCurrency),
      isActive: Value(isActive),
    );
  }

  factory CurrencyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurrencyData(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      symbol: serializer.fromJson<String>(json['symbol']),
      decimalPlaces: serializer.fromJson<int>(json['decimalPlaces']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      isBaseCurrency: serializer.fromJson<bool>(json['isBaseCurrency']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'nameAr': serializer.toJson<String>(nameAr),
      'symbol': serializer.toJson<String>(symbol),
      'decimalPlaces': serializer.toJson<int>(decimalPlaces),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'isBaseCurrency': serializer.toJson<bool>(isBaseCurrency),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  CurrencyData copyWith({
    String? id,
    String? code,
    String? nameAr,
    String? symbol,
    int? decimalPlaces,
    double? exchangeRate,
    bool? isBaseCurrency,
    bool? isActive,
  }) => CurrencyData(
    id: id ?? this.id,
    code: code ?? this.code,
    nameAr: nameAr ?? this.nameAr,
    symbol: symbol ?? this.symbol,
    decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    isBaseCurrency: isBaseCurrency ?? this.isBaseCurrency,
    isActive: isActive ?? this.isActive,
  );
  CurrencyData copyWithCompanion(CurrenciesTableCompanion data) {
    return CurrencyData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      decimalPlaces: data.decimalPlaces.present
          ? data.decimalPlaces.value
          : this.decimalPlaces,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      isBaseCurrency: data.isBaseCurrency.present
          ? data.isBaseCurrency.value
          : this.isBaseCurrency,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('nameAr: $nameAr, ')
          ..write('symbol: $symbol, ')
          ..write('decimalPlaces: $decimalPlaces, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('isBaseCurrency: $isBaseCurrency, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    nameAr,
    symbol,
    decimalPlaces,
    exchangeRate,
    isBaseCurrency,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrencyData &&
          other.id == this.id &&
          other.code == this.code &&
          other.nameAr == this.nameAr &&
          other.symbol == this.symbol &&
          other.decimalPlaces == this.decimalPlaces &&
          other.exchangeRate == this.exchangeRate &&
          other.isBaseCurrency == this.isBaseCurrency &&
          other.isActive == this.isActive);
}

class CurrenciesTableCompanion extends UpdateCompanion<CurrencyData> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> nameAr;
  final Value<String> symbol;
  final Value<int> decimalPlaces;
  final Value<double> exchangeRate;
  final Value<bool> isBaseCurrency;
  final Value<bool> isActive;
  final Value<int> rowid;
  const CurrenciesTableCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.symbol = const Value.absent(),
    this.decimalPlaces = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.isBaseCurrency = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurrenciesTableCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String nameAr,
    required String symbol,
    this.decimalPlaces = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.isBaseCurrency = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       nameAr = Value(nameAr),
       symbol = Value(symbol);
  static Insertable<CurrencyData> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? nameAr,
    Expression<String>? symbol,
    Expression<int>? decimalPlaces,
    Expression<double>? exchangeRate,
    Expression<bool>? isBaseCurrency,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (nameAr != null) 'name_ar': nameAr,
      if (symbol != null) 'symbol': symbol,
      if (decimalPlaces != null) 'decimal_places': decimalPlaces,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (isBaseCurrency != null) 'is_base_currency': isBaseCurrency,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurrenciesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? nameAr,
    Value<String>? symbol,
    Value<int>? decimalPlaces,
    Value<double>? exchangeRate,
    Value<bool>? isBaseCurrency,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return CurrenciesTableCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      symbol: symbol ?? this.symbol,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      isBaseCurrency: isBaseCurrency ?? this.isBaseCurrency,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (decimalPlaces.present) {
      map['decimal_places'] = Variable<int>(decimalPlaces.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (isBaseCurrency.present) {
      map['is_base_currency'] = Variable<bool>(isBaseCurrency.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrenciesTableCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('nameAr: $nameAr, ')
          ..write('symbol: $symbol, ')
          ..write('decimalPlaces: $decimalPlaces, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('isBaseCurrency: $isBaseCurrency, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FiscalYearsTableTable extends FiscalYearsTable
    with TableInfo<$FiscalYearsTableTable, FiscalYearData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiscalYearsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _yearNameMeta = const VerificationMeta(
    'yearName',
  );
  @override
  late final GeneratedColumn<String> yearName = GeneratedColumn<String>(
    'year_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isClosedMeta = const VerificationMeta(
    'isClosed',
  );
  @override
  late final GeneratedColumn<bool> isClosed = GeneratedColumn<bool>(
    'is_closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    yearName,
    startDate,
    endDate,
    isClosed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fiscal_years_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<FiscalYearData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year_name')) {
      context.handle(
        _yearNameMeta,
        yearName.isAcceptableOrUnknown(data['year_name']!, _yearNameMeta),
      );
    } else if (isInserting) {
      context.missing(_yearNameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('is_closed')) {
      context.handle(
        _isClosedMeta,
        isClosed.isAcceptableOrUnknown(data['is_closed']!, _isClosedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FiscalYearData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FiscalYearData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      yearName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year_name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
      isClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_closed'],
      )!,
    );
  }

  @override
  $FiscalYearsTableTable createAlias(String alias) {
    return $FiscalYearsTableTable(attachedDatabase, alias);
  }
}

class FiscalYearData extends DataClass implements Insertable<FiscalYearData> {
  final String id;
  final String yearName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isClosed;
  const FiscalYearData({
    required this.id,
    required this.yearName,
    required this.startDate,
    required this.endDate,
    required this.isClosed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['year_name'] = Variable<String>(yearName);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    map['is_closed'] = Variable<bool>(isClosed);
    return map;
  }

  FiscalYearsTableCompanion toCompanion(bool nullToAbsent) {
    return FiscalYearsTableCompanion(
      id: Value(id),
      yearName: Value(yearName),
      startDate: Value(startDate),
      endDate: Value(endDate),
      isClosed: Value(isClosed),
    );
  }

  factory FiscalYearData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FiscalYearData(
      id: serializer.fromJson<String>(json['id']),
      yearName: serializer.fromJson<String>(json['yearName']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      isClosed: serializer.fromJson<bool>(json['isClosed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'yearName': serializer.toJson<String>(yearName),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'isClosed': serializer.toJson<bool>(isClosed),
    };
  }

  FiscalYearData copyWith({
    String? id,
    String? yearName,
    DateTime? startDate,
    DateTime? endDate,
    bool? isClosed,
  }) => FiscalYearData(
    id: id ?? this.id,
    yearName: yearName ?? this.yearName,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    isClosed: isClosed ?? this.isClosed,
  );
  FiscalYearData copyWithCompanion(FiscalYearsTableCompanion data) {
    return FiscalYearData(
      id: data.id.present ? data.id.value : this.id,
      yearName: data.yearName.present ? data.yearName.value : this.yearName,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      isClosed: data.isClosed.present ? data.isClosed.value : this.isClosed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FiscalYearData(')
          ..write('id: $id, ')
          ..write('yearName: $yearName, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isClosed: $isClosed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, yearName, startDate, endDate, isClosed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiscalYearData &&
          other.id == this.id &&
          other.yearName == this.yearName &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.isClosed == this.isClosed);
}

class FiscalYearsTableCompanion extends UpdateCompanion<FiscalYearData> {
  final Value<String> id;
  final Value<String> yearName;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<bool> isClosed;
  final Value<int> rowid;
  const FiscalYearsTableCompanion({
    this.id = const Value.absent(),
    this.yearName = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FiscalYearsTableCompanion.insert({
    this.id = const Value.absent(),
    required String yearName,
    required DateTime startDate,
    required DateTime endDate,
    this.isClosed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : yearName = Value(yearName),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<FiscalYearData> custom({
    Expression<String>? id,
    Expression<String>? yearName,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<bool>? isClosed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (yearName != null) 'year_name': yearName,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (isClosed != null) 'is_closed': isClosed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FiscalYearsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? yearName,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<bool>? isClosed,
    Value<int>? rowid,
  }) {
    return FiscalYearsTableCompanion(
      id: id ?? this.id,
      yearName: yearName ?? this.yearName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isClosed: isClosed ?? this.isClosed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (yearName.present) {
      map['year_name'] = Variable<String>(yearName.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (isClosed.present) {
      map['is_closed'] = Variable<bool>(isClosed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiscalYearsTableCompanion(')
          ..write('id: $id, ')
          ..write('yearName: $yearName, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isClosed: $isClosed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChartOfAccountsTableTable extends ChartOfAccountsTable
    with TableInfo<$ChartOfAccountsTableTable, AccountData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChartOfAccountsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chart_of_accounts_table (id)',
    ),
  );
  static const VerificationMeta _accountCodeMeta = const VerificationMeta(
    'accountCode',
  );
  @override
  late final GeneratedColumn<String> accountCode = GeneratedColumn<String>(
    'account_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalBalanceMeta = const VerificationMeta(
    'normalBalance',
  );
  @override
  late final GeneratedColumn<String> normalBalance = GeneratedColumn<String>(
    'normal_balance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowPostingMeta = const VerificationMeta(
    'allowPosting',
  );
  @override
  late final GeneratedColumn<bool> allowPosting = GeneratedColumn<bool>(
    'allow_posting',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_posting" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _systemRoleMeta = const VerificationMeta(
    'systemRole',
  );
  @override
  late final GeneratedColumn<String> systemRole = GeneratedColumn<String>(
    'system_role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    accountCode,
    accountName,
    accountType,
    normalBalance,
    allowPosting,
    isSystem,
    systemRole,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chart_of_accounts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('account_code')) {
      context.handle(
        _accountCodeMeta,
        accountCode.isAcceptableOrUnknown(
          data['account_code']!,
          _accountCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountCodeMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountNameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('normal_balance')) {
      context.handle(
        _normalBalanceMeta,
        normalBalance.isAcceptableOrUnknown(
          data['normal_balance']!,
          _normalBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalBalanceMeta);
    }
    if (data.containsKey('allow_posting')) {
      context.handle(
        _allowPostingMeta,
        allowPosting.isAcceptableOrUnknown(
          data['allow_posting']!,
          _allowPostingMeta,
        ),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('system_role')) {
      context.handle(
        _systemRoleMeta,
        systemRole.isAcceptableOrUnknown(data['system_role']!, _systemRoleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      accountCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_code'],
      )!,
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      )!,
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      normalBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normal_balance'],
      )!,
      allowPosting: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_posting'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      systemRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_role'],
      ),
    );
  }

  @override
  $ChartOfAccountsTableTable createAlias(String alias) {
    return $ChartOfAccountsTableTable(attachedDatabase, alias);
  }
}

class AccountData extends DataClass implements Insertable<AccountData> {
  final String id;
  final String? parentId;
  final String accountCode;
  final String accountName;

  /// Major account type: 'Asset', 'Liability', 'Equity', 'Revenue', 'Expense'
  final String accountType;

  /// Normal balance orientation: 'Debit' or 'Credit'
  final String normalBalance;

  /// Whether direct journal posting is allowed (false for parent headers)
  final bool allowPosting;

  /// Protected system accounts essential for automated background engines
  final bool isSystem;

  /// System role identifier (e.g. 'CASH_DRAWER_DEFAULT', 'SALES_REVENUE', 'COGS', 'INVENTORY_ASSET')
  final String? systemRole;
  const AccountData({
    required this.id,
    this.parentId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.normalBalance,
    required this.allowPosting,
    required this.isSystem,
    this.systemRole,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['account_code'] = Variable<String>(accountCode);
    map['account_name'] = Variable<String>(accountName);
    map['account_type'] = Variable<String>(accountType);
    map['normal_balance'] = Variable<String>(normalBalance);
    map['allow_posting'] = Variable<bool>(allowPosting);
    map['is_system'] = Variable<bool>(isSystem);
    if (!nullToAbsent || systemRole != null) {
      map['system_role'] = Variable<String>(systemRole);
    }
    return map;
  }

  ChartOfAccountsTableCompanion toCompanion(bool nullToAbsent) {
    return ChartOfAccountsTableCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      accountCode: Value(accountCode),
      accountName: Value(accountName),
      accountType: Value(accountType),
      normalBalance: Value(normalBalance),
      allowPosting: Value(allowPosting),
      isSystem: Value(isSystem),
      systemRole: systemRole == null && nullToAbsent
          ? const Value.absent()
          : Value(systemRole),
    );
  }

  factory AccountData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountData(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      accountCode: serializer.fromJson<String>(json['accountCode']),
      accountName: serializer.fromJson<String>(json['accountName']),
      accountType: serializer.fromJson<String>(json['accountType']),
      normalBalance: serializer.fromJson<String>(json['normalBalance']),
      allowPosting: serializer.fromJson<bool>(json['allowPosting']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      systemRole: serializer.fromJson<String?>(json['systemRole']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'accountCode': serializer.toJson<String>(accountCode),
      'accountName': serializer.toJson<String>(accountName),
      'accountType': serializer.toJson<String>(accountType),
      'normalBalance': serializer.toJson<String>(normalBalance),
      'allowPosting': serializer.toJson<bool>(allowPosting),
      'isSystem': serializer.toJson<bool>(isSystem),
      'systemRole': serializer.toJson<String?>(systemRole),
    };
  }

  AccountData copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? accountCode,
    String? accountName,
    String? accountType,
    String? normalBalance,
    bool? allowPosting,
    bool? isSystem,
    Value<String?> systemRole = const Value.absent(),
  }) => AccountData(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    accountCode: accountCode ?? this.accountCode,
    accountName: accountName ?? this.accountName,
    accountType: accountType ?? this.accountType,
    normalBalance: normalBalance ?? this.normalBalance,
    allowPosting: allowPosting ?? this.allowPosting,
    isSystem: isSystem ?? this.isSystem,
    systemRole: systemRole.present ? systemRole.value : this.systemRole,
  );
  AccountData copyWithCompanion(ChartOfAccountsTableCompanion data) {
    return AccountData(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      accountCode: data.accountCode.present
          ? data.accountCode.value
          : this.accountCode,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      normalBalance: data.normalBalance.present
          ? data.normalBalance.value
          : this.normalBalance,
      allowPosting: data.allowPosting.present
          ? data.allowPosting.value
          : this.allowPosting,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      systemRole: data.systemRole.present
          ? data.systemRole.value
          : this.systemRole,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountData(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('accountCode: $accountCode, ')
          ..write('accountName: $accountName, ')
          ..write('accountType: $accountType, ')
          ..write('normalBalance: $normalBalance, ')
          ..write('allowPosting: $allowPosting, ')
          ..write('isSystem: $isSystem, ')
          ..write('systemRole: $systemRole')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    accountCode,
    accountName,
    accountType,
    normalBalance,
    allowPosting,
    isSystem,
    systemRole,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountData &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.accountCode == this.accountCode &&
          other.accountName == this.accountName &&
          other.accountType == this.accountType &&
          other.normalBalance == this.normalBalance &&
          other.allowPosting == this.allowPosting &&
          other.isSystem == this.isSystem &&
          other.systemRole == this.systemRole);
}

class ChartOfAccountsTableCompanion extends UpdateCompanion<AccountData> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> accountCode;
  final Value<String> accountName;
  final Value<String> accountType;
  final Value<String> normalBalance;
  final Value<bool> allowPosting;
  final Value<bool> isSystem;
  final Value<String?> systemRole;
  final Value<int> rowid;
  const ChartOfAccountsTableCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.accountCode = const Value.absent(),
    this.accountName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.normalBalance = const Value.absent(),
    this.allowPosting = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.systemRole = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChartOfAccountsTableCompanion.insert({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    required String accountCode,
    required String accountName,
    required String accountType,
    required String normalBalance,
    this.allowPosting = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.systemRole = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountCode = Value(accountCode),
       accountName = Value(accountName),
       accountType = Value(accountType),
       normalBalance = Value(normalBalance);
  static Insertable<AccountData> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? accountCode,
    Expression<String>? accountName,
    Expression<String>? accountType,
    Expression<String>? normalBalance,
    Expression<bool>? allowPosting,
    Expression<bool>? isSystem,
    Expression<String>? systemRole,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (accountCode != null) 'account_code': accountCode,
      if (accountName != null) 'account_name': accountName,
      if (accountType != null) 'account_type': accountType,
      if (normalBalance != null) 'normal_balance': normalBalance,
      if (allowPosting != null) 'allow_posting': allowPosting,
      if (isSystem != null) 'is_system': isSystem,
      if (systemRole != null) 'system_role': systemRole,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChartOfAccountsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? accountCode,
    Value<String>? accountName,
    Value<String>? accountType,
    Value<String>? normalBalance,
    Value<bool>? allowPosting,
    Value<bool>? isSystem,
    Value<String?>? systemRole,
    Value<int>? rowid,
  }) {
    return ChartOfAccountsTableCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      normalBalance: normalBalance ?? this.normalBalance,
      allowPosting: allowPosting ?? this.allowPosting,
      isSystem: isSystem ?? this.isSystem,
      systemRole: systemRole ?? this.systemRole,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (accountCode.present) {
      map['account_code'] = Variable<String>(accountCode.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (normalBalance.present) {
      map['normal_balance'] = Variable<String>(normalBalance.value);
    }
    if (allowPosting.present) {
      map['allow_posting'] = Variable<bool>(allowPosting.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (systemRole.present) {
      map['system_role'] = Variable<String>(systemRole.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChartOfAccountsTableCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('accountCode: $accountCode, ')
          ..write('accountName: $accountName, ')
          ..write('accountType: $accountType, ')
          ..write('normalBalance: $normalBalance, ')
          ..write('allowPosting: $allowPosting, ')
          ..write('isSystem: $isSystem, ')
          ..write('systemRole: $systemRole, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTableTable extends JournalEntriesTable
    with TableInfo<$JournalEntriesTableTable, JournalEntryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _fiscalYearIdMeta = const VerificationMeta(
    'fiscalYearId',
  );
  @override
  late final GeneratedColumn<String> fiscalYearId = GeneratedColumn<String>(
    'fiscal_year_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES fiscal_years_table (id)',
    ),
  );
  static const VerificationMeta _entryNumberMeta = const VerificationMeta(
    'entryNumber',
  );
  @override
  late final GeneratedColumn<String> entryNumber = GeneratedColumn<String>(
    'entry_number',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _entryDateMeta = const VerificationMeta(
    'entryDate',
  );
  @override
  late final GeneratedColumn<DateTime> entryDate = GeneratedColumn<DateTime>(
    'entry_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyIdMeta = const VerificationMeta(
    'currencyId',
  );
  @override
  late final GeneratedColumn<String> currencyId = GeneratedColumn<String>(
    'currency_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies_table (id)',
    ),
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Posted'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fiscalYearId,
    entryNumber,
    entryDate,
    referenceType,
    referenceId,
    currencyId,
    exchangeRate,
    description,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fiscal_year_id')) {
      context.handle(
        _fiscalYearIdMeta,
        fiscalYearId.isAcceptableOrUnknown(
          data['fiscal_year_id']!,
          _fiscalYearIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fiscalYearIdMeta);
    }
    if (data.containsKey('entry_number')) {
      context.handle(
        _entryNumberMeta,
        entryNumber.isAcceptableOrUnknown(
          data['entry_number']!,
          _entryNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entryNumberMeta);
    }
    if (data.containsKey('entry_date')) {
      context.handle(
        _entryDateMeta,
        entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta),
      );
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTypeMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    }
    if (data.containsKey('currency_id')) {
      context.handle(
        _currencyIdMeta,
        currencyId.isAcceptableOrUnknown(data['currency_id']!, _currencyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyIdMeta);
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
        ),
      );
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
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fiscalYearId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_year_id'],
      )!,
      entryNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_number'],
      )!,
      entryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}entry_date'],
      )!,
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      ),
      currencyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_id'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $JournalEntriesTableTable createAlias(String alias) {
    return $JournalEntriesTableTable(attachedDatabase, alias);
  }
}

class JournalEntryData extends DataClass
    implements Insertable<JournalEntryData> {
  final String id;
  final String fiscalYearId;
  final String entryNumber;
  final DateTime entryDate;

  /// Reference transaction type: 'SalesInvoice', 'PurchaseInvoice', 'Payment', 'Expense', 'StockAdjustment', 'Manual', 'ClosingEntry'
  final String referenceType;
  final String? referenceId;
  final String currencyId;
  final double exchangeRate;
  final String? description;

  /// Status: 'Posted', 'Voided'
  final String status;
  final DateTime createdAt;
  const JournalEntryData({
    required this.id,
    required this.fiscalYearId,
    required this.entryNumber,
    required this.entryDate,
    required this.referenceType,
    this.referenceId,
    required this.currencyId,
    required this.exchangeRate,
    this.description,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fiscal_year_id'] = Variable<String>(fiscalYearId);
    map['entry_number'] = Variable<String>(entryNumber);
    map['entry_date'] = Variable<DateTime>(entryDate);
    map['reference_type'] = Variable<String>(referenceType);
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    map['currency_id'] = Variable<String>(currencyId);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  JournalEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesTableCompanion(
      id: Value(id),
      fiscalYearId: Value(fiscalYearId),
      entryNumber: Value(entryNumber),
      entryDate: Value(entryDate),
      referenceType: Value(referenceType),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      currencyId: Value(currencyId),
      exchangeRate: Value(exchangeRate),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory JournalEntryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntryData(
      id: serializer.fromJson<String>(json['id']),
      fiscalYearId: serializer.fromJson<String>(json['fiscalYearId']),
      entryNumber: serializer.fromJson<String>(json['entryNumber']),
      entryDate: serializer.fromJson<DateTime>(json['entryDate']),
      referenceType: serializer.fromJson<String>(json['referenceType']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      currencyId: serializer.fromJson<String>(json['currencyId']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fiscalYearId': serializer.toJson<String>(fiscalYearId),
      'entryNumber': serializer.toJson<String>(entryNumber),
      'entryDate': serializer.toJson<DateTime>(entryDate),
      'referenceType': serializer.toJson<String>(referenceType),
      'referenceId': serializer.toJson<String?>(referenceId),
      'currencyId': serializer.toJson<String>(currencyId),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  JournalEntryData copyWith({
    String? id,
    String? fiscalYearId,
    String? entryNumber,
    DateTime? entryDate,
    String? referenceType,
    Value<String?> referenceId = const Value.absent(),
    String? currencyId,
    double? exchangeRate,
    Value<String?> description = const Value.absent(),
    String? status,
    DateTime? createdAt,
  }) => JournalEntryData(
    id: id ?? this.id,
    fiscalYearId: fiscalYearId ?? this.fiscalYearId,
    entryNumber: entryNumber ?? this.entryNumber,
    entryDate: entryDate ?? this.entryDate,
    referenceType: referenceType ?? this.referenceType,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    currencyId: currencyId ?? this.currencyId,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  JournalEntryData copyWithCompanion(JournalEntriesTableCompanion data) {
    return JournalEntryData(
      id: data.id.present ? data.id.value : this.id,
      fiscalYearId: data.fiscalYearId.present
          ? data.fiscalYearId.value
          : this.fiscalYearId,
      entryNumber: data.entryNumber.present
          ? data.entryNumber.value
          : this.entryNumber,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      currencyId: data.currencyId.present
          ? data.currencyId.value
          : this.currencyId,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntryData(')
          ..write('id: $id, ')
          ..write('fiscalYearId: $fiscalYearId, ')
          ..write('entryNumber: $entryNumber, ')
          ..write('entryDate: $entryDate, ')
          ..write('referenceType: $referenceType, ')
          ..write('referenceId: $referenceId, ')
          ..write('currencyId: $currencyId, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fiscalYearId,
    entryNumber,
    entryDate,
    referenceType,
    referenceId,
    currencyId,
    exchangeRate,
    description,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntryData &&
          other.id == this.id &&
          other.fiscalYearId == this.fiscalYearId &&
          other.entryNumber == this.entryNumber &&
          other.entryDate == this.entryDate &&
          other.referenceType == this.referenceType &&
          other.referenceId == this.referenceId &&
          other.currencyId == this.currencyId &&
          other.exchangeRate == this.exchangeRate &&
          other.description == this.description &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class JournalEntriesTableCompanion extends UpdateCompanion<JournalEntryData> {
  final Value<String> id;
  final Value<String> fiscalYearId;
  final Value<String> entryNumber;
  final Value<DateTime> entryDate;
  final Value<String> referenceType;
  final Value<String?> referenceId;
  final Value<String> currencyId;
  final Value<double> exchangeRate;
  final Value<String?> description;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const JournalEntriesTableCompanion({
    this.id = const Value.absent(),
    this.fiscalYearId = const Value.absent(),
    this.entryNumber = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.currencyId = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalEntriesTableCompanion.insert({
    this.id = const Value.absent(),
    required String fiscalYearId,
    required String entryNumber,
    this.entryDate = const Value.absent(),
    required String referenceType,
    this.referenceId = const Value.absent(),
    required String currencyId,
    this.exchangeRate = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fiscalYearId = Value(fiscalYearId),
       entryNumber = Value(entryNumber),
       referenceType = Value(referenceType),
       currencyId = Value(currencyId);
  static Insertable<JournalEntryData> custom({
    Expression<String>? id,
    Expression<String>? fiscalYearId,
    Expression<String>? entryNumber,
    Expression<DateTime>? entryDate,
    Expression<String>? referenceType,
    Expression<String>? referenceId,
    Expression<String>? currencyId,
    Expression<double>? exchangeRate,
    Expression<String>? description,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fiscalYearId != null) 'fiscal_year_id': fiscalYearId,
      if (entryNumber != null) 'entry_number': entryNumber,
      if (entryDate != null) 'entry_date': entryDate,
      if (referenceType != null) 'reference_type': referenceType,
      if (referenceId != null) 'reference_id': referenceId,
      if (currencyId != null) 'currency_id': currencyId,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalEntriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? fiscalYearId,
    Value<String>? entryNumber,
    Value<DateTime>? entryDate,
    Value<String>? referenceType,
    Value<String?>? referenceId,
    Value<String>? currencyId,
    Value<double>? exchangeRate,
    Value<String?>? description,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return JournalEntriesTableCompanion(
      id: id ?? this.id,
      fiscalYearId: fiscalYearId ?? this.fiscalYearId,
      entryNumber: entryNumber ?? this.entryNumber,
      entryDate: entryDate ?? this.entryDate,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      currencyId: currencyId ?? this.currencyId,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fiscalYearId.present) {
      map['fiscal_year_id'] = Variable<String>(fiscalYearId.value);
    }
    if (entryNumber.present) {
      map['entry_number'] = Variable<String>(entryNumber.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<DateTime>(entryDate.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (currencyId.present) {
      map['currency_id'] = Variable<String>(currencyId.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('fiscalYearId: $fiscalYearId, ')
          ..write('entryNumber: $entryNumber, ')
          ..write('entryDate: $entryDate, ')
          ..write('referenceType: $referenceType, ')
          ..write('referenceId: $referenceId, ')
          ..write('currencyId: $currencyId, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalEntryLinesTableTable extends JournalEntryLinesTable
    with TableInfo<$JournalEntryLinesTableTable, JournalEntryLineData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntryLinesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _journalEntryIdMeta = const VerificationMeta(
    'journalEntryId',
  );
  @override
  late final GeneratedColumn<String> journalEntryId = GeneratedColumn<String>(
    'journal_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES journal_entries_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _lineNumberMeta = const VerificationMeta(
    'lineNumber',
  );
  @override
  late final GeneratedColumn<int> lineNumber = GeneratedColumn<int>(
    'line_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chart_of_accounts_table (id)',
    ),
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
  static const VerificationMeta _debitMeta = const VerificationMeta('debit');
  @override
  late final GeneratedColumn<double> debit = GeneratedColumn<double>(
    'debit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _creditMeta = const VerificationMeta('credit');
  @override
  late final GeneratedColumn<double> credit = GeneratedColumn<double>(
    'credit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _baseDebitMeta = const VerificationMeta(
    'baseDebit',
  );
  @override
  late final GeneratedColumn<double> baseDebit = GeneratedColumn<double>(
    'base_debit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _baseCreditMeta = const VerificationMeta(
    'baseCredit',
  );
  @override
  late final GeneratedColumn<double> baseCredit = GeneratedColumn<double>(
    'base_credit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    journalEntryId,
    lineNumber,
    accountId,
    description,
    debit,
    credit,
    baseDebit,
    baseCredit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entry_lines_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntryLineData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('journal_entry_id')) {
      context.handle(
        _journalEntryIdMeta,
        journalEntryId.isAcceptableOrUnknown(
          data['journal_entry_id']!,
          _journalEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_journalEntryIdMeta);
    }
    if (data.containsKey('line_number')) {
      context.handle(
        _lineNumberMeta,
        lineNumber.isAcceptableOrUnknown(data['line_number']!, _lineNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNumberMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
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
    if (data.containsKey('debit')) {
      context.handle(
        _debitMeta,
        debit.isAcceptableOrUnknown(data['debit']!, _debitMeta),
      );
    }
    if (data.containsKey('credit')) {
      context.handle(
        _creditMeta,
        credit.isAcceptableOrUnknown(data['credit']!, _creditMeta),
      );
    }
    if (data.containsKey('base_debit')) {
      context.handle(
        _baseDebitMeta,
        baseDebit.isAcceptableOrUnknown(data['base_debit']!, _baseDebitMeta),
      );
    }
    if (data.containsKey('base_credit')) {
      context.handle(
        _baseCreditMeta,
        baseCredit.isAcceptableOrUnknown(data['base_credit']!, _baseCreditMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntryLineData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntryLineData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      journalEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journal_entry_id'],
      )!,
      lineNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_number'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      debit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}debit'],
      )!,
      credit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit'],
      )!,
      baseDebit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_debit'],
      )!,
      baseCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_credit'],
      )!,
    );
  }

  @override
  $JournalEntryLinesTableTable createAlias(String alias) {
    return $JournalEntryLinesTableTable(attachedDatabase, alias);
  }
}

class JournalEntryLineData extends DataClass
    implements Insertable<JournalEntryLineData> {
  final String id;
  final String journalEntryId;
  final int lineNumber;
  final String accountId;
  final String? description;
  final double debit;
  final double credit;
  final double baseDebit;
  final double baseCredit;
  const JournalEntryLineData({
    required this.id,
    required this.journalEntryId,
    required this.lineNumber,
    required this.accountId,
    this.description,
    required this.debit,
    required this.credit,
    required this.baseDebit,
    required this.baseCredit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['journal_entry_id'] = Variable<String>(journalEntryId);
    map['line_number'] = Variable<int>(lineNumber);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['debit'] = Variable<double>(debit);
    map['credit'] = Variable<double>(credit);
    map['base_debit'] = Variable<double>(baseDebit);
    map['base_credit'] = Variable<double>(baseCredit);
    return map;
  }

  JournalEntryLinesTableCompanion toCompanion(bool nullToAbsent) {
    return JournalEntryLinesTableCompanion(
      id: Value(id),
      journalEntryId: Value(journalEntryId),
      lineNumber: Value(lineNumber),
      accountId: Value(accountId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      debit: Value(debit),
      credit: Value(credit),
      baseDebit: Value(baseDebit),
      baseCredit: Value(baseCredit),
    );
  }

  factory JournalEntryLineData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntryLineData(
      id: serializer.fromJson<String>(json['id']),
      journalEntryId: serializer.fromJson<String>(json['journalEntryId']),
      lineNumber: serializer.fromJson<int>(json['lineNumber']),
      accountId: serializer.fromJson<String>(json['accountId']),
      description: serializer.fromJson<String?>(json['description']),
      debit: serializer.fromJson<double>(json['debit']),
      credit: serializer.fromJson<double>(json['credit']),
      baseDebit: serializer.fromJson<double>(json['baseDebit']),
      baseCredit: serializer.fromJson<double>(json['baseCredit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'journalEntryId': serializer.toJson<String>(journalEntryId),
      'lineNumber': serializer.toJson<int>(lineNumber),
      'accountId': serializer.toJson<String>(accountId),
      'description': serializer.toJson<String?>(description),
      'debit': serializer.toJson<double>(debit),
      'credit': serializer.toJson<double>(credit),
      'baseDebit': serializer.toJson<double>(baseDebit),
      'baseCredit': serializer.toJson<double>(baseCredit),
    };
  }

  JournalEntryLineData copyWith({
    String? id,
    String? journalEntryId,
    int? lineNumber,
    String? accountId,
    Value<String?> description = const Value.absent(),
    double? debit,
    double? credit,
    double? baseDebit,
    double? baseCredit,
  }) => JournalEntryLineData(
    id: id ?? this.id,
    journalEntryId: journalEntryId ?? this.journalEntryId,
    lineNumber: lineNumber ?? this.lineNumber,
    accountId: accountId ?? this.accountId,
    description: description.present ? description.value : this.description,
    debit: debit ?? this.debit,
    credit: credit ?? this.credit,
    baseDebit: baseDebit ?? this.baseDebit,
    baseCredit: baseCredit ?? this.baseCredit,
  );
  JournalEntryLineData copyWithCompanion(JournalEntryLinesTableCompanion data) {
    return JournalEntryLineData(
      id: data.id.present ? data.id.value : this.id,
      journalEntryId: data.journalEntryId.present
          ? data.journalEntryId.value
          : this.journalEntryId,
      lineNumber: data.lineNumber.present
          ? data.lineNumber.value
          : this.lineNumber,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      description: data.description.present
          ? data.description.value
          : this.description,
      debit: data.debit.present ? data.debit.value : this.debit,
      credit: data.credit.present ? data.credit.value : this.credit,
      baseDebit: data.baseDebit.present ? data.baseDebit.value : this.baseDebit,
      baseCredit: data.baseCredit.present
          ? data.baseCredit.value
          : this.baseCredit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntryLineData(')
          ..write('id: $id, ')
          ..write('journalEntryId: $journalEntryId, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('accountId: $accountId, ')
          ..write('description: $description, ')
          ..write('debit: $debit, ')
          ..write('credit: $credit, ')
          ..write('baseDebit: $baseDebit, ')
          ..write('baseCredit: $baseCredit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    journalEntryId,
    lineNumber,
    accountId,
    description,
    debit,
    credit,
    baseDebit,
    baseCredit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntryLineData &&
          other.id == this.id &&
          other.journalEntryId == this.journalEntryId &&
          other.lineNumber == this.lineNumber &&
          other.accountId == this.accountId &&
          other.description == this.description &&
          other.debit == this.debit &&
          other.credit == this.credit &&
          other.baseDebit == this.baseDebit &&
          other.baseCredit == this.baseCredit);
}

class JournalEntryLinesTableCompanion
    extends UpdateCompanion<JournalEntryLineData> {
  final Value<String> id;
  final Value<String> journalEntryId;
  final Value<int> lineNumber;
  final Value<String> accountId;
  final Value<String?> description;
  final Value<double> debit;
  final Value<double> credit;
  final Value<double> baseDebit;
  final Value<double> baseCredit;
  final Value<int> rowid;
  const JournalEntryLinesTableCompanion({
    this.id = const Value.absent(),
    this.journalEntryId = const Value.absent(),
    this.lineNumber = const Value.absent(),
    this.accountId = const Value.absent(),
    this.description = const Value.absent(),
    this.debit = const Value.absent(),
    this.credit = const Value.absent(),
    this.baseDebit = const Value.absent(),
    this.baseCredit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalEntryLinesTableCompanion.insert({
    this.id = const Value.absent(),
    required String journalEntryId,
    required int lineNumber,
    required String accountId,
    this.description = const Value.absent(),
    this.debit = const Value.absent(),
    this.credit = const Value.absent(),
    this.baseDebit = const Value.absent(),
    this.baseCredit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : journalEntryId = Value(journalEntryId),
       lineNumber = Value(lineNumber),
       accountId = Value(accountId);
  static Insertable<JournalEntryLineData> custom({
    Expression<String>? id,
    Expression<String>? journalEntryId,
    Expression<int>? lineNumber,
    Expression<String>? accountId,
    Expression<String>? description,
    Expression<double>? debit,
    Expression<double>? credit,
    Expression<double>? baseDebit,
    Expression<double>? baseCredit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (journalEntryId != null) 'journal_entry_id': journalEntryId,
      if (lineNumber != null) 'line_number': lineNumber,
      if (accountId != null) 'account_id': accountId,
      if (description != null) 'description': description,
      if (debit != null) 'debit': debit,
      if (credit != null) 'credit': credit,
      if (baseDebit != null) 'base_debit': baseDebit,
      if (baseCredit != null) 'base_credit': baseCredit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalEntryLinesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? journalEntryId,
    Value<int>? lineNumber,
    Value<String>? accountId,
    Value<String?>? description,
    Value<double>? debit,
    Value<double>? credit,
    Value<double>? baseDebit,
    Value<double>? baseCredit,
    Value<int>? rowid,
  }) {
    return JournalEntryLinesTableCompanion(
      id: id ?? this.id,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      lineNumber: lineNumber ?? this.lineNumber,
      accountId: accountId ?? this.accountId,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      baseDebit: baseDebit ?? this.baseDebit,
      baseCredit: baseCredit ?? this.baseCredit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (journalEntryId.present) {
      map['journal_entry_id'] = Variable<String>(journalEntryId.value);
    }
    if (lineNumber.present) {
      map['line_number'] = Variable<int>(lineNumber.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (debit.present) {
      map['debit'] = Variable<double>(debit.value);
    }
    if (credit.present) {
      map['credit'] = Variable<double>(credit.value);
    }
    if (baseDebit.present) {
      map['base_debit'] = Variable<double>(baseDebit.value);
    }
    if (baseCredit.present) {
      map['base_credit'] = Variable<double>(baseCredit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntryLinesTableCompanion(')
          ..write('id: $id, ')
          ..write('journalEntryId: $journalEntryId, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('accountId: $accountId, ')
          ..write('description: $description, ')
          ..write('debit: $debit, ')
          ..write('credit: $credit, ')
          ..write('baseDebit: $baseDebit, ')
          ..write('baseCredit: $baseCredit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PartiesTableTable extends PartiesTable
    with TableInfo<$PartiesTableTable, PartyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partyTypeMeta = const VerificationMeta(
    'partyType',
  );
  @override
  late final GeneratedColumn<String> partyType = GeneratedColumn<String>(
    'party_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chart_of_accounts_table (id)',
    ),
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
    'credit_limit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<double> openingBalance = GeneratedColumn<double>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _openingBalanceTypeMeta =
      const VerificationMeta('openingBalanceType');
  @override
  late final GeneratedColumn<String> openingBalanceType =
      GeneratedColumn<String>(
        'opening_balance_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    partyType,
    phone,
    email,
    address,
    accountId,
    creditLimit,
    openingBalance,
    openingBalanceType,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parties_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PartyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('party_type')) {
      context.handle(
        _partyTypeMeta,
        partyType.isAcceptableOrUnknown(data['party_type']!, _partyTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_partyTypeMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance_type')) {
      context.handle(
        _openingBalanceTypeMeta,
        openingBalanceType.isAcceptableOrUnknown(
          data['opening_balance_type']!,
          _openingBalanceTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PartyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PartyData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      partyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_type'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      )!,
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opening_balance'],
      )!,
      openingBalanceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_balance_type'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PartiesTableTable createAlias(String alias) {
    return $PartiesTableTable(attachedDatabase, alias);
  }
}

class PartyData extends DataClass implements Insertable<PartyData> {
  final String id;
  final String name;

  /// Party type: 'Customer', 'Supplier', 'Both'
  final String partyType;
  final String? phone;
  final String? email;
  final String? address;

  /// Linked ledger account in chart_of_accounts
  final String accountId;
  final double creditLimit;
  final double openingBalance;

  /// Opening balance direction: 'Debit' (owes us) or 'Credit' (we owe them)
  final String? openingBalanceType;
  final bool isActive;
  final DateTime createdAt;
  const PartyData({
    required this.id,
    required this.name,
    required this.partyType,
    this.phone,
    this.email,
    this.address,
    required this.accountId,
    required this.creditLimit,
    required this.openingBalance,
    this.openingBalanceType,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['party_type'] = Variable<String>(partyType);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['account_id'] = Variable<String>(accountId);
    map['credit_limit'] = Variable<double>(creditLimit);
    map['opening_balance'] = Variable<double>(openingBalance);
    if (!nullToAbsent || openingBalanceType != null) {
      map['opening_balance_type'] = Variable<String>(openingBalanceType);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PartiesTableCompanion toCompanion(bool nullToAbsent) {
    return PartiesTableCompanion(
      id: Value(id),
      name: Value(name),
      partyType: Value(partyType),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      accountId: Value(accountId),
      creditLimit: Value(creditLimit),
      openingBalance: Value(openingBalance),
      openingBalanceType: openingBalanceType == null && nullToAbsent
          ? const Value.absent()
          : Value(openingBalanceType),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory PartyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PartyData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      partyType: serializer.fromJson<String>(json['partyType']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      accountId: serializer.fromJson<String>(json['accountId']),
      creditLimit: serializer.fromJson<double>(json['creditLimit']),
      openingBalance: serializer.fromJson<double>(json['openingBalance']),
      openingBalanceType: serializer.fromJson<String?>(
        json['openingBalanceType'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'partyType': serializer.toJson<String>(partyType),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'accountId': serializer.toJson<String>(accountId),
      'creditLimit': serializer.toJson<double>(creditLimit),
      'openingBalance': serializer.toJson<double>(openingBalance),
      'openingBalanceType': serializer.toJson<String?>(openingBalanceType),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PartyData copyWith({
    String? id,
    String? name,
    String? partyType,
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> address = const Value.absent(),
    String? accountId,
    double? creditLimit,
    double? openingBalance,
    Value<String?> openingBalanceType = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
  }) => PartyData(
    id: id ?? this.id,
    name: name ?? this.name,
    partyType: partyType ?? this.partyType,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    address: address.present ? address.value : this.address,
    accountId: accountId ?? this.accountId,
    creditLimit: creditLimit ?? this.creditLimit,
    openingBalance: openingBalance ?? this.openingBalance,
    openingBalanceType: openingBalanceType.present
        ? openingBalanceType.value
        : this.openingBalanceType,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  PartyData copyWithCompanion(PartiesTableCompanion data) {
    return PartyData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      partyType: data.partyType.present ? data.partyType.value : this.partyType,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      openingBalanceType: data.openingBalanceType.present
          ? data.openingBalanceType.value
          : this.openingBalanceType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PartyData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('partyType: $partyType, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('accountId: $accountId, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingBalanceType: $openingBalanceType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    partyType,
    phone,
    email,
    address,
    accountId,
    creditLimit,
    openingBalance,
    openingBalanceType,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartyData &&
          other.id == this.id &&
          other.name == this.name &&
          other.partyType == this.partyType &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.accountId == this.accountId &&
          other.creditLimit == this.creditLimit &&
          other.openingBalance == this.openingBalance &&
          other.openingBalanceType == this.openingBalanceType &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class PartiesTableCompanion extends UpdateCompanion<PartyData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> partyType;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String> accountId;
  final Value<double> creditLimit;
  final Value<double> openingBalance;
  final Value<String?> openingBalanceType;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PartiesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.partyType = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.accountId = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.openingBalanceType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PartiesTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String partyType,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    required String accountId,
    this.creditLimit = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.openingBalanceType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       partyType = Value(partyType),
       accountId = Value(accountId);
  static Insertable<PartyData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? partyType,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? accountId,
    Expression<double>? creditLimit,
    Expression<double>? openingBalance,
    Expression<String>? openingBalanceType,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (partyType != null) 'party_type': partyType,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (accountId != null) 'account_id': accountId,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (openingBalanceType != null)
        'opening_balance_type': openingBalanceType,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PartiesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? partyType,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? address,
    Value<String>? accountId,
    Value<double>? creditLimit,
    Value<double>? openingBalance,
    Value<String?>? openingBalanceType,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PartiesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      partyType: partyType ?? this.partyType,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      accountId: accountId ?? this.accountId,
      creditLimit: creditLimit ?? this.creditLimit,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceType: openingBalanceType ?? this.openingBalanceType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
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
    if (partyType.present) {
      map['party_type'] = Variable<String>(partyType.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<double>(openingBalance.value);
    }
    if (openingBalanceType.present) {
      map['opening_balance_type'] = Variable<String>(openingBalanceType.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartiesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('partyType: $partyType, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('accountId: $accountId, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingBalanceType: $openingBalanceType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentMethodsTableTable extends PaymentMethodsTable
    with TableInfo<$PaymentMethodsTableTable, PaymentMethodData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentMethodsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chart_of_accounts_table (id)',
    ),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    accountId,
    isDefault,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentMethodData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethodData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethodData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $PaymentMethodsTableTable createAlias(String alias) {
    return $PaymentMethodsTableTable(attachedDatabase, alias);
  }
}

class PaymentMethodData extends DataClass
    implements Insertable<PaymentMethodData> {
  final String id;
  final String name;

  /// Type: 'Cash', 'Bank', 'Network'
  final String type;

  /// Linked asset account in chart_of_accounts (Cash drawer or Bank asset)
  final String accountId;
  final bool isDefault;
  final bool isActive;
  const PaymentMethodData({
    required this.id,
    required this.name,
    required this.type,
    required this.accountId,
    required this.isDefault,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['account_id'] = Variable<String>(accountId);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  PaymentMethodsTableCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodsTableCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      accountId: Value(accountId),
      isDefault: Value(isDefault),
      isActive: Value(isActive),
    );
  }

  factory PaymentMethodData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethodData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      accountId: serializer.fromJson<String>(json['accountId']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'accountId': serializer.toJson<String>(accountId),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  PaymentMethodData copyWith({
    String? id,
    String? name,
    String? type,
    String? accountId,
    bool? isDefault,
    bool? isActive,
  }) => PaymentMethodData(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    accountId: accountId ?? this.accountId,
    isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive,
  );
  PaymentMethodData copyWithCompanion(PaymentMethodsTableCompanion data) {
    return PaymentMethodData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, accountId, isDefault, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethodData &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.accountId == this.accountId &&
          other.isDefault == this.isDefault &&
          other.isActive == this.isActive);
}

class PaymentMethodsTableCompanion extends UpdateCompanion<PaymentMethodData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> accountId;
  final Value<bool> isDefault;
  final Value<bool> isActive;
  final Value<int> rowid;
  const PaymentMethodsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.accountId = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentMethodsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    required String accountId,
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       accountId = Value(accountId);
  static Insertable<PaymentMethodData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? accountId,
    Expression<bool>? isDefault,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (accountId != null) 'account_id': accountId,
      if (isDefault != null) 'is_default': isDefault,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentMethodsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? accountId,
    Value<bool>? isDefault,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return PaymentMethodsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTableTable extends UnitsTable
    with TableInfo<$UnitsTableTable, UnitData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, nameAr, code, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnitData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnitData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $UnitsTableTable createAlias(String alias) {
    return $UnitsTableTable(attachedDatabase, alias);
  }
}

class UnitData extends DataClass implements Insertable<UnitData> {
  final String id;
  final String nameAr;
  final String code;
  final bool isActive;
  const UnitData({
    required this.id,
    required this.nameAr,
    required this.code,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name_ar'] = Variable<String>(nameAr);
    map['code'] = Variable<String>(code);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  UnitsTableCompanion toCompanion(bool nullToAbsent) {
    return UnitsTableCompanion(
      id: Value(id),
      nameAr: Value(nameAr),
      code: Value(code),
      isActive: Value(isActive),
    );
  }

  factory UnitData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitData(
      id: serializer.fromJson<String>(json['id']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      code: serializer.fromJson<String>(json['code']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nameAr': serializer.toJson<String>(nameAr),
      'code': serializer.toJson<String>(code),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  UnitData copyWith({
    String? id,
    String? nameAr,
    String? code,
    bool? isActive,
  }) => UnitData(
    id: id ?? this.id,
    nameAr: nameAr ?? this.nameAr,
    code: code ?? this.code,
    isActive: isActive ?? this.isActive,
  );
  UnitData copyWithCompanion(UnitsTableCompanion data) {
    return UnitData(
      id: data.id.present ? data.id.value : this.id,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      code: data.code.present ? data.code.value : this.code,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitData(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('code: $code, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nameAr, code, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitData &&
          other.id == this.id &&
          other.nameAr == this.nameAr &&
          other.code == this.code &&
          other.isActive == this.isActive);
}

class UnitsTableCompanion extends UpdateCompanion<UnitData> {
  final Value<String> id;
  final Value<String> nameAr;
  final Value<String> code;
  final Value<bool> isActive;
  final Value<int> rowid;
  const UnitsTableCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.code = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitsTableCompanion.insert({
    this.id = const Value.absent(),
    required String nameAr,
    required String code,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : nameAr = Value(nameAr),
       code = Value(code);
  static Insertable<UnitData> custom({
    Expression<String>? id,
    Expression<String>? nameAr,
    Expression<String>? code,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameAr != null) 'name_ar': nameAr,
      if (code != null) 'code': code,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? nameAr,
    Value<String>? code,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return UnitsTableCompanion(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsTableCompanion(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('code: $code, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isStockableMeta = const VerificationMeta(
    'isStockable',
  );
  @override
  late final GeneratedColumn<bool> isStockable = GeneratedColumn<bool>(
    'is_stockable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_stockable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _baseUnitIdMeta = const VerificationMeta(
    'baseUnitId',
  );
  @override
  late final GeneratedColumn<String> baseUnitId = GeneratedColumn<String>(
    'base_unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES units_table (id)',
    ),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    sku,
    imagePath,
    isStockable,
    baseUnitId,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('is_stockable')) {
      context.handle(
        _isStockableMeta,
        isStockable.isAcceptableOrUnknown(
          data['is_stockable']!,
          _isStockableMeta,
        ),
      );
    }
    if (data.containsKey('base_unit_id')) {
      context.handle(
        _baseUnitIdMeta,
        baseUnitId.isAcceptableOrUnknown(
          data['base_unit_id']!,
          _baseUnitIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseUnitIdMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      isStockable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_stockable'],
      )!,
      baseUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_unit_id'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductData extends DataClass implements Insertable<ProductData> {
  final String id;
  final String name;
  final String? category;
  final String? sku;
  final String? imagePath;

  /// Whether the item is a tracked physical inventory item (true) or a service/charge (false)
  final bool isStockable;

  /// Base smallest atomic unit for inventory accounting (e.g. Piece/حبة)
  final String baseUnitId;
  final bool isActive;
  final DateTime createdAt;
  const ProductData({
    required this.id,
    required this.name,
    this.category,
    this.sku,
    this.imagePath,
    required this.isStockable,
    required this.baseUnitId,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_stockable'] = Variable<bool>(isStockable);
    map['base_unit_id'] = Variable<String>(baseUnitId);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isStockable: Value(isStockable),
      baseUnitId: Value(baseUnitId),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory ProductData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      sku: serializer.fromJson<String?>(json['sku']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isStockable: serializer.fromJson<bool>(json['isStockable']),
      baseUnitId: serializer.fromJson<String>(json['baseUnitId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'sku': serializer.toJson<String?>(sku),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isStockable': serializer.toJson<bool>(isStockable),
      'baseUnitId': serializer.toJson<String>(baseUnitId),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProductData copyWith({
    String? id,
    String? name,
    Value<String?> category = const Value.absent(),
    Value<String?> sku = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    bool? isStockable,
    String? baseUnitId,
    bool? isActive,
    DateTime? createdAt,
  }) => ProductData(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category.present ? category.value : this.category,
    sku: sku.present ? sku.value : this.sku,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    isStockable: isStockable ?? this.isStockable,
    baseUnitId: baseUnitId ?? this.baseUnitId,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  ProductData copyWithCompanion(ProductsTableCompanion data) {
    return ProductData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      sku: data.sku.present ? data.sku.value : this.sku,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isStockable: data.isStockable.present
          ? data.isStockable.value
          : this.isStockable,
      baseUnitId: data.baseUnitId.present
          ? data.baseUnitId.value
          : this.baseUnitId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('sku: $sku, ')
          ..write('imagePath: $imagePath, ')
          ..write('isStockable: $isStockable, ')
          ..write('baseUnitId: $baseUnitId, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    sku,
    imagePath,
    isStockable,
    baseUnitId,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductData &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.sku == this.sku &&
          other.imagePath == this.imagePath &&
          other.isStockable == this.isStockable &&
          other.baseUnitId == this.baseUnitId &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class ProductsTableCompanion extends UpdateCompanion<ProductData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> category;
  final Value<String?> sku;
  final Value<String?> imagePath;
  final Value<bool> isStockable;
  final Value<String> baseUnitId;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.sku = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isStockable = const Value.absent(),
    this.baseUnitId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.category = const Value.absent(),
    this.sku = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isStockable = const Value.absent(),
    required String baseUnitId,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       baseUnitId = Value(baseUnitId);
  static Insertable<ProductData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? sku,
    Expression<String>? imagePath,
    Expression<bool>? isStockable,
    Expression<String>? baseUnitId,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (sku != null) 'sku': sku,
      if (imagePath != null) 'image_path': imagePath,
      if (isStockable != null) 'is_stockable': isStockable,
      if (baseUnitId != null) 'base_unit_id': baseUnitId,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? category,
    Value<String?>? sku,
    Value<String?>? imagePath,
    Value<bool>? isStockable,
    Value<String>? baseUnitId,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      imagePath: imagePath ?? this.imagePath,
      isStockable: isStockable ?? this.isStockable,
      baseUnitId: baseUnitId ?? this.baseUnitId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isStockable.present) {
      map['is_stockable'] = Variable<bool>(isStockable.value);
    }
    if (baseUnitId.present) {
      map['base_unit_id'] = Variable<String>(baseUnitId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('sku: $sku, ')
          ..write('imagePath: $imagePath, ')
          ..write('isStockable: $isStockable, ')
          ..write('baseUnitId: $baseUnitId, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductUnitsTableTable extends ProductUnitsTable
    with TableInfo<$ProductUnitsTableTable, ProductUnitData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductUnitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES units_table (id)',
    ),
  );
  static const VerificationMeta _conversionFactorMeta = const VerificationMeta(
    'conversionFactor',
  );
  @override
  late final GeneratedColumn<double> conversionFactor = GeneratedColumn<double>(
    'conversion_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _salePriceMeta = const VerificationMeta(
    'salePrice',
  );
  @override
  late final GeneratedColumn<double> salePrice = GeneratedColumn<double>(
    'sale_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _minSalePriceMeta = const VerificationMeta(
    'minSalePrice',
  );
  @override
  late final GeneratedColumn<double> minSalePrice = GeneratedColumn<double>(
    'min_sale_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _purchasePriceMeta = const VerificationMeta(
    'purchasePrice',
  );
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
    'purchase_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isDefaultSaleUnitMeta = const VerificationMeta(
    'isDefaultSaleUnit',
  );
  @override
  late final GeneratedColumn<bool> isDefaultSaleUnit = GeneratedColumn<bool>(
    'is_default_sale_unit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default_sale_unit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDefaultPurchaseUnitMeta =
      const VerificationMeta('isDefaultPurchaseUnit');
  @override
  late final GeneratedColumn<bool> isDefaultPurchaseUnit =
      GeneratedColumn<bool>(
        'is_default_purchase_unit',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_default_purchase_unit" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    unitId,
    conversionFactor,
    barcode,
    salePrice,
    minSalePrice,
    purchasePrice,
    isDefaultSaleUnit,
    isDefaultPurchaseUnit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_units_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductUnitData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('conversion_factor')) {
      context.handle(
        _conversionFactorMeta,
        conversionFactor.isAcceptableOrUnknown(
          data['conversion_factor']!,
          _conversionFactorMeta,
        ),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('sale_price')) {
      context.handle(
        _salePriceMeta,
        salePrice.isAcceptableOrUnknown(data['sale_price']!, _salePriceMeta),
      );
    }
    if (data.containsKey('min_sale_price')) {
      context.handle(
        _minSalePriceMeta,
        minSalePrice.isAcceptableOrUnknown(
          data['min_sale_price']!,
          _minSalePriceMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
        _purchasePriceMeta,
        purchasePrice.isAcceptableOrUnknown(
          data['purchase_price']!,
          _purchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('is_default_sale_unit')) {
      context.handle(
        _isDefaultSaleUnitMeta,
        isDefaultSaleUnit.isAcceptableOrUnknown(
          data['is_default_sale_unit']!,
          _isDefaultSaleUnitMeta,
        ),
      );
    }
    if (data.containsKey('is_default_purchase_unit')) {
      context.handle(
        _isDefaultPurchaseUnitMeta,
        isDefaultPurchaseUnit.isAcceptableOrUnknown(
          data['is_default_purchase_unit']!,
          _isDefaultPurchaseUnitMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductUnitData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductUnitData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      )!,
      conversionFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}conversion_factor'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      salePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sale_price'],
      )!,
      minSalePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_sale_price'],
      )!,
      purchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_price'],
      )!,
      isDefaultSaleUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default_sale_unit'],
      )!,
      isDefaultPurchaseUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default_purchase_unit'],
      )!,
    );
  }

  @override
  $ProductUnitsTableTable createAlias(String alias) {
    return $ProductUnitsTableTable(attachedDatabase, alias);
  }
}

class ProductUnitData extends DataClass implements Insertable<ProductUnitData> {
  final String id;
  final String productId;
  final String unitId;

  /// Multiplier to convert this unit into the product's base unit (Piece = 1.0, Carton = 24.0)
  final double conversionFactor;
  final String? barcode;
  final double salePrice;
  final double minSalePrice;
  final double purchasePrice;
  final bool isDefaultSaleUnit;
  final bool isDefaultPurchaseUnit;
  const ProductUnitData({
    required this.id,
    required this.productId,
    required this.unitId,
    required this.conversionFactor,
    this.barcode,
    required this.salePrice,
    required this.minSalePrice,
    required this.purchasePrice,
    required this.isDefaultSaleUnit,
    required this.isDefaultPurchaseUnit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['unit_id'] = Variable<String>(unitId);
    map['conversion_factor'] = Variable<double>(conversionFactor);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['sale_price'] = Variable<double>(salePrice);
    map['min_sale_price'] = Variable<double>(minSalePrice);
    map['purchase_price'] = Variable<double>(purchasePrice);
    map['is_default_sale_unit'] = Variable<bool>(isDefaultSaleUnit);
    map['is_default_purchase_unit'] = Variable<bool>(isDefaultPurchaseUnit);
    return map;
  }

  ProductUnitsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductUnitsTableCompanion(
      id: Value(id),
      productId: Value(productId),
      unitId: Value(unitId),
      conversionFactor: Value(conversionFactor),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      salePrice: Value(salePrice),
      minSalePrice: Value(minSalePrice),
      purchasePrice: Value(purchasePrice),
      isDefaultSaleUnit: Value(isDefaultSaleUnit),
      isDefaultPurchaseUnit: Value(isDefaultPurchaseUnit),
    );
  }

  factory ProductUnitData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductUnitData(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      unitId: serializer.fromJson<String>(json['unitId']),
      conversionFactor: serializer.fromJson<double>(json['conversionFactor']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      salePrice: serializer.fromJson<double>(json['salePrice']),
      minSalePrice: serializer.fromJson<double>(json['minSalePrice']),
      purchasePrice: serializer.fromJson<double>(json['purchasePrice']),
      isDefaultSaleUnit: serializer.fromJson<bool>(json['isDefaultSaleUnit']),
      isDefaultPurchaseUnit: serializer.fromJson<bool>(
        json['isDefaultPurchaseUnit'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'unitId': serializer.toJson<String>(unitId),
      'conversionFactor': serializer.toJson<double>(conversionFactor),
      'barcode': serializer.toJson<String?>(barcode),
      'salePrice': serializer.toJson<double>(salePrice),
      'minSalePrice': serializer.toJson<double>(minSalePrice),
      'purchasePrice': serializer.toJson<double>(purchasePrice),
      'isDefaultSaleUnit': serializer.toJson<bool>(isDefaultSaleUnit),
      'isDefaultPurchaseUnit': serializer.toJson<bool>(isDefaultPurchaseUnit),
    };
  }

  ProductUnitData copyWith({
    String? id,
    String? productId,
    String? unitId,
    double? conversionFactor,
    Value<String?> barcode = const Value.absent(),
    double? salePrice,
    double? minSalePrice,
    double? purchasePrice,
    bool? isDefaultSaleUnit,
    bool? isDefaultPurchaseUnit,
  }) => ProductUnitData(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    unitId: unitId ?? this.unitId,
    conversionFactor: conversionFactor ?? this.conversionFactor,
    barcode: barcode.present ? barcode.value : this.barcode,
    salePrice: salePrice ?? this.salePrice,
    minSalePrice: minSalePrice ?? this.minSalePrice,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    isDefaultSaleUnit: isDefaultSaleUnit ?? this.isDefaultSaleUnit,
    isDefaultPurchaseUnit: isDefaultPurchaseUnit ?? this.isDefaultPurchaseUnit,
  );
  ProductUnitData copyWithCompanion(ProductUnitsTableCompanion data) {
    return ProductUnitData(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      conversionFactor: data.conversionFactor.present
          ? data.conversionFactor.value
          : this.conversionFactor,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      salePrice: data.salePrice.present ? data.salePrice.value : this.salePrice,
      minSalePrice: data.minSalePrice.present
          ? data.minSalePrice.value
          : this.minSalePrice,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      isDefaultSaleUnit: data.isDefaultSaleUnit.present
          ? data.isDefaultSaleUnit.value
          : this.isDefaultSaleUnit,
      isDefaultPurchaseUnit: data.isDefaultPurchaseUnit.present
          ? data.isDefaultPurchaseUnit.value
          : this.isDefaultPurchaseUnit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductUnitData(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('unitId: $unitId, ')
          ..write('conversionFactor: $conversionFactor, ')
          ..write('barcode: $barcode, ')
          ..write('salePrice: $salePrice, ')
          ..write('minSalePrice: $minSalePrice, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('isDefaultSaleUnit: $isDefaultSaleUnit, ')
          ..write('isDefaultPurchaseUnit: $isDefaultPurchaseUnit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    unitId,
    conversionFactor,
    barcode,
    salePrice,
    minSalePrice,
    purchasePrice,
    isDefaultSaleUnit,
    isDefaultPurchaseUnit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductUnitData &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.unitId == this.unitId &&
          other.conversionFactor == this.conversionFactor &&
          other.barcode == this.barcode &&
          other.salePrice == this.salePrice &&
          other.minSalePrice == this.minSalePrice &&
          other.purchasePrice == this.purchasePrice &&
          other.isDefaultSaleUnit == this.isDefaultSaleUnit &&
          other.isDefaultPurchaseUnit == this.isDefaultPurchaseUnit);
}

class ProductUnitsTableCompanion extends UpdateCompanion<ProductUnitData> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> unitId;
  final Value<double> conversionFactor;
  final Value<String?> barcode;
  final Value<double> salePrice;
  final Value<double> minSalePrice;
  final Value<double> purchasePrice;
  final Value<bool> isDefaultSaleUnit;
  final Value<bool> isDefaultPurchaseUnit;
  final Value<int> rowid;
  const ProductUnitsTableCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.conversionFactor = const Value.absent(),
    this.barcode = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.minSalePrice = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.isDefaultSaleUnit = const Value.absent(),
    this.isDefaultPurchaseUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductUnitsTableCompanion.insert({
    this.id = const Value.absent(),
    required String productId,
    required String unitId,
    this.conversionFactor = const Value.absent(),
    this.barcode = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.minSalePrice = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.isDefaultSaleUnit = const Value.absent(),
    this.isDefaultPurchaseUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       unitId = Value(unitId);
  static Insertable<ProductUnitData> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? unitId,
    Expression<double>? conversionFactor,
    Expression<String>? barcode,
    Expression<double>? salePrice,
    Expression<double>? minSalePrice,
    Expression<double>? purchasePrice,
    Expression<bool>? isDefaultSaleUnit,
    Expression<bool>? isDefaultPurchaseUnit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (unitId != null) 'unit_id': unitId,
      if (conversionFactor != null) 'conversion_factor': conversionFactor,
      if (barcode != null) 'barcode': barcode,
      if (salePrice != null) 'sale_price': salePrice,
      if (minSalePrice != null) 'min_sale_price': minSalePrice,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (isDefaultSaleUnit != null) 'is_default_sale_unit': isDefaultSaleUnit,
      if (isDefaultPurchaseUnit != null)
        'is_default_purchase_unit': isDefaultPurchaseUnit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductUnitsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? unitId,
    Value<double>? conversionFactor,
    Value<String?>? barcode,
    Value<double>? salePrice,
    Value<double>? minSalePrice,
    Value<double>? purchasePrice,
    Value<bool>? isDefaultSaleUnit,
    Value<bool>? isDefaultPurchaseUnit,
    Value<int>? rowid,
  }) {
    return ProductUnitsTableCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      unitId: unitId ?? this.unitId,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      barcode: barcode ?? this.barcode,
      salePrice: salePrice ?? this.salePrice,
      minSalePrice: minSalePrice ?? this.minSalePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      isDefaultSaleUnit: isDefaultSaleUnit ?? this.isDefaultSaleUnit,
      isDefaultPurchaseUnit:
          isDefaultPurchaseUnit ?? this.isDefaultPurchaseUnit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (conversionFactor.present) {
      map['conversion_factor'] = Variable<double>(conversionFactor.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (salePrice.present) {
      map['sale_price'] = Variable<double>(salePrice.value);
    }
    if (minSalePrice.present) {
      map['min_sale_price'] = Variable<double>(minSalePrice.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (isDefaultSaleUnit.present) {
      map['is_default_sale_unit'] = Variable<bool>(isDefaultSaleUnit.value);
    }
    if (isDefaultPurchaseUnit.present) {
      map['is_default_purchase_unit'] = Variable<bool>(
        isDefaultPurchaseUnit.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductUnitsTableCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('unitId: $unitId, ')
          ..write('conversionFactor: $conversionFactor, ')
          ..write('barcode: $barcode, ')
          ..write('salePrice: $salePrice, ')
          ..write('minSalePrice: $minSalePrice, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('isDefaultSaleUnit: $isDefaultSaleUnit, ')
          ..write('isDefaultPurchaseUnit: $isDefaultPurchaseUnit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WarehousesTableTable extends WarehousesTable
    with TableInfo<$WarehousesTableTable, WarehouseData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WarehousesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, code, isDefault, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'warehouses_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<WarehouseData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WarehouseData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WarehouseData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $WarehousesTableTable createAlias(String alias) {
    return $WarehousesTableTable(attachedDatabase, alias);
  }
}

class WarehouseData extends DataClass implements Insertable<WarehouseData> {
  final String id;
  final String name;
  final String code;
  final bool isDefault;
  final bool isActive;
  const WarehouseData({
    required this.id,
    required this.name,
    required this.code,
    required this.isDefault,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  WarehousesTableCompanion toCompanion(bool nullToAbsent) {
    return WarehousesTableCompanion(
      id: Value(id),
      name: Value(name),
      code: Value(code),
      isDefault: Value(isDefault),
      isActive: Value(isActive),
    );
  }

  factory WarehouseData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WarehouseData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  WarehouseData copyWith({
    String? id,
    String? name,
    String? code,
    bool? isDefault,
    bool? isActive,
  }) => WarehouseData(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code ?? this.code,
    isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive,
  );
  WarehouseData copyWithCompanion(WarehousesTableCompanion data) {
    return WarehouseData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WarehouseData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, code, isDefault, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WarehouseData &&
          other.id == this.id &&
          other.name == this.name &&
          other.code == this.code &&
          other.isDefault == this.isDefault &&
          other.isActive == this.isActive);
}

class WarehousesTableCompanion extends UpdateCompanion<WarehouseData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> code;
  final Value<bool> isDefault;
  final Value<bool> isActive;
  final Value<int> rowid;
  const WarehousesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WarehousesTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String code,
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       code = Value(code);
  static Insertable<WarehouseData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? code,
    Expression<bool>? isDefault,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (isDefault != null) 'is_default': isDefault,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WarehousesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? code,
    Value<bool>? isDefault,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return WarehousesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
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
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WarehousesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoriesTableTable extends InventoriesTable
    with TableInfo<$InventoriesTableTable, InventoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _warehouseIdMeta = const VerificationMeta(
    'warehouseId',
  );
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
    'warehouse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES warehouses_table (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products_table (id)',
    ),
  );
  static const VerificationMeta _quantityOnHandMeta = const VerificationMeta(
    'quantityOnHand',
  );
  @override
  late final GeneratedColumn<double> quantityOnHand = GeneratedColumn<double>(
    'quantity_on_hand',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _averageCostMeta = const VerificationMeta(
    'averageCost',
  );
  @override
  late final GeneratedColumn<double> averageCost = GeneratedColumn<double>(
    'average_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _alertQuantityMeta = const VerificationMeta(
    'alertQuantity',
  );
  @override
  late final GeneratedColumn<double> alertQuantity = GeneratedColumn<double>(
    'alert_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(5.0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    warehouseId,
    productId,
    quantityOnHand,
    averageCost,
    alertQuantity,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventories_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
        _warehouseIdMeta,
        warehouseId.isAcceptableOrUnknown(
          data['warehouse_id']!,
          _warehouseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warehouseIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity_on_hand')) {
      context.handle(
        _quantityOnHandMeta,
        quantityOnHand.isAcceptableOrUnknown(
          data['quantity_on_hand']!,
          _quantityOnHandMeta,
        ),
      );
    }
    if (data.containsKey('average_cost')) {
      context.handle(
        _averageCostMeta,
        averageCost.isAcceptableOrUnknown(
          data['average_cost']!,
          _averageCostMeta,
        ),
      );
    }
    if (data.containsKey('alert_quantity')) {
      context.handle(
        _alertQuantityMeta,
        alertQuantity.isAcceptableOrUnknown(
          data['alert_quantity']!,
          _alertQuantityMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {warehouseId, productId},
  ];
  @override
  InventoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      warehouseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warehouse_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantityOnHand: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_on_hand'],
      )!,
      averageCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_cost'],
      )!,
      alertQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alert_quantity'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InventoriesTableTable createAlias(String alias) {
    return $InventoriesTableTable(attachedDatabase, alias);
  }
}

class InventoryData extends DataClass implements Insertable<InventoryData> {
  final String id;
  final String warehouseId;
  final String productId;

  /// Current quantity on hand in the product's base unit
  final double quantityOnHand;

  /// Moving weighted average cost per base unit in base currency
  final double averageCost;
  final double alertQuantity;
  final DateTime updatedAt;
  const InventoryData({
    required this.id,
    required this.warehouseId,
    required this.productId,
    required this.quantityOnHand,
    required this.averageCost,
    required this.alertQuantity,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['warehouse_id'] = Variable<String>(warehouseId);
    map['product_id'] = Variable<String>(productId);
    map['quantity_on_hand'] = Variable<double>(quantityOnHand);
    map['average_cost'] = Variable<double>(averageCost);
    map['alert_quantity'] = Variable<double>(alertQuantity);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InventoriesTableCompanion toCompanion(bool nullToAbsent) {
    return InventoriesTableCompanion(
      id: Value(id),
      warehouseId: Value(warehouseId),
      productId: Value(productId),
      quantityOnHand: Value(quantityOnHand),
      averageCost: Value(averageCost),
      alertQuantity: Value(alertQuantity),
      updatedAt: Value(updatedAt),
    );
  }

  factory InventoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryData(
      id: serializer.fromJson<String>(json['id']),
      warehouseId: serializer.fromJson<String>(json['warehouseId']),
      productId: serializer.fromJson<String>(json['productId']),
      quantityOnHand: serializer.fromJson<double>(json['quantityOnHand']),
      averageCost: serializer.fromJson<double>(json['averageCost']),
      alertQuantity: serializer.fromJson<double>(json['alertQuantity']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'warehouseId': serializer.toJson<String>(warehouseId),
      'productId': serializer.toJson<String>(productId),
      'quantityOnHand': serializer.toJson<double>(quantityOnHand),
      'averageCost': serializer.toJson<double>(averageCost),
      'alertQuantity': serializer.toJson<double>(alertQuantity),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InventoryData copyWith({
    String? id,
    String? warehouseId,
    String? productId,
    double? quantityOnHand,
    double? averageCost,
    double? alertQuantity,
    DateTime? updatedAt,
  }) => InventoryData(
    id: id ?? this.id,
    warehouseId: warehouseId ?? this.warehouseId,
    productId: productId ?? this.productId,
    quantityOnHand: quantityOnHand ?? this.quantityOnHand,
    averageCost: averageCost ?? this.averageCost,
    alertQuantity: alertQuantity ?? this.alertQuantity,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InventoryData copyWithCompanion(InventoriesTableCompanion data) {
    return InventoryData(
      id: data.id.present ? data.id.value : this.id,
      warehouseId: data.warehouseId.present
          ? data.warehouseId.value
          : this.warehouseId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantityOnHand: data.quantityOnHand.present
          ? data.quantityOnHand.value
          : this.quantityOnHand,
      averageCost: data.averageCost.present
          ? data.averageCost.value
          : this.averageCost,
      alertQuantity: data.alertQuantity.present
          ? data.alertQuantity.value
          : this.alertQuantity,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryData(')
          ..write('id: $id, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('productId: $productId, ')
          ..write('quantityOnHand: $quantityOnHand, ')
          ..write('averageCost: $averageCost, ')
          ..write('alertQuantity: $alertQuantity, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    warehouseId,
    productId,
    quantityOnHand,
    averageCost,
    alertQuantity,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryData &&
          other.id == this.id &&
          other.warehouseId == this.warehouseId &&
          other.productId == this.productId &&
          other.quantityOnHand == this.quantityOnHand &&
          other.averageCost == this.averageCost &&
          other.alertQuantity == this.alertQuantity &&
          other.updatedAt == this.updatedAt);
}

class InventoriesTableCompanion extends UpdateCompanion<InventoryData> {
  final Value<String> id;
  final Value<String> warehouseId;
  final Value<String> productId;
  final Value<double> quantityOnHand;
  final Value<double> averageCost;
  final Value<double> alertQuantity;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InventoriesTableCompanion({
    this.id = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantityOnHand = const Value.absent(),
    this.averageCost = const Value.absent(),
    this.alertQuantity = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoriesTableCompanion.insert({
    this.id = const Value.absent(),
    required String warehouseId,
    required String productId,
    this.quantityOnHand = const Value.absent(),
    this.averageCost = const Value.absent(),
    this.alertQuantity = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : warehouseId = Value(warehouseId),
       productId = Value(productId);
  static Insertable<InventoryData> custom({
    Expression<String>? id,
    Expression<String>? warehouseId,
    Expression<String>? productId,
    Expression<double>? quantityOnHand,
    Expression<double>? averageCost,
    Expression<double>? alertQuantity,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (productId != null) 'product_id': productId,
      if (quantityOnHand != null) 'quantity_on_hand': quantityOnHand,
      if (averageCost != null) 'average_cost': averageCost,
      if (alertQuantity != null) 'alert_quantity': alertQuantity,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? warehouseId,
    Value<String>? productId,
    Value<double>? quantityOnHand,
    Value<double>? averageCost,
    Value<double>? alertQuantity,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InventoriesTableCompanion(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      productId: productId ?? this.productId,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      averageCost: averageCost ?? this.averageCost,
      alertQuantity: alertQuantity ?? this.alertQuantity,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantityOnHand.present) {
      map['quantity_on_hand'] = Variable<double>(quantityOnHand.value);
    }
    if (averageCost.present) {
      map['average_cost'] = Variable<double>(averageCost.value);
    }
    if (alertQuantity.present) {
      map['alert_quantity'] = Variable<double>(alertQuantity.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('productId: $productId, ')
          ..write('quantityOnHand: $quantityOnHand, ')
          ..write('averageCost: $averageCost, ')
          ..write('alertQuantity: $alertQuantity, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryTransactionsTableTable extends InventoryTransactionsTable
    with TableInfo<$InventoryTransactionsTableTable, InventoryTransactionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryTransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v4(),
  );
  static const VerificationMeta _warehouseIdMeta = const VerificationMeta(
    'warehouseId',
  );
  @override
  late final GeneratedColumn<String> warehouseId = GeneratedColumn<String>(
    'warehouse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES warehouses_table (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products_table (id)',
    ),
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    warehouseId,
    productId,
    transactionType,
    quantity,
    unitCost,
    referenceType,
    referenceId,
    transactionDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_transactions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryTransactionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('warehouse_id')) {
      context.handle(
        _warehouseIdMeta,
        warehouseId.isAcceptableOrUnknown(
          data['warehouse_id']!,
          _warehouseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warehouseIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTypeMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceIdMeta);
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryTransactionData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryTransactionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      warehouseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warehouse_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_cost'],
      )!,
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      )!,
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
    );
  }

  @override
  $InventoryTransactionsTableTable createAlias(String alias) {
    return $InventoryTransactionsTableTable(attachedDatabase, alias);
  }
}

class InventoryTransactionData extends DataClass
    implements Insertable<InventoryTransactionData> {
  final String id;
  final String warehouseId;
  final String productId;

  /// Movement type: 'In', 'Out', 'Adjustment', 'Damage', 'Transfer'
  final String transactionType;

  /// Quantity in product's base unit
  final double quantity;

  /// Base unit cost at the time of the transaction
  final double unitCost;

  /// Reference type: 'SalesInvoice', 'PurchaseInvoice', 'StockTake', 'DamageVoucher', 'Transfer'
  final String referenceType;
  final String referenceId;
  final DateTime transactionDate;
  const InventoryTransactionData({
    required this.id,
    required this.warehouseId,
    required this.productId,
    required this.transactionType,
    required this.quantity,
    required this.unitCost,
    required this.referenceType,
    required this.referenceId,
    required this.transactionDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['warehouse_id'] = Variable<String>(warehouseId);
    map['product_id'] = Variable<String>(productId);
    map['transaction_type'] = Variable<String>(transactionType);
    map['quantity'] = Variable<double>(quantity);
    map['unit_cost'] = Variable<double>(unitCost);
    map['reference_type'] = Variable<String>(referenceType);
    map['reference_id'] = Variable<String>(referenceId);
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    return map;
  }

  InventoryTransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return InventoryTransactionsTableCompanion(
      id: Value(id),
      warehouseId: Value(warehouseId),
      productId: Value(productId),
      transactionType: Value(transactionType),
      quantity: Value(quantity),
      unitCost: Value(unitCost),
      referenceType: Value(referenceType),
      referenceId: Value(referenceId),
      transactionDate: Value(transactionDate),
    );
  }

  factory InventoryTransactionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryTransactionData(
      id: serializer.fromJson<String>(json['id']),
      warehouseId: serializer.fromJson<String>(json['warehouseId']),
      productId: serializer.fromJson<String>(json['productId']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitCost: serializer.fromJson<double>(json['unitCost']),
      referenceType: serializer.fromJson<String>(json['referenceType']),
      referenceId: serializer.fromJson<String>(json['referenceId']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'warehouseId': serializer.toJson<String>(warehouseId),
      'productId': serializer.toJson<String>(productId),
      'transactionType': serializer.toJson<String>(transactionType),
      'quantity': serializer.toJson<double>(quantity),
      'unitCost': serializer.toJson<double>(unitCost),
      'referenceType': serializer.toJson<String>(referenceType),
      'referenceId': serializer.toJson<String>(referenceId),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
    };
  }

  InventoryTransactionData copyWith({
    String? id,
    String? warehouseId,
    String? productId,
    String? transactionType,
    double? quantity,
    double? unitCost,
    String? referenceType,
    String? referenceId,
    DateTime? transactionDate,
  }) => InventoryTransactionData(
    id: id ?? this.id,
    warehouseId: warehouseId ?? this.warehouseId,
    productId: productId ?? this.productId,
    transactionType: transactionType ?? this.transactionType,
    quantity: quantity ?? this.quantity,
    unitCost: unitCost ?? this.unitCost,
    referenceType: referenceType ?? this.referenceType,
    referenceId: referenceId ?? this.referenceId,
    transactionDate: transactionDate ?? this.transactionDate,
  );
  InventoryTransactionData copyWithCompanion(
    InventoryTransactionsTableCompanion data,
  ) {
    return InventoryTransactionData(
      id: data.id.present ? data.id.value : this.id,
      warehouseId: data.warehouseId.present
          ? data.warehouseId.value
          : this.warehouseId,
      productId: data.productId.present ? data.productId.value : this.productId,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryTransactionData(')
          ..write('id: $id, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('productId: $productId, ')
          ..write('transactionType: $transactionType, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('referenceType: $referenceType, ')
          ..write('referenceId: $referenceId, ')
          ..write('transactionDate: $transactionDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    warehouseId,
    productId,
    transactionType,
    quantity,
    unitCost,
    referenceType,
    referenceId,
    transactionDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryTransactionData &&
          other.id == this.id &&
          other.warehouseId == this.warehouseId &&
          other.productId == this.productId &&
          other.transactionType == this.transactionType &&
          other.quantity == this.quantity &&
          other.unitCost == this.unitCost &&
          other.referenceType == this.referenceType &&
          other.referenceId == this.referenceId &&
          other.transactionDate == this.transactionDate);
}

class InventoryTransactionsTableCompanion
    extends UpdateCompanion<InventoryTransactionData> {
  final Value<String> id;
  final Value<String> warehouseId;
  final Value<String> productId;
  final Value<String> transactionType;
  final Value<double> quantity;
  final Value<double> unitCost;
  final Value<String> referenceType;
  final Value<String> referenceId;
  final Value<DateTime> transactionDate;
  final Value<int> rowid;
  const InventoryTransactionsTableCompanion({
    this.id = const Value.absent(),
    this.warehouseId = const Value.absent(),
    this.productId = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryTransactionsTableCompanion.insert({
    this.id = const Value.absent(),
    required String warehouseId,
    required String productId,
    required String transactionType,
    required double quantity,
    this.unitCost = const Value.absent(),
    required String referenceType,
    required String referenceId,
    this.transactionDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : warehouseId = Value(warehouseId),
       productId = Value(productId),
       transactionType = Value(transactionType),
       quantity = Value(quantity),
       referenceType = Value(referenceType),
       referenceId = Value(referenceId);
  static Insertable<InventoryTransactionData> custom({
    Expression<String>? id,
    Expression<String>? warehouseId,
    Expression<String>? productId,
    Expression<String>? transactionType,
    Expression<double>? quantity,
    Expression<double>? unitCost,
    Expression<String>? referenceType,
    Expression<String>? referenceId,
    Expression<DateTime>? transactionDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (productId != null) 'product_id': productId,
      if (transactionType != null) 'transaction_type': transactionType,
      if (quantity != null) 'quantity': quantity,
      if (unitCost != null) 'unit_cost': unitCost,
      if (referenceType != null) 'reference_type': referenceType,
      if (referenceId != null) 'reference_id': referenceId,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryTransactionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? warehouseId,
    Value<String>? productId,
    Value<String>? transactionType,
    Value<double>? quantity,
    Value<double>? unitCost,
    Value<String>? referenceType,
    Value<String>? referenceId,
    Value<DateTime>? transactionDate,
    Value<int>? rowid,
  }) {
    return InventoryTransactionsTableCompanion(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      productId: productId ?? this.productId,
      transactionType: transactionType ?? this.transactionType,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      transactionDate: transactionDate ?? this.transactionDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (warehouseId.present) {
      map['warehouse_id'] = Variable<String>(warehouseId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryTransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('warehouseId: $warehouseId, ')
          ..write('productId: $productId, ')
          ..write('transactionType: $transactionType, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('referenceType: $referenceType, ')
          ..write('referenceId: $referenceId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final $AccountsTableTable accountsTable = $AccountsTableTable(this);
  late final $SubscriptionsTableTable subscriptionsTable =
      $SubscriptionsTableTable(this);
  late final $CustomersTableTable customersTable = $CustomersTableTable(this);
  late final $SalesInvoicesTableTable salesInvoicesTable =
      $SalesInvoicesTableTable(this);
  late final $CurrenciesTableTable currenciesTable = $CurrenciesTableTable(
    this,
  );
  late final $FiscalYearsTableTable fiscalYearsTable = $FiscalYearsTableTable(
    this,
  );
  late final $ChartOfAccountsTableTable chartOfAccountsTable =
      $ChartOfAccountsTableTable(this);
  late final $JournalEntriesTableTable journalEntriesTable =
      $JournalEntriesTableTable(this);
  late final $JournalEntryLinesTableTable journalEntryLinesTable =
      $JournalEntryLinesTableTable(this);
  late final $PartiesTableTable partiesTable = $PartiesTableTable(this);
  late final $PaymentMethodsTableTable paymentMethodsTable =
      $PaymentMethodsTableTable(this);
  late final $UnitsTableTable unitsTable = $UnitsTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $ProductUnitsTableTable productUnitsTable =
      $ProductUnitsTableTable(this);
  late final $WarehousesTableTable warehousesTable = $WarehousesTableTable(
    this,
  );
  late final $InventoriesTableTable inventoriesTable = $InventoriesTableTable(
    this,
  );
  late final $InventoryTransactionsTableTable inventoryTransactionsTable =
      $InventoryTransactionsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usersTable,
    accountsTable,
    subscriptionsTable,
    customersTable,
    salesInvoicesTable,
    currenciesTable,
    fiscalYearsTable,
    chartOfAccountsTable,
    journalEntriesTable,
    journalEntryLinesTable,
    partiesTable,
    paymentMethodsTable,
    unitsTable,
    productsTable,
    productUnitsTable,
    warehousesTable,
    inventoriesTable,
    inventoryTransactionsTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'journal_entries_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('journal_entry_lines_table', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('product_units_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UsersTableTableCreateCompanionBuilder =
    UsersTableCompanion Function({
      Value<String> id,
      required String email,
      required String passwordHash,
      required String firstName,
      required String lastName,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$UsersTableTableUpdateCompanionBuilder =
    UsersTableCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> passwordHash,
      Value<String> firstName,
      Value<String> lastName,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$UsersTableTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTableTable, UserAccount> {
  $$UsersTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountsTableTable, List<BusinessAccount>>
  _accountsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accountsTable,
    aliasName: $_aliasNameGenerator(db.usersTable.id, db.accountsTable.ownerId),
  );

  $$AccountsTableTableProcessedTableManager get accountsTableRefs {
    final manager = $$AccountsTableTableTableManager(
      $_db,
      $_db.accountsTable,
    ).filter((f) => f.ownerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableTableFilterComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableFilterComposer({
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

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountsTableRefs(
    Expression<bool> Function($$AccountsTableTableFilterComposer f) f,
  ) {
    final $$AccountsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountsTable,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableTableFilterComposer(
            $db: $db,
            $table: $db.accountsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableOrderingComposer({
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

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> accountsTableRefs<T extends Object>(
    Expression<T> Function($$AccountsTableTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountsTable,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.accountsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTableTable,
          UserAccount,
          $$UsersTableTableFilterComposer,
          $$UsersTableTableOrderingComposer,
          $$UsersTableTableAnnotationComposer,
          $$UsersTableTableCreateCompanionBuilder,
          $$UsersTableTableUpdateCompanionBuilder,
          (UserAccount, $$UsersTableTableReferences),
          UserAccount,
          PrefetchHooks Function({bool accountsTableRefs})
        > {
  $$UsersTableTableTableManager(_$AppDatabase db, $UsersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion(
                id: id,
                email: email,
                passwordHash: passwordHash,
                firstName: firstName,
                lastName: lastName,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String email,
                required String passwordHash,
                required String firstName,
                required String lastName,
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion.insert(
                id: id,
                email: email,
                passwordHash: passwordHash,
                firstName: firstName,
                lastName: lastName,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UsersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (accountsTableRefs) db.accountsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accountsTableRefs)
                    await $_getPrefetchedData<
                      UserAccount,
                      $UsersTableTable,
                      BusinessAccount
                    >(
                      currentTable: table,
                      referencedTable: $$UsersTableTableReferences
                          ._accountsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UsersTableTableReferences(
                            db,
                            table,
                            p0,
                          ).accountsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.ownerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UsersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTableTable,
      UserAccount,
      $$UsersTableTableFilterComposer,
      $$UsersTableTableOrderingComposer,
      $$UsersTableTableAnnotationComposer,
      $$UsersTableTableCreateCompanionBuilder,
      $$UsersTableTableUpdateCompanionBuilder,
      (UserAccount, $$UsersTableTableReferences),
      UserAccount,
      PrefetchHooks Function({bool accountsTableRefs})
    >;
typedef $$AccountsTableTableCreateCompanionBuilder =
    AccountsTableCompanion Function({
      Value<String> id,
      required String ownerId,
      required String businessName,
      required String businessType,
      required String defaultCurrency,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AccountsTableTableUpdateCompanionBuilder =
    AccountsTableCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String> businessName,
      Value<String> businessType,
      Value<String> defaultCurrency,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AccountsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $AccountsTableTable, BusinessAccount> {
  $$AccountsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _ownerIdTable(_$AppDatabase db) =>
      db.usersTable.createAlias(
        $_aliasNameGenerator(db.accountsTable.ownerId, db.usersTable.id),
      );

  $$UsersTableTableProcessedTableManager get ownerId {
    final $_column = $_itemColumn<String>('owner_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SubscriptionsTableTable, List<SubscriptionData>>
  _subscriptionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.subscriptionsTable,
        aliasName: $_aliasNameGenerator(
          db.accountsTable.id,
          db.subscriptionsTable.accountId,
        ),
      );

  $$SubscriptionsTableTableProcessedTableManager get subscriptionsTableRefs {
    final manager = $$SubscriptionsTableTableTableManager(
      $_db,
      $_db.subscriptionsTable,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _subscriptionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableFilterComposer({
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

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultCurrency => $composableBuilder(
    column: $table.defaultCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get ownerId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> subscriptionsTableRefs(
    Expression<bool> Function($$SubscriptionsTableTableFilterComposer f) f,
  ) {
    final $$SubscriptionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subscriptionsTable,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableTableFilterComposer(
            $db: $db,
            $table: $db.subscriptionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableOrderingComposer({
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

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultCurrency => $composableBuilder(
    column: $table.defaultCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get ownerId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultCurrency => $composableBuilder(
    column: $table.defaultCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get ownerId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> subscriptionsTableRefs<T extends Object>(
    Expression<T> Function($$SubscriptionsTableTableAnnotationComposer a) f,
  ) {
    final $$SubscriptionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.subscriptionsTable,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SubscriptionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.subscriptionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AccountsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTableTable,
          BusinessAccount,
          $$AccountsTableTableFilterComposer,
          $$AccountsTableTableOrderingComposer,
          $$AccountsTableTableAnnotationComposer,
          $$AccountsTableTableCreateCompanionBuilder,
          $$AccountsTableTableUpdateCompanionBuilder,
          (BusinessAccount, $$AccountsTableTableReferences),
          BusinessAccount,
          PrefetchHooks Function({bool ownerId, bool subscriptionsTableRefs})
        > {
  $$AccountsTableTableTableManager(_$AppDatabase db, $AccountsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String> businessType = const Value.absent(),
                Value<String> defaultCurrency = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsTableCompanion(
                id: id,
                ownerId: ownerId,
                businessName: businessName,
                businessType: businessType,
                defaultCurrency: defaultCurrency,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String ownerId,
                required String businessName,
                required String businessType,
                required String defaultCurrency,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsTableCompanion.insert(
                id: id,
                ownerId: ownerId,
                businessName: businessName,
                businessType: businessType,
                defaultCurrency: defaultCurrency,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ownerId = false, subscriptionsTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subscriptionsTableRefs) db.subscriptionsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ownerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ownerId,
                                    referencedTable:
                                        $$AccountsTableTableReferences
                                            ._ownerIdTable(db),
                                    referencedColumn:
                                        $$AccountsTableTableReferences
                                            ._ownerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subscriptionsTableRefs)
                        await $_getPrefetchedData<
                          BusinessAccount,
                          $AccountsTableTable,
                          SubscriptionData
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableTableReferences
                              ._subscriptionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).subscriptionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTableTable,
      BusinessAccount,
      $$AccountsTableTableFilterComposer,
      $$AccountsTableTableOrderingComposer,
      $$AccountsTableTableAnnotationComposer,
      $$AccountsTableTableCreateCompanionBuilder,
      $$AccountsTableTableUpdateCompanionBuilder,
      (BusinessAccount, $$AccountsTableTableReferences),
      BusinessAccount,
      PrefetchHooks Function({bool ownerId, bool subscriptionsTableRefs})
    >;
typedef $$SubscriptionsTableTableCreateCompanionBuilder =
    SubscriptionsTableCompanion Function({
      Value<String> id,
      required String accountId,
      required String status,
      required String planId,
      required DateTime startDate,
      required DateTime endDate,
      Value<int> rowid,
    });
typedef $$SubscriptionsTableTableUpdateCompanionBuilder =
    SubscriptionsTableCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> status,
      Value<String> planId,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<int> rowid,
    });

final class $$SubscriptionsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SubscriptionsTableTable,
          SubscriptionData
        > {
  $$SubscriptionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountsTableTable _accountIdTable(_$AppDatabase db) =>
      db.accountsTable.createAlias(
        $_aliasNameGenerator(
          db.subscriptionsTable.accountId,
          db.accountsTable.id,
        ),
      );

  $$AccountsTableTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableTableManager(
      $_db,
      $_db.accountsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SubscriptionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTableTable> {
  $$SubscriptionsTableTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableTableFilterComposer get accountId {
    final $$AccountsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accountsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableTableFilterComposer(
            $db: $db,
            $table: $db.accountsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubscriptionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTableTable> {
  $$SubscriptionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableTableOrderingComposer get accountId {
    final $$AccountsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accountsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableTableOrderingComposer(
            $db: $db,
            $table: $db.accountsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubscriptionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTableTable> {
  $$SubscriptionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  $$AccountsTableTableAnnotationComposer get accountId {
    final $$AccountsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accountsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.accountsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubscriptionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTableTable,
          SubscriptionData,
          $$SubscriptionsTableTableFilterComposer,
          $$SubscriptionsTableTableOrderingComposer,
          $$SubscriptionsTableTableAnnotationComposer,
          $$SubscriptionsTableTableCreateCompanionBuilder,
          $$SubscriptionsTableTableUpdateCompanionBuilder,
          (SubscriptionData, $$SubscriptionsTableTableReferences),
          SubscriptionData,
          PrefetchHooks Function({bool accountId})
        > {
  $$SubscriptionsTableTableTableManager(
    _$AppDatabase db,
    $SubscriptionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsTableCompanion(
                id: id,
                accountId: accountId,
                status: status,
                planId: planId,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String accountId,
                required String status,
                required String planId,
                required DateTime startDate,
                required DateTime endDate,
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsTableCompanion.insert(
                id: id,
                accountId: accountId,
                status: status,
                planId: planId,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubscriptionsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$SubscriptionsTableTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$SubscriptionsTableTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SubscriptionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTableTable,
      SubscriptionData,
      $$SubscriptionsTableTableFilterComposer,
      $$SubscriptionsTableTableOrderingComposer,
      $$SubscriptionsTableTableAnnotationComposer,
      $$SubscriptionsTableTableCreateCompanionBuilder,
      $$SubscriptionsTableTableUpdateCompanionBuilder,
      (SubscriptionData, $$SubscriptionsTableTableReferences),
      SubscriptionData,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$CustomersTableTableCreateCompanionBuilder =
    CustomersTableCompanion Function({
      Value<String> id,
      required String businessId,
      required String customerName,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<double> creditLimit,
      Value<String?> defaultCurrencyId,
      Value<double> openingBalance,
      Value<String?> openingBalanceType,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CustomersTableTableUpdateCompanionBuilder =
    CustomersTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> customerName,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<double> creditLimit,
      Value<String?> defaultCurrencyId,
      Value<double> openingBalance,
      Value<String?> openingBalanceType,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$CustomersTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableFilterComposer({
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

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultCurrencyId => $composableBuilder(
    column: $table.defaultCurrencyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingBalanceType => $composableBuilder(
    column: $table.openingBalanceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableOrderingComposer({
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

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultCurrencyId => $composableBuilder(
    column: $table.defaultCurrencyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingBalanceType => $composableBuilder(
    column: $table.openingBalanceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultCurrencyId => $composableBuilder(
    column: $table.defaultCurrencyId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openingBalanceType => $composableBuilder(
    column: $table.openingBalanceType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CustomersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTableTable,
          CustomerModel,
          $$CustomersTableTableFilterComposer,
          $$CustomersTableTableOrderingComposer,
          $$CustomersTableTableAnnotationComposer,
          $$CustomersTableTableCreateCompanionBuilder,
          $$CustomersTableTableUpdateCompanionBuilder,
          (
            CustomerModel,
            BaseReferences<_$AppDatabase, $CustomersTableTable, CustomerModel>,
          ),
          CustomerModel,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableTableManager(
    _$AppDatabase db,
    $CustomersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<double> creditLimit = const Value.absent(),
                Value<String?> defaultCurrencyId = const Value.absent(),
                Value<double> openingBalance = const Value.absent(),
                Value<String?> openingBalanceType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion(
                id: id,
                businessId: businessId,
                customerName: customerName,
                phone: phone,
                email: email,
                address: address,
                creditLimit: creditLimit,
                defaultCurrencyId: defaultCurrencyId,
                openingBalance: openingBalance,
                openingBalanceType: openingBalanceType,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String businessId,
                required String customerName,
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<double> creditLimit = const Value.absent(),
                Value<String?> defaultCurrencyId = const Value.absent(),
                Value<double> openingBalance = const Value.absent(),
                Value<String?> openingBalanceType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion.insert(
                id: id,
                businessId: businessId,
                customerName: customerName,
                phone: phone,
                email: email,
                address: address,
                creditLimit: creditLimit,
                defaultCurrencyId: defaultCurrencyId,
                openingBalance: openingBalance,
                openingBalanceType: openingBalanceType,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTableTable,
      CustomerModel,
      $$CustomersTableTableFilterComposer,
      $$CustomersTableTableOrderingComposer,
      $$CustomersTableTableAnnotationComposer,
      $$CustomersTableTableCreateCompanionBuilder,
      $$CustomersTableTableUpdateCompanionBuilder,
      (
        CustomerModel,
        BaseReferences<_$AppDatabase, $CustomersTableTable, CustomerModel>,
      ),
      CustomerModel,
      PrefetchHooks Function()
    >;
typedef $$SalesInvoicesTableTableCreateCompanionBuilder =
    SalesInvoicesTableCompanion Function({
      Value<String> id,
      required String businessId,
      required String branchId,
      Value<String?> customerId,
      required String invoiceNumber,
      Value<DateTime> invoiceDate,
      Value<DateTime?> dueDate,
      required String currencyId,
      Value<double> exchangeRate,
      Value<double> subTotal,
      Value<double> discountTotal,
      Value<double> taxTotal,
      Value<double> grandTotal,
      Value<double> baseSubtotal,
      Value<double> baseDiscountTotal,
      Value<double> baseTaxTotal,
      Value<double> baseGrandTotal,
      Value<String> paymentStatus,
      Value<String> status,
      Value<String?> notes,
      required String createdBy,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$SalesInvoicesTableTableUpdateCompanionBuilder =
    SalesInvoicesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> branchId,
      Value<String?> customerId,
      Value<String> invoiceNumber,
      Value<DateTime> invoiceDate,
      Value<DateTime?> dueDate,
      Value<String> currencyId,
      Value<double> exchangeRate,
      Value<double> subTotal,
      Value<double> discountTotal,
      Value<double> taxTotal,
      Value<double> grandTotal,
      Value<double> baseSubtotal,
      Value<double> baseDiscountTotal,
      Value<double> baseTaxTotal,
      Value<double> baseGrandTotal,
      Value<String> paymentStatus,
      Value<String> status,
      Value<String?> notes,
      Value<String> createdBy,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$SalesInvoicesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SalesInvoicesTableTable> {
  $$SalesInvoicesTableTableFilterComposer({
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

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyId => $composableBuilder(
    column: $table.currencyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subTotal => $composableBuilder(
    column: $table.subTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxTotal => $composableBuilder(
    column: $table.taxTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseSubtotal => $composableBuilder(
    column: $table.baseSubtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseDiscountTotal => $composableBuilder(
    column: $table.baseDiscountTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseTaxTotal => $composableBuilder(
    column: $table.baseTaxTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseGrandTotal => $composableBuilder(
    column: $table.baseGrandTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SalesInvoicesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesInvoicesTableTable> {
  $$SalesInvoicesTableTableOrderingComposer({
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

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyId => $composableBuilder(
    column: $table.currencyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subTotal => $composableBuilder(
    column: $table.subTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxTotal => $composableBuilder(
    column: $table.taxTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseSubtotal => $composableBuilder(
    column: $table.baseSubtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseDiscountTotal => $composableBuilder(
    column: $table.baseDiscountTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseTaxTotal => $composableBuilder(
    column: $table.baseTaxTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseGrandTotal => $composableBuilder(
    column: $table.baseGrandTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SalesInvoicesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesInvoicesTableTable> {
  $$SalesInvoicesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get currencyId => $composableBuilder(
    column: $table.currencyId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subTotal =>
      $composableBuilder(column: $table.subTotal, builder: (column) => column);

  GeneratedColumn<double> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get taxTotal =>
      $composableBuilder(column: $table.taxTotal, builder: (column) => column);

  GeneratedColumn<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseSubtotal => $composableBuilder(
    column: $table.baseSubtotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseDiscountTotal => $composableBuilder(
    column: $table.baseDiscountTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseTaxTotal => $composableBuilder(
    column: $table.baseTaxTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseGrandTotal => $composableBuilder(
    column: $table.baseGrandTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SalesInvoicesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesInvoicesTableTable,
          SalesInvoiceModel,
          $$SalesInvoicesTableTableFilterComposer,
          $$SalesInvoicesTableTableOrderingComposer,
          $$SalesInvoicesTableTableAnnotationComposer,
          $$SalesInvoicesTableTableCreateCompanionBuilder,
          $$SalesInvoicesTableTableUpdateCompanionBuilder,
          (
            SalesInvoiceModel,
            BaseReferences<
              _$AppDatabase,
              $SalesInvoicesTableTable,
              SalesInvoiceModel
            >,
          ),
          SalesInvoiceModel,
          PrefetchHooks Function()
        > {
  $$SalesInvoicesTableTableTableManager(
    _$AppDatabase db,
    $SalesInvoicesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesInvoicesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesInvoicesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesInvoicesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> invoiceNumber = const Value.absent(),
                Value<DateTime> invoiceDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String> currencyId = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<double> subTotal = const Value.absent(),
                Value<double> discountTotal = const Value.absent(),
                Value<double> taxTotal = const Value.absent(),
                Value<double> grandTotal = const Value.absent(),
                Value<double> baseSubtotal = const Value.absent(),
                Value<double> baseDiscountTotal = const Value.absent(),
                Value<double> baseTaxTotal = const Value.absent(),
                Value<double> baseGrandTotal = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesInvoicesTableCompanion(
                id: id,
                businessId: businessId,
                branchId: branchId,
                customerId: customerId,
                invoiceNumber: invoiceNumber,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                currencyId: currencyId,
                exchangeRate: exchangeRate,
                subTotal: subTotal,
                discountTotal: discountTotal,
                taxTotal: taxTotal,
                grandTotal: grandTotal,
                baseSubtotal: baseSubtotal,
                baseDiscountTotal: baseDiscountTotal,
                baseTaxTotal: baseTaxTotal,
                baseGrandTotal: baseGrandTotal,
                paymentStatus: paymentStatus,
                status: status,
                notes: notes,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String businessId,
                required String branchId,
                Value<String?> customerId = const Value.absent(),
                required String invoiceNumber,
                Value<DateTime> invoiceDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                required String currencyId,
                Value<double> exchangeRate = const Value.absent(),
                Value<double> subTotal = const Value.absent(),
                Value<double> discountTotal = const Value.absent(),
                Value<double> taxTotal = const Value.absent(),
                Value<double> grandTotal = const Value.absent(),
                Value<double> baseSubtotal = const Value.absent(),
                Value<double> baseDiscountTotal = const Value.absent(),
                Value<double> baseTaxTotal = const Value.absent(),
                Value<double> baseGrandTotal = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required String createdBy,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesInvoicesTableCompanion.insert(
                id: id,
                businessId: businessId,
                branchId: branchId,
                customerId: customerId,
                invoiceNumber: invoiceNumber,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                currencyId: currencyId,
                exchangeRate: exchangeRate,
                subTotal: subTotal,
                discountTotal: discountTotal,
                taxTotal: taxTotal,
                grandTotal: grandTotal,
                baseSubtotal: baseSubtotal,
                baseDiscountTotal: baseDiscountTotal,
                baseTaxTotal: baseTaxTotal,
                baseGrandTotal: baseGrandTotal,
                paymentStatus: paymentStatus,
                status: status,
                notes: notes,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SalesInvoicesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesInvoicesTableTable,
      SalesInvoiceModel,
      $$SalesInvoicesTableTableFilterComposer,
      $$SalesInvoicesTableTableOrderingComposer,
      $$SalesInvoicesTableTableAnnotationComposer,
      $$SalesInvoicesTableTableCreateCompanionBuilder,
      $$SalesInvoicesTableTableUpdateCompanionBuilder,
      (
        SalesInvoiceModel,
        BaseReferences<
          _$AppDatabase,
          $SalesInvoicesTableTable,
          SalesInvoiceModel
        >,
      ),
      SalesInvoiceModel,
      PrefetchHooks Function()
    >;
typedef $$CurrenciesTableTableCreateCompanionBuilder =
    CurrenciesTableCompanion Function({
      Value<String> id,
      required String code,
      required String nameAr,
      required String symbol,
      Value<int> decimalPlaces,
      Value<double> exchangeRate,
      Value<bool> isBaseCurrency,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$CurrenciesTableTableUpdateCompanionBuilder =
    CurrenciesTableCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> nameAr,
      Value<String> symbol,
      Value<int> decimalPlaces,
      Value<double> exchangeRate,
      Value<bool> isBaseCurrency,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$CurrenciesTableTableReferences
    extends BaseReferences<_$AppDatabase, $CurrenciesTableTable, CurrencyData> {
  $$CurrenciesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$JournalEntriesTableTable, List<JournalEntryData>>
  _journalEntriesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.journalEntriesTable,
        aliasName: $_aliasNameGenerator(
          db.currenciesTable.id,
          db.journalEntriesTable.currencyId,
        ),
      );

  $$JournalEntriesTableTableProcessedTableManager get journalEntriesTableRefs {
    final manager = $$JournalEntriesTableTableTableManager(
      $_db,
      $_db.journalEntriesTable,
    ).filter((f) => f.currencyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _journalEntriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CurrenciesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CurrenciesTableTable> {
  $$CurrenciesTableTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get decimalPlaces => $composableBuilder(
    column: $table.decimalPlaces,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBaseCurrency => $composableBuilder(
    column: $table.isBaseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> journalEntriesTableRefs(
    Expression<bool> Function($$JournalEntriesTableTableFilterComposer f) f,
  ) {
    final $$JournalEntriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntriesTable,
      getReferencedColumn: (t) => t.currencyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableTableFilterComposer(
            $db: $db,
            $table: $db.journalEntriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CurrenciesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CurrenciesTableTable> {
  $$CurrenciesTableTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get decimalPlaces => $composableBuilder(
    column: $table.decimalPlaces,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBaseCurrency => $composableBuilder(
    column: $table.isBaseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CurrenciesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CurrenciesTableTable> {
  $$CurrenciesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<int> get decimalPlaces => $composableBuilder(
    column: $table.decimalPlaces,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBaseCurrency => $composableBuilder(
    column: $table.isBaseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> journalEntriesTableRefs<T extends Object>(
    Expression<T> Function($$JournalEntriesTableTableAnnotationComposer a) f,
  ) {
    final $$JournalEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.journalEntriesTable,
          getReferencedColumn: (t) => t.currencyId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JournalEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.journalEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CurrenciesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CurrenciesTableTable,
          CurrencyData,
          $$CurrenciesTableTableFilterComposer,
          $$CurrenciesTableTableOrderingComposer,
          $$CurrenciesTableTableAnnotationComposer,
          $$CurrenciesTableTableCreateCompanionBuilder,
          $$CurrenciesTableTableUpdateCompanionBuilder,
          (CurrencyData, $$CurrenciesTableTableReferences),
          CurrencyData,
          PrefetchHooks Function({bool journalEntriesTableRefs})
        > {
  $$CurrenciesTableTableTableManager(
    _$AppDatabase db,
    $CurrenciesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrenciesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrenciesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CurrenciesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<int> decimalPlaces = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<bool> isBaseCurrency = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesTableCompanion(
                id: id,
                code: code,
                nameAr: nameAr,
                symbol: symbol,
                decimalPlaces: decimalPlaces,
                exchangeRate: exchangeRate,
                isBaseCurrency: isBaseCurrency,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String code,
                required String nameAr,
                required String symbol,
                Value<int> decimalPlaces = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<bool> isBaseCurrency = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesTableCompanion.insert(
                id: id,
                code: code,
                nameAr: nameAr,
                symbol: symbol,
                decimalPlaces: decimalPlaces,
                exchangeRate: exchangeRate,
                isBaseCurrency: isBaseCurrency,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CurrenciesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({journalEntriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (journalEntriesTableRefs) db.journalEntriesTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (journalEntriesTableRefs)
                    await $_getPrefetchedData<
                      CurrencyData,
                      $CurrenciesTableTable,
                      JournalEntryData
                    >(
                      currentTable: table,
                      referencedTable: $$CurrenciesTableTableReferences
                          ._journalEntriesTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CurrenciesTableTableReferences(
                            db,
                            table,
                            p0,
                          ).journalEntriesTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.currencyId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CurrenciesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CurrenciesTableTable,
      CurrencyData,
      $$CurrenciesTableTableFilterComposer,
      $$CurrenciesTableTableOrderingComposer,
      $$CurrenciesTableTableAnnotationComposer,
      $$CurrenciesTableTableCreateCompanionBuilder,
      $$CurrenciesTableTableUpdateCompanionBuilder,
      (CurrencyData, $$CurrenciesTableTableReferences),
      CurrencyData,
      PrefetchHooks Function({bool journalEntriesTableRefs})
    >;
typedef $$FiscalYearsTableTableCreateCompanionBuilder =
    FiscalYearsTableCompanion Function({
      Value<String> id,
      required String yearName,
      required DateTime startDate,
      required DateTime endDate,
      Value<bool> isClosed,
      Value<int> rowid,
    });
typedef $$FiscalYearsTableTableUpdateCompanionBuilder =
    FiscalYearsTableCompanion Function({
      Value<String> id,
      Value<String> yearName,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<bool> isClosed,
      Value<int> rowid,
    });

final class $$FiscalYearsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $FiscalYearsTableTable, FiscalYearData> {
  $$FiscalYearsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$JournalEntriesTableTable, List<JournalEntryData>>
  _journalEntriesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.journalEntriesTable,
        aliasName: $_aliasNameGenerator(
          db.fiscalYearsTable.id,
          db.journalEntriesTable.fiscalYearId,
        ),
      );

  $$JournalEntriesTableTableProcessedTableManager get journalEntriesTableRefs {
    final manager = $$JournalEntriesTableTableTableManager(
      $_db,
      $_db.journalEntriesTable,
    ).filter((f) => f.fiscalYearId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _journalEntriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FiscalYearsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FiscalYearsTableTable> {
  $$FiscalYearsTableTableFilterComposer({
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

  ColumnFilters<String> get yearName => $composableBuilder(
    column: $table.yearName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> journalEntriesTableRefs(
    Expression<bool> Function($$JournalEntriesTableTableFilterComposer f) f,
  ) {
    final $$JournalEntriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntriesTable,
      getReferencedColumn: (t) => t.fiscalYearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableTableFilterComposer(
            $db: $db,
            $table: $db.journalEntriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FiscalYearsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FiscalYearsTableTable> {
  $$FiscalYearsTableTableOrderingComposer({
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

  ColumnOrderings<String> get yearName => $composableBuilder(
    column: $table.yearName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FiscalYearsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FiscalYearsTableTable> {
  $$FiscalYearsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get yearName =>
      $composableBuilder(column: $table.yearName, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<bool> get isClosed =>
      $composableBuilder(column: $table.isClosed, builder: (column) => column);

  Expression<T> journalEntriesTableRefs<T extends Object>(
    Expression<T> Function($$JournalEntriesTableTableAnnotationComposer a) f,
  ) {
    final $$JournalEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.journalEntriesTable,
          getReferencedColumn: (t) => t.fiscalYearId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JournalEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.journalEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FiscalYearsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FiscalYearsTableTable,
          FiscalYearData,
          $$FiscalYearsTableTableFilterComposer,
          $$FiscalYearsTableTableOrderingComposer,
          $$FiscalYearsTableTableAnnotationComposer,
          $$FiscalYearsTableTableCreateCompanionBuilder,
          $$FiscalYearsTableTableUpdateCompanionBuilder,
          (FiscalYearData, $$FiscalYearsTableTableReferences),
          FiscalYearData,
          PrefetchHooks Function({bool journalEntriesTableRefs})
        > {
  $$FiscalYearsTableTableTableManager(
    _$AppDatabase db,
    $FiscalYearsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FiscalYearsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FiscalYearsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FiscalYearsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> yearName = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FiscalYearsTableCompanion(
                id: id,
                yearName: yearName,
                startDate: startDate,
                endDate: endDate,
                isClosed: isClosed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String yearName,
                required DateTime startDate,
                required DateTime endDate,
                Value<bool> isClosed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FiscalYearsTableCompanion.insert(
                id: id,
                yearName: yearName,
                startDate: startDate,
                endDate: endDate,
                isClosed: isClosed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FiscalYearsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({journalEntriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (journalEntriesTableRefs) db.journalEntriesTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (journalEntriesTableRefs)
                    await $_getPrefetchedData<
                      FiscalYearData,
                      $FiscalYearsTableTable,
                      JournalEntryData
                    >(
                      currentTable: table,
                      referencedTable: $$FiscalYearsTableTableReferences
                          ._journalEntriesTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FiscalYearsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).journalEntriesTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.fiscalYearId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FiscalYearsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FiscalYearsTableTable,
      FiscalYearData,
      $$FiscalYearsTableTableFilterComposer,
      $$FiscalYearsTableTableOrderingComposer,
      $$FiscalYearsTableTableAnnotationComposer,
      $$FiscalYearsTableTableCreateCompanionBuilder,
      $$FiscalYearsTableTableUpdateCompanionBuilder,
      (FiscalYearData, $$FiscalYearsTableTableReferences),
      FiscalYearData,
      PrefetchHooks Function({bool journalEntriesTableRefs})
    >;
typedef $$ChartOfAccountsTableTableCreateCompanionBuilder =
    ChartOfAccountsTableCompanion Function({
      Value<String> id,
      Value<String?> parentId,
      required String accountCode,
      required String accountName,
      required String accountType,
      required String normalBalance,
      Value<bool> allowPosting,
      Value<bool> isSystem,
      Value<String?> systemRole,
      Value<int> rowid,
    });
typedef $$ChartOfAccountsTableTableUpdateCompanionBuilder =
    ChartOfAccountsTableCompanion Function({
      Value<String> id,
      Value<String?> parentId,
      Value<String> accountCode,
      Value<String> accountName,
      Value<String> accountType,
      Value<String> normalBalance,
      Value<bool> allowPosting,
      Value<bool> isSystem,
      Value<String?> systemRole,
      Value<int> rowid,
    });

final class $$ChartOfAccountsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ChartOfAccountsTableTable, AccountData> {
  $$ChartOfAccountsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChartOfAccountsTableTable _parentIdTable(_$AppDatabase db) =>
      db.chartOfAccountsTable.createAlias(
        $_aliasNameGenerator(
          db.chartOfAccountsTable.parentId,
          db.chartOfAccountsTable.id,
        ),
      );

  $$ChartOfAccountsTableTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$ChartOfAccountsTableTableTableManager(
      $_db,
      $_db.chartOfAccountsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $JournalEntryLinesTableTable,
    List<JournalEntryLineData>
  >
  _journalEntryLinesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.journalEntryLinesTable,
        aliasName: $_aliasNameGenerator(
          db.chartOfAccountsTable.id,
          db.journalEntryLinesTable.accountId,
        ),
      );

  $$JournalEntryLinesTableTableProcessedTableManager
  get journalEntryLinesTableRefs {
    final manager = $$JournalEntryLinesTableTableTableManager(
      $_db,
      $_db.journalEntryLinesTable,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _journalEntryLinesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PartiesTableTable, List<PartyData>>
  _partiesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.partiesTable,
    aliasName: $_aliasNameGenerator(
      db.chartOfAccountsTable.id,
      db.partiesTable.accountId,
    ),
  );

  $$PartiesTableTableProcessedTableManager get partiesTableRefs {
    final manager = $$PartiesTableTableTableManager(
      $_db,
      $_db.partiesTable,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_partiesTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentMethodsTableTable, List<PaymentMethodData>>
  _paymentMethodsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.paymentMethodsTable,
        aliasName: $_aliasNameGenerator(
          db.chartOfAccountsTable.id,
          db.paymentMethodsTable.accountId,
        ),
      );

  $$PaymentMethodsTableTableProcessedTableManager get paymentMethodsTableRefs {
    final manager = $$PaymentMethodsTableTableTableManager(
      $_db,
      $_db.paymentMethodsTable,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _paymentMethodsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChartOfAccountsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ChartOfAccountsTableTable> {
  $$ChartOfAccountsTableTableFilterComposer({
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

  ColumnFilters<String> get accountCode => $composableBuilder(
    column: $table.accountCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalBalance => $composableBuilder(
    column: $table.normalBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowPosting => $composableBuilder(
    column: $table.allowPosting,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemRole => $composableBuilder(
    column: $table.systemRole,
    builder: (column) => ColumnFilters(column),
  );

  $$ChartOfAccountsTableTableFilterComposer get parentId {
    final $$ChartOfAccountsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.chartOfAccountsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChartOfAccountsTableTableFilterComposer(
            $db: $db,
            $table: $db.chartOfAccountsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> journalEntryLinesTableRefs(
    Expression<bool> Function($$JournalEntryLinesTableTableFilterComposer f) f,
  ) {
    final $$JournalEntryLinesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.journalEntryLinesTable,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JournalEntryLinesTableTableFilterComposer(
                $db: $db,
                $table: $db.journalEntryLinesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> partiesTableRefs(
    Expression<bool> Function($$PartiesTableTableFilterComposer f) f,
  ) {
    final $$PartiesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partiesTable,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartiesTableTableFilterComposer(
            $db: $db,
            $table: $db.partiesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentMethodsTableRefs(
    Expression<bool> Function($$PaymentMethodsTableTableFilterComposer f) f,
  ) {
    final $$PaymentMethodsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paymentMethodsTable,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableTableFilterComposer(
            $db: $db,
            $table: $db.paymentMethodsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChartOfAccountsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ChartOfAccountsTableTable> {
  $$ChartOfAccountsTableTableOrderingComposer({
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

  ColumnOrderings<String> get accountCode => $composableBuilder(
    column: $table.accountCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalBalance => $composableBuilder(
    column: $table.normalBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowPosting => $composableBuilder(
    column: $table.allowPosting,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemRole => $composableBuilder(
    column: $table.systemRole,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChartOfAccountsTableTableOrderingComposer get parentId {
    final $$ChartOfAccountsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.parentId,
          referencedTable: $db.chartOfAccountsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChartOfAccountsTableTableOrderingComposer(
                $db: $db,
                $table: $db.chartOfAccountsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ChartOfAccountsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChartOfAccountsTableTable> {
  $$ChartOfAccountsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountCode => $composableBuilder(
    column: $table.accountCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalBalance => $composableBuilder(
    column: $table.normalBalance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowPosting => $composableBuilder(
    column: $table.allowPosting,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<String> get systemRole => $composableBuilder(
    column: $table.systemRole,
    builder: (column) => column,
  );

  $$ChartOfAccountsTableTableAnnotationComposer get parentId {
    final $$ChartOfAccountsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.parentId,
          referencedTable: $db.chartOfAccountsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChartOfAccountsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.chartOfAccountsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> journalEntryLinesTableRefs<T extends Object>(
    Expression<T> Function($$JournalEntryLinesTableTableAnnotationComposer a) f,
  ) {
    final $$JournalEntryLinesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.journalEntryLinesTable,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JournalEntryLinesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.journalEntryLinesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> partiesTableRefs<T extends Object>(
    Expression<T> Function($$PartiesTableTableAnnotationComposer a) f,
  ) {
    final $$PartiesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.partiesTable,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PartiesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.partiesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentMethodsTableRefs<T extends Object>(
    Expression<T> Function($$PaymentMethodsTableTableAnnotationComposer a) f,
  ) {
    final $$PaymentMethodsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.paymentMethodsTable,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PaymentMethodsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.paymentMethodsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ChartOfAccountsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChartOfAccountsTableTable,
          AccountData,
          $$ChartOfAccountsTableTableFilterComposer,
          $$ChartOfAccountsTableTableOrderingComposer,
          $$ChartOfAccountsTableTableAnnotationComposer,
          $$ChartOfAccountsTableTableCreateCompanionBuilder,
          $$ChartOfAccountsTableTableUpdateCompanionBuilder,
          (AccountData, $$ChartOfAccountsTableTableReferences),
          AccountData,
          PrefetchHooks Function({
            bool parentId,
            bool journalEntryLinesTableRefs,
            bool partiesTableRefs,
            bool paymentMethodsTableRefs,
          })
        > {
  $$ChartOfAccountsTableTableTableManager(
    _$AppDatabase db,
    $ChartOfAccountsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChartOfAccountsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChartOfAccountsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ChartOfAccountsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> accountCode = const Value.absent(),
                Value<String> accountName = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<String> normalBalance = const Value.absent(),
                Value<bool> allowPosting = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<String?> systemRole = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChartOfAccountsTableCompanion(
                id: id,
                parentId: parentId,
                accountCode: accountCode,
                accountName: accountName,
                accountType: accountType,
                normalBalance: normalBalance,
                allowPosting: allowPosting,
                isSystem: isSystem,
                systemRole: systemRole,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                required String accountCode,
                required String accountName,
                required String accountType,
                required String normalBalance,
                Value<bool> allowPosting = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<String?> systemRole = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChartOfAccountsTableCompanion.insert(
                id: id,
                parentId: parentId,
                accountCode: accountCode,
                accountName: accountName,
                accountType: accountType,
                normalBalance: normalBalance,
                allowPosting: allowPosting,
                isSystem: isSystem,
                systemRole: systemRole,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChartOfAccountsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                journalEntryLinesTableRefs = false,
                partiesTableRefs = false,
                paymentMethodsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (journalEntryLinesTableRefs) db.journalEntryLinesTable,
                    if (partiesTableRefs) db.partiesTable,
                    if (paymentMethodsTableRefs) db.paymentMethodsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable:
                                        $$ChartOfAccountsTableTableReferences
                                            ._parentIdTable(db),
                                    referencedColumn:
                                        $$ChartOfAccountsTableTableReferences
                                            ._parentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (journalEntryLinesTableRefs)
                        await $_getPrefetchedData<
                          AccountData,
                          $ChartOfAccountsTableTable,
                          JournalEntryLineData
                        >(
                          currentTable: table,
                          referencedTable: $$ChartOfAccountsTableTableReferences
                              ._journalEntryLinesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChartOfAccountsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).journalEntryLinesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (partiesTableRefs)
                        await $_getPrefetchedData<
                          AccountData,
                          $ChartOfAccountsTableTable,
                          PartyData
                        >(
                          currentTable: table,
                          referencedTable: $$ChartOfAccountsTableTableReferences
                              ._partiesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChartOfAccountsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).partiesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (paymentMethodsTableRefs)
                        await $_getPrefetchedData<
                          AccountData,
                          $ChartOfAccountsTableTable,
                          PaymentMethodData
                        >(
                          currentTable: table,
                          referencedTable: $$ChartOfAccountsTableTableReferences
                              ._paymentMethodsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChartOfAccountsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentMethodsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChartOfAccountsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChartOfAccountsTableTable,
      AccountData,
      $$ChartOfAccountsTableTableFilterComposer,
      $$ChartOfAccountsTableTableOrderingComposer,
      $$ChartOfAccountsTableTableAnnotationComposer,
      $$ChartOfAccountsTableTableCreateCompanionBuilder,
      $$ChartOfAccountsTableTableUpdateCompanionBuilder,
      (AccountData, $$ChartOfAccountsTableTableReferences),
      AccountData,
      PrefetchHooks Function({
        bool parentId,
        bool journalEntryLinesTableRefs,
        bool partiesTableRefs,
        bool paymentMethodsTableRefs,
      })
    >;
typedef $$JournalEntriesTableTableCreateCompanionBuilder =
    JournalEntriesTableCompanion Function({
      Value<String> id,
      required String fiscalYearId,
      required String entryNumber,
      Value<DateTime> entryDate,
      required String referenceType,
      Value<String?> referenceId,
      required String currencyId,
      Value<double> exchangeRate,
      Value<String?> description,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$JournalEntriesTableTableUpdateCompanionBuilder =
    JournalEntriesTableCompanion Function({
      Value<String> id,
      Value<String> fiscalYearId,
      Value<String> entryNumber,
      Value<DateTime> entryDate,
      Value<String> referenceType,
      Value<String?> referenceId,
      Value<String> currencyId,
      Value<double> exchangeRate,
      Value<String?> description,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$JournalEntriesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $JournalEntriesTableTable,
          JournalEntryData
        > {
  $$JournalEntriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FiscalYearsTableTable _fiscalYearIdTable(_$AppDatabase db) =>
      db.fiscalYearsTable.createAlias(
        $_aliasNameGenerator(
          db.journalEntriesTable.fiscalYearId,
          db.fiscalYearsTable.id,
        ),
      );

  $$FiscalYearsTableTableProcessedTableManager get fiscalYearId {
    final $_column = $_itemColumn<String>('fiscal_year_id')!;

    final manager = $$FiscalYearsTableTableTableManager(
      $_db,
      $_db.fiscalYearsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fiscalYearIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTableTable _currencyIdTable(_$AppDatabase db) =>
      db.currenciesTable.createAlias(
        $_aliasNameGenerator(
          db.journalEntriesTable.currencyId,
          db.currenciesTable.id,
        ),
      );

  $$CurrenciesTableTableProcessedTableManager get currencyId {
    final $_column = $_itemColumn<String>('currency_id')!;

    final manager = $$CurrenciesTableTableTableManager(
      $_db,
      $_db.currenciesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $JournalEntryLinesTableTable,
    List<JournalEntryLineData>
  >
  _journalEntryLinesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.journalEntryLinesTable,
        aliasName: $_aliasNameGenerator(
          db.journalEntriesTable.id,
          db.journalEntryLinesTable.journalEntryId,
        ),
      );

  $$JournalEntryLinesTableTableProcessedTableManager
  get journalEntryLinesTableRefs {
    final manager = $$JournalEntryLinesTableTableTableManager(
      $_db,
      $_db.journalEntryLinesTable,
    ).filter((f) => f.journalEntryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _journalEntryLinesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$JournalEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTableTable> {
  $$JournalEntriesTableTableFilterComposer({
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

  ColumnFilters<String> get entryNumber => $composableBuilder(
    column: $table.entryNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
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

  $$FiscalYearsTableTableFilterComposer get fiscalYearId {
    final $$FiscalYearsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fiscalYearId,
      referencedTable: $db.fiscalYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FiscalYearsTableTableFilterComposer(
            $db: $db,
            $table: $db.fiscalYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableTableFilterComposer get currencyId {
    final $$CurrenciesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyId,
      referencedTable: $db.currenciesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableTableFilterComposer(
            $db: $db,
            $table: $db.currenciesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> journalEntryLinesTableRefs(
    Expression<bool> Function($$JournalEntryLinesTableTableFilterComposer f) f,
  ) {
    final $$JournalEntryLinesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.journalEntryLinesTable,
          getReferencedColumn: (t) => t.journalEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JournalEntryLinesTableTableFilterComposer(
                $db: $db,
                $table: $db.journalEntryLinesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$JournalEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTableTable> {
  $$JournalEntriesTableTableOrderingComposer({
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

  ColumnOrderings<String> get entryNumber => $composableBuilder(
    column: $table.entryNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
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

  $$FiscalYearsTableTableOrderingComposer get fiscalYearId {
    final $$FiscalYearsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fiscalYearId,
      referencedTable: $db.fiscalYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FiscalYearsTableTableOrderingComposer(
            $db: $db,
            $table: $db.fiscalYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableTableOrderingComposer get currencyId {
    final $$CurrenciesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyId,
      referencedTable: $db.currenciesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableTableOrderingComposer(
            $db: $db,
            $table: $db.currenciesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JournalEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTableTable> {
  $$JournalEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryNumber => $composableBuilder(
    column: $table.entryNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FiscalYearsTableTableAnnotationComposer get fiscalYearId {
    final $$FiscalYearsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fiscalYearId,
      referencedTable: $db.fiscalYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FiscalYearsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.fiscalYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableTableAnnotationComposer get currencyId {
    final $$CurrenciesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyId,
      referencedTable: $db.currenciesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.currenciesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> journalEntryLinesTableRefs<T extends Object>(
    Expression<T> Function($$JournalEntryLinesTableTableAnnotationComposer a) f,
  ) {
    final $$JournalEntryLinesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.journalEntryLinesTable,
          getReferencedColumn: (t) => t.journalEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JournalEntryLinesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.journalEntryLinesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$JournalEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalEntriesTableTable,
          JournalEntryData,
          $$JournalEntriesTableTableFilterComposer,
          $$JournalEntriesTableTableOrderingComposer,
          $$JournalEntriesTableTableAnnotationComposer,
          $$JournalEntriesTableTableCreateCompanionBuilder,
          $$JournalEntriesTableTableUpdateCompanionBuilder,
          (JournalEntryData, $$JournalEntriesTableTableReferences),
          JournalEntryData,
          PrefetchHooks Function({
            bool fiscalYearId,
            bool currencyId,
            bool journalEntryLinesTableRefs,
          })
        > {
  $$JournalEntriesTableTableTableManager(
    _$AppDatabase db,
    $JournalEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fiscalYearId = const Value.absent(),
                Value<String> entryNumber = const Value.absent(),
                Value<DateTime> entryDate = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String> currencyId = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEntriesTableCompanion(
                id: id,
                fiscalYearId: fiscalYearId,
                entryNumber: entryNumber,
                entryDate: entryDate,
                referenceType: referenceType,
                referenceId: referenceId,
                currencyId: currencyId,
                exchangeRate: exchangeRate,
                description: description,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String fiscalYearId,
                required String entryNumber,
                Value<DateTime> entryDate = const Value.absent(),
                required String referenceType,
                Value<String?> referenceId = const Value.absent(),
                required String currencyId,
                Value<double> exchangeRate = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEntriesTableCompanion.insert(
                id: id,
                fiscalYearId: fiscalYearId,
                entryNumber: entryNumber,
                entryDate: entryDate,
                referenceType: referenceType,
                referenceId: referenceId,
                currencyId: currencyId,
                exchangeRate: exchangeRate,
                description: description,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JournalEntriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                fiscalYearId = false,
                currencyId = false,
                journalEntryLinesTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (journalEntryLinesTableRefs) db.journalEntryLinesTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (fiscalYearId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fiscalYearId,
                                    referencedTable:
                                        $$JournalEntriesTableTableReferences
                                            ._fiscalYearIdTable(db),
                                    referencedColumn:
                                        $$JournalEntriesTableTableReferences
                                            ._fiscalYearIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (currencyId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyId,
                                    referencedTable:
                                        $$JournalEntriesTableTableReferences
                                            ._currencyIdTable(db),
                                    referencedColumn:
                                        $$JournalEntriesTableTableReferences
                                            ._currencyIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (journalEntryLinesTableRefs)
                        await $_getPrefetchedData<
                          JournalEntryData,
                          $JournalEntriesTableTable,
                          JournalEntryLineData
                        >(
                          currentTable: table,
                          referencedTable: $$JournalEntriesTableTableReferences
                              ._journalEntryLinesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$JournalEntriesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).journalEntryLinesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.journalEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$JournalEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalEntriesTableTable,
      JournalEntryData,
      $$JournalEntriesTableTableFilterComposer,
      $$JournalEntriesTableTableOrderingComposer,
      $$JournalEntriesTableTableAnnotationComposer,
      $$JournalEntriesTableTableCreateCompanionBuilder,
      $$JournalEntriesTableTableUpdateCompanionBuilder,
      (JournalEntryData, $$JournalEntriesTableTableReferences),
      JournalEntryData,
      PrefetchHooks Function({
        bool fiscalYearId,
        bool currencyId,
        bool journalEntryLinesTableRefs,
      })
    >;
typedef $$JournalEntryLinesTableTableCreateCompanionBuilder =
    JournalEntryLinesTableCompanion Function({
      Value<String> id,
      required String journalEntryId,
      required int lineNumber,
      required String accountId,
      Value<String?> description,
      Value<double> debit,
      Value<double> credit,
      Value<double> baseDebit,
      Value<double> baseCredit,
      Value<int> rowid,
    });
typedef $$JournalEntryLinesTableTableUpdateCompanionBuilder =
    JournalEntryLinesTableCompanion Function({
      Value<String> id,
      Value<String> journalEntryId,
      Value<int> lineNumber,
      Value<String> accountId,
      Value<String?> description,
      Value<double> debit,
      Value<double> credit,
      Value<double> baseDebit,
      Value<double> baseCredit,
      Value<int> rowid,
    });

final class $$JournalEntryLinesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $JournalEntryLinesTableTable,
          JournalEntryLineData
        > {
  $$JournalEntryLinesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $JournalEntriesTableTable _journalEntryIdTable(_$AppDatabase db) =>
      db.journalEntriesTable.createAlias(
        $_aliasNameGenerator(
          db.journalEntryLinesTable.journalEntryId,
          db.journalEntriesTable.id,
        ),
      );

  $$JournalEntriesTableTableProcessedTableManager get journalEntryId {
    final $_column = $_itemColumn<String>('journal_entry_id')!;

    final manager = $$JournalEntriesTableTableTableManager(
      $_db,
      $_db.journalEntriesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_journalEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChartOfAccountsTableTable _accountIdTable(_$AppDatabase db) =>
      db.chartOfAccountsTable.createAlias(
        $_aliasNameGenerator(
          db.journalEntryLinesTable.accountId,
          db.chartOfAccountsTable.id,
        ),
      );

  $$ChartOfAccountsTableTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$ChartOfAccountsTableTableTableManager(
      $_db,
      $_db.chartOfAccountsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JournalEntryLinesTableTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntryLinesTableTable> {
  $$JournalEntryLinesTableTableFilterComposer({
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

  ColumnFilters<int> get lineNumber => $composableBuilder(
    column: $table.lineNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get debit => $composableBuilder(
    column: $table.debit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get credit => $composableBuilder(
    column: $table.credit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseDebit => $composableBuilder(
    column: $table.baseDebit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseCredit => $composableBuilder(
    column: $table.baseCredit,
    builder: (column) => ColumnFilters(column),
  );

  $$JournalEntriesTableTableFilterComposer get journalEntryId {
    final $$JournalEntriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.journalEntryId,
      referencedTable: $db.journalEntriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableTableFilterComposer(
            $db: $db,
            $table: $db.journalEntriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChartOfAccountsTableTableFilterComposer get accountId {
    final $$ChartOfAccountsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.chartOfAccountsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChartOfAccountsTableTableFilterComposer(
            $db: $db,
            $table: $db.chartOfAccountsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JournalEntryLinesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntryLinesTableTable> {
  $$JournalEntryLinesTableTableOrderingComposer({
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

  ColumnOrderings<int> get lineNumber => $composableBuilder(
    column: $table.lineNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get debit => $composableBuilder(
    column: $table.debit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get credit => $composableBuilder(
    column: $table.credit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseDebit => $composableBuilder(
    column: $table.baseDebit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseCredit => $composableBuilder(
    column: $table.baseCredit,
    builder: (column) => ColumnOrderings(column),
  );

  $$JournalEntriesTableTableOrderingComposer get journalEntryId {
    final $$JournalEntriesTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.journalEntryId,
          referencedTable: $db.journalEntriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JournalEntriesTableTableOrderingComposer(
                $db: $db,
                $table: $db.journalEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ChartOfAccountsTableTableOrderingComposer get accountId {
    final $$ChartOfAccountsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.chartOfAccountsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChartOfAccountsTableTableOrderingComposer(
                $db: $db,
                $table: $db.chartOfAccountsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$JournalEntryLinesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntryLinesTableTable> {
  $$JournalEntryLinesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lineNumber => $composableBuilder(
    column: $table.lineNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get debit =>
      $composableBuilder(column: $table.debit, builder: (column) => column);

  GeneratedColumn<double> get credit =>
      $composableBuilder(column: $table.credit, builder: (column) => column);

  GeneratedColumn<double> get baseDebit =>
      $composableBuilder(column: $table.baseDebit, builder: (column) => column);

  GeneratedColumn<double> get baseCredit => $composableBuilder(
    column: $table.baseCredit,
    builder: (column) => column,
  );

  $$JournalEntriesTableTableAnnotationComposer get journalEntryId {
    final $$JournalEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.journalEntryId,
          referencedTable: $db.journalEntriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$JournalEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.journalEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ChartOfAccountsTableTableAnnotationComposer get accountId {
    final $$ChartOfAccountsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.chartOfAccountsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChartOfAccountsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.chartOfAccountsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$JournalEntryLinesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalEntryLinesTableTable,
          JournalEntryLineData,
          $$JournalEntryLinesTableTableFilterComposer,
          $$JournalEntryLinesTableTableOrderingComposer,
          $$JournalEntryLinesTableTableAnnotationComposer,
          $$JournalEntryLinesTableTableCreateCompanionBuilder,
          $$JournalEntryLinesTableTableUpdateCompanionBuilder,
          (JournalEntryLineData, $$JournalEntryLinesTableTableReferences),
          JournalEntryLineData,
          PrefetchHooks Function({bool journalEntryId, bool accountId})
        > {
  $$JournalEntryLinesTableTableTableManager(
    _$AppDatabase db,
    $JournalEntryLinesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntryLinesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$JournalEntryLinesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$JournalEntryLinesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> journalEntryId = const Value.absent(),
                Value<int> lineNumber = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> debit = const Value.absent(),
                Value<double> credit = const Value.absent(),
                Value<double> baseDebit = const Value.absent(),
                Value<double> baseCredit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEntryLinesTableCompanion(
                id: id,
                journalEntryId: journalEntryId,
                lineNumber: lineNumber,
                accountId: accountId,
                description: description,
                debit: debit,
                credit: credit,
                baseDebit: baseDebit,
                baseCredit: baseCredit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String journalEntryId,
                required int lineNumber,
                required String accountId,
                Value<String?> description = const Value.absent(),
                Value<double> debit = const Value.absent(),
                Value<double> credit = const Value.absent(),
                Value<double> baseDebit = const Value.absent(),
                Value<double> baseCredit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEntryLinesTableCompanion.insert(
                id: id,
                journalEntryId: journalEntryId,
                lineNumber: lineNumber,
                accountId: accountId,
                description: description,
                debit: debit,
                credit: credit,
                baseDebit: baseDebit,
                baseCredit: baseCredit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JournalEntryLinesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({journalEntryId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (journalEntryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.journalEntryId,
                                referencedTable:
                                    $$JournalEntryLinesTableTableReferences
                                        ._journalEntryIdTable(db),
                                referencedColumn:
                                    $$JournalEntryLinesTableTableReferences
                                        ._journalEntryIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$JournalEntryLinesTableTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$JournalEntryLinesTableTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$JournalEntryLinesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalEntryLinesTableTable,
      JournalEntryLineData,
      $$JournalEntryLinesTableTableFilterComposer,
      $$JournalEntryLinesTableTableOrderingComposer,
      $$JournalEntryLinesTableTableAnnotationComposer,
      $$JournalEntryLinesTableTableCreateCompanionBuilder,
      $$JournalEntryLinesTableTableUpdateCompanionBuilder,
      (JournalEntryLineData, $$JournalEntryLinesTableTableReferences),
      JournalEntryLineData,
      PrefetchHooks Function({bool journalEntryId, bool accountId})
    >;
typedef $$PartiesTableTableCreateCompanionBuilder =
    PartiesTableCompanion Function({
      Value<String> id,
      required String name,
      required String partyType,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      required String accountId,
      Value<double> creditLimit,
      Value<double> openingBalance,
      Value<String?> openingBalanceType,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$PartiesTableTableUpdateCompanionBuilder =
    PartiesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> partyType,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<String> accountId,
      Value<double> creditLimit,
      Value<double> openingBalance,
      Value<String?> openingBalanceType,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PartiesTableTableReferences
    extends BaseReferences<_$AppDatabase, $PartiesTableTable, PartyData> {
  $$PartiesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChartOfAccountsTableTable _accountIdTable(_$AppDatabase db) =>
      db.chartOfAccountsTable.createAlias(
        $_aliasNameGenerator(
          db.partiesTable.accountId,
          db.chartOfAccountsTable.id,
        ),
      );

  $$ChartOfAccountsTableTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$ChartOfAccountsTableTableTableManager(
      $_db,
      $_db.chartOfAccountsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PartiesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PartiesTableTable> {
  $$PartiesTableTableFilterComposer({
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

  ColumnFilters<String> get partyType => $composableBuilder(
    column: $table.partyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingBalanceType => $composableBuilder(
    column: $table.openingBalanceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChartOfAccountsTableTableFilterComposer get accountId {
    final $$ChartOfAccountsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.chartOfAccountsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChartOfAccountsTableTableFilterComposer(
            $db: $db,
            $table: $db.chartOfAccountsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PartiesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PartiesTableTable> {
  $$PartiesTableTableOrderingComposer({
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

  ColumnOrderings<String> get partyType => $composableBuilder(
    column: $table.partyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingBalanceType => $composableBuilder(
    column: $table.openingBalanceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChartOfAccountsTableTableOrderingComposer get accountId {
    final $$ChartOfAccountsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.chartOfAccountsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChartOfAccountsTableTableOrderingComposer(
                $db: $db,
                $table: $db.chartOfAccountsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PartiesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartiesTableTable> {
  $$PartiesTableTableAnnotationComposer({
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

  GeneratedColumn<String> get partyType =>
      $composableBuilder(column: $table.partyType, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openingBalanceType => $composableBuilder(
    column: $table.openingBalanceType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChartOfAccountsTableTableAnnotationComposer get accountId {
    final $$ChartOfAccountsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.chartOfAccountsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChartOfAccountsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.chartOfAccountsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PartiesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PartiesTableTable,
          PartyData,
          $$PartiesTableTableFilterComposer,
          $$PartiesTableTableOrderingComposer,
          $$PartiesTableTableAnnotationComposer,
          $$PartiesTableTableCreateCompanionBuilder,
          $$PartiesTableTableUpdateCompanionBuilder,
          (PartyData, $$PartiesTableTableReferences),
          PartyData,
          PrefetchHooks Function({bool accountId})
        > {
  $$PartiesTableTableTableManager(_$AppDatabase db, $PartiesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartiesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartiesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartiesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> partyType = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<double> creditLimit = const Value.absent(),
                Value<double> openingBalance = const Value.absent(),
                Value<String?> openingBalanceType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PartiesTableCompanion(
                id: id,
                name: name,
                partyType: partyType,
                phone: phone,
                email: email,
                address: address,
                accountId: accountId,
                creditLimit: creditLimit,
                openingBalance: openingBalance,
                openingBalanceType: openingBalanceType,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String partyType,
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                required String accountId,
                Value<double> creditLimit = const Value.absent(),
                Value<double> openingBalance = const Value.absent(),
                Value<String?> openingBalanceType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PartiesTableCompanion.insert(
                id: id,
                name: name,
                partyType: partyType,
                phone: phone,
                email: email,
                address: address,
                accountId: accountId,
                creditLimit: creditLimit,
                openingBalance: openingBalance,
                openingBalanceType: openingBalanceType,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PartiesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$PartiesTableTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$PartiesTableTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PartiesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PartiesTableTable,
      PartyData,
      $$PartiesTableTableFilterComposer,
      $$PartiesTableTableOrderingComposer,
      $$PartiesTableTableAnnotationComposer,
      $$PartiesTableTableCreateCompanionBuilder,
      $$PartiesTableTableUpdateCompanionBuilder,
      (PartyData, $$PartiesTableTableReferences),
      PartyData,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$PaymentMethodsTableTableCreateCompanionBuilder =
    PaymentMethodsTableCompanion Function({
      Value<String> id,
      required String name,
      required String type,
      required String accountId,
      Value<bool> isDefault,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$PaymentMethodsTableTableUpdateCompanionBuilder =
    PaymentMethodsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<String> accountId,
      Value<bool> isDefault,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$PaymentMethodsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PaymentMethodsTableTable,
          PaymentMethodData
        > {
  $$PaymentMethodsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChartOfAccountsTableTable _accountIdTable(_$AppDatabase db) =>
      db.chartOfAccountsTable.createAlias(
        $_aliasNameGenerator(
          db.paymentMethodsTable.accountId,
          db.chartOfAccountsTable.id,
        ),
      );

  $$ChartOfAccountsTableTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$ChartOfAccountsTableTableTableManager(
      $_db,
      $_db.chartOfAccountsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentMethodsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTableTable> {
  $$PaymentMethodsTableTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$ChartOfAccountsTableTableFilterComposer get accountId {
    final $$ChartOfAccountsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.chartOfAccountsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChartOfAccountsTableTableFilterComposer(
            $db: $db,
            $table: $db.chartOfAccountsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentMethodsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTableTable> {
  $$PaymentMethodsTableTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChartOfAccountsTableTableOrderingComposer get accountId {
    final $$ChartOfAccountsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.chartOfAccountsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChartOfAccountsTableTableOrderingComposer(
                $db: $db,
                $table: $db.chartOfAccountsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PaymentMethodsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTableTable> {
  $$PaymentMethodsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$ChartOfAccountsTableTableAnnotationComposer get accountId {
    final $$ChartOfAccountsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.chartOfAccountsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChartOfAccountsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.chartOfAccountsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PaymentMethodsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentMethodsTableTable,
          PaymentMethodData,
          $$PaymentMethodsTableTableFilterComposer,
          $$PaymentMethodsTableTableOrderingComposer,
          $$PaymentMethodsTableTableAnnotationComposer,
          $$PaymentMethodsTableTableCreateCompanionBuilder,
          $$PaymentMethodsTableTableUpdateCompanionBuilder,
          (PaymentMethodData, $$PaymentMethodsTableTableReferences),
          PaymentMethodData,
          PrefetchHooks Function({bool accountId})
        > {
  $$PaymentMethodsTableTableTableManager(
    _$AppDatabase db,
    $PaymentMethodsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentMethodsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentMethodsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PaymentMethodsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentMethodsTableCompanion(
                id: id,
                name: name,
                type: type,
                accountId: accountId,
                isDefault: isDefault,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String type,
                required String accountId,
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentMethodsTableCompanion.insert(
                id: id,
                name: name,
                type: type,
                accountId: accountId,
                isDefault: isDefault,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PaymentMethodsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$PaymentMethodsTableTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$PaymentMethodsTableTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PaymentMethodsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentMethodsTableTable,
      PaymentMethodData,
      $$PaymentMethodsTableTableFilterComposer,
      $$PaymentMethodsTableTableOrderingComposer,
      $$PaymentMethodsTableTableAnnotationComposer,
      $$PaymentMethodsTableTableCreateCompanionBuilder,
      $$PaymentMethodsTableTableUpdateCompanionBuilder,
      (PaymentMethodData, $$PaymentMethodsTableTableReferences),
      PaymentMethodData,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$UnitsTableTableCreateCompanionBuilder =
    UnitsTableCompanion Function({
      Value<String> id,
      required String nameAr,
      required String code,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$UnitsTableTableUpdateCompanionBuilder =
    UnitsTableCompanion Function({
      Value<String> id,
      Value<String> nameAr,
      Value<String> code,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$UnitsTableTableReferences
    extends BaseReferences<_$AppDatabase, $UnitsTableTable, UnitData> {
  $$UnitsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductsTableTable, List<ProductData>>
  _productsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productsTable,
    aliasName: $_aliasNameGenerator(
      db.unitsTable.id,
      db.productsTable.baseUnitId,
    ),
  );

  $$ProductsTableTableProcessedTableManager get productsTableRefs {
    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.baseUnitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProductUnitsTableTable, List<ProductUnitData>>
  _productUnitsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.productUnitsTable,
        aliasName: $_aliasNameGenerator(
          db.unitsTable.id,
          db.productUnitsTable.unitId,
        ),
      );

  $$ProductUnitsTableTableProcessedTableManager get productUnitsTableRefs {
    final manager = $$ProductUnitsTableTableTableManager(
      $_db,
      $_db.productUnitsTable,
    ).filter((f) => f.unitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _productUnitsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UnitsTableTableFilterComposer
    extends Composer<_$AppDatabase, $UnitsTableTable> {
  $$UnitsTableTableFilterComposer({
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

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productsTableRefs(
    Expression<bool> Function($$ProductsTableTableFilterComposer f) f,
  ) {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.baseUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> productUnitsTableRefs(
    Expression<bool> Function($$ProductUnitsTableTableFilterComposer f) f,
  ) {
    final $$ProductUnitsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productUnitsTable,
      getReferencedColumn: (t) => t.unitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductUnitsTableTableFilterComposer(
            $db: $db,
            $table: $db.productUnitsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UnitsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitsTableTable> {
  $$UnitsTableTableOrderingComposer({
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

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnitsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitsTableTable> {
  $$UnitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> productsTableRefs<T extends Object>(
    Expression<T> Function($$ProductsTableTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.baseUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> productUnitsTableRefs<T extends Object>(
    Expression<T> Function($$ProductUnitsTableTableAnnotationComposer a) f,
  ) {
    final $$ProductUnitsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.productUnitsTable,
          getReferencedColumn: (t) => t.unitId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductUnitsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.productUnitsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UnitsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnitsTableTable,
          UnitData,
          $$UnitsTableTableFilterComposer,
          $$UnitsTableTableOrderingComposer,
          $$UnitsTableTableAnnotationComposer,
          $$UnitsTableTableCreateCompanionBuilder,
          $$UnitsTableTableUpdateCompanionBuilder,
          (UnitData, $$UnitsTableTableReferences),
          UnitData,
          PrefetchHooks Function({
            bool productsTableRefs,
            bool productUnitsTableRefs,
          })
        > {
  $$UnitsTableTableTableManager(_$AppDatabase db, $UnitsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitsTableCompanion(
                id: id,
                nameAr: nameAr,
                code: code,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String nameAr,
                required String code,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitsTableCompanion.insert(
                id: id,
                nameAr: nameAr,
                code: code,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UnitsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({productsTableRefs = false, productUnitsTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productsTableRefs) db.productsTable,
                    if (productUnitsTableRefs) db.productUnitsTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productsTableRefs)
                        await $_getPrefetchedData<
                          UnitData,
                          $UnitsTableTable,
                          ProductData
                        >(
                          currentTable: table,
                          referencedTable: $$UnitsTableTableReferences
                              ._productsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UnitsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.baseUnitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (productUnitsTableRefs)
                        await $_getPrefetchedData<
                          UnitData,
                          $UnitsTableTable,
                          ProductUnitData
                        >(
                          currentTable: table,
                          referencedTable: $$UnitsTableTableReferences
                              ._productUnitsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UnitsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productUnitsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.unitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UnitsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnitsTableTable,
      UnitData,
      $$UnitsTableTableFilterComposer,
      $$UnitsTableTableOrderingComposer,
      $$UnitsTableTableAnnotationComposer,
      $$UnitsTableTableCreateCompanionBuilder,
      $$UnitsTableTableUpdateCompanionBuilder,
      (UnitData, $$UnitsTableTableReferences),
      UnitData,
      PrefetchHooks Function({
        bool productsTableRefs,
        bool productUnitsTableRefs,
      })
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      required String name,
      Value<String?> category,
      Value<String?> sku,
      Value<String?> imagePath,
      Value<bool> isStockable,
      required String baseUnitId,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> category,
      Value<String?> sku,
      Value<String?> imagePath,
      Value<bool> isStockable,
      Value<String> baseUnitId,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ProductsTableTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTableTable, ProductData> {
  $$ProductsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UnitsTableTable _baseUnitIdTable(_$AppDatabase db) =>
      db.unitsTable.createAlias(
        $_aliasNameGenerator(db.productsTable.baseUnitId, db.unitsTable.id),
      );

  $$UnitsTableTableProcessedTableManager get baseUnitId {
    final $_column = $_itemColumn<String>('base_unit_id')!;

    final manager = $$UnitsTableTableTableManager(
      $_db,
      $_db.unitsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProductUnitsTableTable, List<ProductUnitData>>
  _productUnitsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.productUnitsTable,
        aliasName: $_aliasNameGenerator(
          db.productsTable.id,
          db.productUnitsTable.productId,
        ),
      );

  $$ProductUnitsTableTableProcessedTableManager get productUnitsTableRefs {
    final manager = $$ProductUnitsTableTableTableManager(
      $_db,
      $_db.productUnitsTable,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _productUnitsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InventoriesTableTable, List<InventoryData>>
  _inventoriesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoriesTable,
    aliasName: $_aliasNameGenerator(
      db.productsTable.id,
      db.inventoriesTable.productId,
    ),
  );

  $$InventoriesTableTableProcessedTableManager get inventoriesTableRefs {
    final manager = $$InventoriesTableTableTableManager(
      $_db,
      $_db.inventoriesTable,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inventoriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $InventoryTransactionsTableTable,
    List<InventoryTransactionData>
  >
  _inventoryTransactionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.inventoryTransactionsTable,
        aliasName: $_aliasNameGenerator(
          db.productsTable.id,
          db.inventoryTransactionsTable.productId,
        ),
      );

  $$InventoryTransactionsTableTableProcessedTableManager
  get inventoryTransactionsTableRefs {
    final manager = $$InventoryTransactionsTableTableTableManager(
      $_db,
      $_db.inventoryTransactionsTable,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inventoryTransactionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStockable => $composableBuilder(
    column: $table.isStockable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UnitsTableTableFilterComposer get baseUnitId {
    final $$UnitsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseUnitId,
      referencedTable: $db.unitsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitsTableTableFilterComposer(
            $db: $db,
            $table: $db.unitsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> productUnitsTableRefs(
    Expression<bool> Function($$ProductUnitsTableTableFilterComposer f) f,
  ) {
    final $$ProductUnitsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productUnitsTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductUnitsTableTableFilterComposer(
            $db: $db,
            $table: $db.productUnitsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inventoriesTableRefs(
    Expression<bool> Function($$InventoriesTableTableFilterComposer f) f,
  ) {
    final $$InventoriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoriesTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableTableFilterComposer(
            $db: $db,
            $table: $db.inventoriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inventoryTransactionsTableRefs(
    Expression<bool> Function($$InventoryTransactionsTableTableFilterComposer f)
    f,
  ) {
    final $$InventoryTransactionsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inventoryTransactionsTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventoryTransactionsTableTableFilterComposer(
                $db: $db,
                $table: $db.inventoryTransactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStockable => $composableBuilder(
    column: $table.isStockable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UnitsTableTableOrderingComposer get baseUnitId {
    final $$UnitsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseUnitId,
      referencedTable: $db.unitsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitsTableTableOrderingComposer(
            $db: $db,
            $table: $db.unitsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isStockable => $composableBuilder(
    column: $table.isStockable,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UnitsTableTableAnnotationComposer get baseUnitId {
    final $$UnitsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseUnitId,
      referencedTable: $db.unitsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.unitsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> productUnitsTableRefs<T extends Object>(
    Expression<T> Function($$ProductUnitsTableTableAnnotationComposer a) f,
  ) {
    final $$ProductUnitsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.productUnitsTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductUnitsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.productUnitsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> inventoriesTableRefs<T extends Object>(
    Expression<T> Function($$InventoriesTableTableAnnotationComposer a) f,
  ) {
    final $$InventoriesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoriesTable,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inventoryTransactionsTableRefs<T extends Object>(
    Expression<T> Function(
      $$InventoryTransactionsTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$InventoryTransactionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inventoryTransactionsTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventoryTransactionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.inventoryTransactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductData,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (ProductData, $$ProductsTableTableReferences),
          ProductData,
          PrefetchHooks Function({
            bool baseUnitId,
            bool productUnitsTableRefs,
            bool inventoriesTableRefs,
            bool inventoryTransactionsTableRefs,
          })
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isStockable = const Value.absent(),
                Value<String> baseUnitId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                name: name,
                category: category,
                sku: sku,
                imagePath: imagePath,
                isStockable: isStockable,
                baseUnitId: baseUnitId,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                Value<String?> category = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isStockable = const Value.absent(),
                required String baseUnitId,
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                name: name,
                category: category,
                sku: sku,
                imagePath: imagePath,
                isStockable: isStockable,
                baseUnitId: baseUnitId,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                baseUnitId = false,
                productUnitsTableRefs = false,
                inventoriesTableRefs = false,
                inventoryTransactionsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productUnitsTableRefs) db.productUnitsTable,
                    if (inventoriesTableRefs) db.inventoriesTable,
                    if (inventoryTransactionsTableRefs)
                      db.inventoryTransactionsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (baseUnitId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.baseUnitId,
                                    referencedTable:
                                        $$ProductsTableTableReferences
                                            ._baseUnitIdTable(db),
                                    referencedColumn:
                                        $$ProductsTableTableReferences
                                            ._baseUnitIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productUnitsTableRefs)
                        await $_getPrefetchedData<
                          ProductData,
                          $ProductsTableTable,
                          ProductUnitData
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableTableReferences
                              ._productUnitsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productUnitsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inventoriesTableRefs)
                        await $_getPrefetchedData<
                          ProductData,
                          $ProductsTableTable,
                          InventoryData
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableTableReferences
                              ._inventoriesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoriesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inventoryTransactionsTableRefs)
                        await $_getPrefetchedData<
                          ProductData,
                          $ProductsTableTable,
                          InventoryTransactionData
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableTableReferences
                              ._inventoryTransactionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryTransactionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductData,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (ProductData, $$ProductsTableTableReferences),
      ProductData,
      PrefetchHooks Function({
        bool baseUnitId,
        bool productUnitsTableRefs,
        bool inventoriesTableRefs,
        bool inventoryTransactionsTableRefs,
      })
    >;
typedef $$ProductUnitsTableTableCreateCompanionBuilder =
    ProductUnitsTableCompanion Function({
      Value<String> id,
      required String productId,
      required String unitId,
      Value<double> conversionFactor,
      Value<String?> barcode,
      Value<double> salePrice,
      Value<double> minSalePrice,
      Value<double> purchasePrice,
      Value<bool> isDefaultSaleUnit,
      Value<bool> isDefaultPurchaseUnit,
      Value<int> rowid,
    });
typedef $$ProductUnitsTableTableUpdateCompanionBuilder =
    ProductUnitsTableCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> unitId,
      Value<double> conversionFactor,
      Value<String?> barcode,
      Value<double> salePrice,
      Value<double> minSalePrice,
      Value<double> purchasePrice,
      Value<bool> isDefaultSaleUnit,
      Value<bool> isDefaultPurchaseUnit,
      Value<int> rowid,
    });

final class $$ProductUnitsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProductUnitsTableTable,
          ProductUnitData
        > {
  $$ProductUnitsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTableTable _productIdTable(_$AppDatabase db) =>
      db.productsTable.createAlias(
        $_aliasNameGenerator(
          db.productUnitsTable.productId,
          db.productsTable.id,
        ),
      );

  $$ProductsTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UnitsTableTable _unitIdTable(_$AppDatabase db) =>
      db.unitsTable.createAlias(
        $_aliasNameGenerator(db.productUnitsTable.unitId, db.unitsTable.id),
      );

  $$UnitsTableTableProcessedTableManager get unitId {
    final $_column = $_itemColumn<String>('unit_id')!;

    final manager = $$UnitsTableTableTableManager(
      $_db,
      $_db.unitsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductUnitsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductUnitsTableTable> {
  $$ProductUnitsTableTableFilterComposer({
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

  ColumnFilters<double> get conversionFactor => $composableBuilder(
    column: $table.conversionFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minSalePrice => $composableBuilder(
    column: $table.minSalePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefaultSaleUnit => $composableBuilder(
    column: $table.isDefaultSaleUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefaultPurchaseUnit => $composableBuilder(
    column: $table.isDefaultPurchaseUnit,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableTableFilterComposer get productId {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UnitsTableTableFilterComposer get unitId {
    final $$UnitsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.unitId,
      referencedTable: $db.unitsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitsTableTableFilterComposer(
            $db: $db,
            $table: $db.unitsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductUnitsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductUnitsTableTable> {
  $$ProductUnitsTableTableOrderingComposer({
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

  ColumnOrderings<double> get conversionFactor => $composableBuilder(
    column: $table.conversionFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salePrice => $composableBuilder(
    column: $table.salePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minSalePrice => $composableBuilder(
    column: $table.minSalePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefaultSaleUnit => $composableBuilder(
    column: $table.isDefaultSaleUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefaultPurchaseUnit => $composableBuilder(
    column: $table.isDefaultPurchaseUnit,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableTableOrderingComposer get productId {
    final $$ProductsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableOrderingComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UnitsTableTableOrderingComposer get unitId {
    final $$UnitsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.unitId,
      referencedTable: $db.unitsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitsTableTableOrderingComposer(
            $db: $db,
            $table: $db.unitsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductUnitsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductUnitsTableTable> {
  $$ProductUnitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get conversionFactor => $composableBuilder(
    column: $table.conversionFactor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get salePrice =>
      $composableBuilder(column: $table.salePrice, builder: (column) => column);

  GeneratedColumn<double> get minSalePrice => $composableBuilder(
    column: $table.minSalePrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefaultSaleUnit => $composableBuilder(
    column: $table.isDefaultSaleUnit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefaultPurchaseUnit => $composableBuilder(
    column: $table.isDefaultPurchaseUnit,
    builder: (column) => column,
  );

  $$ProductsTableTableAnnotationComposer get productId {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UnitsTableTableAnnotationComposer get unitId {
    final $$UnitsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.unitId,
      referencedTable: $db.unitsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UnitsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.unitsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductUnitsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductUnitsTableTable,
          ProductUnitData,
          $$ProductUnitsTableTableFilterComposer,
          $$ProductUnitsTableTableOrderingComposer,
          $$ProductUnitsTableTableAnnotationComposer,
          $$ProductUnitsTableTableCreateCompanionBuilder,
          $$ProductUnitsTableTableUpdateCompanionBuilder,
          (ProductUnitData, $$ProductUnitsTableTableReferences),
          ProductUnitData,
          PrefetchHooks Function({bool productId, bool unitId})
        > {
  $$ProductUnitsTableTableTableManager(
    _$AppDatabase db,
    $ProductUnitsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductUnitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductUnitsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductUnitsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> unitId = const Value.absent(),
                Value<double> conversionFactor = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<double> salePrice = const Value.absent(),
                Value<double> minSalePrice = const Value.absent(),
                Value<double> purchasePrice = const Value.absent(),
                Value<bool> isDefaultSaleUnit = const Value.absent(),
                Value<bool> isDefaultPurchaseUnit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductUnitsTableCompanion(
                id: id,
                productId: productId,
                unitId: unitId,
                conversionFactor: conversionFactor,
                barcode: barcode,
                salePrice: salePrice,
                minSalePrice: minSalePrice,
                purchasePrice: purchasePrice,
                isDefaultSaleUnit: isDefaultSaleUnit,
                isDefaultPurchaseUnit: isDefaultPurchaseUnit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String productId,
                required String unitId,
                Value<double> conversionFactor = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<double> salePrice = const Value.absent(),
                Value<double> minSalePrice = const Value.absent(),
                Value<double> purchasePrice = const Value.absent(),
                Value<bool> isDefaultSaleUnit = const Value.absent(),
                Value<bool> isDefaultPurchaseUnit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductUnitsTableCompanion.insert(
                id: id,
                productId: productId,
                unitId: unitId,
                conversionFactor: conversionFactor,
                barcode: barcode,
                salePrice: salePrice,
                minSalePrice: minSalePrice,
                purchasePrice: purchasePrice,
                isDefaultSaleUnit: isDefaultSaleUnit,
                isDefaultPurchaseUnit: isDefaultPurchaseUnit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductUnitsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false, unitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$ProductUnitsTableTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$ProductUnitsTableTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (unitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.unitId,
                                referencedTable:
                                    $$ProductUnitsTableTableReferences
                                        ._unitIdTable(db),
                                referencedColumn:
                                    $$ProductUnitsTableTableReferences
                                        ._unitIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProductUnitsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductUnitsTableTable,
      ProductUnitData,
      $$ProductUnitsTableTableFilterComposer,
      $$ProductUnitsTableTableOrderingComposer,
      $$ProductUnitsTableTableAnnotationComposer,
      $$ProductUnitsTableTableCreateCompanionBuilder,
      $$ProductUnitsTableTableUpdateCompanionBuilder,
      (ProductUnitData, $$ProductUnitsTableTableReferences),
      ProductUnitData,
      PrefetchHooks Function({bool productId, bool unitId})
    >;
typedef $$WarehousesTableTableCreateCompanionBuilder =
    WarehousesTableCompanion Function({
      Value<String> id,
      required String name,
      required String code,
      Value<bool> isDefault,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$WarehousesTableTableUpdateCompanionBuilder =
    WarehousesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> code,
      Value<bool> isDefault,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$WarehousesTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $WarehousesTableTable, WarehouseData> {
  $$WarehousesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$InventoriesTableTable, List<InventoryData>>
  _inventoriesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoriesTable,
    aliasName: $_aliasNameGenerator(
      db.warehousesTable.id,
      db.inventoriesTable.warehouseId,
    ),
  );

  $$InventoriesTableTableProcessedTableManager get inventoriesTableRefs {
    final manager = $$InventoriesTableTableTableManager(
      $_db,
      $_db.inventoriesTable,
    ).filter((f) => f.warehouseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inventoriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $InventoryTransactionsTableTable,
    List<InventoryTransactionData>
  >
  _inventoryTransactionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.inventoryTransactionsTable,
        aliasName: $_aliasNameGenerator(
          db.warehousesTable.id,
          db.inventoryTransactionsTable.warehouseId,
        ),
      );

  $$InventoryTransactionsTableTableProcessedTableManager
  get inventoryTransactionsTableRefs {
    final manager = $$InventoryTransactionsTableTableTableManager(
      $_db,
      $_db.inventoryTransactionsTable,
    ).filter((f) => f.warehouseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inventoryTransactionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WarehousesTableTableFilterComposer
    extends Composer<_$AppDatabase, $WarehousesTableTable> {
  $$WarehousesTableTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> inventoriesTableRefs(
    Expression<bool> Function($$InventoriesTableTableFilterComposer f) f,
  ) {
    final $$InventoriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoriesTable,
      getReferencedColumn: (t) => t.warehouseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableTableFilterComposer(
            $db: $db,
            $table: $db.inventoriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inventoryTransactionsTableRefs(
    Expression<bool> Function($$InventoryTransactionsTableTableFilterComposer f)
    f,
  ) {
    final $$InventoryTransactionsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inventoryTransactionsTable,
          getReferencedColumn: (t) => t.warehouseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventoryTransactionsTableTableFilterComposer(
                $db: $db,
                $table: $db.inventoryTransactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WarehousesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WarehousesTableTable> {
  $$WarehousesTableTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WarehousesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WarehousesTableTable> {
  $$WarehousesTableTableAnnotationComposer({
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

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> inventoriesTableRefs<T extends Object>(
    Expression<T> Function($$InventoriesTableTableAnnotationComposer a) f,
  ) {
    final $$InventoriesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoriesTable,
      getReferencedColumn: (t) => t.warehouseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoriesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inventoryTransactionsTableRefs<T extends Object>(
    Expression<T> Function(
      $$InventoryTransactionsTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$InventoryTransactionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inventoryTransactionsTable,
          getReferencedColumn: (t) => t.warehouseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InventoryTransactionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.inventoryTransactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WarehousesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WarehousesTableTable,
          WarehouseData,
          $$WarehousesTableTableFilterComposer,
          $$WarehousesTableTableOrderingComposer,
          $$WarehousesTableTableAnnotationComposer,
          $$WarehousesTableTableCreateCompanionBuilder,
          $$WarehousesTableTableUpdateCompanionBuilder,
          (WarehouseData, $$WarehousesTableTableReferences),
          WarehouseData,
          PrefetchHooks Function({
            bool inventoriesTableRefs,
            bool inventoryTransactionsTableRefs,
          })
        > {
  $$WarehousesTableTableTableManager(
    _$AppDatabase db,
    $WarehousesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WarehousesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WarehousesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WarehousesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WarehousesTableCompanion(
                id: id,
                name: name,
                code: code,
                isDefault: isDefault,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String code,
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WarehousesTableCompanion.insert(
                id: id,
                name: name,
                code: code,
                isDefault: isDefault,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WarehousesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                inventoriesTableRefs = false,
                inventoryTransactionsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (inventoriesTableRefs) db.inventoriesTable,
                    if (inventoryTransactionsTableRefs)
                      db.inventoryTransactionsTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (inventoriesTableRefs)
                        await $_getPrefetchedData<
                          WarehouseData,
                          $WarehousesTableTable,
                          InventoryData
                        >(
                          currentTable: table,
                          referencedTable: $$WarehousesTableTableReferences
                              ._inventoriesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WarehousesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoriesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.warehouseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inventoryTransactionsTableRefs)
                        await $_getPrefetchedData<
                          WarehouseData,
                          $WarehousesTableTable,
                          InventoryTransactionData
                        >(
                          currentTable: table,
                          referencedTable: $$WarehousesTableTableReferences
                              ._inventoryTransactionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WarehousesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryTransactionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.warehouseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WarehousesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WarehousesTableTable,
      WarehouseData,
      $$WarehousesTableTableFilterComposer,
      $$WarehousesTableTableOrderingComposer,
      $$WarehousesTableTableAnnotationComposer,
      $$WarehousesTableTableCreateCompanionBuilder,
      $$WarehousesTableTableUpdateCompanionBuilder,
      (WarehouseData, $$WarehousesTableTableReferences),
      WarehouseData,
      PrefetchHooks Function({
        bool inventoriesTableRefs,
        bool inventoryTransactionsTableRefs,
      })
    >;
typedef $$InventoriesTableTableCreateCompanionBuilder =
    InventoriesTableCompanion Function({
      Value<String> id,
      required String warehouseId,
      required String productId,
      Value<double> quantityOnHand,
      Value<double> averageCost,
      Value<double> alertQuantity,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$InventoriesTableTableUpdateCompanionBuilder =
    InventoriesTableCompanion Function({
      Value<String> id,
      Value<String> warehouseId,
      Value<String> productId,
      Value<double> quantityOnHand,
      Value<double> averageCost,
      Value<double> alertQuantity,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$InventoriesTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $InventoriesTableTable, InventoryData> {
  $$InventoriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WarehousesTableTable _warehouseIdTable(_$AppDatabase db) =>
      db.warehousesTable.createAlias(
        $_aliasNameGenerator(
          db.inventoriesTable.warehouseId,
          db.warehousesTable.id,
        ),
      );

  $$WarehousesTableTableProcessedTableManager get warehouseId {
    final $_column = $_itemColumn<String>('warehouse_id')!;

    final manager = $$WarehousesTableTableTableManager(
      $_db,
      $_db.warehousesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_warehouseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTableTable _productIdTable(_$AppDatabase db) =>
      db.productsTable.createAlias(
        $_aliasNameGenerator(
          db.inventoriesTable.productId,
          db.productsTable.id,
        ),
      );

  $$ProductsTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InventoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $InventoriesTableTable> {
  $$InventoriesTableTableFilterComposer({
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

  ColumnFilters<double> get quantityOnHand => $composableBuilder(
    column: $table.quantityOnHand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageCost => $composableBuilder(
    column: $table.averageCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alertQuantity => $composableBuilder(
    column: $table.alertQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WarehousesTableTableFilterComposer get warehouseId {
    final $$WarehousesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.warehouseId,
      referencedTable: $db.warehousesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableTableFilterComposer(
            $db: $db,
            $table: $db.warehousesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableFilterComposer get productId {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoriesTableTable> {
  $$InventoriesTableTableOrderingComposer({
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

  ColumnOrderings<double> get quantityOnHand => $composableBuilder(
    column: $table.quantityOnHand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageCost => $composableBuilder(
    column: $table.averageCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alertQuantity => $composableBuilder(
    column: $table.alertQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WarehousesTableTableOrderingComposer get warehouseId {
    final $$WarehousesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.warehouseId,
      referencedTable: $db.warehousesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableTableOrderingComposer(
            $db: $db,
            $table: $db.warehousesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableOrderingComposer get productId {
    final $$ProductsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableOrderingComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoriesTableTable> {
  $$InventoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get quantityOnHand => $composableBuilder(
    column: $table.quantityOnHand,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageCost => $composableBuilder(
    column: $table.averageCost,
    builder: (column) => column,
  );

  GeneratedColumn<double> get alertQuantity => $composableBuilder(
    column: $table.alertQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WarehousesTableTableAnnotationComposer get warehouseId {
    final $$WarehousesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.warehouseId,
      referencedTable: $db.warehousesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.warehousesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableAnnotationComposer get productId {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoriesTableTable,
          InventoryData,
          $$InventoriesTableTableFilterComposer,
          $$InventoriesTableTableOrderingComposer,
          $$InventoriesTableTableAnnotationComposer,
          $$InventoriesTableTableCreateCompanionBuilder,
          $$InventoriesTableTableUpdateCompanionBuilder,
          (InventoryData, $$InventoriesTableTableReferences),
          InventoryData,
          PrefetchHooks Function({bool warehouseId, bool productId})
        > {
  $$InventoriesTableTableTableManager(
    _$AppDatabase db,
    $InventoriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> warehouseId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<double> quantityOnHand = const Value.absent(),
                Value<double> averageCost = const Value.absent(),
                Value<double> alertQuantity = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoriesTableCompanion(
                id: id,
                warehouseId: warehouseId,
                productId: productId,
                quantityOnHand: quantityOnHand,
                averageCost: averageCost,
                alertQuantity: alertQuantity,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String warehouseId,
                required String productId,
                Value<double> quantityOnHand = const Value.absent(),
                Value<double> averageCost = const Value.absent(),
                Value<double> alertQuantity = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoriesTableCompanion.insert(
                id: id,
                warehouseId: warehouseId,
                productId: productId,
                quantityOnHand: quantityOnHand,
                averageCost: averageCost,
                alertQuantity: alertQuantity,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({warehouseId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (warehouseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.warehouseId,
                                referencedTable:
                                    $$InventoriesTableTableReferences
                                        ._warehouseIdTable(db),
                                referencedColumn:
                                    $$InventoriesTableTableReferences
                                        ._warehouseIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$InventoriesTableTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$InventoriesTableTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InventoriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoriesTableTable,
      InventoryData,
      $$InventoriesTableTableFilterComposer,
      $$InventoriesTableTableOrderingComposer,
      $$InventoriesTableTableAnnotationComposer,
      $$InventoriesTableTableCreateCompanionBuilder,
      $$InventoriesTableTableUpdateCompanionBuilder,
      (InventoryData, $$InventoriesTableTableReferences),
      InventoryData,
      PrefetchHooks Function({bool warehouseId, bool productId})
    >;
typedef $$InventoryTransactionsTableTableCreateCompanionBuilder =
    InventoryTransactionsTableCompanion Function({
      Value<String> id,
      required String warehouseId,
      required String productId,
      required String transactionType,
      required double quantity,
      Value<double> unitCost,
      required String referenceType,
      required String referenceId,
      Value<DateTime> transactionDate,
      Value<int> rowid,
    });
typedef $$InventoryTransactionsTableTableUpdateCompanionBuilder =
    InventoryTransactionsTableCompanion Function({
      Value<String> id,
      Value<String> warehouseId,
      Value<String> productId,
      Value<String> transactionType,
      Value<double> quantity,
      Value<double> unitCost,
      Value<String> referenceType,
      Value<String> referenceId,
      Value<DateTime> transactionDate,
      Value<int> rowid,
    });

final class $$InventoryTransactionsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InventoryTransactionsTableTable,
          InventoryTransactionData
        > {
  $$InventoryTransactionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WarehousesTableTable _warehouseIdTable(_$AppDatabase db) =>
      db.warehousesTable.createAlias(
        $_aliasNameGenerator(
          db.inventoryTransactionsTable.warehouseId,
          db.warehousesTable.id,
        ),
      );

  $$WarehousesTableTableProcessedTableManager get warehouseId {
    final $_column = $_itemColumn<String>('warehouse_id')!;

    final manager = $$WarehousesTableTableTableManager(
      $_db,
      $_db.warehousesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_warehouseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTableTable _productIdTable(_$AppDatabase db) =>
      db.productsTable.createAlias(
        $_aliasNameGenerator(
          db.inventoryTransactionsTable.productId,
          db.productsTable.id,
        ),
      );

  $$ProductsTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InventoryTransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryTransactionsTableTable> {
  $$InventoryTransactionsTableTableFilterComposer({
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

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  $$WarehousesTableTableFilterComposer get warehouseId {
    final $$WarehousesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.warehouseId,
      referencedTable: $db.warehousesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableTableFilterComposer(
            $db: $db,
            $table: $db.warehousesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableFilterComposer get productId {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryTransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryTransactionsTableTable> {
  $$InventoryTransactionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$WarehousesTableTableOrderingComposer get warehouseId {
    final $$WarehousesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.warehouseId,
      referencedTable: $db.warehousesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableTableOrderingComposer(
            $db: $db,
            $table: $db.warehousesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableOrderingComposer get productId {
    final $$ProductsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableOrderingComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryTransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryTransactionsTableTable> {
  $$InventoryTransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  $$WarehousesTableTableAnnotationComposer get warehouseId {
    final $$WarehousesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.warehouseId,
      referencedTable: $db.warehousesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WarehousesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.warehousesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableAnnotationComposer get productId {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryTransactionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryTransactionsTableTable,
          InventoryTransactionData,
          $$InventoryTransactionsTableTableFilterComposer,
          $$InventoryTransactionsTableTableOrderingComposer,
          $$InventoryTransactionsTableTableAnnotationComposer,
          $$InventoryTransactionsTableTableCreateCompanionBuilder,
          $$InventoryTransactionsTableTableUpdateCompanionBuilder,
          (
            InventoryTransactionData,
            $$InventoryTransactionsTableTableReferences,
          ),
          InventoryTransactionData,
          PrefetchHooks Function({bool warehouseId, bool productId})
        > {
  $$InventoryTransactionsTableTableTableManager(
    _$AppDatabase db,
    $InventoryTransactionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryTransactionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InventoryTransactionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InventoryTransactionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> warehouseId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<String> referenceId = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryTransactionsTableCompanion(
                id: id,
                warehouseId: warehouseId,
                productId: productId,
                transactionType: transactionType,
                quantity: quantity,
                unitCost: unitCost,
                referenceType: referenceType,
                referenceId: referenceId,
                transactionDate: transactionDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String warehouseId,
                required String productId,
                required String transactionType,
                required double quantity,
                Value<double> unitCost = const Value.absent(),
                required String referenceType,
                required String referenceId,
                Value<DateTime> transactionDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryTransactionsTableCompanion.insert(
                id: id,
                warehouseId: warehouseId,
                productId: productId,
                transactionType: transactionType,
                quantity: quantity,
                unitCost: unitCost,
                referenceType: referenceType,
                referenceId: referenceId,
                transactionDate: transactionDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoryTransactionsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({warehouseId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (warehouseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.warehouseId,
                                referencedTable:
                                    $$InventoryTransactionsTableTableReferences
                                        ._warehouseIdTable(db),
                                referencedColumn:
                                    $$InventoryTransactionsTableTableReferences
                                        ._warehouseIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$InventoryTransactionsTableTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$InventoryTransactionsTableTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InventoryTransactionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryTransactionsTableTable,
      InventoryTransactionData,
      $$InventoryTransactionsTableTableFilterComposer,
      $$InventoryTransactionsTableTableOrderingComposer,
      $$InventoryTransactionsTableTableAnnotationComposer,
      $$InventoryTransactionsTableTableCreateCompanionBuilder,
      $$InventoryTransactionsTableTableUpdateCompanionBuilder,
      (InventoryTransactionData, $$InventoryTransactionsTableTableReferences),
      InventoryTransactionData,
      PrefetchHooks Function({bool warehouseId, bool productId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
  $$AccountsTableTableTableManager get accountsTable =>
      $$AccountsTableTableTableManager(_db, _db.accountsTable);
  $$SubscriptionsTableTableTableManager get subscriptionsTable =>
      $$SubscriptionsTableTableTableManager(_db, _db.subscriptionsTable);
  $$CustomersTableTableTableManager get customersTable =>
      $$CustomersTableTableTableManager(_db, _db.customersTable);
  $$SalesInvoicesTableTableTableManager get salesInvoicesTable =>
      $$SalesInvoicesTableTableTableManager(_db, _db.salesInvoicesTable);
  $$CurrenciesTableTableTableManager get currenciesTable =>
      $$CurrenciesTableTableTableManager(_db, _db.currenciesTable);
  $$FiscalYearsTableTableTableManager get fiscalYearsTable =>
      $$FiscalYearsTableTableTableManager(_db, _db.fiscalYearsTable);
  $$ChartOfAccountsTableTableTableManager get chartOfAccountsTable =>
      $$ChartOfAccountsTableTableTableManager(_db, _db.chartOfAccountsTable);
  $$JournalEntriesTableTableTableManager get journalEntriesTable =>
      $$JournalEntriesTableTableTableManager(_db, _db.journalEntriesTable);
  $$JournalEntryLinesTableTableTableManager get journalEntryLinesTable =>
      $$JournalEntryLinesTableTableTableManager(
        _db,
        _db.journalEntryLinesTable,
      );
  $$PartiesTableTableTableManager get partiesTable =>
      $$PartiesTableTableTableManager(_db, _db.partiesTable);
  $$PaymentMethodsTableTableTableManager get paymentMethodsTable =>
      $$PaymentMethodsTableTableTableManager(_db, _db.paymentMethodsTable);
  $$UnitsTableTableTableManager get unitsTable =>
      $$UnitsTableTableTableManager(_db, _db.unitsTable);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$ProductUnitsTableTableTableManager get productUnitsTable =>
      $$ProductUnitsTableTableTableManager(_db, _db.productUnitsTable);
  $$WarehousesTableTableTableManager get warehousesTable =>
      $$WarehousesTableTableTableManager(_db, _db.warehousesTable);
  $$InventoriesTableTableTableManager get inventoriesTable =>
      $$InventoriesTableTableTableManager(_db, _db.inventoriesTable);
  $$InventoryTransactionsTableTableTableManager
  get inventoryTransactionsTable =>
      $$InventoryTransactionsTableTableTableManager(
        _db,
        _db.inventoryTransactionsTable,
      );
}
