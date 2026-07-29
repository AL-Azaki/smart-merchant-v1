import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class UnitsOfMeasureView extends StatefulWidget {
  const UnitsOfMeasureView({super.key});

  @override
  State<UnitsOfMeasureView> createState() => _UnitsOfMeasureViewState();
}

class _UnitsOfMeasureViewState extends State<UnitsOfMeasureView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _units = [
    {'id': 'u1', 'name': 'قطعة', 'symbol': 'قطعة', 'desc': 'وحدة مفردة', 'is_default': true, 'is_active': true},
    {'id': 'u2', 'name': 'كرتون', 'symbol': 'كرتون', 'desc': 'كرتون (12 قطعة)', 'is_default': false, 'is_active': true},
    {'id': 'u3', 'name': 'كيلو', 'symbol': 'كغ', 'desc': 'كيلوجرام', 'is_default': false, 'is_active': true},
    {'id': 'u4', 'name': 'لتر', 'symbol': 'لتر', 'desc': 'لتر سائل', 'is_default': false, 'is_active': true},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _units;
    final q = _searchQuery.toLowerCase();
    return _units.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final symbol = (u['symbol'] ?? '').toString().toLowerCase();
      final desc = (u['desc'] ?? '').toString().toLowerCase();
      return name.contains(q) || symbol.contains(q) || desc.contains(q);
    }).toList();
  }

  void _setDefault(String id) {
    setState(() {
      for (var u in _units) {
        u['is_default'] = u['id'] == id;
      }
    });
  }

  void _confirmDelete(Map<String, dynamic> unit) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final surface = isDark ? AppColors.surfaceDark : Colors.white;
        final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: surface,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تأكيد الحذف',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'هل أنت متأكد من أنك تريد حذف "${unit['name']}"؟ لا يمكنك التراجع عن هذا الإجراء.',
                            style: TextStyle(fontSize: 14, color: textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('إلغاء', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _units.removeWhere((u) => u['id'] == unit['id']);
                            });
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('حذف نهائي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFormSheet({Map<String, dynamic>? unit}) {
    final nameController = TextEditingController(text: (unit?['name'] as String?) ?? '');
    final symbolController = TextEditingController(text: (unit?['symbol'] as String?) ?? '');
    final descController = TextEditingController(text: (unit?['desc'] as String?) ?? '');
    bool isDefault = (unit?['is_default'] as bool?) ?? false;
    bool isActive = (unit?['is_active'] as bool?) ?? true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surface = isDark ? AppColors.surfaceDark : Colors.white;
        final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
        final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
        final inputBg = isDark ? const Color(0xFF1E293B) : Colors.white;

        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sheet Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border(bottom: BorderSide(color: borderColor)),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.scale_rounded, color: Color(0xFF3B82F6), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                unit != null ? 'تعديل الوحدة' : 'إضافة وحدة جديدة',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: textPrimary, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Form Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('اسم الوحدة *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputBg,
                              hintText: 'مثال: قطعة، كرتون، كيلو',
                              hintStyle: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                            ),
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الرمز / الاختصار *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: symbolController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: inputBg,
                                        hintText: 'مثال: قطعة، كرتون، كغ',
                                        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 13),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                                      ),
                                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الوصف', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: descController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: inputBg,
                                        hintText: 'الوصف أو التفاصيل',
                                        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 13),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                                      ),
                                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              InkWell(
                                onTap: () => setModalState(() => isActive = !isActive),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: isActive,
                                        activeColor: const Color(0xFF2563EB),
                                        onChanged: (val) => setModalState(() => isActive = val ?? true),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('وحدة نشطة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              InkWell(
                                onTap: () => setModalState(() => isDefault = !isDefault),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: isDefault,
                                        activeColor: const Color(0xFF2563EB),
                                        onChanged: (val) => setModalState(() => isDefault = val ?? false),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('افتراضية النظام', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('إلغاء', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textSecondary)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (nameController.text.trim().isEmpty) return;
                                      setState(() {
                                        if (isDefault) {
                                          for (var u in _units) {
                                            u['is_default'] = false;
                                          }
                                        }
                                        if (unit != null) {
                                          unit['name'] = nameController.text.trim();
                                          unit['symbol'] = symbolController.text.trim();
                                          unit['desc'] = descController.text.trim();
                                          unit['is_default'] = isDefault;
                                          unit['is_active'] = isActive;
                                        } else {
                                          _units.insert(0, {
                                            'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
                                            'name': nameController.text.trim(),
                                            'symbol': symbolController.text.trim(),
                                            'desc': descController.text.trim(),
                                            'is_default': isDefault,
                                            'is_active': isActive,
                                          });
                                        }
                                      });
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: const Text('حفظ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final items = _filtered;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('وحدات القياس', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.scale_rounded, color: Color(0xFF3B82F6), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'وحدات القياس',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary),
                              ),
                              Text(
                                '${items.length} وحدة',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _showFormSheet(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('إضافة وحدة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Search Bar
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن وحدة...',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 145,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final isDefault = item['is_default'] == true;
                        final isActive = item['is_active'] == true;

                        return Container(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDefault ? const Color(0xFFF59E0B) : borderColor,
                              width: isDefault ? 2 : 1.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(left: 16, right: 16, top: isDefault ? 24 : 16, bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: borderColor),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            (item['symbol'] ?? '').toString(),
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textPrimary),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (item['name'] ?? '').toString(),
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                (item['desc'] ?? '').toString(),
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isActive ? const Color(0xFF10B981).withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isActive ? 'نشط' : 'غير نشط',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: isActive ? const Color(0xFF10B981) : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                      border: Border(top: BorderSide(color: borderColor)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (!isDefault)
                                          InkWell(
                                            onTap: () => _setDefault(item['id'].toString()),
                                            child: Row(
                                              children: [
                                                Icon(Icons.star_outline_rounded, size: 14, color: textSecondary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'تعيين كافتراضية',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                                              onPressed: () => _showFormSheet(unit: item),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 16),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                              onPressed: () => _confirmDelete(item),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isDefault)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(14),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                                        SizedBox(width: 4),
                                        Text(
                                          'افتراضية النظام',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
