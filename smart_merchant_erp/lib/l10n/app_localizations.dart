import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'التاجر الذكي'**
  String get appTitle;

  /// No description provided for @authGateWelcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في عالم الإدارة الذكية'**
  String get authGateWelcome;

  /// No description provided for @authGateSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف أسهل طريقة لإدارة مبيعاتك ومخزونك وحساباتك من مكان واحد بكل أمان واحترافية.'**
  String get authGateSubtitle;

  /// No description provided for @startFreeTrial.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ تجربتك المجانية'**
  String get startFreeTrial;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @sales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get sales;

  /// No description provided for @inventory.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get inventory;

  /// No description provided for @accounting.
  ///
  /// In ar, this message translates to:
  /// **'المالية'**
  String get accounting;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @financialSnapshot.
  ///
  /// In ar, this message translates to:
  /// **'نظرة مالية سريعة'**
  String get financialSnapshot;

  /// No description provided for @todaysSales.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات اليوم'**
  String get todaysSales;

  /// No description provided for @cashBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيد الصندوق'**
  String get cashBalance;

  /// No description provided for @payables.
  ///
  /// In ar, this message translates to:
  /// **'الموردون (مستحقات)'**
  String get payables;

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'العمليات السريعة'**
  String get quickActions;

  /// No description provided for @quickActionsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نفذ مهامك بلمسة واحدة دون الدخول للقوائم المعقدة'**
  String get quickActionsSubtitle;

  /// No description provided for @salesInvoice.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة مبيعات'**
  String get salesInvoice;

  /// No description provided for @salesInvoiceDesc.
  ///
  /// In ar, this message translates to:
  /// **'نقطة بيع سريعة'**
  String get salesInvoiceDesc;

  /// No description provided for @purchaseInvoice.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة مشتريات'**
  String get purchaseInvoice;

  /// No description provided for @purchaseInvoiceDesc.
  ///
  /// In ar, this message translates to:
  /// **'إدخال بضاعة للمخزن'**
  String get purchaseInvoiceDesc;

  /// No description provided for @receiptVoucher.
  ///
  /// In ar, this message translates to:
  /// **'سند قبض'**
  String get receiptVoucher;

  /// No description provided for @receiptVoucherDesc.
  ///
  /// In ar, this message translates to:
  /// **'استلام دفعة نقدية'**
  String get receiptVoucherDesc;

  /// No description provided for @paymentVoucher.
  ///
  /// In ar, this message translates to:
  /// **'سند صرف'**
  String get paymentVoucher;

  /// No description provided for @paymentVoucherDesc.
  ///
  /// In ar, this message translates to:
  /// **'صرف دفعة نقدية'**
  String get paymentVoucherDesc;

  /// No description provided for @searchProducts.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منتج...'**
  String get searchProducts;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allCategories;

  /// No description provided for @invoiceNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الفاتورة'**
  String get invoiceNumber;

  /// No description provided for @chooseCustomer.
  ///
  /// In ar, this message translates to:
  /// **'اختر العميل'**
  String get chooseCustomer;

  /// No description provided for @addVoucher.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سند'**
  String get addVoucher;

  /// No description provided for @hold.
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get hold;

  /// No description provided for @heldInvoices.
  ///
  /// In ar, this message translates to:
  /// **'معلقة ({count})'**
  String heldInvoices(Object count);

  /// No description provided for @returns.
  ///
  /// In ar, this message translates to:
  /// **'المرتجعات'**
  String get returns;

  /// No description provided for @cart.
  ///
  /// In ar, this message translates to:
  /// **'السلة'**
  String get cart;

  /// No description provided for @cartEmpty.
  ///
  /// In ar, this message translates to:
  /// **'السلة فارغة'**
  String get cartEmpty;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @pay.
  ///
  /// In ar, this message translates to:
  /// **'دفع'**
  String get pay;

  /// No description provided for @vat.
  ///
  /// In ar, this message translates to:
  /// **'شامل الضريبة'**
  String get vat;

  /// No description provided for @productOutOfStock.
  ///
  /// In ar, this message translates to:
  /// **'نفدت الكمية'**
  String get productOutOfStock;

  /// No description provided for @salesAndOrders.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات والطلبات'**
  String get salesAndOrders;

  /// No description provided for @newInvoicePos.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة جديدة'**
  String get newInvoicePos;

  /// No description provided for @salesInvoices.
  ///
  /// In ar, this message translates to:
  /// **'فواتير المبيعات'**
  String get salesInvoices;

  /// No description provided for @ecommerceOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلبات المتجر الإلكتروني'**
  String get ecommerceOrders;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
