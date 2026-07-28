import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../providers/fixed_assets_provider.dart';
import 'widgets/fixed_asset_form_sheet.dart';

class FixedAssetsView extends ConsumerStatefulWidget {
  const FixedAssetsView({super.key});

  @override
  ConsumerState<FixedAssetsView> createState() => _FixedAssetsViewState();
}

class _FixedAssetsViewState extends ConsumerState<FixedAssetsView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final assetsStream = ref.watch(fixedAssetsListProvider);

    return assetsStream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطأ: $err')),
      data: (assets) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: surfaceColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.business_center_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الأصول الثابتة',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${assets.length} أصل',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 160,
                    child: PrimaryButton(
                      text: 'إضافة أصل',
                      icon: Icons.add,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            child: FixedAssetFormSheet(
                              onClose: () => Navigator.pop(ctx),
                              onSave: (data) async {
                                final success = await ref.read(fixedAssetsNotifierProvider.notifier).saveAsset(data);
                                if (success && ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Toolbar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                          ref.read(fixedAssetsSearchQueryProvider.notifier).setQuery(val);
                        },
                        decoration: const InputDecoration(
                          hintText: 'ابحث باسم الأصل أو الكود...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Icon(Icons.filter_list),
                  ),
                ],
              ),
            ),
            // Data Grid / Empty State
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: assets.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد أصول',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'قم بإضافة أصل جديد لعرضه هنا.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: assets.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                      itemBuilder: (context, index) {
                        final asset = assets[index];
                        return ListTile(
                          onTap: () {},
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.business_center, color: AppColors.primary),
                          ),
                          title: Text(asset.assetName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${asset.assetCode} - ${asset.assetCategoryId ?? ""}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${asset.acquisitionCost.toStringAsFixed(0)} YER',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    asset.status,
                                    style: TextStyle(
                                      color: asset.status == 'Active' ? Colors.green : (asset.status == 'Draft' ? Colors.orange : Colors.red),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        );
      }
    );
  }
}
