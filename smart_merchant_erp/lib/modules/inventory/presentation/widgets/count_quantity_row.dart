import 'package:flutter/material.dart';
import '../../../catalog/presentation/views/widgets/catalog_formatters.dart';

double? parseCountQuantity(String text) {
  var normalized = text.trim();
  for (var i = 0; i < 10; i++) {
    normalized = normalized
        .replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i')
        .replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i');
  }
  final value = double.tryParse(
    normalized.replaceAll('٫', '.').replaceAll(',', '.'),
  );
  return value != null && value.isFinite && value >= 0 ? value : null;
}

class CountQuantityRow extends StatelessWidget {
  final String name, unit;
  final double expected;
  final double? physical;
  final Widget? input;
  final VoidCallback? onRemove;
  const CountQuantityRow({
    required this.name, required this.unit, required this.expected, required this.physical, super.key,
    this.input,
    this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    final diff = physical == null ? null : physical! - expected;
    final theme = Theme.of(context);
    final color = diff == null || diff == 0
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : diff > 0
        ? (theme.brightness == Brightness.dark
              ? const Color(0xFF6EE7B7)
              : const Color(0xFF047857))
        : Theme.of(context).colorScheme.error;
    Widget value(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
    final numbers = [
      Expanded(
        child: value(
          'رصيد النظام',
          Text(
            formatCatalogNumber(expected),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: value(
          'الكمية الفعلية',
          input ??
              Text(
                physical == null ? 'لم يُعدّ' : formatCatalogNumber(physical!),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: value(
          'الفرق',
          Text(
            diff == null
                ? '—'
                : '${diff > 0 ? '+' : ''}${formatCatalogNumber(diff)}',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ];
    final product = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                catalogDisplayName(unit),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'إزالة المنتج',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              children: [
                product,
                const SizedBox(height: 14),
                Row(children: numbers),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: product),
              const SizedBox(width: 28),
              Expanded(flex: 4, child: Row(children: numbers)),
            ],
          );
        },
      ),
    );
  }
}
