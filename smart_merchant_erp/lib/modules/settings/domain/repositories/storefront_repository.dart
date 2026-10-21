import 'package:dartz/dartz.dart';
import '../../../../kernel/error/failures.dart';
import '../entities/slug_availability.dart';
import '../entities/storefront_settings.dart';

/// Validation failure specifically carrying field-level error messages from Laravel.
class StorefrontValidationFailure extends ValidationFailure {
  final Map<String, List<String>> fieldErrors;

  const StorefrontValidationFailure(
    String message, {
    this.fieldErrors = const {},
    int? code,
  }) : super(message, code);

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Repository interface for storefront settings management.
abstract class StorefrontRepository {
  /// Fetches current storefront settings for the authenticated merchant business.
  Future<Either<Failure, StorefrontSettings>> getSettings();

  /// Updates storefront settings for the authenticated merchant business.
  Future<Either<Failure, StorefrontSettings>> updateSettings(
    StorefrontSettings settings,
  );

  /// Checks whether a given slug is available for the current merchant business.
  Future<Either<Failure, SlugAvailability>> checkSlugAvailability(String slug);
}
