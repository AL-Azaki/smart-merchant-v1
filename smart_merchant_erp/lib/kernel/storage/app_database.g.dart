// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomersTableTable customersTable = $CustomersTableTable(this);
  late final $SalesInvoicesTableTable salesInvoicesTable =
      $SalesInvoicesTableTable(this);
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final $AccountsTableTable accountsTable = $AccountsTableTable(this);
  late final $SubscriptionsTableTable subscriptionsTable =
      $SubscriptionsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customersTable,
    salesInvoicesTable,
    usersTable,
    accountsTable,
    subscriptionsTable,
  ];
}

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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomersTableTableTableManager get customersTable =>
      $$CustomersTableTableTableManager(_db, _db.customersTable);
  $$SalesInvoicesTableTableTableManager get salesInvoicesTable =>
      $$SalesInvoicesTableTableTableManager(_db, _db.salesInvoicesTable);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
  $$AccountsTableTableTableManager get accountsTable =>
      $$AccountsTableTableTableManager(_db, _db.accountsTable);
  $$SubscriptionsTableTableTableManager get subscriptionsTable =>
      $$SubscriptionsTableTableTableManager(_db, _db.subscriptionsTable);
}
