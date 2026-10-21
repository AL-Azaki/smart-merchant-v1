import 'package:dartz/dartz.dart';
import '../../../../app/config/api_client.dart';
import '../../../../kernel/error/failures.dart';
import '../../domain/entities/slug_availability.dart';
import '../../domain/entities/storefront_settings.dart';
import '../../domain/repositories/storefront_repository.dart';
import '../api/storefront_remote_api_client.dart';
import '../dto/storefront_settings_dto.dart';

class StorefrontRepositoryImpl implements StorefrontRepository {
  final StorefrontRemoteApiClient _remoteApi;

  const StorefrontRepositoryImpl(this._remoteApi);

  @override
  Future<Either<Failure, StorefrontSettings>> getSettings() async {
    try {
      final dto = await _remoteApi.getSettings();
      return Right(dto.toDomain());
    } on ApiException catch (e) {
      return Left(_mapApiException(e));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StorefrontSettings>> updateSettings(
    StorefrontSettings settings,
  ) async {
    try {
      final dto = StorefrontSettingsDto.fromDomain(settings);
      final updatedDto = await _remoteApi.updateSettings(dto);
      return Right(updatedDto.toDomain());
    } on ApiException catch (e) {
      return Left(_mapApiException(e));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SlugAvailability>> checkSlugAvailability(
    String slug,
  ) async {
    try {
      final dto = await _remoteApi.checkSlugAvailability(slug);
      return Right(dto.toDomain());
    } on ApiException catch (e) {
      return Left(_mapApiException(e));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
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
