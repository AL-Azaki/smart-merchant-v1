import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/presentation/providers/accounting_provider.dart';
import 'package:smart_merchant_erp/modules/accounting/presentation/widgets/account_form_sheet.dart';
import 'package:smart_merchant_erp/modules/accounting/presentation/widgets/account_tree_model.dart';
import 'package:smart_merchant_erp/modules/accounting/presentation/widgets/chart_of_accounts_tab.dart';
import 'package:smart_merchant_erp/shared/design_system/theme/app_theme.dart';
import 'package:smart_merchant_erp/shared/design_system/widgets/app_text_field.dart';

ChartOfAccount account(
  String id,
  String code,
  String name, {
  String? parent,
  bool posting = false,
  int type = 1,
  String balance = 'Debit',
  bool active = true,
}) => ChartOfAccount(
  id: id,
  businessId: 'business',
  accountCode: code,
  accountName: name,
  parentAccountId: parent,
  accountTypeId: type,
  normalBalance: balance,
  accountLevel: parent == null ? 1 : 2,
  allowPosting: posting,
  isSystem: false,
  isActive: active,
  syncStatus: 'synced',
  version: 1,
);
final accounts = [
  account('1', '1', 'الأصول (Assets)'),
  account('11', '11', 'الأصول المتداولة', parent: '1'),
  account('111', '111', 'النقدية', parent: '11'),
  account('11101', '11101', 'الصندوق الرئيسي', parent: '111', posting: true),
  account('5', '5', 'المصروفات (Expenses)', type: 5),
  account('52', '52', 'المصروفات التشغيلية', type: 5, parent: '5'),
  account(
    '52001',
    '52001',
    'مصاريف التوصيل',
    type: 5,
    parent: '52',
    posting: true,
  ),
];

class Accounts extends ChartOfAccountsNotifier {
  @override
  Stream<List<ChartOfAccount>> build() => Stream.value(accounts);
}

Future<void> mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1024, 768),
  bool dark = false,
  double scale = 1,
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [chartOfAccountsNotifierProvider.overrideWith(Accounts.new)],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder nameField() => find.descendant(
  of: find.widgetWithText(AppTextField, 'اسم الحساب *'),
  matching: find.byType(TextFormField),
);
Widget form(Future<void> Function(Map<String, dynamic>) save) => Dialog(
  backgroundColor: Colors.transparent,
  child: AccountFormSheet(
    parentAccounts: accounts,
    initialParentId: '11',
    onClose: () {},
    onSave: save,
  ),
);

void main() {
  test('Search preserves the account path and never duplicates rows', () {
    final entries = AccountTreeModel(accounts).entries(query: 'التوصيل');
    expect(entries.map((e) => e.account.id), ['5', '52', '52001']);
    expect(entries.map((e) => e.depth), [0, 1, 2]);
    expect(
      AccountTreeModel(accounts).entries(typeId: 1).map((e) => e.account.id),
      ['1', '11', '111', '11101'],
    );
  });
  test(
    'Cycles and orphan parents stay discoverable without endless recursion',
    () {
      final model = AccountTreeModel([
        account('a', '11', 'الأول', parent: 'b'),
        account('b', '12', 'الثاني', parent: 'a'),
        account('c', '13', 'الثالث', parent: 'missing'),
      ]);
      expect(model.entries(), hasLength(3));
      expect(model.hierarchyIssueCount, 3);
    },
  );
  test('Only real active grouping accounts are offered as parents', () {
    final model = AccountTreeModel([
      ...accounts,
      account('disabled', '60', 'متوقف', active: false),
      account('coa-cash', '1001', 'Cash in Hand'),
    ]);
    expect(model.parentOptions.map((e) => e.account.id), [
      '1',
      '11',
      '111',
      '5',
      '52',
    ]);
    expect(model.parentOptions.map((e) => e.depth), [0, 1, 2, 0, 1]);
  });

  for (final size in [
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(390, 844),
  ]) {
    testWidgets('Arabic tree and centered add form fit $size', (tester) async {
      await mount(tester, const ChartOfAccountsTab(), size: size);
      expect(tester.takeException(), isNull);
      expect(find.text('الأصول (Assets)'), findsNothing);
      expect(find.text('الأصول'), findsOneWidget);
      await tester.tap(find.byTooltip('توسيع الكل'));
      await tester.pumpAndSettle();
      expect(find.text('الصندوق الرئيسي'), findsOneWidget);
      await tester.tap(find.byTooltip('طي الكل'));
      await tester.pumpAndSettle();
      expect(find.text('الصندوق الرئيسي'), findsNothing);
      expect(find.text('الأصول المتداولة'), findsNothing);
      await tester.enterText(find.byType(TextField), 'التوصيل');
      await tester.pumpAndSettle();
      expect(find.text('مصاريف التوصيل'), findsOneWidget);
      expect(find.text('المصروفات التشغيلية'), findsOneWidget);
      await tester.tap(find.text('إضافة حساب'));
      await tester.pumpAndSettle();
      expect(find.text('حفظ الحساب'), findsOneWidget);
      expect(find.text('رمز الحساب *'), findsNothing);
      expect(find.text('نوع الحساب'), findsNothing);
      expect(find.text('الرصيد الطبيعي'), findsNothing);
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(RegExp('[A-Za-z]').hasMatch(texts), isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Name is beside parent and dropdown shows the actual hierarchy', (
    tester,
  ) async {
    await mount(tester, form((_) async {}));
    final name = tester.getRect(nameField());
    final parent = tester.getRect(find.byType(DropdownButtonFormField<String>));
    expect((name.center.dy - parent.center.dy).abs(), lessThan(5));
    expect(name.center.dx, greaterThan(parent.center.dx));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('الأصول'), findsWidgets);
    expect(find.text('النقدية'), findsWidgets);
    expect(find.text('الصندوق الرئيسي'), findsNothing);
    expect(find.byIcon(Icons.subdirectory_arrow_left_rounded), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Save awaits persistence, blocks duplicate submissions and retains a failed entry',
    (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      Map<String, dynamic>? data;
      await mount(
        tester,
        form((value) async {
          calls++;
          data = value;
          await pending.future;
        }),
      );
      await tester.enterText(nameField(), 'مصاريف شحن');
      await tester.tap(find.text('حفظ الحساب'));
      await tester.pump();
      expect(calls, 1);
      expect(data!['parentId'], '11');
      expect(data!.containsKey('code'), isFalse);
      expect(data!.containsKey('type'), isFalse);
      expect(data!.containsKey('normalBalance'), isFalse);
      pending.completeError(
        const AccountFormSaveException('تعذر حفظ الحساب، حاول مرة أخرى.'),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(nameField()).controller!.text,
        'مصاريف شحن',
      );
      expect(find.text('تعذر حفظ الحساب، حاول مرة أخرى.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Dark tablet with large text keeps save visible above keyboard', (
    tester,
  ) async {
    await mount(
      tester,
      form((_) async {}),
      dark: true,
      scale: 1.3,
      keyboard: 300,
    );
    expect(find.text('حفظ الحساب').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
