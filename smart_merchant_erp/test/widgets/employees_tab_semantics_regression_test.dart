import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/modules/hr/presentation/views/employees_view.dart';
import 'package:smart_merchant_erp/modules/crm/presentation/views/customers_list_view.dart';
import 'package:smart_merchant_erp/modules/crm/presentation/views/suppliers_list_view.dart';
import 'package:smart_merchant_erp/modules/hr/presentation/providers/hr_provider.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/providers/customer_provider.dart';
import 'package:smart_merchant_erp/modules/purchasing/presentation/providers/purchasing_provider.dart';
import 'package:smart_merchant_erp/modules/hr/presentation/views/widgets/employee_form_sheet.dart';
import 'package:smart_merchant_erp/modules/hr/presentation/views/widgets/employee_detail_screen.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';

class _MockCustomersNotifier extends CustomersNotifier {
  @override
  Stream<List<Customer>> build() => Stream.value([]);
}

class _MockSuppliersNotifier extends SuppliersNotifier {
  @override
  Stream<List<Supplier>> build() => Stream.value([]);
}

void main() {
  testWidgets('Employees Tab semantics and lifecycle regression test', (WidgetTester tester) async {
    // 1. Setup a simple Tabbed app imitating the Inventory Module.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeesListProvider.overrideWith((ref) => Stream.value([])),
          customersNotifierProvider.overrideWith(() => _MockCustomersNotifier()),
          suppliersNotifierProvider.overrideWith(() => _MockSuppliersNotifier()),
        ],
        child: MaterialApp(
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Customers'),
                    Tab(text: 'Suppliers'),
                    Tab(text: 'Employees'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  CustomersListView(),
                  SuppliersListView(),
                  EmployeesView(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // 2. Switch tabs repeatedly to expose mounting/unmounting issues.
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Employees'));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Customers'));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('Suppliers'));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Employees'));
      await tester.pump(const Duration(seconds: 1));
    }

    // 3. Open Add Employee Form
    final addEmployeeBtn = find.text('إضافة موظف');
    if (addEmployeeBtn.evaluate().isNotEmpty) {
      await tester.tap(addEmployeeBtn);
      await tester.pump(const Duration(seconds: 1));

      // Ensure form is displayed
      expect(find.byType(EmployeeFormSheet), findsOneWidget);

      // Close it (Cancel)
      await tester.tap(find.text('إلغاء'));
      await tester.pump(const Duration(seconds: 1));

      // Ensure form is closed
      expect(find.byType(EmployeeFormSheet), findsNothing);

      // Open it again
      await tester.tap(addEmployeeBtn);
      await tester.pump(const Duration(seconds: 1));

      // Save it
      await tester.tap(find.text('حفظ الموظف'));
      await tester.pump(const Duration(seconds: 1));
    }

    // 4. Assert NO exceptions were thrown during this aggressive lifecycle test
    final dynamic exception = tester.takeException();
    expect(exception, isNull, reason: 'Flutter framework threw an exception during Employees lifecycle test: $exception');
  });
}
