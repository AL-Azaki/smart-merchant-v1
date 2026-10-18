import '../../../../database/daos/accounting_dao.dart' show ChartOfAccountFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../app/di/getit_instance.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../accounting/domain/repositories/accounting_repository.dart';
import '../../../accounting/presentation/providers/accounting_provider.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../providers/treasury_provider.dart';

enum TreasuryItemType {
  cash,
  wallet,
  bank,
}

class AddBankOrCashDialog extends ConsumerStatefulWidget {
  final TreasuryItemType initialType;

  const AddBankOrCashDialog({
    super.key,
    this.initialType = TreasuryItemType.cash,
  });

  /// Factory constructor for backward compatibility with initialIsBank flag
  factory AddBankOrCashDialog.legacy({
    Key? key,
    bool initialIsBank = false,
  }) {
    return AddBankOrCashDialog(
      key: key,
      initialType: initialIsBank ? TreasuryItemType.bank : TreasuryItemType.cash,
    );
  }

  @override
  ConsumerState<AddBankOrCashDialog> createState() => _AddBankOrCashDialogState();
}

class _AddBankOrCashDialogState extends ConsumerState<AddBankOrCashDialog> {
  final _formKey = GlobalKey<FormState>();

  late TreasuryItemType _selectedType;
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0.0');

  String _selectedWalletProvider = 'كريمي جوال';
  static const List<String> _yemeniWalletProviders = [
    'كريمي جوال',
    'محفظة كاش',
    'محفظة جيب',
    'محفظة ون كاش',
    'محفظة فلوسك',
    'محفظة جوالي',
    'محفظة يمن كاش',
    'محفظة إلكترونية أخرى',
  ];

  String? _selectedCurrencyId;
  List<CurrencyEntity> _currencies = [];
  bool _isLoadingCurrencies = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _applyDefaultsForType(_selectedType);
    _loadCurrencies();
  }

  void _applyDefaultsForType(TreasuryItemType type) {
    if (type == TreasuryItemType.wallet) {
      if (_nameController.text.isEmpty) {
        _nameController.text = '$_selectedWalletProvider الرئيسي';
      }
      _bankNameController.text = _selectedWalletProvider;
    } else if (type == TreasuryItemType.bank) {
      if (_bankNameController.text.isEmpty) {
        _bankNameController.text = 'بنك الكريمي الإسلامي';
      }
    }
  }

  Future<void> _loadCurrencies() async {
    try {
      final coreRepo = ref.read(coreRepositoryProvider);
      final currencies = await coreRepo.listCurrencies(isActive: true);
      if (mounted) {
        setState(() {
          _currencies = currencies;
          if (currencies.isNotEmpty) {
            final base = currencies.firstWhere(
              (c) => c.isBaseCurrency,
              orElse: () => currencies.first,
            );
            _selectedCurrencyId = base.id;
          }
          _isLoadingCurrencies = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedCurrencyId = 'YER';
          _isLoadingCurrencies = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) {
      _showSnack('جلسة المستخدم غير نشطة أو مفقودة');
      return;
    }

    final businessId = session.businessId!;
    final name = _nameController.text.trim();
    final bankName = _bankNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final openingBalance = double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;
    final currencyId = _selectedCurrencyId ?? 'YER';

    setState(() => _isSubmitting = true);

    try {
      final db = getIt<AppDatabase>();
      final accountingRepo = getIt<AccountingRepository>();
      final treasuryRepo = getIt<TreasuryRepository>();
      const uuid = Uuid();

      // Safeguard: Guarantee valid branchId from database to prevent foreign key constraint failure
      final existingBranches = await (db.select(db.branches)
            ..where((b) => b.businessId.equals(businessId)))
          .get();

      String effectiveBranchId;
      if (existingBranches.isNotEmpty) {
        final matched = existingBranches.where((b) => b.id == session.branchId).firstOrNull;
        effectiveBranchId = matched != null ? matched.id : existingBranches.first.id;
      } else {
        effectiveBranchId = 'branch-$businessId';
        await db.into(db.branches).insertOnConflictUpdate(
          BranchesCompanion.insert(
            id: effectiveBranchId,
            businessId: businessId,
            branchName: 'الفرع الرئيسي',
            branchCode: 'MAIN',
            isActive: const drift.Value(true),
          ),
        );
      }

      // 1. Determine Chart of Account Code and Category
      final String prefix;
      final String category;
      final String paymentType;

      switch (_selectedType) {
        case TreasuryItemType.cash:
          prefix = '11101';
          category = 'Cash';
          paymentType = 'Cash';
          break;
        case TreasuryItemType.wallet:
          prefix = '11103';
          category = 'DigitalWallet';
          paymentType = 'DigitalWallet';
          break;
        case TreasuryItemType.bank:
          prefix = '11102';
          category = 'Bank';
          paymentType = 'Bank';
          break;
      }

      final existingAccounts = await accountingRepo.listChartOfAccounts(
        ChartOfAccountFilter(businessId: businessId),
      );
      final matchingAccounts = existingAccounts
          .where((a) => a.accountCode.startsWith(prefix))
          .toList();

      int nextSubNumber = matchingAccounts.length + 1;
      String newCode = '$prefix${nextSubNumber.toString().padLeft(2, '0')}';
      while (existingAccounts.any((a) => a.accountCode == newCode)) {
        nextSubNumber++;
        newCode = '$prefix${nextSubNumber.toString().padLeft(2, '0')}';
      }

      // 2. Insert Chart of Account
      final coaId = uuid.v4();
      await accountingRepo.insertChartOfAccount(
        ChartOfAccountsCompanion.insert(
          id: coaId,
          businessId: businessId,
          accountCode: newCode,
          accountName: name,
          accountTypeId: 1,
          accountCategory: drift.Value(category),
          normalBalance: 'Debit',
          allowPosting: const drift.Value(true),
          isActive: const drift.Value(true),
        ),
      );

      // 3. Insert Treasury Entity
      if (_selectedType == TreasuryItemType.cash) {
        final cashId = uuid.v4();
        await treasuryRepo.insertCashRegister(
          CashRegistersCompanion.insert(
            id: cashId,
            businessId: businessId,
            branchId: effectiveBranchId,
            currencyId: currencyId,
            registerName: name,
            status: const drift.Value('Open'),
            currentBalance: drift.Value(openingBalance),
          ),
        );
      } else {
        // Both Wallet and Bank are stored in BankAccounts table with distinct description & metadata
        final bankId = uuid.v4();
        final isWallet = _selectedType == TreasuryItemType.wallet;
        final institution = isWallet
            ? _selectedWalletProvider
            : (bankName.isNotEmpty ? bankName : name);

        await treasuryRepo.insertBankAccount(
          BankAccountsCompanion.insert(
            id: bankId,
            businessId: businessId,
            branchId: drift.Value(effectiveBranchId),
            currencyId: currencyId,
            accountNumber: accountNumber.isNotEmpty ? accountNumber : newCode,
            bankName: institution,
            displayName: drift.Value(name),
            description: drift.Value(isWallet ? 'WALLET' : 'BANK'),
            status: const drift.Value('Active'),
            openingBalance: drift.Value(openingBalance),
            currentBalance: drift.Value(openingBalance),
          ),
        );
      }

      // 4. Insert Payment Method linked to this Chart of Account
      final typePrefix = _selectedType == TreasuryItemType.cash
          ? 'CASH'
          : (_selectedType == TreasuryItemType.wallet ? 'WALLET' : 'BANK');

      final methodCode = '${typePrefix}_${DateTime.now().millisecondsSinceEpoch % 100000}';

      await treasuryRepo.insertPaymentMethod(
        PaymentMethodsCompanion.insert(
          id: uuid.v4(),
          businessId: businessId,
          chartOfAccountId: coaId,
          methodCode: methodCode,
          methodName: name,
          paymentType: paymentType,
          isActive: const drift.Value(true),
        ),
      );

      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);

      // Refresh all providers
      ref.invalidate(cashRegistersStreamProvider);
      ref.invalidate(bankAccountsStreamProvider);
      ref.invalidate(chartOfAccountsNotifierProvider);
      ref.invalidate(trialBalanceReportProvider());

      Navigator.of(context).pop(true);

      final successMsg = switch (_selectedType) {
        TreasuryItemType.cash => 'تمت إضافة الصندوق النقدي بنجاح',
        TreasuryItemType.wallet => 'تمت إضافة المحفظة الإلكترونية بنجاح',
        TreasuryItemType.bank => 'تمت إضافة الحساب البنكي بنجاح',
      };
      _showSnack(successMsg);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      _showSnack('حدث خطأ أثناء الإضافة: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final themeColor = switch (_selectedType) {
      TreasuryItemType.cash => const Color(0xFF06B6D4),
      TreasuryItemType.wallet => const Color(0xFF10B981),
      TreasuryItemType.bank => const Color(0xFF3B82F6),
    };

    final headerTitle = switch (_selectedType) {
      TreasuryItemType.cash => 'إضافة صندوق نقدي / خزينة',
      TreasuryItemType.wallet => 'إضافة محفظة إلكترونية',
      TreasuryItemType.bank => 'إضافة حساب بنكي / مصرفي',
    };

    final headerIcon = switch (_selectedType) {
      TreasuryItemType.cash => Icons.point_of_sale_rounded,
      TreasuryItemType.wallet => Icons.account_balance_wallet_rounded,
      TreasuryItemType.bank => Icons.account_balance_rounded,
    };

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dialog Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(headerIcon, color: themeColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ربط مباشر مع شجرة الحسابات وطرق الدفع',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── 3-Way Type Selector (Cash, Wallet, Bank) ──
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // 1. Cash Box
                      Expanded(
                        child: _buildTypeSegment(
                          title: 'صندوق نقدي',
                          type: TreasuryItemType.cash,
                          icon: Icons.point_of_sale_rounded,
                          activeColor: const Color(0xFF06B6D4),
                          isDark: isDark,
                          surface: surface,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 2. Electronic Wallet
                      Expanded(
                        child: _buildTypeSegment(
                          title: 'محفظة إلكترونية',
                          type: TreasuryItemType.wallet,
                          icon: Icons.account_balance_wallet_rounded,
                          activeColor: const Color(0xFF10B981),
                          isDark: isDark,
                          surface: surface,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 3. Bank Account
                      Expanded(
                        child: _buildTypeSegment(
                          title: 'حساب بنكي',
                          type: TreasuryItemType.bank,
                          icon: Icons.account_balance_rounded,
                          activeColor: const Color(0xFF3B82F6),
                          isDark: isDark,
                          surface: surface,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Wallet Provider Selection if Wallet ──
                if (_selectedType == TreasuryItemType.wallet) ...[
                  Text(
                    'مزود المحفظة الإلكترونية في اليمن *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedWalletProvider,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: _yemeniWalletProviders
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p, style: TextStyle(fontSize: 13, color: textPrimary)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedWalletProvider = val;
                          _nameController.text = '$val الرئيسي';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Name Field ──
                Text(
                  _selectedType == TreasuryItemType.cash
                      ? 'اسم الصندوق / الخزينة *'
                      : (_selectedType == TreasuryItemType.wallet
                          ? 'اسم المحفظة للعرض *'
                          : 'اسم الحساب البنكي للعرض *'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: _selectedType == TreasuryItemType.cash
                        ? 'مثال: صندوق الكاشير 1، خزينة المحل الرئيسية'
                        : (_selectedType == TreasuryItemType.wallet
                            ? 'مثال: محفظة الكريمي مميز، كاش الفرع'
                            : 'مثال: حساب بنك الكريمي فرع التحرير'),
                    prefixIcon: Icon(headerIcon, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'يرجى إدخال الاسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Bank or Wallet Specific Fields ──
                if (_selectedType == TreasuryItemType.wallet) ...[
                  Text(
                    'رقم هاتف / حساب المحفظة *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'مثال: 777123456 أو رقم الحساب التجاري',
                      prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال رقم الهاتف أو رقم حساب المحفظة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ] else if (_selectedType == TreasuryItemType.bank) ...[
                  Text(
                    'اسم البنك / المصرف *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: InputDecoration(
                      hintText: 'مثال: بنك التضامن الإسلامي، بنك الكريمي...',
                      prefixIcon: const Icon(Icons.account_balance_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال اسم البنك';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'رقم الحساب البنكي / الآيبان (IBAN) *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _accountNumberController,
                    decoration: InputDecoration(
                      hintText: 'مثال: 123456789 أو الآيبان',
                      prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال رقم الحساب البنكي';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Currency and Opening Balance Row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'العملة *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (_isLoadingCurrencies)
                            const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: _selectedCurrencyId,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.monetization_on_outlined, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: _currencies.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(
                                    '${c.currencyNameAr} (${c.id})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCurrencyId = val);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الرصيد الافتتاحي',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _openingBalanceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Actions ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: Text('إلغاء', style: TextStyle(color: textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'حفظ وتثبيت',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required String title,
    required TreasuryItemType type,
    required IconData icon,
    required Color activeColor,
    required bool isDark,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _applyDefaultsForType(type);
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? textPrimary : textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
