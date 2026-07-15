// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Merchant';

  @override
  String get authGateWelcome => 'Welcome to Smart Management';

  @override
  String get authGateSubtitle =>
      'Discover the easiest way to manage your sales, inventory, and accounts securely and professionally.';

  @override
  String get startFreeTrial => 'Start Free Trial';

  @override
  String get login => 'Login';

  @override
  String get home => 'Home';

  @override
  String get sales => 'Sales';

  @override
  String get inventory => 'Inventory';

  @override
  String get accounting => 'Finance';

  @override
  String get settings => 'Settings';

  @override
  String get financialSnapshot => 'Financial Snapshot';

  @override
  String get todaysSales => 'Today\'s Sales';

  @override
  String get cashBalance => 'Cash Balance';

  @override
  String get payables => 'Payables';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get quickActionsSubtitle =>
      'Execute tasks with one touch, without complex menus';

  @override
  String get salesInvoice => 'Sales Invoice';

  @override
  String get salesInvoiceDesc => 'Quick POS';

  @override
  String get purchaseInvoice => 'Purchase Invoice';

  @override
  String get purchaseInvoiceDesc => 'Enter inventory';

  @override
  String get receiptVoucher => 'Receipt Voucher';

  @override
  String get receiptVoucherDesc => 'Receive cash';

  @override
  String get paymentVoucher => 'Payment Voucher';

  @override
  String get paymentVoucherDesc => 'Pay cash';

  @override
  String get searchProducts => 'Search for a product...';

  @override
  String get allCategories => 'All';

  @override
  String get invoiceNumber => 'Invoice No.';

  @override
  String get chooseCustomer => 'Choose Customer';

  @override
  String get addVoucher => 'Add Voucher';

  @override
  String get hold => 'Hold';

  @override
  String heldInvoices(Object count) {
    return 'Held ($count)';
  }

  @override
  String get returns => 'Returns';

  @override
  String get cart => 'Cart';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get total => 'Total';

  @override
  String get pay => 'Pay';

  @override
  String get vat => 'Inc. VAT';

  @override
  String get productOutOfStock => 'Out of stock';

  @override
  String get salesAndOrders => 'Sales & Orders';

  @override
  String get newInvoicePos => 'New Invoice';

  @override
  String get salesInvoices => 'Sales Invoices';

  @override
  String get ecommerceOrders => 'eCommerce Orders';
}
