import '../../../authentication/presentation/providers/session_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../application/services/stock_count_workflow.dart';
import '../../application/usecases/save_stock_count_usecase.dart';

final stockCountWorkflowProvider = Provider<StockCountWorkflow>((ref) {
  ref.watch(sessionNotifierProvider);
  return getIt<StockCountWorkflow>();
});
final stockCountCandidatesProvider = FutureProvider.autoDispose
    .family<List<StockCountCandidate>, String>(
      (ref, id) => ref.watch(stockCountWorkflowProvider).candidates(id),
    );
final stockCountDocumentProvider = FutureProvider.autoDispose
    .family<StockCountDocument, String>(
      (ref, id) => ref.watch(stockCountWorkflowProvider).load(id),
    );
final stockCountAccountsProvider =
    FutureProvider.autoDispose<List<ChartOfAccount>>((ref) {
      final workflow = ref.watch(stockCountWorkflowProvider);
      return (workflow.db.select(workflow.db.chartOfAccounts)..where(
            (a) =>
                a.businessId.equals(workflow.businessId) &
                a.isActive.equals(true) &
                a.allowPosting.equals(true),
          ))
          .get();
    });
final stockCountEmployeesProvider = FutureProvider.autoDispose<List<Employee>>((
  ref,
) {
  final workflow = ref.watch(stockCountWorkflowProvider);
  return (workflow.db.select(workflow.db.employees)..where(
        (e) =>
            e.businessId.equals(workflow.businessId) &
            e.status.equals('Active') &
            e.deletedAt.isNull(),
      ))
      .get();
});
final stockCountsNotifierProvider =
    AutoDisposeStreamNotifierProvider<StockCountsNotifier, List<StockCount>>(
      StockCountsNotifier.new,
    );

class StockCountsNotifier extends AutoDisposeStreamNotifier<List<StockCount>> {
  @override
  Stream<List<StockCount>> build() =>
      ref.watch(stockCountWorkflowProvider).watchCounts();
  Future<void> refreshCounts() async {
    ref.invalidateSelf();
  }

  Future<String> saveDraft(SaveStockCountCommand command) async {
    final id = await ref.read(stockCountWorkflowProvider).save(command);
    ref.invalidate(stockCountDocumentProvider(id));
    return id;
  }

  Future<void> postCount(String id) async {
    await ref.read(stockCountWorkflowProvider).correct(id);
    ref.invalidate(stockCountDocumentProvider(id));
  }
}
