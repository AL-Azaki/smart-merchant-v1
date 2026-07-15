import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

class ReturnsModal extends StatelessWidget {
  const ReturnsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.assignment_return_rounded, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('مرتجعات المبيعات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 64, color: AppColors.textSecondaryLight.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('لا توجد فواتير مرتجعة اليوم', style: TextStyle(fontSize: 16, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('مرتجع جديد', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
