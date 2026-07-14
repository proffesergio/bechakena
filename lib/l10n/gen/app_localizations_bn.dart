// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get navPos => 'বিক্রয়';

  @override
  String get navProducts => 'পণ্য';

  @override
  String get navCustomers => 'গ্রাহক';

  @override
  String get navReports => 'রিপোর্ট';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get searchProducts => 'পণ্য খুঁজুন (নাম বা বারকোড)';

  @override
  String get invoicePanel => 'চালান';

  @override
  String get emptyCart => 'শুরু করতে পণ্য স্ক্যান বা ট্যাপ করুন';

  @override
  String get noProducts => 'এখনও কোনো পণ্য নেই — প্রথম পণ্য যোগ করুন';

  @override
  String get subtotal => 'উপমোট';

  @override
  String get discount => 'ছাড়';

  @override
  String get vat => 'ভ্যাট';

  @override
  String get total => 'মোট';

  @override
  String get pay => 'পেমেন্ট';

  @override
  String get cashReceived => 'নগদ গ্রহণ';

  @override
  String get change => 'ফেরত';

  @override
  String get confirmSale => 'বিক্রয় নিশ্চিত করুন';

  @override
  String saleComplete(String invoiceNo) {
    return 'বিক্রয় সম্পন্ন — $invoiceNo';
  }

  @override
  String get addProduct => 'পণ্য যোগ করুন';

  @override
  String get productName => 'নাম';

  @override
  String get price => 'মূল্য';

  @override
  String get barcode => 'বারকোড (ঐচ্ছিক)';

  @override
  String get openingStock => 'প্রারম্ভিক স্টক (ঐচ্ছিক)';

  @override
  String stockLabel(String qty) {
    return 'স্টক: $qty';
  }

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get cancel => 'বাতিল';

  @override
  String get customerLabel => 'গ্রাহক';

  @override
  String get walkIn => 'সাধারণ ক্রেতা';

  @override
  String willBeDue(String amount) {
    return '$amount বাকি থাকবে';
  }

  @override
  String get addCustomer => 'গ্রাহক যোগ করুন';

  @override
  String get customerName => 'গ্রাহকের নাম';

  @override
  String get phone => 'ফোন (ঐচ্ছিক)';

  @override
  String get dueLabel => 'বাকি';

  @override
  String get receivePayment => 'পেমেন্ট গ্রহণ';

  @override
  String get amount => 'পরিমাণ';

  @override
  String get noCustomers => 'এখনও কোনো গ্রাহক নেই';

  @override
  String get todayTransactions => 'আজকের লেনদেন';

  @override
  String get todaySalesTotal => 'আজকের বিক্রয়';

  @override
  String get todayNewDue => 'আজকের নতুন বাকি';

  @override
  String get language => 'ভাষা';

  @override
  String get invalidAmount => 'সঠিক পরিমাণ লিখুন';

  @override
  String get requiredField => 'আবশ্যক';

  @override
  String get cashLabel => 'নগদ';

  @override
  String get bkash => 'বিকাশ';

  @override
  String get nagad => 'নগদ (Nagad)';

  @override
  String get card => 'কার্ড';

  @override
  String get receiptTitle => 'রসিদ';

  @override
  String get printReceipt => 'প্রিন্ট';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String printFailed(String error) {
    return 'প্রিন্ট ব্যর্থ: $error';
  }

  @override
  String get manualItem => 'খুচরা আইটেম';

  @override
  String get quantity => 'পরিমাণ';

  @override
  String get navPurchases => 'ক্রয়';

  @override
  String get newPurchase => 'নতুন ক্রয়';

  @override
  String get supplier => 'সরবরাহকারী (ঐচ্ছিক)';

  @override
  String get invoiceRef => 'সরবরাহকারীর চালান নং (ঐচ্ছিক)';

  @override
  String get unitCost => 'একক ক্রয়মূল্য';

  @override
  String get expiry => 'মেয়াদ YYYY-MM-DD (ঐচ্ছিক)';

  @override
  String get addLine => 'লাইন যোগ করুন';

  @override
  String get product => 'পণ্য';

  @override
  String get noPurchases => 'এখনও কোনো ক্রয় নেই';

  @override
  String get addSupplier => 'সরবরাহকারী যোগ করুন';

  @override
  String get supplierName => 'সরবরাহকারীর নাম';

  @override
  String get invalidDate => 'ভুল তারিখ';

  @override
  String get adjustStock => 'স্টক সমন্বয়';

  @override
  String get qtyChange => 'পরিবর্তন (+ গ্রহণ / − বাদ)';

  @override
  String get reason => 'কারণ';

  @override
  String currentStock(String qty) {
    return 'বর্তমান স্টক: $qty';
  }

  @override
  String get shopSection => 'দোকানের তথ্য';

  @override
  String get shopNameLabel => 'দোকানের নাম';

  @override
  String get shopPhone => 'দোকানের ফোন';

  @override
  String get shopAddress => 'ঠিকানা';

  @override
  String get receiptFooterLabel => 'রসিদের ফুটার';

  @override
  String get printerSection => 'প্রিন্টার';

  @override
  String get printerHost => 'প্রিন্টার আইপি (LAN)';

  @override
  String get printerPort => 'পোর্ট';

  @override
  String get paperWidth => 'কাগজ';

  @override
  String get testPrint => 'টেস্ট প্রিন্ট';

  @override
  String get backupSection => 'ব্যাকআপ';

  @override
  String get backupNow => 'এখনই ব্যাকআপ করুন';

  @override
  String backupSaved(String path) {
    return 'ব্যাকআপ সংরক্ষিত: $path';
  }

  @override
  String get restoreBackup => 'ব্যাকআপ থেকে পুনরুদ্ধার';

  @override
  String get restoreDone =>
      'পুনরুদ্ধার সম্পন্ন। অ্যাপটি বন্ধ করে আবার চালু করুন।';

  @override
  String get saved => 'সংরক্ষিত';

  @override
  String get loadDemo => 'নমুনা পণ্য লোড করুন (ডেমো)';

  @override
  String get demoLoaded => 'নমুনা পণ্য লোড হয়েছে';

  @override
  String get demoSkipped => 'পণ্য আগে থেকেই আছে — ডেমো লোড হয়নি';

  @override
  String get salesTrend => 'বিক্রয়ের ধারা';

  @override
  String get topProductsTitle => 'সেরা পণ্য';

  @override
  String get paymentMethodsTitle => 'পেমেন্ট মাধ্যম';

  @override
  String get rangeToday => 'আজ';

  @override
  String get range7d => '৭ দিন';

  @override
  String get range30d => '৩০ দিন';

  @override
  String get noData => 'এই সময়ে এখনও কোনো বিক্রয় নেই';

  @override
  String get avgPerSale => 'গড় বিক্রয়';

  @override
  String get allCategories => 'সব';

  @override
  String get setupOwnerTitle => 'স্বাগতম — মালিক অ্যাকাউন্ট তৈরি করুন';

  @override
  String get setupOwnerSubtitle => 'এই অ্যাকাউন্ট কর্মী ও সেটিংস পরিচালনা করে';

  @override
  String get loginTitle => 'আপনার পিন দিন';

  @override
  String get staffName => 'আপনার নাম';

  @override
  String get pin => 'পিন';

  @override
  String get confirmPin => 'পিন নিশ্চিত করুন';

  @override
  String get pinMismatch => 'পিন মিলছে না';

  @override
  String get pinTooShort => 'পিন কমপক্ষে ৪ সংখ্যার হতে হবে';

  @override
  String get wrongPin => 'ভুল পিন';

  @override
  String get createAccount => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get login => 'লগ ইন';

  @override
  String get logout => 'লগ আউট';

  @override
  String loggedInAs(String name) {
    return 'সাইন ইন: $name';
  }

  @override
  String get roleOwner => 'মালিক';

  @override
  String get roleManager => 'ম্যানেজার';

  @override
  String get roleCashier => 'ক্যাশিয়ার';

  @override
  String get staffSection => 'কর্মী ও পিন';

  @override
  String get addStaff => 'কর্মী যোগ করুন';

  @override
  String get role => 'ভূমিকা';

  @override
  String removeStaff(String name) {
    return '$name সরাবেন?';
  }

  @override
  String get remove => 'সরান';

  @override
  String get navInventory => 'ইনভেন্টরি';

  @override
  String get lowStockTitle => 'স্টক কম';

  @override
  String get expiringSoonTitle => 'মেয়াদ শেষ হচ্ছে';

  @override
  String get noAlerts => 'সব ঠিক আছে — কোনো সতর্কতা নেই';

  @override
  String expiresOn(String date) {
    return 'মেয়াদ $date';
  }

  @override
  String get expired => 'মেয়াদোত্তীর্ণ';

  @override
  String get staffSalesTitle => 'কর্মী অনুযায়ী বিক্রয়';

  @override
  String get navHistory => 'ইতিহাস';

  @override
  String get noSales => 'এখনও কোনো বিক্রয় নেই';

  @override
  String saleDetail(String invoiceNo) {
    return 'বিক্রয় $invoiceNo';
  }

  @override
  String get reprint => 'রসিদ পুনরায় প্রিন্ট';

  @override
  String get returnItems => 'পণ্য ফেরত';

  @override
  String get returnQty => 'ফেরত পরিমাণ';

  @override
  String get refund => 'ফেরত';

  @override
  String get refundTotal => 'মোট ফেরত';

  @override
  String get confirmReturn => 'ফেরত নিশ্চিত করুন';

  @override
  String returnDone(String amount) {
    return 'ফেরত রেকর্ড হয়েছে — $amount ফেরত দেওয়া হয়েছে';
  }

  @override
  String get refundsToday => 'ফেরত';

  @override
  String get netSales => 'নিট বিক্রয়';

  @override
  String get alreadyReturned => 'ফেরত';

  @override
  String get importCsv => 'CSV ইমপোর্ট';

  @override
  String get exportCsv => 'CSV এক্সপোর্ট';

  @override
  String importDone(String count) {
    return '$countটি পণ্য ইমপোর্ট হয়েছে';
  }

  @override
  String importErrors(String count) {
    return '$countটি সারি বাদ পড়েছে';
  }

  @override
  String exportDone(String path) {
    return 'এক্সপোর্ট হয়েছে $path';
  }

  @override
  String get dueReminderSms => 'বাকির রিমাইন্ডার পাঠান';

  @override
  String get queueSms => 'SMS কিউ করুন';

  @override
  String get smsQueued =>
      'SMS কিউ হয়েছে (ক্লাউড প্ল্যান সক্রিয় হলে পাঠানো হবে)';

  @override
  String get transportLan => 'LAN';

  @override
  String get transportUsb => 'USB';

  @override
  String get transportBt => 'ব্লুটুথ';

  @override
  String get selectDevice => 'ডিভাইস নির্বাচন';

  @override
  String get noDeviceSelected => 'কোনো ডিভাইস নির্বাচিত হয়নি';

  @override
  String get noDevices => 'এই ডিভাইসে কোনো প্রিন্টার পাওয়া যায়নি';

  @override
  String get shopLogoHint =>
      'প্রতিটি রসিদের উপরে ছাপা হবে (সাদা-কালো, ~৩৮৪px পর্যন্ত চওড়া)';

  @override
  String get chooseLogo => 'লোগো নির্বাচন';

  @override
  String get removeLogo => 'লোগো সরান';

  @override
  String get clearData => 'স্থানীয় ডেটা মুছুন';

  @override
  String get clearDataWarning =>
      'এটি এই ডিভাইসের সব পণ্য, বিক্রয়, গ্রাহক, কর্মী ও সেটিংস স্থায়ীভাবে মুছে ফেলবে। প্রয়োজন হলে আগে ব্যাকআপ নিন। চালিয়ে যাবেন?';

  @override
  String get clearDataDone =>
      'সব ডেটা মুছে ফেলা হবে। অ্যাপটি বন্ধ করে আবার চালু করুন।';

  @override
  String get theme => 'থিম';

  @override
  String get themeSystem => 'সিস্টেম';

  @override
  String get themeLight => 'লাইট';

  @override
  String get themeDark => 'ডার্ক';

  @override
  String get saveInvoice => 'ইনভয়েস সংরক্ষণ';

  @override
  String get saveAsPdf => 'PDF হিসেবে সংরক্ষণ';

  @override
  String get saveAsImage => 'ছবি হিসেবে সংরক্ষণ';

  @override
  String invoiceSaved(String path) {
    return '$path-এ সংরক্ষিত হয়েছে';
  }

  @override
  String saveFailed(String error) {
    return 'সংরক্ষণ ব্যর্থ: $error';
  }

  @override
  String get editProduct => 'পণ্য সম্পাদনা';

  @override
  String get deleteProduct => 'পণ্য মুছুন';

  @override
  String deleteProductConfirm(String name) {
    return '\"$name\" মুছবেন? এটি পূর্বের বিক্রয়ে থাকবে তবে ক্যাটালগ থেকে সরানো হবে।';
  }

  @override
  String get productDeleted => 'পণ্য মুছে ফেলা হয়েছে';

  @override
  String get productNameBn => 'নাম (বাংলা)';

  @override
  String get sku => 'এসকেইউ';

  @override
  String get category => 'ক্যাটাগরি';

  @override
  String get noCategory => 'ক্যাটাগরি নেই';

  @override
  String get costPrice => 'ক্রয় মূল্য';

  @override
  String get unit => 'একক';

  @override
  String get lowStockLevel => 'কম স্টক সতর্কতার মাত্রা';

  @override
  String get productImage => 'পণ্যের ছবি';

  @override
  String get chooseImage => 'ছবি বাছুন';

  @override
  String get removeImage => 'ছবি সরান';

  @override
  String get lowStockOnly => 'শুধু কম স্টক';

  @override
  String get clearFilters => 'ফিল্টার মুছুন';

  @override
  String get noResults => 'আপনার ফিল্টারের সাথে কোনো পণ্য মিলছে না';

  @override
  String get branchSection => 'শাখা / আউটলেট';

  @override
  String get currentBranch => 'এই ডিভাইসের শাখা';

  @override
  String get addBranch => 'শাখা যোগ করুন';

  @override
  String get branchName => 'শাখার নাম';

  @override
  String get branchHint =>
      'এই ডিভাইসের বিক্রয়, ক্রয় ও স্টক এই শাখার অধীনে রেকর্ড হয়।';

  @override
  String get branchAdded => 'শাখা যোগ হয়েছে';

  @override
  String get chooseBusinessType => 'এটি কোন ধরনের ব্যবসা?';

  @override
  String get chooseBusinessTypeHint =>
      'এটি আপনার ব্যবসার জন্য সঠিক স্ক্রিন ও টুল সেট করে দেয়।';

  @override
  String get chooseModule => 'কোন মডিউল খুলতে চান?';

  @override
  String get chooseModuleHint =>
      'আজ কোথায় কাজ করবেন বেছে নিন। সুপারশপ ও রেস্টুরেন্টের আলাদা ক্যাটালগ থাকে।';

  @override
  String get bizSupershop => 'সুপারশপ / খুচরা';

  @override
  String get bizSupershopDesc => 'পণ্য, বারকোড বিলিং, ইনভেন্টরি ও বাকি খাতা।';

  @override
  String get bizRestaurant => 'রেস্টুরেন্ট';

  @override
  String get bizRestaurantDesc => 'মেনু আইটেম, টেবিল ও টেবিল-ভিত্তিক অর্ডার।';

  @override
  String get tourWelcomeTitle => 'স্বাগতম!';

  @override
  String get tourWelcomeBody =>
      'দ্রুত, অফলাইন-ফার্স্ট পয়েন্ট অব সেল। এই ৩০ সেকেন্ডের টুর — যেকোনো সময় স্কিপ করতে পারেন।';

  @override
  String get tourSellTitle => 'সেকেন্ডেই বিক্রি';

  @override
  String get tourSellBody =>
      'বারকোড স্ক্যান করুন, পণ্যে ট্যাপ করুন বা টাইপ করুন। নগদ, বিকাশ, নগদ, কার্ড বা বাকি — খুচরা ও ভাগ পেমেন্টসহ।';

  @override
  String get tourOrdersTitle => 'দ্রুত অর্ডার নিন';

  @override
  String get tourOrdersBody =>
      'অর্ডারে মেনু আইটেম যোগ করুন, টেবিল পরিচালনা করুন এবং সেকেন্ডেই বিল প্রিন্ট করুন।';

  @override
  String get tourStockTitle => 'নিজে থেকেই আপডেট হওয়া ইনভেন্টরি';

  @override
  String get tourStockBody =>
      'প্রতিটি বিক্রয়ে স্টক কমে, প্রতিটি ক্রয়ে বাড়ে। কম-স্টক ও মেয়াদের সতর্কতা — শাখা অনুযায়ী।';

  @override
  String get tourReportsTitle => 'খাতা ও রিপোর্ট অন্তর্ভুক্ত';

  @override
  String get tourReportsBody =>
      'গ্রাহকের বাকি ট্র্যাক করুন, দৈনিক লাভ ও শীর্ষ পণ্য দেখুন এবং ডেটা ব্যাকআপ নিন — সবই অফলাইনে।';

  @override
  String get skip => 'স্কিপ';

  @override
  String get next => 'পরবর্তী';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get navOrders => 'অর্ডার';

  @override
  String get navMenu => 'মেনু';

  @override
  String get navTables => 'টেবিল';

  @override
  String get noTables => 'এখনো কোনো টেবিল নেই — প্রথম টেবিল যোগ করুন';

  @override
  String get addTable => 'টেবিল যোগ করুন';

  @override
  String get editTable => 'টেবিল সম্পাদনা';

  @override
  String get deleteTable => 'টেবিল মুছুন';

  @override
  String get tableDeleted => 'টেবিল মুছে ফেলা হয়েছে';

  @override
  String get tableName => 'টেবিলের নাম / নম্বর';

  @override
  String get tableArea => 'এলাকা (যেমন ছাদ)';

  @override
  String get tableSeats => 'আসন';

  @override
  String get orderTypeDineIn => 'টেবিলে';

  @override
  String get orderTypeTakeaway => 'পার্সেল';

  @override
  String get orderTypeDelivery => 'ডেলিভারি';

  @override
  String get newTakeaway => 'নতুন পার্সেল';

  @override
  String get newDelivery => 'নতুন ডেলিভারি';

  @override
  String get openOrders => 'চলমান অর্ডার';

  @override
  String get noOpenOrders =>
      'কোনো চলমান অর্ডার নেই — টেবিলে ট্যাপ করুন বা পার্সেল শুরু করুন';

  @override
  String get tableFree => 'খালি';

  @override
  String get tableOccupied => 'চলছে';

  @override
  String get manageTables => 'টেবিল পরিচালনা';

  @override
  String get doneManaging => 'সম্পন্ন';

  @override
  String get guest => 'অতিথি';

  @override
  String get guestName => 'অতিথির নাম (ঐচ্ছিক)';

  @override
  String get guestPhone => 'ফোন (ঐচ্ছিক)';

  @override
  String get orderPanel => 'অর্ডার';

  @override
  String get addToOrder => 'অর্ডারে যোগ করুন';

  @override
  String get noOrderItems => 'এখনো কোনো আইটেম নেই — মেনু থেকে যোগ করুন';

  @override
  String get sendToKitchen => 'রান্নাঘরে পাঠান';

  @override
  String get kitchenTicket => 'কিচেন টিকিট';

  @override
  String get sentToKitchen => 'রান্নাঘরে পাঠানো হয়েছে';

  @override
  String get nothingNewToSend => 'নতুন কিছু পাঠানোর নেই';

  @override
  String get settleOrder => 'বিল ও পেমেন্ট';

  @override
  String orderSettled(String invoiceNo) {
    return 'অর্ডার সম্পন্ন — $invoiceNo';
  }

  @override
  String get cancelOrder => 'অর্ডার বাতিল';

  @override
  String get cancelOrderConfirm =>
      'এই অর্ডার বাতিল করবেন? কোনো চার্জ নেওয়া হবে না।';

  @override
  String get orderCancelled => 'অর্ডার বাতিল হয়েছে';

  @override
  String itemsCount(String count) {
    return '$count আইটেম';
  }

  @override
  String newItemsToFire(String count) {
    return '$countটি নতুন পাঠাতে';
  }

  @override
  String get switchModule => 'মডিউল পরিবর্তন';

  @override
  String get switchModuleConfirm =>
      'অন্য মডিউলে যাবেন? আপনি সাইন আউট হয়ে আবার বেছে নেবেন। প্রতিটি মডিউলের আলাদা ডেটা থাকে।';

  @override
  String get switchModuleAction => 'পরিবর্তন';
}
