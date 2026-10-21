import '../../../../app/config/api_client.dart';
import '../dto/slug_availability_dto.dart';
import '../dto/storefront_settings_dto.dart';

/// Remote HTTP client for storefront settings endpoints.
/// Reuses the application's central [ApiClient].
class StorefrontRemoteApiClient {
  final ApiClient _apiClient;

  const StorefrontRemoteApiClient(this._apiClient);

  /// GET /platform/storefront/settings
  Future<StorefrontSettingsDto> getSettings() async {
    final response = await _apiClient.get('/platform/storefront/settings');
    return StorefrontSettingsDto.fromJson(response.json);
  }

  /// PUT /platform/storefront/settings
  Future<StorefrontSettingsDto> updateSettings(
    StorefrontSettingsDto dto,
  ) async {
    final response = await _apiClient.put(
      '/platform/storefront/settings',
      data: dto.toJson(),
    );
    return StorefrontSettingsDto.fromJson(response.json);
  }

  /// GET /platform/storefront/slug-availability?slug=...
  Future<SlugAvailabilityDto> checkSlugAvailability(String slug) async {
    final response = await _apiClient.get(
      '/platform/storefront/slug-availability',
      queryParams: {'slug': slug},
    );
    return SlugAvailabilityDto.fromJson(response.json);
  }
}
