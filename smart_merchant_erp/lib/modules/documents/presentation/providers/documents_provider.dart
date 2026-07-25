import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/injection.dart';
import '../../../system/application/services/document_application_service.dart';

part 'documents_provider.g.dart';

@riverpod
class DocumentsNotifier extends _$DocumentsNotifier {
  @override
  void build() {
    return;
  }

  Future<bool> saveDocument(Map<String, dynamic> data) async {
    try {
      final service = getIt<DocumentApplicationService>();
      final command = AttachmentCommand(
        fileName: data['document_name'] ?? 'Doc',
        documentType: data['document_type'],
        entityType: data['reference_type'] ?? 'Unknown',
        entityId: data['reference_id'] ?? 'Unknown',
        remoteUrl: data['file_url'],
        fileType: 'pdf',
        fileSize: 0,
      );
      final result = await service.saveAttachment(command);
      return result.isRight();
    } catch (e) {
      return false;
    }
  }
}
