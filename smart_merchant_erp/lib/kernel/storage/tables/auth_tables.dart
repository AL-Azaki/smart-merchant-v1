import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('UserAccount')
class UsersTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get email => text().withLength(min: 5, max: 255).unique()();
  TextColumn get passwordHash => text()(); // In offline-first, store a salted hash
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BusinessAccount')
class AccountsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get ownerId => text().references(UsersTable, #id)();
  TextColumn get businessName => text()();
  TextColumn get businessType => text()();
  TextColumn get defaultCurrency => text()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SubscriptionData')
class SubscriptionsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get accountId => text().references(AccountsTable, #id)();
  TextColumn get status => text()(); // active, pending, expired, trial
  TextColumn get planId => text()();
  
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
