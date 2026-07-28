import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/storage/app_database.dart' show Customer;
import '../../../../database/daos/sales_dao.dart' show CustomerFilter, CustomerBalanceSummary;
import '../../../authentication/presentation/providers/session_provider.dart';

part 'customer_provider.g.dart';

@riverpod
class CustomersNotifier extends _$CustomersNotifier {
  @override
  Stream<List<Customer>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) return const Stream.empty();

    final repo = ref.watch(salesRepositoryProvider);

    // Watch active, non-deleted customers for this business
    return repo.watchCustomers(
      CustomerFilter(businessId: session.businessId!, isActive: true),
    );
  }
}

@riverpod
Future<CustomerBalanceSummary?> customerBalance(CustomerBalanceRef ref, String customerId) async {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive) return null;

  final repo = ref.watch(salesRepositoryProvider);
  return repo.getCustomerBalanceSummary(customerId, session.businessId!);
}
