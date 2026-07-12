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
}
