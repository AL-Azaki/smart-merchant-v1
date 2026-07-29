import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/injection.dart';
import '../../../../database/daos/system_dao.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../system/application/services/archive_document_service.dart';

part 'archive_provider.g.dart';

@riverpod
class ArchiveFilterState extends _$ArchiveFilterState {
  @override
  ArchiveDocumentFilter build() {
    return const ArchiveDocumentFilter(businessId: '');
  }

  void updateFilter({
    String? category,
    String? searchQuery,
    bool? isExpired,
  }) {
    state = ArchiveDocumentFilter(
      businessId: state.businessId,
      category: category ?? state.category,
      searchQuery: searchQuery ?? state.searchQuery,
      isExpired: isExpired ?? state.isExpired,
    );
  }

  void setBusinessId(String businessId) {
    if (state.businessId == businessId) return;
    state = ArchiveDocumentFilter(
      businessId: businessId,
      category: state.category,
      searchQuery: state.searchQuery,
      isExpired: state.isExpired,
    );
  }
}

@riverpod
Stream<List<ArchiveDocument>> archiveDocuments(ArchiveDocumentsRef ref) {
  final filter = ref.watch(archiveFilterStateProvider);
  if (filter.businessId.isEmpty) {
    return Stream.value([]);
  }
  final service = getIt<ArchiveDocumentService>();
  return service.watchDocuments(filter);
}

@riverpod
class ArchiveStats extends _$ArchiveStats {
  @override
  Map<String, int> build() {
    final docs = ref.watch(archiveDocumentsProvider).valueOrNull ?? [];
    int total = docs.length;
    int invoices = docs.where((d) => d.category == 'invoice').length;
    int nearExpiry = docs.where((d) {
      if (d.expiryDate == null) return false;
      final diff = d.expiryDate!.difference(DateTime.now()).inDays;
      return diff > 0 && diff <= 30;
    }).length;
    return {'total': total, 'invoices': invoices, 'nearExpiry': nearExpiry};
  }
}
