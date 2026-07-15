import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/auth_provider.dart';

class LockedSubscriptionView extends ConsumerStatefulWidget {
  const LockedSubscriptionView({super.key});

  @override
  ConsumerState<LockedSubscriptionView> createState() => _LockedSubscriptionViewState();
}

class _LockedSubscriptionViewState extends ConsumerState<LockedSubscriptionView> {
  int _selectedPlanIndex = 1; // Default to Pro plan

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'الأساسية',
      'price': '9,000',
      'duration': 'شهرياً',
      'features': ['1 فرع', '2 مستخدمين', 'مبيعات ومخزون مبسط'],
      'isPopular': false,
    },
    {
      'name': 'الاحترافية',
      'price': '15,000',
      'duration': 'شهرياً',
      'features': ['3 فروع', '5 مستخدمين', 'مبيعات، مخزون، محاسبة'],
      'isPopular': true,
    },
    {
      'name': 'المؤسسات',
      'price': '25,000',
      'duration': 'شهرياً',
      'features': ['فروع غير محدودة', 'مستخدمين غير محدود', 'جميع الأنظمة والتقارير المتقدمة'],
      'isPopular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep dark premium color
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock_rounded, color: AppColors.error, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('انتهت صلاحية اشتراكك', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('نأمل أن تكون قد استمتعت بتجربتك. يرجى تجديد الاشتراك للاستمرار في استخدام النظام.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5)),
                ],
              ),
            ),
            
            // Plans List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  final isSelected = _selectedPlanIndex == index;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPlanIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                        border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFF334155), width: isSelected ? 2 : 1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20)] : null,
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(plan['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isSelected ? AppColors.primary : Colors.white30, width: 2),
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                      ),
                                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(plan['price'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                    const SizedBox(width: 4),
                                    Text('ر.ي / ${plan['duration']}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Color(0xFF334155)),
                                const SizedBox(height: 12),
                                ...((plan['features'] as List<String>).map((f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                                      const SizedBox(width: 8),
                                      Text(f, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                                    ],
                                  ),
                                )).toList()),
                              ],
                            ),
                          ),
                          if (plan['isPopular'])
                            Positioned(
                              top: 0, right: 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                                ),
                                child: const Text('الأكثر طلباً', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Action
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _showPaymentInstructionsSheet,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('متابعة لتأكيد الاشتراك', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                    child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white60)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showPaymentInstructionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            const Text('تأكيد الاشتراك (تحويل بنكي)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('يرجى تحويل المبلغ المطلوب إلى أحد الحسابات التالية، ثم اضغط على "تأكيد إرسال الطلب".', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            
            _buildBankCard('بنك الكريمي', 'المميز للتقنية', '123456789'),
            const SizedBox(height: 12),
            _buildBankCard('بنك التضامن', 'المميز للتقنية', '987654321'),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(authNotifierProvider.notifier).requestSubscription();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('قمت بالتحويل، أرسل الطلب للإدارة', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24), // For safe area
          ],
        ),
      ),
    );
  }

  Widget _buildBankCard(String bank, String name, String account) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bank, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('الاسم: $name', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                Text('الحساب: $account', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
