// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navPos => 'POS';

  @override
  String get navProducts => 'Products';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get searchProducts => 'Search products (name or barcode)';

  @override
  String get invoicePanel => 'Invoice';

  @override
  String get emptyCart => 'Scan or tap a product to start';

  @override
  String get noProducts => 'No products yet — add your first product';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get vat => 'VAT';

  @override
  String get total => 'Total';

  @override
  String get pay => 'Pay';

  @override
  String get cashReceived => 'Cash received';

  @override
  String get change => 'Change';

  @override
  String get confirmSale => 'Confirm sale';

  @override
  String saleComplete(String invoiceNo) {
    return 'Sale complete — $invoiceNo';
  }

  @override
  String get addProduct => 'Add product';

  @override
  String get productName => 'Name';

  @override
  String get price => 'Price';

  @override
  String get barcode => 'Barcode (optional)';

  @override
  String get openingStock => 'Opening stock (optional)';

  @override
  String stockLabel(String qty) {
    return 'Stock: $qty';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get customerLabel => 'Customer';

  @override
  String get walkIn => 'Walk-in customer';

  @override
  String willBeDue(String amount) {
    return '$amount will be due (baki)';
  }

  @override
  String get addCustomer => 'Add customer';

  @override
  String get customerName => 'Customer name';

  @override
  String get phone => 'Phone (optional)';

  @override
  String get dueLabel => 'Due';

  @override
  String get receivePayment => 'Receive payment';

  @override
  String get amount => 'Amount';

  @override
  String get noCustomers => 'No customers yet';

  @override
  String get todayTransactions => 'Transactions today';

  @override
  String get todaySalesTotal => 'Sales today';

  @override
  String get todayNewDue => 'New due today';

  @override
  String get language => 'Language';

  @override
  String get invalidAmount => 'Enter a valid amount';

  @override
  String get requiredField => 'Required';

  @override
  String get cashLabel => 'Cash';

  @override
  String get bkash => 'bKash';

  @override
  String get nagad => 'Nagad';

  @override
  String get card => 'Card';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get printReceipt => 'Print';

  @override
  String get close => 'Close';

  @override
  String printFailed(String error) {
    return 'Print failed: $error';
  }

  @override
  String get manualItem => 'Manual item';

  @override
  String get quantity => 'Quantity';

  @override
  String get navPurchases => 'Purchases';

  @override
  String get newPurchase => 'New purchase';

  @override
  String get supplier => 'Supplier (optional)';

  @override
  String get invoiceRef => 'Supplier invoice no (optional)';

  @override
  String get unitCost => 'Unit cost';

  @override
  String get expiry => 'Expiry YYYY-MM-DD (optional)';

  @override
  String get addLine => 'Add line';

  @override
  String get product => 'Product';

  @override
  String get noPurchases => 'No purchases recorded yet';

  @override
  String get addSupplier => 'Add supplier';

  @override
  String get supplierName => 'Supplier name';

  @override
  String get invalidDate => 'Invalid date';

  @override
  String get adjustStock => 'Adjust stock';

  @override
  String get qtyChange => 'Change (+ receive / − remove)';

  @override
  String get reason => 'Reason';

  @override
  String currentStock(String qty) {
    return 'Current stock: $qty';
  }

  @override
  String get shopSection => 'Shop profile';

  @override
  String get shopNameLabel => 'Shop name';

  @override
  String get shopPhone => 'Shop phone';

  @override
  String get shopAddress => 'Address';

  @override
  String get receiptFooterLabel => 'Receipt footer';

  @override
  String get printerSection => 'Printer';

  @override
  String get printerHost => 'Printer IP (LAN)';

  @override
  String get printerPort => 'Port';

  @override
  String get paperWidth => 'Paper';

  @override
  String get testPrint => 'Test print';

  @override
  String get backupSection => 'Backup';

  @override
  String get backupNow => 'Backup now';

  @override
  String backupSaved(String path) {
    return 'Backup saved: $path';
  }

  @override
  String get restoreBackup => 'Restore from backup';

  @override
  String get restoreDone => 'Restored. Please close and reopen the app.';

  @override
  String get saved => 'Saved';

  @override
  String get loadDemo => 'Load sample products (demo)';

  @override
  String get demoLoaded => 'Sample products loaded';

  @override
  String get demoSkipped => 'Products already exist — demo not loaded';

  @override
  String get salesTrend => 'Sales trend';

  @override
  String get topProductsTitle => 'Top products';

  @override
  String get paymentMethodsTitle => 'Payment methods';

  @override
  String get rangeToday => 'Today';

  @override
  String get range7d => '7 days';

  @override
  String get range30d => '30 days';

  @override
  String get noData => 'No sales in this period yet';

  @override
  String get avgPerSale => 'Average per sale';

  @override
  String get allCategories => 'All';

  @override
  String get setupOwnerTitle => 'Welcome — create the owner account';

  @override
  String get setupOwnerSubtitle => 'This account manages staff and settings';

  @override
  String get loginTitle => 'Enter your PIN';

  @override
  String get staffName => 'Your name';

  @override
  String get pin => 'PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get pinTooShort => 'PIN must be at least 4 digits';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get createAccount => 'Create account';

  @override
  String get login => 'Log in';

  @override
  String get logout => 'Log out';

  @override
  String loggedInAs(String name) {
    return 'Signed in: $name';
  }

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCashier => 'Cashier';

  @override
  String get staffSection => 'Staff & PINs';

  @override
  String get addStaff => 'Add staff';

  @override
  String get role => 'Role';

  @override
  String removeStaff(String name) {
    return 'Remove $name?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get navInventory => 'Inventory';

  @override
  String get lowStockTitle => 'Low stock';

  @override
  String get expiringSoonTitle => 'Expiring soon';

  @override
  String get noAlerts => 'All good — no stock alerts';

  @override
  String expiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get expired => 'Expired';

  @override
  String get staffSalesTitle => 'Sales by staff';
}
