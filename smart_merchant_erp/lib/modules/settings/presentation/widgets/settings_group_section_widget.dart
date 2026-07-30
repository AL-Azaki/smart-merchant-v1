import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../models/settings_card_item_model.dart';
import 'settings_card_widget.dart';

class SettingsGroupSectionWidget extends StatelessWidget {
  final SettingsGroupModel group;
  final void Function(SettingsCardItemModel) onCardTap;

  const SettingsGroupSectionWidget({
    super.key,
    required this.group,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Header Title & Line
        Row(
          children: [
            Text(
              group.title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Container(height: 1.5, color: border)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Grid Layout: Responsive 1, 2, or 3 columns based on screen width
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 1;
            if (width > 1050) {
              crossAxisCount = 3;
            } else if (width > 680) {
              crossAxisCount = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
                mainAxisExtent: width <= 700 ? 215 : 185,
              ),
              itemBuilder: (context, index) {
                final cardItem = group.cards[index];
                return SettingsCardWidget(
                  item: cardItem,
                  onTap: () => onCardTap(cardItem),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
