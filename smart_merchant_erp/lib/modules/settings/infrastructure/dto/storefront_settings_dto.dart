import '../../domain/entities/storefront_settings.dart';

/// Data Transfer Object for Storefront Settings matching Laravel platform API contract.
class StorefrontSettingsDto {
  final bool storefrontActive;
  final String? storefrontDisplayName;
  final String? effectiveDisplayName;
  final String? storefrontSlug;
  final String? storeUrl;
  final String? storefrontWhatsapp;
  final String? storefrontPhone;
  final String? effectivePhone;
  final String? storefrontAddressText;
  final double? storefrontLat;
  final double? storefrontLng;
  final Map<String, dynamic>? storefrontThemeSettings;
  final List<String>? storefrontCategories;

  const StorefrontSettingsDto({
    required this.storefrontActive,
    this.storefrontDisplayName,
    this.effectiveDisplayName,
    this.storefrontSlug,
    this.storeUrl,
    this.storefrontWhatsapp,
    this.storefrontPhone,
    this.effectivePhone,
    this.storefrontAddressText,
    this.storefrontLat,
    this.storefrontLng,
    this.storefrontThemeSettings,
    this.storefrontCategories,
  });

  /// Safely parses JSON response from Laravel envelope (`data` or root map).
  factory StorefrontSettingsDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return StorefrontSettingsDto(
      storefrontActive: _parseBool(data['storefront_active']),
      storefrontDisplayName: data['storefront_display_name'] as String?,
      effectiveDisplayName: data['effective_display_name'] as String?,
      storefrontSlug: data['storefront_slug'] as String?,
      storeUrl: data['store_url'] as String?,
      storefrontWhatsapp: data['storefront_whatsapp'] as String?,
      storefrontPhone: data['storefront_phone'] as String?,
      effectivePhone: data['effective_phone'] as String?,
      storefrontAddressText: data['storefront_address_text'] as String?,
      storefrontLat: _parseCoord(data['storefront_lat']),
      storefrontLng: _parseCoord(data['storefront_lng']),
      storefrontThemeSettings: data['storefront_theme_settings'] is Map
          ? Map<String, dynamic>.from(data['storefront_theme_settings'] as Map)
          : null,
      storefrontCategories: (data['storefront_categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Converts to JSON payload for PUT request.
  /// IMPORTANT: [store_url] is computed by the server and MUST NOT be sent in PUT.
  Map<String, dynamic> toJson() {
    return {
      'storefront_active': storefrontActive,
      'storefront_display_name': storefrontDisplayName,
      'storefront_slug': storefrontSlug,
      'storefront_whatsapp': storefrontWhatsapp,
      'storefront_phone': storefrontPhone,
      'storefront_address_text': storefrontAddressText,
      'storefront_lat': storefrontLat,
      'storefront_lng': storefrontLng,
      'storefront_theme_settings': storefrontThemeSettings,
      'storefront_categories': storefrontCategories,
    };
  }

  /// Maps DTO to domain Entity.
  StorefrontSettings toDomain() {
    return StorefrontSettings(
      storefrontActive: storefrontActive,
      storefrontDisplayName: storefrontDisplayName,
      effectiveDisplayName: effectiveDisplayName,
      storefrontSlug: storefrontSlug,
      storeUrl: storeUrl,
      storefrontWhatsapp: storefrontWhatsapp,
      storefrontPhone: storefrontPhone,
      effectivePhone: effectivePhone,
      storefrontAddressText: storefrontAddressText,
      storefrontLat: storefrontLat,
      storefrontLng: storefrontLng,
      storefrontThemeSettings: storefrontThemeSettings,
      storefrontCategories: storefrontCategories,
    );
  }

  /// Creates DTO from domain Entity.
  factory StorefrontSettingsDto.fromDomain(StorefrontSettings entity) {
    return StorefrontSettingsDto(
      storefrontActive: entity.storefrontActive,
      storefrontDisplayName: entity.storefrontDisplayName,
      effectiveDisplayName: entity.effectiveDisplayName,
      storefrontSlug: entity.storefrontSlug,
      storeUrl: entity.storeUrl,
      storefrontWhatsapp: entity.storefrontWhatsapp,
      storefrontPhone: entity.storefrontPhone,
      effectivePhone: entity.effectivePhone,
      storefrontAddressText: entity.storefrontAddressText,
      storefrontLat: entity.storefrontLat,
      storefrontLng: entity.storefrontLng,
      storefrontThemeSettings: entity.storefrontThemeSettings,
      storefrontCategories: entity.storefrontCategories,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) {
      return false;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  static double? _parseCoord(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
