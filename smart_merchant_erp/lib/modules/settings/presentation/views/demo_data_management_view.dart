import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/seeders/demo_data_seeder_service.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../widgets/settings_header_widget.dart';

class DemoDataManagementView extends ConsumerStatefulWidget {
  const DemoDataManagementView({super.key});

  @override
  ConsumerState<DemoDataManagementView> createState() =>
      _DemoDataManagementViewState();
}

class _DemoDataManagementViewState extends ConsumerState<DemoDataManagementView> {
  late final DemoDataSeederService _seederService;
  DemoDataStats? _stats;
  bool _isLoading = false;
  String? _actionMessage;

  @override
  void initState() {
    super.initState();
    _seederService = DemoDataSeederService(getIt<AppDatabase>());
    _loadStats();
  }

  Future<void> _loadStats() async {
    final session = ref.read(sessionNotifierProvider);
    final businessId = session.businessId ?? 'qa-business-id';
    final stats = await _seederService.getStats(businessId);
    if (mounted) {
      setState(() => _stats = stats);
    }
  }

  Future<void> _handleGenerateDemoData() async {
    final session = ref.read(sessionNotifierProvider);
    final businessId = session.businessId ?? 'qa-business-id';
    final branchId = session.branchId ?? 'qa-branch-id';
    final userId = session.userId ?? 'qa-user-id';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('تأكيد إنشاء البيانات التجريبية'),
          ],
        ),
        content: const Text(
          'سيتم إنشاء 100 منتج واقعي (مع الباركود والمخزون والتكاليف والوحدات)، بالإضافة إلى 50 عميلاً بأسماء وهواتف يمنية واقعية، و 50 مورداً وشركة تجارية معتمدة.\n\nهل ترغب في المتابعة؟',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('نعم، ابدأ التوليد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _actionMessage = 'جاري توليد 100 منتج و 50 عميل و 50 مورد...';
    });

    try {
      await _seederService.seedDemoData(
        businessId: businessId,
        branchId: branchId,
        userId: userId,
      );
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم إنشاء 100 منتج و 50 عميل و 50 مورد بنجاح! يمكنك الآن تجربة نقطة البيع والمبيعات.',
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التوليد: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _actionMessage = null;
        });
      }
    }
  }

  Future<void> _handleWipeDemoData() async {
    final session = ref.read(sessionNotifierProvider);
    final businessId = session.businessId ?? 'qa-business-id';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('تأكيد تصفير وحذف البيانات'),
          ],
        ),
        content: const Text(
          'سيتم حذف المنتجات، الوحدات، المخزون، والعملاء، والموردين فقط للمتجر الحالي.\n\nلن تتأثر شجرة الحسابات أو الفروع أو حساب الدخول.\n\nهل أنت متأكد من رغبتك في المتابعة؟',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('نعم، تصفير الآن'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _actionMessage = 'جاري تصفير وحذف البيانات التجريبية...';
    });

    try {
      await _seederService.wipeDemoData(businessId: businessId);
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete_sweep_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('تم تصفير المنتجات والعملاء والموردين بنجاح.'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF334155),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التصفير: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _actionMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          SettingsHeaderWidget(
            title: 'إدارة البيانات التجريبية (Demo Data Seeder)',
            description: 'توليد منتجات وعملاء وموردين بأسماء واقعية أو تصفيرهم للاختبار السريع',
            onBackTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Loading Overlay Banner if active
                      if (_isLoading && _actionMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _actionMessage!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4F46E5),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Statistics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'إجمالي المنتجات',
                              value: _stats != null ? '${_stats!.productsCount}' : '...',
                              icon: Icons.inventory_2_rounded,
                              color: const Color(0xFF3B82F6),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              title: 'العملاء المسجلين',
                              value: _stats != null ? '${_stats!.customersCount}' : '...',
                              icon: Icons.people_alt_rounded,
                              color: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              title: 'الموردين والشركات',
                              value: _stats != null ? '${_stats!.suppliersCount}' : '...',
                              icon: Icons.local_shipping_rounded,
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Card 1: Generate Demo Data
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'توليد وتعبئة بيانات تجريبية واقعية',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'منتجات تموينية وغذائية بأسعارها ومخزونها، مع عملاء وموردين بأسماء عربية حقيقية',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FeatureItem(
                                    icon: Icons.check_circle_outline_rounded,
                                    text: '100 منتج متنوع موزعة على 8 أقسام تجارية ببيانات دقيقة ومفصلة.',
                                  ),
                                  SizedBox(height: 6),
                                  _FeatureItem(
                                    icon: Icons.check_circle_outline_rounded,
                                    text: 'تسعير كامل (سعر البيع + التكلفة الافتراضية) مع باركود ووحدات قياس (حبة، كرتون، باكت).',
                                  ),
                                  SizedBox(height: 6),
                                  _FeatureItem(
                                    icon: Icons.check_circle_outline_rounded,
                                    text: 'أرصدة مخزون افتتاحي جاهزة للبيع المباشر والفوري في نقطة البيع (POS).',
                                  ),
                                  SizedBox(height: 6),
                                  _FeatureItem(
                                    icon: Icons.check_circle_outline_rounded,
                                    text: '50 عميلاً بأسماء ثلاثية يمنية وعناوين وأرقام هواتف وسقوف ائتمانية واقعية.',
                                  ),
                                  SizedBox(height: 6),
                                  _FeatureItem(
                                    icon: Icons.check_circle_outline_rounded,
                                    text: '50 شركة ومورداً تجارياً معتمداً للتوريدات ومردودات المشتريات.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleGenerateDemoData,
                                icon: const Icon(Icons.flash_on_rounded, size: 20),
                                label: const Text(
                                  'توليد البيانات الآن (Generate Demo Data)',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Card 2: Wipe Demo Data
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.delete_sweep_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تصفير وحذف بيانات الاختبار',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'حذف المنتجات والعملاء والموردين المسجلين فقط مع بقاء الحسابات والإعدادات',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'هذا الإجراء يقوم بحذف كافة المنتجات وقوائم الأسعار والمخزون والعملاء والموردين فقط، لتنظيف النظام والبدء من جديد. لن يتم حذف الفروع أو الحسابات أو إعدادات النظام.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleWipeDemoData,
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                label: const Text(
                                  'تصفير المنتجات والعملاء والموردين',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
