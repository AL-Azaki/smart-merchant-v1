import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/modules/authentication/presentation/providers/session_provider.dart';

void main() {
  late ProviderContainer container;
  late SessionHolder holder;

  setUp(() {
    GetIt.I.reset();
    holder = SessionHolder();
    GetIt.I.registerSingleton<SessionHolder>(holder);
    GetIt.I.registerSingleton<ApplicationContext>(
      RuntimeApplicationContext(holder),
    );
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'Session A sets context and RuntimeApplicationContext resolves it correctly',
    () {
      final notifier = container.read(sessionNotifierProvider.notifier);

      // Initial state
      expect(container.read(sessionNotifierProvider).isActive, isFalse);
      expect(holder.isActive, isFalse);

      // Set Session A
      notifier.setSession(
        businessId: 'BUS_A',
        branchId: 'BRANCH_A',
        userId: 'USER_A',
      );

      // Verify Riverpod State
      final state = container.read(sessionNotifierProvider);
      expect(state.isActive, isTrue);
      expect(state.businessId, 'BUS_A');
      expect(state.branchId, 'BRANCH_A');
      expect(state.userId, 'USER_A');

      // Verify ApplicationContext via GetIt
      final appContext = GetIt.I<ApplicationContext>();
      expect(appContext.currentBusinessId, 'BUS_A');
      expect(appContext.currentBranchId, 'BRANCH_A');
      expect(appContext.currentUserId, 'USER_A');
    },
  );

  test(
    'Switching branch updates both Riverpod and GetIt context immediately',
    () {
      final notifier = container.read(sessionNotifierProvider.notifier);

      // Set initial session
      notifier.setSession(
        businessId: 'BUS_A',
        branchId: 'BRANCH_A',
        userId: 'USER_A',
      );

      // Switch branch
      notifier.switchBranch('BRANCH_B');

      final state = container.read(sessionNotifierProvider);
      expect(state.branchId, 'BRANCH_B');

      final appContext = GetIt.I<ApplicationContext>();
      expect(appContext.currentBranchId, 'BRANCH_B');
    },
  );

  test(
    'Switching business clears branch and updates both Riverpod and GetIt context',
    () {
      final notifier = container.read(sessionNotifierProvider.notifier);

      notifier.setSession(
        businessId: 'BUS_A',
        branchId: 'BRANCH_A',
        userId: 'USER_A',
      );

      notifier.switchBusiness(
        newBusinessId: 'BUS_B',
      ); // Intentionally no branch

      final state = container.read(sessionNotifierProvider);
      expect(state.businessId, 'BUS_B');
      expect(state.branchId, isNull);

      final appContext = GetIt.I<ApplicationContext>();
      expect(appContext.currentBusinessId, 'BUS_B');
      expect(appContext.currentBranchId, isNull);
    },
  );

  test('Clearing session removes context everywhere', () {
    final notifier = container.read(sessionNotifierProvider.notifier);

    notifier.setSession(
      businessId: 'BUS_A',
      branchId: 'BRANCH_A',
      userId: 'USER_A',
    );
    notifier.clearSession();

    final state = container.read(sessionNotifierProvider);
    expect(state.isActive, isFalse);

    final appContext = GetIt.I<ApplicationContext>();
    expect(() => appContext.currentBusinessId, throwsStateError);
  });
}
