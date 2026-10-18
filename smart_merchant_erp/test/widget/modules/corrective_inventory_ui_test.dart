import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/enums/stock_count_status.dart';
import 'package:smart_merchant_erp/modules/inventory/application/services/stock_count_workflow.dart';
import 'package:smart_merchant_erp/modules/inventory/application/usecases/save_stock_count_usecase.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/providers/stock_counts_provider.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/views/stock_counts/widgets/stock_count_form_sheet.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/views/stock_counts/widgets/stock_count_settlement_dialog.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/views/stock_counts/stock_count_details_view.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/views/transfers/widgets/warehouse_transfer_dialog.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/widgets/count_quantity_row.dart';
import 'catalog_entry_test.dart' as fixture;

final candidates = [
  const StockCountCandidate(
    product: fixture.product,
    unit: fixture.baseUnit,
    unitName: 'حبة',
    quantity: 20,
    unitCost: 10,
  ),
  StockCountCandidate(
    product: fixture.product.copyWith(id: 'p2', productName: 'سكر'),
    unit: fixture.baseUnit.copyWith(id: 'pu2', productId: 'p2'),
    unitName: 'حبة',
    quantity: 10,
    unitCost: 20,
  ),
];

class CapturingCounts extends StockCountsNotifier {
  final List<SaveStockCountCommand> saved = [];
  Completer<void>? pending;
  bool fail = false;
  @override
  Stream<List<StockCount>> build() => Stream.value([]);
  @override
  Future<String> saveDraft(SaveStockCountCommand command) async {
    saved.add(command);
    if (pending != null) {
      await pending!.future;
    }
    if (fail) {
      throw const InventoryWorkflowException('تعذر الحفظ للاختبار');
    }
    return 'saved';
  }
}

StockCountDocument document({bool draft = true}) => StockCountDocument(
  count: StockCount(
    id: 'count',
    businessId: 'business',
    branchId: 'branch',
    warehouseId: 'warehouse',
    countNumber: 'SC-1',
    countDate: DateTime(2026, 10, 18),
    status: draft ? StockCountStatus.draft : StockCountStatus.posted,
    createdBy: 'user',
    financialStatus: 'Pending',
    financialJournalId: draft ? null : 'journal',
    syncStatus: 'synced',
    version: 1,
  ),
  items: const [
    StockCountItem(
      id: 'line',
      businessId: 'business',
      stockCountId: 'count',
      productId: 'product',
      productUnitId: 'pu',
      expectedQuantity: 20,
      countedQuantity: 15,
      differenceQuantity: -5,
      unitCost: 10,
      syncStatus: 'synced',
      version: 1,
    ),
  ],
  names: const {'product': 'حليب'},
  unitNames: const {'pu': 'حبة'},
  warehouseName: 'المستودع الرئيسي',
  currency: 'ر.ي',
);

class SettlementWorkflow implements StockCountWorkflow {
  String? selectedEmployee, selectedLoss;
  int calls = 0;
  @override
  Future<void> settle(
    String id, {
    String? lossAccountId,
    String? gainAccountId,
    String? employeeId,
  }) async {
    calls++;
    selectedEmployee = employeeId;
    selectedLoss = lossAccountId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget launch(WidgetBuilder dialog) => Builder(
  builder: (context) => Center(
    child: FilledButton(
      onPressed: () => showDialog<void>(context: context, builder: dialog),
      child: const Text('فتح'),
    ),
  ),
);

void main() {
  test(
    'Arabic fractional quantities are accepted and invalid numbers rejected',
    () {
      expect(parseCountQuantity('١٥٫٥'), 15.5);
      expect(parseCountQuantity('۰'), 0);
      expect(parseCountQuantity('-1'), isNull);
      expect(parseCountQuantity('NaN'), isNull);
      expect(parseCountQuantity('Infinity'), isNull);
    },
  );
  for (final size in [
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(390, 844),
    const Size(320, 740),
  ]) {
    testWidgets(
      'Corrective count dialog is centered and accepts explicit zero at $size',
      (tester) async {
        final notifier = CapturingCounts();
        await fixture.mount(
          tester,
          launch((_) => const StockCountFormSheet()),
          size: size,
          overrides: [
            stockCountsNotifierProvider.overrideWith(() => notifier),
            stockCountCandidatesProvider(
              'warehouse',
            ).overrideWith((ref) async => candidates),
          ],
        );
        await tester.tap(find.text('فتح'));
        await tester.pumpAndSettle();
        final rect = tester.getRect(find.byType(Dialog));
        expect(rect.center.dx, closeTo(size.width / 2, 1));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        await tester.ensureVisible(find.text('إضافة جميع المنتجات'));
        await tester.tap(find.text('إضافة جميع المنتجات'));
        await tester.pumpAndSettle();
        final input = find.byKey(const ValueKey('quantity_pu'));
        await tester.ensureVisible(input);
        await tester.enterText(input, '٠');
        await tester.pump();
        await tester.tap(find.text('حفظ ومراجعة'));
        await tester.pumpAndSettle();
        expect(notifier.saved, hasLength(1));
        expect(notifier.saved.single.items, hasLength(1));
        expect(notifier.saved.single.items.single.countedQuantity, 0);
        expect(notifier.saved.single.items.single.expectedQuantity, 20);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Failed save retains quantities; repeated tap cannot submit twice',
    (tester) async {
      final notifier = CapturingCounts()
        ..pending = Completer<void>()
        ..fail = true;
      await fixture.mount(
        tester,
        launch((_) => const StockCountFormSheet()),
        overrides: [
          stockCountsNotifierProvider.overrideWith(() => notifier),
          stockCountCandidatesProvider(
            'warehouse',
          ).overrideWith((ref) async => candidates),
        ],
      );
      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة جميع المنتجات'));
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('quantity_pu'));
      await tester.ensureVisible(input);
      await tester.enterText(input, '١٥٫٥');
      await tester.tap(find.text('حفظ ومراجعة'));
      await tester.pump();
      expect(notifier.saved, hasLength(1));
      expect(find.text('جارٍ الحفظ…'), findsOneWidget);
      notifier.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('تعذر الحفظ للاختبار'), findsOneWidget);
      expect(tester.widget<TextFormField>(input).initialValue, '١٥٫٥');
      notifier.pending = null;
      notifier.fail = false;
      await tester.tap(find.text('حفظ ومراجعة'));
      await tester.pumpAndSettle();
      expect(notifier.saved, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Tablet keyboard and large text leave count actions reachable', (
    tester,
  ) async {
    await fixture.mount(
      tester,
      launch((_) => StockCountFormSheet(document: document())),
      scale: 1.3,
      keyboard: 280,
      overrides: [
        stockCountCandidatesProvider(
          'warehouse',
        ).overrideWith((ref) async => candidates),
      ],
    );
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    expect(find.text('حفظ ومراجعة').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(1024, 768), const Size(320, 740)]) {
    testWidgets('Transfer dialog fits and validates before posting at $size', (
      tester,
    ) async {
      await fixture.mount(
        tester,
        launch((_) => const WarehouseTransferDialog()),
        size: size,
      );
      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد التحويل'));
      await tester.pumpAndSettle();
      expect(
        find.text('اختر مستودعين مختلفين وأضف المنتجات المراد تحويلها.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Posted count shows pending treatment and employee allocation uses selected employee',
    (tester) async {
      final workflow = SettlementWorkflow();
      await fixture.mount(
        tester,
        launch(
          (_) => StockCountSettlementDialog(document: document(draft: false)),
        ),
        size: const Size(390, 844),
        overrides: [
          stockCountWorkflowProvider.overrideWithValue(workflow),
          stockCountAccountsProvider.overrideWith((ref) async => []),
          stockCountEmployeesProvider.overrideWith(
            (ref) async => [
              Employee(
                id: 'employee',
                businessId: 'business',
                employeeCode: 'E',
                firstName: 'أحمد',
                lastName: 'علي',
                hireDate: DateTime(2026),
                salary: 0,
                currencyId: 'yer',
                status: 'Active',
                syncStatus: 'synced',
                version: 1,
              ),
            ],
          ),
        ],
      );
      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تحميل على موظف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الموظف المسؤول'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('أحمد علي').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد المعالجة المالية'));
      await tester.pumpAndSettle();
      expect(workflow.calls, 1);
      expect(workflow.selectedEmployee, 'employee');
      expect(workflow.selectedLoss, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Closing a dirty count asks before discarding quantities', (
    tester,
  ) async {
    final notifier = CapturingCounts();
    await fixture.mount(
      tester,
      launch((_) => const StockCountFormSheet()),
      overrides: [
        stockCountsNotifierProvider.overrideWith(() => notifier),
        stockCountCandidatesProvider(
          'warehouse',
        ).overrideWith((ref) async => candidates),
      ],
    );
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة جميع المنتجات'));
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('quantity_pu'));
    await tester.ensureVisible(input);
    await tester.enterText(input, '15');
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.text('تجاهل المدخلات غير المحفوظة؟'), findsOneWidget);
    await tester.tap(find.text('متابعة العمل'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(input).initialValue, '15');
    expect(notifier.saved, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('A thousand count lines remain lazy and scrollable', (
    tester,
  ) async {
    final many = List.generate(
      1000,
      (i) => StockCountCandidate(
        product: fixture.product.copyWith(id: 'p$i', productName: 'منتج $i'),
        unit: fixture.baseUnit.copyWith(id: 'u$i', productId: 'p$i'),
        unitName: 'حبة',
        quantity: 10,
        unitCost: 5,
      ),
    );
    await fixture.mount(
      tester,
      launch((_) => const StockCountFormSheet()),
      overrides: [
        stockCountsNotifierProvider.overrideWith(CapturingCounts.new),
        stockCountCandidatesProvider(
          'warehouse',
        ).overrideWith((ref) async => many),
      ],
    );
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة جميع المنتجات'));
    await tester.pumpAndSettle();
    expect(find.text('تم عدّ 0 من 1000 منتج'), findsOneWidget);
    expect(find.byType(TextFormField).evaluate().length, lessThan(15));
    expect(find.text('منتج 999'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Draft review requires explicit correction confirmation', (
    tester,
  ) async {
    await fixture.mount(
      tester,
      const StockCountDetailsView(countId: 'count'),
      overrides: [
        stockCountDocumentProvider(
          'count',
        ).overrideWith((ref) async => document()),
      ],
    );
    expect(
      find.text('مسودة للمراجعة. رصيد المخزون لم يتغير بعد.'),
      findsOneWidget,
    );
    await tester.tap(find.text('اعتماد وتصحيح المخزون'));
    await tester.pumpAndSettle();
    expect(find.text('تصحيح رصيد المخزون؟'), findsOneWidget);
    expect(find.textContaining('حساب معلّق'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
