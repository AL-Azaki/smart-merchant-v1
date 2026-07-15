import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_provider.dart';

class CustomerAddModal extends ConsumerStatefulWidget {
  const CustomerAddModal({super.key});

  @override
  ConsumerState<CustomerAddModal> createState() => _CustomerAddModalState();
}

class _CustomerAddModalState extends ConsumerState<CustomerAddModal> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_add_rounded, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('إضافة عميل جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم العميل / الشركة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'رقم الهاتف (اختياري)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  // تحديث السلة لتحديد العميل الجديد مباشرة
                  ref.read(posNotifierProvider.notifier).setCustomer(_nameController.text.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('حفظ واختيار العميل', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
