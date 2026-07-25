import 'package:drift/drift.dart';

/// Drift table definition for `employees`.
///
/// Purpose: Employee personnel records linked optionally to a system user account and department.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS (Human Resources)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as employee master records, salary rates, and statuses are managed locally in SQLite (Source of Truth) and synced to the cloud.
@DataClassName('Employee')
class Employees extends Table {
  @override
  String get tableName => 'employees';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Optional Foreign Key linking to system user account `users.id` (SET NULL).
  TextColumn get userId => text()
      .named('user_id')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

  /// Unique internal identifier code for the employee (`string(50)`).
  TextColumn get employeeCode => text().named('employee_code')();

  /// Employee first name (`string(100)`).
  TextColumn get firstName => text().named('first_name')();

  /// Employee last name (`string(100)`).
  TextColumn get lastName => text().named('last_name')();

  /// Employee contact email (`string(255)`, nullable).
  TextColumn get email => text().nullable()();

  /// Employee contact phone number (`string(30)`, nullable).
  TextColumn get phone => text().nullable()();

  /// Date of hire (`date`).
  DateTimeColumn get hireDate => dateTime().named('hire_date')();

  /// Date of termination (`date`, nullable, check `>= hire_date`).
  DateTimeColumn get terminationDate =>
      dateTime().named('termination_date').nullable()();

  /// Composite Foreign Key linking to assigned `departments(business_id, id)` (SET NULL, nullable).
  TextColumn get departmentId => text().named('department_id').nullable()();

  /// Composite Foreign Key linking to assigned `job_titles(business_id, id)` (SET NULL, nullable).
  TextColumn get jobTitleId => text().named('job_title_id').nullable()();

  /// Base salary amount (`decimal(18,2)`, default `0.00`, check `>= 0`).
  RealColumn get salary => real().withDefault(const Constant(0.00))();

  /// Foreign Key linking to operating currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Operational employment status (`Active`, `Terminated`, `OnLeave`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Active'))();

  /// Record creation timestamp (`timestamp`).
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp (`timestamp`).
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  /// Soft delete timestamp (`deleted_at`).
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the employee record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, employeeCode},
    {businessId, userId},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, department_id) REFERENCES departments(business_id, id) ON DELETE SET NULL',
    'FOREIGN KEY (business_id, job_title_id) REFERENCES job_titles(business_id, id) ON DELETE SET NULL',
    'CHECK (termination_date >= hire_date)',
    'CHECK (salary >= 0)',
    'CHECK (status IN (\'Active\', \'Terminated\', \'OnLeave\'))',
  ];
}
