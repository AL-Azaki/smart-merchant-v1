import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/modules/settings/domain/entities/storefront_settings.dart';
import 'package:smart_merchant_erp/modules/settings/infrastructure/dto/slug_availability_dto.dart';
import 'package:smart_merchant_erp/modules/settings/infrastructure/dto/storefront_settings_dto.dart';

void main() {
  group('StorefrontSettingsDto', () {
    test('parses full envelope from Laravel API response', () {
      final json = {
        'success': true,
        'data': {
          'storefront_active': true,
          'storefront_display_name': 'متجر النور',
          'effective_display_name': 'متجر النور',
          'storefront_slug': 'alnoor-store',
          'store_url': 'https://domain.test/store/alnoor-store',
          'storefront_whatsapp': '+967770000000',
          'storefront_phone': '+967710000000',
          'effective_phone': '+967710000000',
          'storefront_address_text': 'صنعاء، شارع الزبيري',
          'storefront_lat': 15.354,
          'storefront_lng': 44.205,
          'storefront_theme_settings': {
            'primary_color': '#3B82F6',
          },
        },
      };

      final dto = StorefrontSettingsDto.fromJson(json);

      expect(dto.storefrontActive, isTrue);
      expect(dto.storefrontDisplayName, 'متجر النور');
      expect(dto.effectiveDisplayName, 'متجر النور');
      expect(dto.storefrontSlug, 'alnoor-store');
      expect(dto.storeUrl, 'https://domain.test/store/alnoor-store');
      expect(dto.storefrontWhatsapp, '+967770000000');
      expect(dto.storefrontPhone, '+967710000000');
      expect(dto.effectivePhone, '+967710000000');
      expect(dto.storefrontAddressText, 'صنعاء، شارع الزبيري');
      expect(dto.storefrontLat, 15.354);
      expect(dto.storefrontLng, 44.205);
      expect(dto.storefrontThemeSettings?['primary_color'], '#3B82F6');
    });

    test('parses null fields safely', () {
      final json = {
        'data': {
          'storefront_active': false,
          'storefront_display_name': null,
          'storefront_slug': null,
          'store_url': null,
          'storefront_whatsapp': null,
          'storefront_phone': null,
          'storefront_address_text': null,
          'storefront_lat': null,
          'storefront_lng': null,
          'storefront_theme_settings': null,
        },
      };

      final dto = StorefrontSettingsDto.fromJson(json);

      expect(dto.storefrontActive, isFalse);
      expect(dto.storefrontDisplayName, isNull);
      expect(dto.storefrontSlug, isNull);
      expect(dto.storeUrl, isNull);
      expect(dto.storefrontLat, isNull);
      expect(dto.storefrontLng, isNull);
    });

    test('parses numeric string lat/lng correctly', () {
      final json = {
        'storefront_active': true,
        'storefront_lat': '15.3500000',
        'storefront_lng': '44.2000000',
      };

      final dto = StorefrontSettingsDto.fromJson(json);

      expect(dto.storefrontLat, 15.35);
      expect(dto.storefrontLng, 44.20);
    });

    test('parses various boolean formats safely', () {
      expect(
        StorefrontSettingsDto.fromJson({'storefront_active': 1}).storefrontActive,
        isTrue,
      );
      expect(
        StorefrontSettingsDto.fromJson({'storefront_active': 'true'}).storefrontActive,
        isTrue,
      );
      expect(
        StorefrontSettingsDto.fromJson({'storefront_active': '1'}).storefrontActive,
        isTrue,
      );
      expect(
        StorefrontSettingsDto.fromJson({'storefront_active': 0}).storefrontActive,
        isFalse,
      );
      expect(
        StorefrontSettingsDto.fromJson({'storefront_active': null}).storefrontActive,
        isFalse,
      );
    });

    test('toJson() MUST NOT contain store_url', () {
      const dto = StorefrontSettingsDto(
        storefrontActive: true,
        storefrontDisplayName: 'اسم المتجر',
        storefrontSlug: 'slug-test',
        storeUrl: 'https://domain.test/store/slug-test',
        storefrontWhatsapp: '+967770000000',
      );

      final json = dto.toJson();

      expect(json.containsKey('store_url'), isFalse);
      expect(json['storefront_active'], isTrue);
      expect(json['storefront_slug'], 'slug-test');
      expect(json['storefront_whatsapp'], '+967770000000');
    });

    test('toDomain() and fromDomain() preserve data integrity', () {
      const entity = StorefrontSettings(
        storefrontActive: true,
        storefrontDisplayName: 'متجر التحويل',
        storefrontSlug: 'conversion-store',
        storeUrl: 'https://test.com/store/conversion-store',
        storefrontWhatsapp: '+96777111222',
        storefrontPhone: '+96771111222',
        storefrontAddressText: 'عدن',
        storefrontLat: 12.8,
        storefrontLng: 45.0,
      );

      final dto = StorefrontSettingsDto.fromDomain(entity);
      final mappedEntity = dto.toDomain();

      expect(mappedEntity, equals(entity));
    });
  });

  group('SlugAvailabilityDto', () {
    test('parses available response', () {
      final json = {
        'success': true,
        'data': {
          'slug': 'available-slug',
          'available': true,
          'store_url': 'https://domain.test/store/available-slug',
        },
      };

      final dto = SlugAvailabilityDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.slug, 'available-slug');
      expect(domain.available, isTrue);
      expect(domain.storeUrl, 'https://domain.test/store/available-slug');
    });

    test('parses unavailable response', () {
      final json = {
        'data': {
          'slug': 'taken-slug',
          'available': false,
          'store_url': null,
        },
      };

      final dto = SlugAvailabilityDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.slug, 'taken-slug');
      expect(domain.available, isFalse);
      expect(domain.storeUrl, isNull);
    });
  });
}
