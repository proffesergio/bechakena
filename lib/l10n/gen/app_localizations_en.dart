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

  @override
  String get navHistory => 'History';

  @override
  String get noSales => 'No sales yet';

  @override
  String saleDetail(String invoiceNo) {
    return 'Sale $invoiceNo';
  }

  @override
  String get reprint => 'Reprint receipt';

  @override
  String get returnItems => 'Return items';

  @override
  String get returnQty => 'Return qty';

  @override
  String get refund => 'Refund';

  @override
  String get refundTotal => 'Refund total';

  @override
  String get confirmReturn => 'Confirm return';

  @override
  String returnDone(String amount) {
    return 'Return recorded — $amount refunded';
  }

  @override
  String get refundsToday => 'Refunds';

  @override
  String get netSales => 'Net sales';

  @override
  String get alreadyReturned => 'Returned';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String importDone(String count) {
    return 'Imported $count products';
  }

  @override
  String importErrors(String count) {
    return '$count rows skipped';
  }

  @override
  String exportDone(String path) {
    return 'Exported to $path';
  }

  @override
  String get dueReminderSms => 'Send due reminder';

  @override
  String get queueSms => 'Queue SMS';

  @override
  String get smsQueued =>
      'SMS queued (will send when the Cloud Plan is active)';

  @override
  String get transportLan => 'LAN';

  @override
  String get transportUsb => 'USB';

  @override
  String get transportBt => 'Bluetooth';

  @override
  String get selectDevice => 'Select device';

  @override
  String get noDeviceSelected => 'No device selected';

  @override
  String get noDevices => 'No printer found on this device';

  @override
  String get shopLogoHint =>
      'Printed at the top of every receipt (black & white, up to ~384px wide)';

  @override
  String get chooseLogo => 'Choose logo';

  @override
  String get removeLogo => 'Remove logo';

  @override
  String get clearData => 'Clear local data';

  @override
  String get clearDataWarning =>
      'This permanently deletes ALL products, sales, customers, staff and settings on this device. Back up first if you might need this data. Continue?';

  @override
  String get clearDataDone =>
      'All data will be cleared. Please close and reopen the app.';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get saveInvoice => 'Save invoice';

  @override
  String get saveAsPdf => 'Save as PDF';

  @override
  String get saveAsImage => 'Save as image';

  @override
  String invoiceSaved(String path) {
    return 'Saved to $path';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get editProduct => 'Edit product';

  @override
  String get deleteProduct => 'Delete product';

  @override
  String deleteProductConfirm(String name) {
    return 'Delete \"$name\"? It stays in past sales but is removed from the catalog.';
  }

  @override
  String get productDeleted => 'Product deleted';

  @override
  String get productNameBn => 'Name (Bengali)';

  @override
  String get sku => 'SKU';

  @override
  String get category => 'Category';

  @override
  String get noCategory => 'No category';

  @override
  String get costPrice => 'Cost price';

  @override
  String get unit => 'Unit';

  @override
  String get lowStockLevel => 'Low-stock alert level';

  @override
  String get productImage => 'Product photo';

  @override
  String get chooseImage => 'Choose photo';

  @override
  String get removeImage => 'Remove photo';

  @override
  String get lowStockOnly => 'Low stock only';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get noResults => 'No products match your filters';

  @override
  String get branchSection => 'Branch / outlet';

  @override
  String get currentBranch => 'This device\'s branch';

  @override
  String get addBranch => 'Add branch';

  @override
  String get branchName => 'Branch name';

  @override
  String get branchHint =>
      'Sales, purchases and stock on this device are recorded against this branch.';

  @override
  String get branchAdded => 'Branch added';

  @override
  String get chooseBusinessType => 'What kind of business is this?';

  @override
  String get chooseBusinessTypeHint =>
      'This sets up the right screens and tools for your business.';

  @override
  String get chooseModule => 'Which module do you want to open?';

  @override
  String get chooseModuleHint =>
      'Pick where you\'re working today. Supershop and Restaurant keep separate catalogs.';

  @override
  String get bizSupershop => 'Supershop / Retail';

  @override
  String get bizSupershopDesc =>
      'Products, barcode billing, inventory and baki khata.';

  @override
  String get bizRestaurant => 'Restaurant';

  @override
  String get bizRestaurantDesc =>
      'Menu items, dining tables and table-side orders.';

  @override
  String get tourWelcomeTitle => 'Welcome!';

  @override
  String get tourWelcomeBody =>
      'A fast, offline-first point of sale. Here\'s a 30-second tour — you can skip anytime.';

  @override
  String get tourSellTitle => 'Sell in seconds';

  @override
  String get tourSellBody =>
      'Scan a barcode, tap a product, or type an item. Take cash, bKash, Nagad, card or due — with change and split payments.';

  @override
  String get tourOrdersTitle => 'Take orders fast';

  @override
  String get tourOrdersBody =>
      'Add menu items to an order, manage dining tables, and print the bill in seconds.';

  @override
  String get tourStockTitle => 'Inventory that maintains itself';

  @override
  String get tourStockBody =>
      'Every sale reduces stock and every purchase restocks. Low-stock and expiry alerts keep you ahead — per branch.';

  @override
  String get tourReportsTitle => 'Khata & reports built in';

  @override
  String get tourReportsBody =>
      'Track customer due (baki), see daily profit and top products, and back up your data — all offline.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get navOrders => 'Orders';

  @override
  String get navMenu => 'Menu';

  @override
  String get navTables => 'Tables';

  @override
  String get noTables => 'No tables yet — add your first table';

  @override
  String get addTable => 'Add table';

  @override
  String get editTable => 'Edit table';

  @override
  String get deleteTable => 'Delete table';

  @override
  String get tableDeleted => 'Table deleted';

  @override
  String get tableName => 'Table name / number';

  @override
  String get tableArea => 'Area (e.g. Rooftop)';

  @override
  String get tableSeats => 'Seats';

  @override
  String get orderTypeDineIn => 'Dine-in';

  @override
  String get orderTypeTakeaway => 'Takeaway';

  @override
  String get orderTypeDelivery => 'Delivery';

  @override
  String get newTakeaway => 'New takeaway';

  @override
  String get newDelivery => 'New delivery';

  @override
  String get openOrders => 'Open orders';

  @override
  String get noOpenOrders => 'No open orders — tap a table or start a takeaway';

  @override
  String get tableFree => 'Free';

  @override
  String get tableOccupied => 'Occupied';

  @override
  String get manageTables => 'Manage tables';

  @override
  String get doneManaging => 'Done';

  @override
  String get guest => 'Guest';

  @override
  String get guestName => 'Guest name (optional)';

  @override
  String get guestPhone => 'Phone (optional)';

  @override
  String get orderPanel => 'Order';

  @override
  String get addToOrder => 'Add to order';

  @override
  String get noOrderItems => 'No items yet — add from the menu';

  @override
  String get sendToKitchen => 'Send to kitchen';

  @override
  String get kitchenTicket => 'Kitchen ticket';

  @override
  String get sentToKitchen => 'Sent to kitchen';

  @override
  String get nothingNewToSend => 'Nothing new to send';

  @override
  String get settleOrder => 'Settle & pay';

  @override
  String orderSettled(String invoiceNo) {
    return 'Order settled — $invoiceNo';
  }

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderConfirm =>
      'Cancel this order? Nothing will be charged.';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String itemsCount(String count) {
    return '$count items';
  }

  @override
  String newItemsToFire(String count) {
    return '$count new to fire';
  }

  @override
  String get switchModule => 'Switch module';

  @override
  String get switchModuleConfirm =>
      'Switch to the other module? You\'ll sign out and pick again. Each module keeps its own separate data.';

  @override
  String get switchModuleAction => 'Switch';
}
