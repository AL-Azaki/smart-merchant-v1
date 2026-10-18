import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

class InventorySectionHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget action;
  const InventorySectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final titleRow = Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        if (constraints.maxWidth < 580) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [titleRow, const SizedBox(height: 12), action],
          );
        }
        return Row(
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 16),
            action,
          ],
        );
      },
    ),
  );
}
