import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/config/api_client.dart';
import '../../../../kernel/error/failures.dart';
import '../../domain/entities/slug_availability.dart';
import '../../domain/entities/storefront_settings.dart';
import '../../domain/repositories/storefront_repository.dart';
import '../api/storefront_remote_api_client.dart';
import '../dto/storefront_settings_dto.dart';

class StorefrontRepositoryImpl implements StorefrontRepository {
  final StorefrontRemoteApiClient _remoteApi;
  static const String _localCacheKey = 'smart_merchant_storefront_settings_v1';

  const StorefrontRepositoryImpl(this._remoteApi);

  static String _buildDefaultUrl(String? slug) {
    final cleanSlug = (slug != null && slug.trim().isNotEmpty)
        ? slug.trim().toLowerCase()
        : 'smart-store';
    return 'http://localhost:3000/store/$cleanSlug';
  }

  Future<void> _saveToLocalCache(StorefrontSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final slug = (settings.storefrontSlug != null &&
              settings.storefrontSlug!.trim().isNotEmpty)
          ? settings.storefrontSlug!.trim()
          : 'smart-store';
      final effectiveUrl = (settings.storeUrl != null &&
              settings.storeUrl!.trim().isNotEmpty)
          ? settings.storeUrl!
          : _buildDefaultUrl(slug);

      final dto = StorefrontSettingsDto.fromDomain(
        settings.copyWith(
          storefrontSlug: slug,
          storeUrl: effectiveUrl,
        ),
      );
      final map = {
        ...dto.toJson(),
        'effective_display_name':
            settings.effectiveDisplayName ?? settings.storefrontDisplayName ?? 'متجر التاجر الذكي',
        'effective_phone': settings.effectivePhone ?? settings.storefrontPhone ?? '777000000',
        'store_url': effectiveUrl,
      };
      await prefs.setString(_localCacheKey, jsonEncode(map));
    } catch (_) {
      // Ignore cache write errors
    }
  }

  Future<StorefrontSettings> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return StorefrontSettingsDto.fromJson(decoded).toDomain();
      }
    } catch (_) {
      // Fallback to default local settings
    }

    return const StorefrontSettings(
      storefrontActive: true,
      storefrontDisplayName: 'متجر التاجر الذكي',
      effectiveDisplayName: 'متجر التاجر الذكي',
      storefrontSlug: 'smart-store',
      storeUrl: 'http://localhost:3000/store/smart-store',
      storefrontWhatsapp: '967777000000',
      storefrontPhone: '967777000000',
      effectivePhone: '967777000000',
      storefrontAddressText: 'المركز الرئيسي - شارع الستين',
      storefrontCategories: [
        'سوبرماركت',
        'مواد غذائية',
        'هواتف وإلكترونيات',
        'عطور وتجميل',
        'بضائع منوعة',
      ],
    );
  }

  @override
  Future<Either<Failure, StorefrontSettings>> getSettings() async {
    try {
      final dto = await _remoteApi.getSettings();
      final domain = dto.toDomain();
      await _saveToLocalCache(domain);
      return Right(domain);
    } on ApiException catch (e) {
      // Offline-First Fallback: return cached/default settings when backend is unreachable or unauthorized in offline mode
      if (e.type == ApiExceptionType.noNetwork ||
          e.type == ApiExceptionType.timeout ||
          e.type == ApiExceptionType.unauthorized ||
          e.type == ApiExceptionType.server ||
          e.type == ApiExceptionType.unknown) {
        final cached = await _loadFromLocalCache();
        return Right(cached);
      }
      return Left(_mapApiException(e));
    } catch (_) {
      final cached = await _loadFromLocalCache();
      return Right(cached);
    }
  }

  @override
  Future<Either<Failure, StorefrontSettings>> updateSettings(
    StorefrontSettings settings,
  ) async {
    final normalizedSlug = (settings.storefrontSlug != null &&
            settings.storefrontSlug!.trim().isNotEmpty)
        ? settings.storefrontSlug!.trim()
        : 'smart-store';
    final localUpdated = settings.copyWith(
      storefrontSlug: normalizedSlug,
      storeUrl: _buildDefaultUrl(normalizedSlug),
      effectiveDisplayName:
          settings.storefrontDisplayName ?? settings.effectiveDisplayName ?? 'متجر التاجر الذكي',
      effectivePhone:
          settings.storefrontPhone ?? settings.effectivePhone ?? settings.storefrontWhatsapp,
    );

    // Always persist locally first (Offline-First)
    await _saveToLocalCache(localUpdated);

    try {
      final dto = StorefrontSettingsDto.fromDomain(localUpdated);
      final updatedDto = await _remoteApi.updateSettings(dto);
      final remoteDomain = updatedDto.toDomain().copyWith(
            storefrontCategories: localUpdated.storefrontCategories,
          );
      await _saveToLocalCache(remoteDomain);
      return Right(remoteDomain);
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.validation ||
          e.type == ApiExceptionType.conflict) {
        return Left(_mapApiException(e));
      }
      // In offline/local mode, succeed with the locally saved settings
      return Right(localUpdated);
    } catch (_) {
      return Right(localUpdated);
    }
  }

  @override
  Future<Either<Failure, SlugAvailability>> checkSlugAvailability(
    String slug,
  ) async {
    try {
      final dto = await _remoteApi.checkSlugAvailability(slug);
      return Right(dto.toDomain());
    } catch (_) {
      // Offline fallback: syntax and reserved checks are already validated in notifier
      return Right(
        SlugAvailability(
          slug: slug,
          available: true,
          storeUrl: _buildDefaultUrl(slug),
        ),
      );
    }
  }

  Failure _mapApiException(ApiException e) {
    switch (e.type) {
      case ApiExceptionType.validation:
        return StorefrontValidationFailure(
          e.message,
          fieldErrors: e.validationErrors ?? {},
          code: e.statusCode ?? 422,
        );
      case ApiExceptionType.conflict:
        return ConflictFailure(e.message, e.statusCode ?? 409);
      case ApiExceptionType.unauthorized:
      case ApiExceptionType.forbidden:
      case ApiExceptionType.deviceRevoked:
        return AuthFailure(e.message, e.statusCode);
      case ApiExceptionType.noNetwork:
      case ApiExceptionType.timeout:
        return NetworkFailure(e.message);
      case ApiExceptionType.server:
      case ApiExceptionType.serialization:
      case ApiExceptionType.rateLimited:
      case ApiExceptionType.unknown:
        return UnexpectedFailure(e.message, e.statusCode);
    }
  }
}
