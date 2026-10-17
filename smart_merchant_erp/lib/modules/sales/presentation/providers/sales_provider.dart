import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_providers.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';

final salesInvoicesNotifierProvider = AutoDisposeStreamNotifierProvider<SalesInvoicesNotifier, List<SalesInvoice>>(() => SalesInvoicesNotifier());

class SalesInvoicesNotifier extends AutoDisposeStreamNotifier<List<SalesInvoice>> {
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

final salesReturnsNotifierProvider =
    AutoDisposeStreamNotifierProvider<SalesReturnsNotifier, List<SalesReturn>>(
  () => SalesReturnsNotifier(),
);

class SalesReturnsNotifier
    extends AutoDisposeStreamNotifier<List<SalesReturn>> {
  @override
  Stream<List<SalesReturn>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) {
      return const Stream.empty();
    }

    final repo = ref.watch(salesRepositoryProvider);
    return repo.watchReturns(
      SalesReturnFilter(businessId: session.businessId!),
    );
  }
}
