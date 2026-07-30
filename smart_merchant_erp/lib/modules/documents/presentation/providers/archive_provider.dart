import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../database/daos/system_dao.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../system/application/services/archive_document_service.dart';

final archiveFilterStateProvider = AutoDisposeNotifierProvider<ArchiveFilterState, ArchiveDocumentFilter>(() => ArchiveFilterState());

class ArchiveFilterState extends AutoDisposeNotifier<ArchiveDocumentFilter> {
  @override
  ArchiveDocumentFilter build() {
    return const ArchiveDocumentFilter(businessId: '');
  }

  void updateFilter({String? category, String? searchQuery, bool? isExpired}) {
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

final archiveDocumentsProvider = StreamProvider.autoDispose<List<ArchiveDocument>>((ref) => _archiveDocuments(ref));

Stream<List<ArchiveDocument>> _archiveDocuments(Ref ref)  {
  final filter = ref.watch(archiveFilterStateProvider);
  if (filter.businessId.isEmpty) {
    return Stream.value([]);
  }
  final service = getIt<ArchiveDocumentService>();
  return service.watchDocuments(filter);
}

final archiveStatsProvider = AutoDisposeNotifierProvider<ArchiveStats, Map<String, int>>(() => ArchiveStats());

class ArchiveStats extends AutoDisposeNotifier<Map<String, int>> {
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
