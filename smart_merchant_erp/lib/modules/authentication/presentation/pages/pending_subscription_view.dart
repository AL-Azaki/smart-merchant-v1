import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/auth_provider.dart';

class PendingSubscriptionView extends ConsumerWidget {
  const PendingSubscriptionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Very light clean background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animation or Icon
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 64),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'طلبك قيد المراجعة',
                style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'لقد استلمنا طلب اشتراكك بنجاح. تقوم الإدارة حالياً بمراجعة عملية الدفع والتحويل البنكي.\nسيتم تفعيل حسابك فور تأكيد الدفع.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14, height: 1.6),
              ),
              
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تحتاج إلى مساعدة؟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('تواصل مع الدعم الفني عبر الواتساب', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondaryLight),
                  ],
                ),
              ),
              
              const SizedBox(height: 64),
              
              TextButton.icon(
                onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
