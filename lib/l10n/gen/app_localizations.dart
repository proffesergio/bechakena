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

  /// No description provided for @setupOwnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome — create the owner account'**
  String get setupOwnerTitle;

  /// No description provided for @setupOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This account manages staff and settings'**
  String get setupOwnerSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get loginTitle;

  /// No description provided for @staffName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get staffName;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinMismatch;

  /// No description provided for @pinTooShort.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 digits'**
  String get pinTooShort;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get wrongPin;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @loggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in: {name}'**
  String loggedInAs(String name);

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get roleCashier;

  /// No description provided for @staffSection.
  ///
  /// In en, this message translates to:
  /// **'Staff & PINs'**
  String get staffSection;

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get addStaff;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @removeStaff.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeStaff(String name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @lowStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockTitle;

  /// No description provided for @expiringSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiringSoonTitle;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'All good — no stock alerts'**
  String get noAlerts;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOn(String date);

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @staffSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales by staff'**
  String get staffSalesTitle;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @noSales.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get noSales;

  /// No description provided for @saleDetail.
  ///
  /// In en, this message translates to:
  /// **'Sale {invoiceNo}'**
  String saleDetail(String invoiceNo);

  /// No description provided for @reprint.
  ///
  /// In en, this message translates to:
  /// **'Reprint receipt'**
  String get reprint;

  /// No description provided for @returnItems.
  ///
  /// In en, this message translates to:
  /// **'Return items'**
  String get returnItems;

  /// No description provided for @returnQty.
  ///
  /// In en, this message translates to:
  /// **'Return qty'**
  String get returnQty;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @refundTotal.
  ///
  /// In en, this message translates to:
  /// **'Refund total'**
  String get refundTotal;

  /// No description provided for @confirmReturn.
  ///
  /// In en, this message translates to:
  /// **'Confirm return'**
  String get confirmReturn;

  /// No description provided for @returnDone.
  ///
  /// In en, this message translates to:
  /// **'Return recorded — {amount} refunded'**
  String returnDone(String amount);

  /// No description provided for @refundsToday.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refundsToday;

  /// No description provided for @netSales.
  ///
  /// In en, this message translates to:
  /// **'Net sales'**
  String get netSales;

  /// No description provided for @alreadyReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get alreadyReturned;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} products'**
  String importDone(String count);

  /// No description provided for @importErrors.
  ///
  /// In en, this message translates to:
  /// **'{count} rows skipped'**
  String importErrors(String count);

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}'**
  String exportDone(String path);

  /// No description provided for @dueReminderSms.
  ///
  /// In en, this message translates to:
  /// **'Send due reminder'**
  String get dueReminderSms;

  /// No description provided for @queueSms.
  ///
  /// In en, this message translates to:
  /// **'Queue SMS'**
  String get queueSms;

  /// No description provided for @smsQueued.
  ///
  /// In en, this message translates to:
  /// **'SMS queued (will send when the Cloud Plan is active)'**
  String get smsQueued;

  /// No description provided for @transportLan.
  ///
  /// In en, this message translates to:
  /// **'LAN'**
  String get transportLan;

  /// No description provided for @transportUsb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get transportUsb;

  /// No description provided for @transportBt.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get transportBt;

  /// No description provided for @selectDevice.
  ///
  /// In en, this message translates to:
  /// **'Select device'**
  String get selectDevice;

  /// No description provided for @noDeviceSelected.
  ///
  /// In en, this message translates to:
  /// **'No device selected'**
  String get noDeviceSelected;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No printer found on this device'**
  String get noDevices;

  /// No description provided for @shopLogoHint.
  ///
  /// In en, this message translates to:
  /// **'Printed at the top of every receipt (black & white, up to ~384px wide)'**
  String get shopLogoHint;

  /// No description provided for @chooseLogo.
  ///
  /// In en, this message translates to:
  /// **'Choose logo'**
  String get chooseLogo;

  /// No description provided for @removeLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove logo'**
  String get removeLogo;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get clearData;

  /// No description provided for @clearDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes ALL products, sales, customers, staff and settings on this device. Back up first if you might need this data. Continue?'**
  String get clearDataWarning;

  /// No description provided for @clearDataDone.
  ///
  /// In en, this message translates to:
  /// **'All data will be cleared. Please close and reopen the app.'**
  String get clearDataDone;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @saveInvoice.
  ///
  /// In en, this message translates to:
  /// **'Save invoice'**
  String get saveInvoice;

  /// No description provided for @saveAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Save as PDF'**
  String get saveAsPdf;

  /// No description provided for @saveAsImage.
  ///
  /// In en, this message translates to:
  /// **'Save as image'**
  String get saveAsImage;

  /// No description provided for @invoiceSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String invoiceSaved(String path);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get deleteProduct;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? It stays in past sales but is removed from the catalog.'**
  String deleteProductConfirm(String name);

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeleted;

  /// No description provided for @productNameBn.
  ///
  /// In en, this message translates to:
  /// **'Name (Bengali)'**
  String get productNameBn;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get costPrice;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @lowStockLevel.
  ///
  /// In en, this message translates to:
  /// **'Low-stock alert level'**
  String get lowStockLevel;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get productImage;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get chooseImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removeImage;

  /// No description provided for @lowStockOnly.
  ///
  /// In en, this message translates to:
  /// **'Low stock only'**
  String get lowStockOnly;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No products match your filters'**
  String get noResults;

  /// No description provided for @branchSection.
  ///
  /// In en, this message translates to:
  /// **'Branch / outlet'**
  String get branchSection;

  /// No description provided for @currentBranch.
  ///
  /// In en, this message translates to:
  /// **'This device\'s branch'**
  String get currentBranch;

  /// No description provided for @addBranch.
  ///
  /// In en, this message translates to:
  /// **'Add branch'**
  String get addBranch;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchName;

  /// No description provided for @branchHint.
  ///
  /// In en, this message translates to:
  /// **'Sales, purchases and stock on this device are recorded against this branch.'**
  String get branchHint;

  /// No description provided for @branchAdded.
  ///
  /// In en, this message translates to:
  /// **'Branch added'**
  String get branchAdded;

  /// No description provided for @chooseBusinessType.
  ///
  /// In en, this message translates to:
  /// **'What kind of business is this?'**
  String get chooseBusinessType;

  /// No description provided for @chooseBusinessTypeHint.
  ///
  /// In en, this message translates to:
  /// **'This sets up the right screens and tools for your business.'**
  String get chooseBusinessTypeHint;

  /// No description provided for @chooseModule.
  ///
  /// In en, this message translates to:
  /// **'Which module do you want to open?'**
  String get chooseModule;

  /// No description provided for @chooseModuleHint.
  ///
  /// In en, this message translates to:
  /// **'Pick where you\'re working today. Supershop and Restaurant keep separate catalogs.'**
  String get chooseModuleHint;

  /// No description provided for @bizSupershop.
  ///
  /// In en, this message translates to:
  /// **'Supershop / Retail'**
  String get bizSupershop;

  /// No description provided for @bizSupershopDesc.
  ///
  /// In en, this message translates to:
  /// **'Products, barcode billing, inventory and baki khata.'**
  String get bizSupershopDesc;

  /// No description provided for @bizRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get bizRestaurant;

  /// No description provided for @bizRestaurantDesc.
  ///
  /// In en, this message translates to:
  /// **'Menu items, dining tables and table-side orders.'**
  String get bizRestaurantDesc;

  /// No description provided for @tourWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get tourWelcomeTitle;

  /// No description provided for @tourWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A fast, offline-first point of sale. Here\'s a 30-second tour — you can skip anytime.'**
  String get tourWelcomeBody;

  /// No description provided for @tourSellTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell in seconds'**
  String get tourSellTitle;

  /// No description provided for @tourSellBody.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode, tap a product, or type an item. Take cash, bKash, Nagad, card or due — with change and split payments.'**
  String get tourSellBody;

  /// No description provided for @tourOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Take orders fast'**
  String get tourOrdersTitle;

  /// No description provided for @tourOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'Add menu items to an order, manage dining tables, and print the bill in seconds.'**
  String get tourOrdersBody;

  /// No description provided for @tourStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory that maintains itself'**
  String get tourStockTitle;

  /// No description provided for @tourStockBody.
  ///
  /// In en, this message translates to:
  /// **'Every sale reduces stock and every purchase restocks. Low-stock and expiry alerts keep you ahead — per branch.'**
  String get tourStockBody;

  /// No description provided for @tourReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Khata & reports built in'**
  String get tourReportsTitle;

  /// No description provided for @tourReportsBody.
  ///
  /// In en, this message translates to:
  /// **'Track customer due (baki), see daily profit and top products, and back up your data — all offline.'**
  String get tourReportsBody;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @navTables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get navTables;

  /// No description provided for @noTables.
  ///
  /// In en, this message translates to:
  /// **'No tables yet — add your first table'**
  String get noTables;

  /// No description provided for @addTable.
  ///
  /// In en, this message translates to:
  /// **'Add table'**
  String get addTable;

  /// No description provided for @editTable.
  ///
  /// In en, this message translates to:
  /// **'Edit table'**
  String get editTable;

  /// No description provided for @deleteTable.
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get deleteTable;

  /// No description provided for @tableDeleted.
  ///
  /// In en, this message translates to:
  /// **'Table deleted'**
  String get tableDeleted;

  /// No description provided for @tableName.
  ///
  /// In en, this message translates to:
  /// **'Table name / number'**
  String get tableName;

  /// No description provided for @tableArea.
  ///
  /// In en, this message translates to:
  /// **'Area (e.g. Rooftop)'**
  String get tableArea;

  /// No description provided for @tableSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get tableSeats;

  /// No description provided for @orderTypeDineIn.
  ///
  /// In en, this message translates to:
  /// **'Dine-in'**
  String get orderTypeDineIn;

  /// No description provided for @orderTypeTakeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get orderTypeTakeaway;

  /// No description provided for @orderTypeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get orderTypeDelivery;

  /// No description provided for @newTakeaway.
  ///
  /// In en, this message translates to:
  /// **'New takeaway'**
  String get newTakeaway;

  /// No description provided for @newDelivery.
  ///
  /// In en, this message translates to:
  /// **'New delivery'**
  String get newDelivery;

  /// No description provided for @openOrders.
  ///
  /// In en, this message translates to:
  /// **'Open orders'**
  String get openOrders;

  /// No description provided for @noOpenOrders.
  ///
  /// In en, this message translates to:
  /// **'No open orders — tap a table or start a takeaway'**
  String get noOpenOrders;

  /// No description provided for @tableFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tableFree;

  /// No description provided for @tableOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get tableOccupied;

  /// No description provided for @manageTables.
  ///
  /// In en, this message translates to:
  /// **'Manage tables'**
  String get manageTables;

  /// No description provided for @doneManaging.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneManaging;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @guestName.
  ///
  /// In en, this message translates to:
  /// **'Guest name (optional)'**
  String get guestName;

  /// No description provided for @guestPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get guestPhone;

  /// No description provided for @orderPanel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderPanel;

  /// No description provided for @addToOrder.
  ///
  /// In en, this message translates to:
  /// **'Add to order'**
  String get addToOrder;

  /// No description provided for @noOrderItems.
  ///
  /// In en, this message translates to:
  /// **'No items yet — add from the menu'**
  String get noOrderItems;

  /// No description provided for @sendToKitchen.
  ///
  /// In en, this message translates to:
  /// **'Send to kitchen'**
  String get sendToKitchen;

  /// No description provided for @kitchenTicket.
  ///
  /// In en, this message translates to:
  /// **'Kitchen ticket'**
  String get kitchenTicket;

  /// No description provided for @sentToKitchen.
  ///
  /// In en, this message translates to:
  /// **'Sent to kitchen'**
  String get sentToKitchen;

  /// No description provided for @nothingNewToSend.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to send'**
  String get nothingNewToSend;

  /// No description provided for @settleOrder.
  ///
  /// In en, this message translates to:
  /// **'Settle & pay'**
  String get settleOrder;

  /// No description provided for @orderSettled.
  ///
  /// In en, this message translates to:
  /// **'Order settled — {invoiceNo}'**
  String orderSettled(String invoiceNo);

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order? Nothing will be charged.'**
  String get cancelOrderConfirm;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(String count);

  /// No description provided for @newItemsToFire.
  ///
  /// In en, this message translates to:
  /// **'{count} new to fire'**
  String newItemsToFire(String count);

  /// No description provided for @switchModule.
  ///
  /// In en, this message translates to:
  /// **'Switch module'**
  String get switchModule;

  /// No description provided for @switchModuleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switch to the other module? You\'ll sign out and pick again. Each module keeps its own separate data.'**
  String get switchModuleConfirm;

  /// No description provided for @switchModuleAction.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchModuleAction;
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
