import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_merchant_erp/app/config/api_client.dart';
import 'package:smart_merchant_erp/kernel/error/failures.dart';
import 'package:smart_merchant_erp/modules/settings/domain/entities/storefront_settings.dart';
import 'package:smart_merchant_erp/modules/settings/domain/repositories/storefront_repository.dart';
import 'package:smart_merchant_erp/modules/settings/infrastructure/api/storefront_remote_api_client.dart';
import 'package:smart_merchant_erp/modules/settings/infrastructure/dto/slug_availability_dto.dart';
import 'package:smart_merchant_erp/modules/settings/infrastructure/dto/storefront_settings_dto.dart';
import 'package:smart_merchant_erp/modules/settings/infrastructure/repositories/storefront_repository_impl.dart';

class MockStorefrontRemoteApiClient extends Mock
    implements StorefrontRemoteApiClient {}

void main() {
  late MockStorefrontRemoteApiClient mockApi;
  late StorefrontRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const StorefrontSettingsDto(storefrontActive: false));
  });

  setUp(() {
    mockApi = MockStorefrontRemoteApiClient();
    repository = StorefrontRepositoryImpl(mockApi);
  });

  group('StorefrontRepositoryImpl - getSettings', () {
    test('returns Right(StorefrontSettings) on API success', () async {
      const dto = StorefrontSettingsDto(
        storefrontActive: true,
        storefrontDisplayName: 'متجر الاختبار',
        storefrontSlug: 'test-store',
        storeUrl: 'https://test.com/store/test-store',
      );

      when(() => mockApi.getSettings()).thenAnswer((_) async => dto);

      final result = await repository.getSettings();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left($failure)'),
        (settings) {
          expect(settings.storefrontActive, isTrue);
          expect(settings.storefrontDisplayName, 'متجر الاختبار');
          expect(settings.storefrontSlug, 'test-store');
        },
      );
    });

    test('maps ApiException.noNetwork to NetworkFailure', () async {
      when(() => mockApi.getSettings())
          .thenThrow(const ApiException.noNetwork());

      final result = await repository.getSettings();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (settings) => fail('Expected Left'),
      );
    });

    test('maps ApiException.unauthorized to AuthFailure', () async {
      when(() => mockApi.getSettings())
          .thenThrow(ApiException.unauthorized('Unauthenticated'));

      final result = await repository.getSettings();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.code, 401);
        },
        (settings) => fail('Expected Left'),
      );
    });
  });

  group('StorefrontRepositoryImpl - updateSettings', () {
    test('returns Right(StorefrontSettings) on successful update', () async {
      const updatedDto = StorefrontSettingsDto(
        storefrontActive: true,
        storefrontDisplayName: 'محدث',
        storefrontSlug: 'updated-store',
      );

      when(() => mockApi.updateSettings(any()))
          .thenAnswer((_) async => updatedDto);

      const requestEntity = StorefrontSettings(
        storefrontActive: true,
        storefrontDisplayName: 'محدث',
        storefrontSlug: 'updated-store',
      );

      final result = await repository.updateSettings(requestEntity);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right'),
        (settings) => expect(settings.storefrontDisplayName, 'محدث'),
      );
    });

    test('maps 422 ApiException to StorefrontValidationFailure with field errors',
        () async {
      final apiException = ApiException.validation(
        'Validation failed',
        validationErrors: {
          'storefront_slug': ['الرابط محجوز مسبقاً'],
          'storefront_whatsapp': ['رقم الواتساب مطلوب للتفعيل'],
        },
      );

      when(() => mockApi.updateSettings(any())).thenThrow(apiException);

      const requestEntity = StorefrontSettings(storefrontActive: true);
      final result = await repository.updateSettings(requestEntity);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<StorefrontValidationFailure>());
          final vFailure = failure as StorefrontValidationFailure;
          expect(
            vFailure.fieldErrors['storefront_slug']?.first,
            'الرابط محجوز مسبقاً',
          );
          expect(
            vFailure.fieldErrors['storefront_whatsapp']?.first,
            'رقم الواتساب مطلوب للتفعيل',
          );
        },
        (settings) => fail('Expected Left'),
      );
    });

    test('maps 409 conflict to ConflictFailure', () async {
      when(() => mockApi.updateSettings(any()))
          .thenThrow(ApiException.conflict('Slug conflict'));

      const requestEntity = StorefrontSettings(storefrontActive: true);
      final result = await repository.updateSettings(requestEntity);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ConflictFailure>()),
        (settings) => fail('Expected Left'),
      );
    });
  });

  group('StorefrontRepositoryImpl - checkSlugAvailability', () {
    test('returns Right(SlugAvailability) on API success', () async {
      const availabilityDto = SlugAvailabilityDto(
        slug: 'fresh-slug',
        available: true,
        storeUrl: 'https://test.com/store/fresh-slug',
      );

      when(() => mockApi.checkSlugAvailability('fresh-slug'))
          .thenAnswer((_) async => availabilityDto);

      final result = await repository.checkSlugAvailability('fresh-slug');

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right'),
        (availability) {
          expect(availability.slug, 'fresh-slug');
          expect(availability.available, isTrue);
        },
      );
    });
  });
}
