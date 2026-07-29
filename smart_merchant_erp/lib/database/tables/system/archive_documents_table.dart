import 'package:drift/drift.dart';

/// Drift table definition for `archive_documents`.
///
/// Purpose: Standalone document archiving (invoices, contracts, licenses, etc.).
/// Domain: DOMAIN 10 — System Administration & Archive
@DataClassName('ArchiveDocument')
class ArchiveDocuments extends Table {
  @override
  String get tableName => 'archive_documents';

  TextColumn get id => text()();
  
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint('NOT NULL REFERENCES businesses(id) ON DELETE CASCADE')();
  
  TextColumn get title => text().named('title')();
  TextColumn get category => text().named('category')();
  TextColumn get refNumber => text().named('ref_number').nullable()();
  DateTimeColumn get issueDate => dateTime().named('issue_date')();
  DateTimeColumn get expiryDate => dateTime().named('expiry_date').nullable()();
  TextColumn get fileUrl => text().named('file_url')();
  TextColumn get notes => text().named('notes').nullable()();
  
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  // Sync Metadata
  TextColumn get syncStatus => text().named('sync_status').withDefault(const Constant('pending'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
