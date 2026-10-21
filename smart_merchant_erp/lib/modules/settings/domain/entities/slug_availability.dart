import 'package:equatable/equatable.dart';

/// Value object representing the result of checking storefront slug availability.
class SlugAvailability extends Equatable {
  final String slug;
  final bool available;
  final String? storeUrl;

  const SlugAvailability({
    required this.slug,
    required this.available,
    this.storeUrl,
  });

  @override
  List<Object?> get props => [slug, available, storeUrl];
}
