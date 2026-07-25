import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart' hide Unit;
import '../../domain/repositories/system_repository.dart';

class AttachmentCommand {
  final String entityType;
  final String entityId;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String? localPath;
  final String? remoteUrl;
  final String? documentType;

  const AttachmentCommand({
    required this.entityType,
    required this.entityId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.localPath,
    this.remoteUrl,
    this.documentType,
  });
}

@injectable
class DocumentApplicationService {
  final SystemRepository _systemRepository;
  final ApplicationContext _context;
  final Uuid _uuid = const Uuid();

  DocumentApplicationService(this._systemRepository, this._context);

  Future<Either<Failure, String>> saveAttachment(AttachmentCommand command) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      final attachmentId = _uuid.v4();

      final companion = AttachmentsCompanion(
        id: drift.Value(attachmentId),
        businessId: drift.Value(businessId),
        entityType: drift.Value(command.entityType),
        entityId: drift.Value(command.entityId),
        fileName: drift.Value(command.fileName),
        filePath: drift.Value(command.localPath ?? command.remoteUrl ?? ''),
        syncStatus: const drift.Value('pending'),
      );

      await _systemRepository.insertAttachment(companion);
      return Right(attachmentId);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> deleteAttachment(String id) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      await _systemRepository.deleteAttachment(id, businessId);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
