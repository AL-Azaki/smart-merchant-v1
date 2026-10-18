import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_image_provider.dart';

class ProductThumbnail extends ConsumerWidget {
  final String productId;
  final String name;
  const ProductThumbnail({
    required this.productId,
    required this.name,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(productImagePathProvider(productId)).valueOrNull;
    final theme = Theme.of(context);
    Widget placeholder() => ColoredBox(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: theme.colorScheme.primary,
          size: 23,
        ),
      ),
    );
    return Semantics(
      label: 'صورة $name',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: path == null || path.isEmpty
              ? placeholder()
              : path.startsWith('https://') || path.startsWith('http://')
              ? Image.network(
                  path,
                  fit: BoxFit.cover,
                  cacheWidth: 144,
                  errorBuilder: (_, error, stack) => placeholder(),
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: 144,
                  errorBuilder: (_, error, stack) => placeholder(),
                ),
        ),
      ),
    );
  }
}
