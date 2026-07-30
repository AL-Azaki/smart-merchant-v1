import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/getit_instance.dart';
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
        fileName: data['document_name']?.toString() ?? 'Doc',
        documentType: data['document_type']?.toString(),
        entityType: data['reference_type']?.toString() ?? 'Unknown',
        entityId: data['reference_id']?.toString() ?? 'Unknown',
        remoteUrl: data['file_url']?.toString(),
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
