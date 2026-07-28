import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';
import 'package:smart_merchant_erp/modules/crm/presentation/views/contacts_view.dart';
import 'package:smart_merchant_erp/modules/crm/presentation/views/suppliers_list_view.dart';
import 'package:smart_merchant_erp/modules/crm/presentation/views/customers_list_view.dart';
import 'package:smart_merchant_erp/shared/design_system/theme/app_theme.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart' show Customer, Supplier;
import 'package:smart_merchant_erp/modules/sales/presentation/providers/customer_provider.dart';
import 'package:smart_merchant_erp/modules/purchasing/presentation/providers/purchasing_provider.dart';

class MockCustomersNotifier extends AutoDisposeStreamNotifier<List<Customer>> implements CustomersNotifier {
  @override
  Stream<List<Customer>> build() => Stream.value([]);
}

class MockSuppliersNotifier extends AutoDisposeStreamNotifier<List<Supplier>> implements SuppliersNotifier {
  @override
  Stream<List<Supplier>> build() => Stream.value([]);
}

void main() {
  testWidgets('ContactsView tab switching regression test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customersNotifierProvider.overrideWith(() => MockCustomersNotifier()),
          suppliersNotifierProvider.overrideWith(() => MockSuppliersNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          locale: const Locale('ar'),
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ContactsView(),
          ),
        ),
      ),
    );

    // Initial render might take some time to resolve providers, so we settle
    await tester.pumpAndSettle();
    
    // Ensure no exceptions occurred during initial build (Customers tab is default)
    expect(tester.takeException(), isNull);

    // Verify Customers tab is currently showing
    expect(find.byType(CustomersListView), findsOneWidget);

    // 2. Tap on Suppliers Tab
    final suppliersTab = find.text('الموردين');
    expect(suppliersTab, findsOneWidget);
    await tester.tap(suppliersTab);
    
    // Allow the tab transition to settle
    await tester.pumpAndSettle();

    // Ensure no exceptions occurred during switch to Suppliers tab
    expect(tester.takeException(), isNull);

    // Verify Suppliers tab is now showing
    expect(find.byType(SuppliersListView), findsOneWidget);
    
    // 3. Switch back and forth multiple times
    final customersTab = find.text('العملاء');
    
    // -> Customers
    await tester.tap(customersTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    
    // -> Suppliers
    await tester.tap(suppliersTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    
    // -> Customers
    await tester.tap(customersTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    
    // -> Suppliers
    await tester.tap(suppliersTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
