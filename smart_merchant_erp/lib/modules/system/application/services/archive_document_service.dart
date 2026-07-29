import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart' hide Unit;
import '../../../../database/daos/system_dao.dart';
import '../../domain/repositories/system_repository.dart';

class ArchiveDocumentCommand {
  final String title;
  final String category;
  final String? refNumber;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String fileUrl;
  final String? notes;

  const ArchiveDocumentCommand({
    required this.title,
    required this.category,
    this.refNumber,
    required this.issueDate,
    this.expiryDate,
    required this.fileUrl,
    this.notes,
  });
}

@injectable
class ArchiveDocumentService {
  final SystemRepository _repository;
  final ApplicationContext _context;
  final Uuid _uuid = const Uuid();

  ArchiveDocumentService(this._repository, this._context);

  Future<Either<Failure, String>> saveDocument(ArchiveDocumentCommand command) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      final docId = _uuid.v4();

      final companion = ArchiveDocumentsCompanion(
        id: drift.Value(docId),
        businessId: drift.Value(businessId),
        title: drift.Value(command.title),
        category: drift.Value(command.category),
        refNumber: drift.Value(command.refNumber),
        issueDate: drift.Value(command.issueDate),
        expiryDate: drift.Value(command.expiryDate),
        fileUrl: drift.Value(command.fileUrl),
        notes: drift.Value(command.notes),
        syncStatus: const drift.Value('pending'),
      );

      await _repository.insertArchiveDocument(companion);
      return Right(docId);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> deleteDocument(String id) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      await _repository.deleteArchiveDocument(id, businessId);
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Stream<List<ArchiveDocument>> watchDocuments(ArchiveDocumentFilter filter) {
    return _repository.watchArchiveDocuments(filter);
  }
}
