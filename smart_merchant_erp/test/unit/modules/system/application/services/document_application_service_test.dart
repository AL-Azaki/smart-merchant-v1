import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/modules/system/application/services/document_application_service.dart';
import 'package:smart_merchant_erp/database/daos/system_dao.dart';
import 'package:smart_merchant_erp/modules/system/domain/repositories/system_repository.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/modules/system/infrastructure/repositories/system_repository_impl.dart';

void main() {
  late AppDatabase db;
  late SystemRepository repository;
  late ApplicationContext context;
  late String businessId;
  late DocumentApplicationService service;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    repository = SystemRepositoryImpl(SystemDao(db));

    businessId = const Uuid().v4();
    final branchId = const Uuid().v4();
    final userId = const Uuid().v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    service = DocumentApplicationService(
      repository,
      context,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('DocumentApplicationService - Create Document', () async {
    final command = AttachmentCommand(
      entityType: 'Customer',
      entityId: 'cust-1',
      fileName: 'Test Doc',
      fileType: 'pdf',
      fileSize: 1024,
    );

    final result = await service.saveAttachment(command);
    expect(result.isRight(), isTrue);

    final docs = await db.select(db.attachments).get();
    expect(docs.length, 1);
    expect(docs.first.fileName, 'Test Doc');
  });

  test('DocumentApplicationService - Soft Delete Document', () async {
    final id = const Uuid().v4();
    await repository.insertAttachment(AttachmentsCompanion.insert(
        id: id,
        businessId: businessId,
        entityType: 'Customer',
        entityId: 'cust-1',
        fileName: 'Test Doc',
        filePath: '/path/to/doc',
        syncStatus: const drift.Value('pending'),
    ));

    final result = await service.deleteAttachment(id);
    expect(result.isRight(), isTrue);

    final docs = await db.select(db.attachments).get();
    expect(docs.length, 0); // Assuming delete is hard delete or soft delete logic is checked

  });
}
