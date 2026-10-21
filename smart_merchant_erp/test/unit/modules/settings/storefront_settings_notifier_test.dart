import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_merchant_erp/kernel/error/failures.dart';
import 'package:smart_merchant_erp/modules/settings/domain/entities/slug_availability.dart';
import 'package:smart_merchant_erp/modules/settings/domain/entities/storefront_settings.dart';
import 'package:smart_merchant_erp/modules/settings/domain/repositories/storefront_repository.dart';
import 'package:smart_merchant_erp/modules/settings/presentation/providers/storefront_settings_provider.dart';

class MockStorefrontRepository extends Mock implements StorefrontRepository {}

void main() {
  late MockStorefrontRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const StorefrontSettings(storefrontActive: false));
  });

  setUp(() {
    mockRepository = MockStorefrontRepository();
  });

  group('StorefrontSettingsNotifier - Initialization & Load', () {
    test('loads settings successfully on creation', () async {
      const initialSettings = StorefrontSettings(
        storefrontActive: true,
        storefrontDisplayName: 'متجر التاجر',
        storefrontSlug: 'merchant-store',
        storeUrl: 'https://test.com/store/merchant-store',
      );

      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(initialSettings));

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.settings, equals(initialSettings));
      expect(notifier.state.slugStatus, SlugCheckStatus.available);
      expect(notifier.state.checkedSlug, 'merchant-store');
    });

    test('sets errorMessage on load failure', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Left(NetworkFailure('انقطع الاتصال بالإنترنت')));

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.settings, isNull);
      expect(notifier.state.errorMessage, 'انقطع الاتصال بالإنترنت');
    });
  });

  group('StorefrontSettingsNotifier - Slug handling & normalization', () {
    test('normalizes slug spaces, uppercase, and repeated hyphens', () {
      expect(
        StorefrontSettingsNotifier.normalizeSlug('  --My   Great---Store--  '),
        'my-great-store',
      );
    });

    test('validates slug syntax properly', () {
      expect(StorefrontSettingsNotifier.isValidSlugSyntax('valid-slug-123'), isTrue);
      expect(StorefrontSettingsNotifier.isValidSlugSyntax('ab'), isFalse); // < 3 chars
      expect(StorefrontSettingsNotifier.isValidSlugSyntax('متجر-عربي'), isFalse); // Arabic
      expect(StorefrontSettingsNotifier.isValidSlugSyntax('invalid_symbols!'), isFalse);
    });

    test('recognizes own existing slug as available immediately', () async {
      const initialSettings = StorefrontSettings(
        storefrontActive: true,
        storefrontSlug: 'my-own-slug',
      );

      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(initialSettings));

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      notifier.onSlugChanged('my-own-slug');

      expect(notifier.state.slugStatus, SlugCheckStatus.available);
      expect(notifier.state.slugMessage, contains('رابط المتجر الحالي'));
    });

    test('rejects Arabic input immediately without network request', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      final notifier = StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      notifier.onSlugChanged('متجر-الأمل');

      expect(notifier.state.slugStatus, SlugCheckStatus.invalid);
      expect(notifier.state.slugMessage, contains('لا يقبل الأحرف العربية'));
      verifyNever(() => mockRepository.checkSlugAvailability(any()));
    });

    test('rejects invalid symbols without network request', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      final notifier = StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      notifier.onSlugChanged('shop@2026!');

      expect(notifier.state.slugStatus, SlugCheckStatus.invalid);
      expect(notifier.state.slugMessage, contains('رموز غير مسموحة'));
      verifyNever(() => mockRepository.checkSlugAvailability(any()));
    });

    test('rejects reserved slug keywords locally', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      final notifier = StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      notifier.onSlugChanged('admin');

      expect(notifier.state.slugStatus, SlugCheckStatus.invalid);
      expect(notifier.state.slugMessage, contains('محجوز للنظام'));
      verifyNever(() => mockRepository.checkSlugAvailability(any()));
    });

    test('debounces and checks availability of valid new slug', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      when(() => mockRepository.checkSlugAvailability('brand-new-slug'))
          .thenAnswer(
        (_) async => const Right(
          SlugAvailability(slug: 'brand-new-slug', available: true),
        ),
      );

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      notifier.onSlugChanged('brand-new-slug');

      // Immediately checking state
      expect(notifier.state.slugStatus, SlugCheckStatus.checking);

      // Wait for debounce timer (500ms + margin)
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(notifier.state.slugStatus, SlugCheckStatus.available);
      expect(notifier.state.slugMessage, contains('الرابط متاح'));
    });
  });

  group('StorefrontSettingsNotifier - Save Draft & Activation', () {
    test('saveDraft forces storefrontActive to false', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      const returnedFromBackend = StorefrontSettings(
        storefrontActive: false,
        storefrontDisplayName: 'مسودة المتجر',
        storefrontSlug: 'draft-slug',
      );

      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => const Right(returnedFromBackend));

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const inputSettings = StorefrontSettings(
        storefrontActive: true, // Caller attempted true
        storefrontDisplayName: 'مسودة المتجر',
        storefrontSlug: 'draft-slug',
      );

      final success = await notifier.saveDraft(inputSettings);

      expect(success, isTrue);
      expect(notifier.state.settings?.storefrontActive, isFalse);
      expect(notifier.state.isSuccess, isTrue);

      verify(() => mockRepository.updateSettings(
            any(
              that: isA<StorefrontSettings>().having(
                (s) => s.storefrontActive,
                'storefrontActive',
                isFalse,
              ),
            ),
          )).called(1);
    });

    test('activateStore prevents activation without slug', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const invalidSettings = StorefrontSettings(
        storefrontActive: true,
        storefrontSlug: '', // Empty slug
        storefrontDisplayName: 'متجر بدون رابط',
        storefrontPhone: '+967770000000',
      );

      final success = await notifier.activateStore(invalidSettings);

      expect(success, isFalse);
      expect(notifier.state.validationErrors.containsKey('storefront_slug'), isTrue);
      verifyNever(() => mockRepository.updateSettings(any()));
    });

    test('activateStore prevents activation without contact info', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const noContactSettings = StorefrontSettings(
        storefrontActive: true,
        storefrontSlug: 'has-slug-only',
        storefrontDisplayName: 'متجر بدون اتصال',
      );

      final success = await notifier.activateStore(noContactSettings);

      expect(success, isFalse);
      expect(notifier.state.validationErrors.containsKey('storefront_whatsapp'), isTrue);
      verifyNever(() => mockRepository.updateSettings(any()));
    });

    test('activateStore activates when all requirements are met', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      const serverResponse = StorefrontSettings(
        storefrontActive: true,
        storefrontDisplayName: 'المتجر النشط',
        storefrontSlug: 'active-store',
        storefrontWhatsapp: '+967770000000',
        storeUrl: 'https://test.com/store/active-store',
      );

      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => const Right(serverResponse));

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const readySettings = StorefrontSettings(
        storefrontActive: true,
        storefrontDisplayName: 'المتجر النشط',
        storefrontSlug: 'active-store',
        storefrontWhatsapp: '+967770000000',
      );

      final success = await notifier.activateStore(readySettings);

      expect(success, isTrue);
      expect(notifier.state.settings?.storefrontActive, isTrue);
      expect(notifier.state.isSuccess, isTrue);
    });

    test('activateStore activates with fallback contact info', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      const serverResponse = StorefrontSettings(
        storefrontActive: true,
        storefrontSlug: 'fallback-contact-store',
      );

      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => const Right(serverResponse));

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const settingsWithFallback = StorefrontSettings(
        storefrontActive: true,
        storefrontSlug: 'fallback-contact-store',
        storefrontDisplayName: 'متجر الاعتماد',
        effectivePhone: '+967771234567',
      );

      final success = await notifier.activateStore(settingsWithFallback);

      expect(success, isTrue);
      expect(notifier.state.settings?.storefrontActive, isTrue);
    });

    test('preserves user state on update failure', () async {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(StorefrontSettings(storefrontActive: false)));

      when(() => mockRepository.updateSettings(any())).thenAnswer(
        (_) async => const Left(
          StorefrontValidationFailure(
            'فشل التحقق',
            fieldErrors: {
              'storefront_slug': ['الرابط مستخدم من منشأة أخرى'],
            },
          ),
        ),
      );

      final notifier =
          StorefrontSettingsNotifier(repository: mockRepository);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const input = StorefrontSettings(
        storefrontActive: true,
        storefrontSlug: 'taken-slug',
        storefrontDisplayName: 'متجر تجريبي',
        storefrontWhatsapp: '770000000',
      );

      final success = await notifier.activateStore(input);

      expect(success, isFalse);
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, 'فشل التحقق');
      expect(
        notifier.state.validationErrors['storefront_slug']?.first,
        'الرابط مستخدم من منشأة أخرى',
      );
    });
  });
}
