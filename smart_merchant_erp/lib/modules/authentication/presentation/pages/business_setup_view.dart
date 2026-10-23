import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/auth_provider.dart';

class BusinessSetupView extends ConsumerStatefulWidget {
  const BusinessSetupView({super.key});

  @override
  ConsumerState<BusinessSetupView> createState() => _BusinessSetupViewState();
}

class _BusinessSetupViewState extends ConsumerState<BusinessSetupView> {
  String _selectedBusinessType = 'retail';
  String _selectedCity = 'صنعاء';
  String _selectedInstallmentPlan = '1_payment';
  bool _isLoading = false;

  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  final List<Map<String, dynamic>> _businessTypes = [
    {'id': 'grocery', 'label': 'بقالة وتموينات', 'icon': Icons.shopping_cart_rounded},
    {'id': 'retail', 'label': 'تجزئة عامة', 'icon': Icons.storefront_rounded},
    {'id': 'wholesale', 'label': 'جملة ومستودعات', 'icon': Icons.inventory_2_rounded},
    {'id': 'restaurant', 'label': 'مطاعم وكافيهات', 'icon': Icons.restaurant_rounded},
    {'id': 'pharmacy', 'label': 'صيدلية وعناية', 'icon': Icons.local_pharmacy_rounded},
    {'id': 'electronics', 'label': 'هواتف وإلكترونيات', 'icon': Icons.devices_rounded},
    {'id': 'fashion', 'label': 'أزياء وملابس', 'icon': Icons.checkroom_rounded},
    {'id': 'other', 'label': 'نشاط تجاري آخر', 'icon': Icons.business_rounded},
  ];

  final List<String> _cities = [
    'صنعاء',
    'عدن',
    'تعز',
    'إب',
    'حضرموت',
    'الحديدة',
    'مدينة أخرى',
  ];

  final List<Map<String, String>> _installmentPlans = [
    {
      'id': '1_payment',
      'title': 'دفعة سنوية واحدة',
      'subtitle': 'سداد سنوي كامل (الأكثر طلباً)',
      'badge': 'موصى به',
    },
    {
      'id': '2_installments',
      'title': 'دفعتان (نصف سنوي)',
      'subtitle': 'قسط كل 6 أشهر',
      'badge': '',
    },
    {
      'id': '3_installments',
      'title': '3 دفعات ميسرة',
      'subtitle': 'قسط كل 4 أشهر',
      'badge': '',
    },
    {
      'id': '4_installments',
      'title': '4 دفعات (ربع سنوي)',
      'subtitle': 'قسط كل 3 أشهر',
      'badge': 'مرونة قصوى',
    },
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteSetup() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).completeSetup({
        'business_type': _selectedBusinessType,
        'business_name': _businessNameController.text.trim().isNotEmpty
            ? _businessNameController.text.trim()
            : 'متجري',
        'primary_phone': _phoneController.text.trim(),
        'primary_email': _emailController.text.trim(),
        'city': _selectedCity,
        'address': _addressController.text.trim(),
        'installment_plan': _selectedInstallmentPlan,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D9488),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E2B), Color(0xFF0F766E), Color(0xFF0D9488)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Top Bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        // Step Indicator (Step 2 of 2)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'الخطوة 2 من 2: تخصيص نشاطك',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'تخصيص نشاطك التجاري',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر نشاطك التجاري وجدول الاشتراك لتجهيز النظام لك مباشرة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Form Content Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111C2F) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Business Activity (Smart Compact Chips)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'نوع النشاط التجاري *',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'اختر نشاطك لتهيئة الأصناف',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Smart Horizontal Scrolling Chips (Saves 75% height!)
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _businessTypes.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final type = _businessTypes[index];
                            final isSelected = _selectedBusinessType == type['id'];

                            return InkWell(
                              onTap: () => setState(() => _selectedBusinessType = type['id'] as String),
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0D9488)
                                      : (isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0D9488)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      type['icon'] as IconData,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      type['label'] as String,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section 2: City / Location (Quick Pills)
                      Text(
                        'المدينة أو المحافظة *',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _cities.map((city) {
                          final isSelected = _selectedCity == city;
                          return ChoiceChip(
                            label: Text(city),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCity = city),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                            selectedColor: const Color(0xFF0D9488),
                            backgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF0D9488)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // Section 3: Subscription & Installment Plan
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0A1C2E) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBBF7D0),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: Color(0xFF0D9488),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'الاشتراك السنوي في تاجركم',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'شامل نقاط البيع، المخزون، المزامنة، وتطبيق الجوال',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'اختر خطة تسديد الاشتراك السنوي المناسبة لك:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Installment Options (Radio Tiles)
                            ...(_installmentPlans.map((plan) {
                              final isSelected = _selectedInstallmentPlan == plan['id'];
                              return InkWell(
                                onTap: () => setState(() => _selectedInstallmentPlan = plan['id']!),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? const Color(0xFF0D3330) : const Color(0xFFCCFBF1))
                                        : (isDark ? const Color(0xFF0B1220) : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0D9488)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: isSelected
                                            ? const Color(0xFF0D9488)
                                            : const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan['title']!,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                              ),
                                            ),
                                            Text(
                                              plan['subtitle']!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (plan['badge']!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D9488),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            plan['badge']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            })),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit CTA: Direct Entry
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleCompleteSetup,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'إتمام الإعداد وإرسال الطلب للاعتماد',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
