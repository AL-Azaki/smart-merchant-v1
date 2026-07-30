import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../kernel/storage/app_database.dart';

class FixedAssetDetailScreen extends ConsumerStatefulWidget {
  final FixedAsset asset;
  final VoidCallback onBack;

  const FixedAssetDetailScreen({
    super.key,
    required this.asset,
    required this.onBack,
  });

  @override
  ConsumerState<FixedAssetDetailScreen> createState() =>
      _FixedAssetDetailScreenState();
}

class _FixedAssetDetailScreenState extends ConsumerState<FixedAssetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(widget.asset.assetName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Edit coming soon')));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard)),
            Tab(text: 'المعلومات المالية', icon: Icon(Icons.attach_money)),
            Tab(text: 'الإهلاك', icon: Icon(Icons.trending_down)),
            Tab(text: 'الصيانة', icon: Icon(Icons.build)),
            Tab(text: 'الحركات', icon: Icon(Icons.swap_horiz)),
            Tab(text: 'المرفقات', icon: Icon(Icons.attach_file)),
            Tab(text: 'الملاحظات', icon: Icon(Icons.note)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(surfaceColor),
          _buildFinancialTab(surfaceColor),
          _buildDepreciationTab(surfaceColor),
          _buildMaintenanceTab(surfaceColor),
          _buildMovementsTab(surfaceColor),
          _buildAttachmentsTab(surfaceColor),
          _buildNotesTab(surfaceColor),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Color surfaceColor) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
        children: [
          _buildInfoCard(
            'تكلفة الشراء الأصلية',
            '${widget.asset.acquisitionCost.toStringAsFixed(0)} YER',
            surfaceColor,
          ),
          _buildInfoCard(
            'مجمع الإهلاك',
            '${(widget.asset.acquisitionCost * 0.45).toStringAsFixed(0)} YER',
            surfaceColor,
          ),
          _buildInfoCard(
            'صافي القيمة الدفترية',
            '${(widget.asset.acquisitionCost * 0.55).toStringAsFixed(0)} YER',
            surfaceColor,
          ),
          _buildInfoCard(
            'العمر الإنتاجي المتبقي',
            '${widget.asset.usefulLife} أشهر',
            surfaceColor,
          ),
          _buildInfoCard('إجمالي عمليات الصيانة', '0', surfaceColor),
          _buildInfoCard('نسبة الإهلاك السنوي', '15%', surfaceColor),
        ],
      ),
    );
  }

  Widget _buildFinancialTab(Color surfaceColor) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Card(
        color: surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تفاصيل الشراء والمالية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem(
                    'تاريخ الشراء',
                    widget.asset.acquisitionDate
                        .toIso8601String()
                        .split('T')
                        .first,
                  ),
                  _buildDetailItem(
                    'الحساب المحاسبي للأصل',
                    '120100 - آلات ومعدات',
                  ),
                  _buildDetailItem(
                    'حساب مجمع الإهلاك',
                    '120199 - مجمع إهلاك آلات ومعدات',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepreciationTab(Color surfaceColor) {
    return const Center(
      child: Text(
        'جدول الإهلاك (CAPABILITY GAP - No Depreciation Service yet)',
      ),
    );
  }

  Widget _buildMaintenanceTab(Color surfaceColor) {
    return const Center(
      child: Text('سجل الصيانة (CAPABILITY GAP - No Maintenance Service yet)'),
    );
  }

  Widget _buildMovementsTab(Color surfaceColor) {
    return const Center(
      child: Text('الحركات (CAPABILITY GAP - No Movement Tracking yet)'),
    );
  }

  Widget _buildAttachmentsTab(Color surfaceColor) {
    return const Center(
      child: Text('المرفقات (CAPABILITY GAP - No Attachment Service yet)'),
    );
  }

  Widget _buildNotesTab(Color surfaceColor) {
    return const Center(
      child: Text('الملاحظات (CAPABILITY GAP - No Note Service yet)'),
    );
  }

  Widget _buildInfoCard(String title, String value, Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
