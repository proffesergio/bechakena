import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
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
/// import 'gen/app_localizations.dart';
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
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @navPos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get navPos;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products (name or barcode)'**
  String get searchProducts;

  /// No description provided for @invoicePanel.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoicePanel;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'Scan or tap a product to start'**
  String get emptyCart;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products yet — add your first product'**
  String get noProducts;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @vat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vat;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get cashReceived;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @confirmSale.
  ///
  /// In en, this message translates to:
  /// **'Confirm sale'**
  String get confirmSale;

  /// No description provided for @saleComplete.
  ///
  /// In en, this message translates to:
  /// **'Sale complete — {invoiceNo}'**
  String saleComplete(String invoiceNo);

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get productName;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode (optional)'**
  String get barcode;

  /// No description provided for @openingStock.
  ///
  /// In en, this message translates to:
  /// **'Opening stock (optional)'**
  String get openingStock;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock: {qty}'**
  String stockLabel(String qty);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @walkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customer'**
  String get walkIn;

  /// No description provided for @willBeDue.
  ///
  /// In en, this message translates to:
  /// **'{amount} will be due (baki)'**
  String willBeDue(String amount);

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phone;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueLabel;

  /// No description provided for @receivePayment.
  ///
  /// In en, this message translates to:
  /// **'Receive payment'**
  String get receivePayment;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomers;

  /// No description provided for @todayTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions today'**
  String get todayTransactions;

  /// No description provided for @todaySalesTotal.
  ///
  /// In en, this message translates to:
  /// **'Sales today'**
  String get todaySalesTotal;

  /// No description provided for @todayNewDue.
  ///
  /// In en, this message translates to:
  /// **'New due today'**
  String get todayNewDue;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @cashLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashLabel;

  /// No description provided for @bkash.
  ///
  /// In en, this message translates to:
  /// **'bKash'**
  String get bkash;

  /// No description provided for @nagad.
  ///
  /// In en, this message translates to:
  /// **'Nagad'**
  String get nagad;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printReceipt;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @printFailed.
  ///
  /// In en, this message translates to:
  /// **'Print failed: {error}'**
  String printFailed(String error);

  /// No description provided for @manualItem.
  ///
  /// In en, this message translates to:
  /// **'Manual item'**
  String get manualItem;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @navPurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get navPurchases;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New purchase'**
  String get newPurchase;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier (optional)'**
  String get supplier;

  /// No description provided for @invoiceRef.
  ///
  /// In en, this message translates to:
  /// **'Supplier invoice no (optional)'**
  String get invoiceRef;

  /// No description provided for @unitCost.
  ///
  /// In en, this message translates to:
  /// **'Unit cost'**
  String get unitCost;

  /// No description provided for @expiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry YYYY-MM-DD (optional)'**
  String get expiry;

  /// No description provided for @addLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get addLine;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @noPurchases.
  ///
  /// In en, this message translates to:
  /// **'No purchases recorded yet'**
  String get noPurchases;

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add supplier'**
  String get addSupplier;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier name'**
  String get supplierName;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get invalidDate;

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get adjustStock;

  /// No description provided for @qtyChange.
  ///
  /// In en, this message translates to:
  /// **'Change (+ receive / − remove)'**
  String get qtyChange;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @currentStock.
  ///
  /// In en, this message translates to:
  /// **'Current stock: {qty}'**
  String currentStock(String qty);

  /// No description provided for @shopSection.
  ///
  /// In en, this message translates to:
  /// **'Shop profile'**
  String get shopSection;

  /// No description provided for @shopNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopNameLabel;

  /// No description provided for @shopPhone.
  ///
  /// In en, this message translates to:
  /// **'Shop phone'**
  String get shopPhone;

  /// No description provided for @shopAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get shopAddress;

  /// No description provided for @receiptFooterLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt footer'**
  String get receiptFooterLabel;

  /// No description provided for @printerSection.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get printerSection;

  /// No description provided for @printerHost.
  ///
  /// In en, this message translates to:
  /// **'Printer IP (LAN)'**
  String get printerHost;

  /// No description provided for @printerPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get printerPort;

  /// No description provided for @paperWidth.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get paperWidth;

  /// No description provided for @testPrint.
  ///
  /// In en, this message translates to:
  /// **'Test print'**
  String get testPrint;

  /// No description provided for @backupSection.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupSection;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup now'**
  String get backupNow;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved: {path}'**
  String backupSaved(String path);

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreBackup;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Restored. Please close and reopen the app.'**
  String get restoreDone;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @loadDemo.
  ///
  /// In en, this message translates to:
  /// **'Load sample products (demo)'**
  String get loadDemo;

  /// No description provided for @demoLoaded.
  ///
  /// In en, this message translates to:
  /// **'Sample products loaded'**
  String get demoLoaded;

  /// No description provided for @demoSkipped.
  ///
  /// In en, this message translates to:
  /// **'Products already exist — demo not loaded'**
  String get demoSkipped;

  /// No description provided for @salesTrend.
  ///
  /// In en, this message translates to:
  /// **'Sales trend'**
  String get salesTrend;

  /// No description provided for @topProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get topProductsTitle;

  /// No description provided for @paymentMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethodsTitle;

  /// No description provided for @rangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rangeToday;

  /// No description provided for @range7d.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get range7d;

  /// No description provided for @range30d.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get range30d;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period yet'**
  String get noData;

  /// No description provided for @avgPerSale.
  ///
  /// In en, this message translates to:
  /// **'Average per sale'**
  String get avgPerSale;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
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
