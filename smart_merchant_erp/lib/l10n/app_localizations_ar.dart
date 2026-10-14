// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'التاجر الذكي';

  @override
  String get authGateWelcome => 'مرحباً بك في عالم الإدارة الذكية';

  @override
  String get authGateSubtitle =>
      'اكتشف أسهل طريقة لإدارة مبيعاتك ومخزونك وحساباتك من مكان واحد بكل أمان واحترافية.';

  @override
  String get startFreeTrial => 'ابدأ تجربتك المجانية';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get home => 'الرئيسية';

  @override
  String get sales => 'المبيعات';

  @override
  String get inventory => 'المخزون';

  @override
  String get accounting => 'المالية';

  @override
  String get settings => 'الإعدادات';

  @override
  String get financialSnapshot => 'نظرة مالية سريعة';

  @override
  String get todaysSales => 'مبيعات اليوم';

  @override
  String get cashBalance => 'رصيد الصندوق';

  @override
  String get payables => 'الموردون (مستحقات)';

  @override
  String get quickActions => 'العمليات السريعة';

  @override
  String get quickActionsSubtitle =>
      'نفذ مهامك بلمسة واحدة دون الدخول للقوائم المعقدة';

  @override
  String get salesInvoice => 'فاتورة مبيعات';

  @override
  String get salesInvoiceDesc => 'نقطة بيع سريعة';

  @override
  String get purchaseInvoice => 'فاتورة مشتريات';

  @override
  String get purchaseInvoiceDesc => 'إدخال بضاعة للمخزن';

  @override
  String get receiptVoucher => 'سند قبض';

  @override
  String get receiptVoucherDesc => 'استلام دفعة نقدية';

  @override
  String get paymentVoucher => 'سند صرف';

  @override
  String get paymentVoucherDesc => 'صرف دفعة نقدية';

  @override
  String get searchProducts => 'ابحث عن منتج...';

  @override
  String get allCategories => 'الكل';

  @override
  String get invoiceNumber => 'رقم الفاتورة';

  @override
  String get chooseCustomer => 'اختر العميل';

  @override
  String get addVoucher => 'إضافة سند';

  @override
  String get hold => 'تعليق';

  @override
  String heldInvoices(Object count) {
    return 'معلقة ($count)';
  }

  @override
  String get returns => 'المرتجعات';

  @override
  String get cart => 'السلة';

  @override
  String get cartEmpty => 'السلة فارغة';

  @override
  String get total => 'الإجمالي';

  @override
  String get pay => 'دفع';

  @override
  String get vat => 'شامل الضريبة';

  @override
  String get productOutOfStock => 'نفدت الكمية';

  @override
  String get salesAndOrders => 'المبيعات والطلبات';

  @override
  String get newInvoicePos => 'فاتورة جديدة';

  @override
  String get salesInvoices => 'فواتير المبيعات';

  @override
  String get ecommerceOrders => 'طلبات المتجر الإلكتروني';
}
