import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../../../kernel/storage/app_database.dart' show SalesInvoice;
import '../../../../database/daos/sales_dao.dart' show SalesInvoiceFilter;
import '../../../authentication/presentation/providers/session_provider.dart';

part 'sales_provider.g.dart';

@riverpod
class SalesInvoicesNotifier extends _$SalesInvoicesNotifier {
  @override
  Stream<List<SalesInvoice>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) return const Stream.empty();

    final repo = ref.watch(salesRepositoryProvider);

    // Watch all sales invoices for this business (descending order typically handled by DAO)
    return repo.watchInvoices(
      SalesInvoiceFilter(businessId: session.businessId!),
    );
  }
}
