import '../../domain/entities/slug_availability.dart';

/// Data Transfer Object for Slug Availability check response.
class SlugAvailabilityDto {
  final String slug;
  final bool available;
  final String? storeUrl;

  const SlugAvailabilityDto({
    required this.slug,
    required this.available,
    this.storeUrl,
  });

  factory SlugAvailabilityDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return SlugAvailabilityDto(
      slug: (data['slug'] as String?) ?? '',
      available: (data['available'] as bool?) ?? false,
      storeUrl: data['store_url'] as String?,
    );
  }

  SlugAvailability toDomain() {
    return SlugAvailability(
      slug: slug,
      available: available,
      storeUrl: storeUrl,
    );
  }
}
