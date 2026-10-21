import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_merchant_erp/kernel/error/failures.dart';
import 'package:smart_merchant_erp/modules/settings/domain/entities/storefront_settings.dart';
import 'package:smart_merchant_erp/modules/settings/domain/repositories/storefront_repository.dart';
import 'package:smart_merchant_erp/modules/settings/presentation/providers/storefront_settings_provider.dart';
import 'package:smart_merchant_erp/modules/settings/presentation/views/settings_control_center_view.dart';
import 'package:smart_merchant_erp/modules/settings/presentation/views/storefront_settings_view.dart';

class MockStorefrontRepository extends Mock implements StorefrontRepository {}

void main() {
  late MockStorefrontRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const StorefrontSettings(storefrontActive: false));
  });

  setUp(() {
    mockRepository = MockStorefrontRepository();
  });

  Widget buildTestableWidget(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );
  }

  group('StorefrontSettingsView - Widget Tests', () {
    testWidgets('renders loading state initially', (tester) async {
      final completer = Completer<Either<Failure, StorefrontSettings>>();
      when(() => mockRepository.getSettings()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        buildTestableWidget(
          const StorefrontSettingsView(),
          overrides: [
            storefrontSettingsProvider.overrideWith(
              (ref) => StorefrontSettingsNotifier(repository: mockRepository),
            ),
          ],
        ),
      );

      // Loading spinner is visible initially while future is unresolved
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete future to clean up pending timers
      completer.complete(const Right(StorefrontSettings(storefrontActive: false)));
      await tester.pumpAndSettle();
    });

    testWidgets('renders loaded form with settings and allows switch toggle',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const loadedSettings = StorefrontSettings(
        storefrontActive: true,
        storefrontDisplayName: 'متجر التاجر الذهبي',
        storefrontSlug: 'golden-merchant',
        storeUrl: 'https://test.com/store/golden-merchant',
        storefrontWhatsapp: '+967770000000',
        storefrontPhone: '+967710000000',
        storefrontAddressText: 'صنعاء، شارع الزبيري',
      );

      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(loadedSettings));

      await tester.pumpWidget(
        buildTestableWidget(
          const StorefrontSettingsView(),
          overrides: [
            storefrontSettingsProvider.overrideWith(
              (ref) => StorefrontSettingsNotifier(repository: mockRepository),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Check header and sections
      expect(find.text('إعدادات المتجر الإلكتروني'), findsOneWidget);
      expect(find.text('حالة المتجر الإلكتروني'), findsOneWidget);
      expect(find.text('هوية المتجر والرابط العام'), findsOneWidget);
      expect(find.text('بيانات التواصل والعنوان'), findsOneWidget);

      // Check form fields pre-populated
      expect(find.text('متجر التاجر الذهبي'), findsWidgets);
      expect(find.text('golden-merchant'), findsOneWidget);

      // Check action buttons
      expect(find.text('تفعيل وحفظ الإعدادات'), findsOneWidget);
      expect(find.text('حفظ كمسودة (بدون تفعيل)'), findsOneWidget);

      // Check Switch exists and is toggled
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // Toggle switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      final Switch updatedSwitch = tester.widget(switchFinder);
      expect(updatedSwitch.value, isFalse);
    });

    testWidgets('copy button is disabled when storeUrl is null', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const noUrlSettings = StorefrontSettings(
        storefrontActive: false,
        storefrontDisplayName: 'مسودة',
      );

      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(noUrlSettings));

      await tester.pumpWidget(
        buildTestableWidget(
          const StorefrontSettingsView(),
          overrides: [
            storefrontSettingsProvider.overrideWith(
              (ref) => StorefrontSettingsNotifier(repository: mockRepository),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final copyButtonFinder = find.widgetWithText(OutlinedButton, 'نسخ الرابط');
      expect(copyButtonFinder, findsOneWidget);

      final OutlinedButton button = tester.widget(copyButtonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('renders on mobile screen (400x800) without RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const mobileSettings = StorefrontSettings(
        storefrontActive: true,
        storefrontDisplayName: 'متجر الجوال',
        storefrontSlug: 'mobile-store',
        storeUrl: 'http://localhost:3000/store/mobile-store',
        storefrontWhatsapp: '967770000000',
        storefrontPhone: '967710000000',
      );

      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(mobileSettings));

      await tester.pumpWidget(
        buildTestableWidget(
          const StorefrontSettingsView(),
          overrides: [
            storefrontSettingsProvider.overrideWith(
              (ref) => StorefrontSettingsNotifier(repository: mockRepository),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(StorefrontSettingsView), findsOneWidget);
      expect(find.text('متجر الجوال'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on tablet screen (800x1200) without RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const tabletSettings = StorefrontSettings(
        storefrontActive: false,
        storefrontDisplayName: 'متجر التابلت التجريبي',
        effectiveDisplayName: 'مؤسسة التابلت',
        effectivePhone: '+96777112233',
      );

      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(tabletSettings));

      await tester.pumpWidget(
        buildTestableWidget(
          const StorefrontSettingsView(),
          overrides: [
            storefrontSettingsProvider.overrideWith(
              (ref) => StorefrontSettingsNotifier(repository: mockRepository),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(StorefrontSettingsView), findsOneWidget);
      expect(
        find.textContaining('يمكنك إدارة المنتجات ومزامنتها أثناء تعطيل المتجر'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsControlCenterView - Integration with Storefront Card', () {
    testWidgets('displays Storefront card under Management section',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          const SettingsControlCenterView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('المتجر الإلكتروني'), findsOneWidget);
      expect(find.text('إدارة متجر العملاء، الرابط العام، وتفعيل استقبال الطلبات أونلاين'),
          findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
    });

    testWidgets('SettingsControlCenterView renders cleanly on mobile screen without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          const SettingsControlCenterView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('المتجر الإلكتروني'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Storefront card pushes StorefrontSettingsView',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      await tester.pumpWidget(
        buildTestableWidget(
          const SettingsControlCenterView(),
          overrides: [
            storefrontSettingsProvider.overrideWith(
              (ref) => StorefrontSettingsNotifier(repository: mockRepository),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final cardFinder = find.text('المتجر الإلكتروني');
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Now StorefrontSettingsView should be on top
      expect(find.byType(StorefrontSettingsView), findsOneWidget);
      expect(find.text('إعدادات المتجر الإلكتروني'), findsOneWidget);
    });
  });
}
