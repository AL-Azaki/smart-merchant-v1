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
  
  final List<Map<String, dynamic>> _businessTypes = [
    {'id': 'grocery', 'label': 'بقالة/تموينات', 'icon': Icons.shopping_cart_rounded},
    {'id': 'retail', 'label': 'تجزئة', 'icon': Icons.storefront_rounded},
    {'id': 'wholesale', 'label': 'جملة', 'icon': Icons.inventory_2_rounded},
    {'id': 'restaurant', 'label': 'مطعم', 'icon': Icons.restaurant_rounded},
    {'id': 'cafe', 'label': 'مقهى', 'icon': Icons.local_cafe_rounded},
    {'id': 'pharmacy', 'label': 'صيدلية', 'icon': Icons.local_pharmacy_rounded},
    {'id': 'electronics', 'label': 'إلكترونيات', 'icon': Icons.devices_rounded},
    {'id': 'fashion', 'label': 'أزياء', 'icon': Icons.checkroom_rounded},
    {'id': 'other', 'label': 'أخرى', 'icon': Icons.business_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D9488), 
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C8A7E), Color(0xFF0D9488), Color(0xFF14B8A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header Area
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // We hide the back button since this is a required step after registration
                        const SizedBox(width: 40), 
                        // Step Indicators
                        Row(
                          children: [
                            _buildStepDot(true, true),
                            const SizedBox(width: 6),
                            _buildStepDot(true, false),
                            const SizedBox(width: 6),
                            _buildStepDot(false, false),
                          ],
                        ),
                        const SizedBox(width: 40), 
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('إعداد النشاط التجاري', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('أدخل بيانات نشاطك التجاري ليتم تخصيص النظام لك', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Form Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('نوع النشاط التجاري *', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: _businessTypes.length,
                        itemBuilder: (context, index) {
                          final type = _businessTypes[index];
                          final isSelected = _selectedBusinessType == type['id'];
                          
                          return InkWell(
                            onTap: () => setState(() => _selectedBusinessType = type['id']),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0D9488).withOpacity(0.1) : AppColors.backgroundLight,
                                border: Border.all(color: isSelected ? const Color(0xFF0D9488) : AppColors.borderLight, width: isSelected ? 1.5 : 1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(type['icon'], color: isSelected ? const Color(0xFF0D9488) : AppColors.textSecondaryLight, size: 24),
                                  const SizedBox(height: 6),
                                  Text(type['label'], style: TextStyle(color: isSelected ? const Color(0xFF0D9488) : AppColors.textSecondaryLight, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildTextField('اسم النشاط التجاري *', 'مثال: متجر النور'),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(child: _buildTextField('رقم الهاتف', '+967...', textDirection: TextDirection.ltr, keyboardType: TextInputType.phone)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('البريد الإلكتروني', 'biz@...', textDirection: TextDirection.ltr, keyboardType: TextInputType.emailAddress)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField('الدولة *', 'اليمن', ['اليمن', 'السعودية', 'مصر']),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('المدينة *', 'صنعاء')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextField('العنوان التفصيلي', 'شارع، حي، مبنى...'),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField('العملة الأساسية *', 'YER (الريال اليمني)', ['YER (الريال اليمني)', 'USD (الدولار الأمريكي)', 'SAR (الريال السعودي)']),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField('بداية السنة المالية', 'يناير', ['يناير', 'فبراير', 'مارس']),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      ElevatedButton(
                        onPressed: () {
                          // Trigger Trial State
                          ref.read(authNotifierProvider.notifier).completeSetup();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: const Color(0xFF0D9488),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: const Color(0xFF0D9488).withOpacity(0.4),
                        ),
                        child: const Text('إنشاء النشاط والمتابعة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(bool isActive, bool isCompleted) {
    return Container(
      width: isActive ? 24 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.white : (isActive ? Colors.white : Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {TextDirection? textDirection, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          textDirection: textDirection,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondaryLight),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight)),
                );
              }).toList(),
              onChanged: (val) {},
            ),
          ),
        ),
      ],
    );
  }
}
