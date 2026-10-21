import 'package:equatable/equatable.dart';

/// Entity representing the public storefront configuration for a merchant business.
class StorefrontSettings extends Equatable {
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

  const StorefrontSettings({
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
  });

  /// Factory creating an empty draft state for an inactive storefront.
  factory StorefrontSettings.empty() {
    return const StorefrontSettings(
      storefrontActive: false,
    );
  }

  StorefrontSettings copyWith({
    bool? storefrontActive,
    String? storefrontDisplayName,
    String? effectiveDisplayName,
    String? storefrontSlug,
    String? storeUrl,
    String? storefrontWhatsapp,
    String? storefrontPhone,
    String? effectivePhone,
    String? storefrontAddressText,
    double? storefrontLat,
    double? storefrontLng,
    Map<String, dynamic>? storefrontThemeSettings,
  }) {
    return StorefrontSettings(
      storefrontActive: storefrontActive ?? this.storefrontActive,
      storefrontDisplayName:
          storefrontDisplayName ?? this.storefrontDisplayName,
      effectiveDisplayName:
          effectiveDisplayName ?? this.effectiveDisplayName,
      storefrontSlug: storefrontSlug ?? this.storefrontSlug,
      storeUrl: storeUrl ?? this.storeUrl,
      storefrontWhatsapp: storefrontWhatsapp ?? this.storefrontWhatsapp,
      storefrontPhone: storefrontPhone ?? this.storefrontPhone,
      effectivePhone: effectivePhone ?? this.effectivePhone,
      storefrontAddressText:
          storefrontAddressText ?? this.storefrontAddressText,
      storefrontLat: storefrontLat ?? this.storefrontLat,
      storefrontLng: storefrontLng ?? this.storefrontLng,
      storefrontThemeSettings:
          storefrontThemeSettings ?? this.storefrontThemeSettings,
    );
  }

  @override
  List<Object?> get props => [
        storefrontActive,
        storefrontDisplayName,
        effectiveDisplayName,
        storefrontSlug,
        storeUrl,
        storefrontWhatsapp,
        storefrontPhone,
        effectivePhone,
        storefrontAddressText,
        storefrontLat,
        storefrontLng,
        storefrontThemeSettings,
      ];
}
