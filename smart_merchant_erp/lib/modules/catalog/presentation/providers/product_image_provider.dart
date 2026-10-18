import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../authentication/presentation/providers/session_provider.dart';

/// Only visible thumbnails subscribe; off-screen images release their streams.
final productImagePathProvider = StreamProvider.autoDispose
    .family<String?, String>((ref, productId) {
      final session = ref.watch(sessionNotifierProvider);
      if (!session.isActive) {
        return Stream.value(null);
      }
      return ref
          .watch(catalogRepositoryProvider)
          .watchProductImagesByProductId(productId)
          .map(
            (images) =>
                (images.where((i) => i.isPrimary).firstOrNull ??
                        images.firstOrNull)
                    ?.imagePath,
          );
    });
