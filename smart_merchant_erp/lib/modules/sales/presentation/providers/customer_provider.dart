import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';

final customersNotifierProvider = AutoDisposeStreamNotifierProvider<CustomersNotifier, List<Customer>>(() => CustomersNotifier());

class CustomersNotifier extends AutoDisposeStreamNotifier<List<Customer>> {
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

final customerBalanceProvider = FutureProvider.autoDispose.family<CustomerBalanceSummary?, String>((ref, customerId) => _customerBalance(ref, customerId));

Future<CustomerBalanceSummary?> _customerBalance(
  Ref ref,
  String customerId,
) async {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive) return null;

  final repo = ref.watch(salesRepositoryProvider);
  return repo.getCustomerBalanceSummary(customerId, session.businessId!);
}
