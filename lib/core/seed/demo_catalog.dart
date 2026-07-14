import 'package:drift/drift.dart';

import '../db/database.dart';
import '../money.dart';
import '../qty.dart';

/// Demo catalog of common Bangladeshi supermarket products (Chaldal-style
/// assortment; prices are realistic mid-2026 Dhaka retail, in paisa).
/// Product art is an emoji stored as `imagePath = "emoji:<glyph>"` until real
/// photos are attached per shop.

class _DemoCategory {
  const _DemoCategory(this.key, this.en, this.bn, this.colorHex, this.emoji);
  final String key;
  final String en;
  final String bn;
  final String colorHex;
  final String emoji;
}

class _DemoProduct {
  const _DemoProduct(this.cat, this.en, this.bn, this.pricePaisa, this.emoji,
      {this.unit = 'pcs', this.vatBp = 0, this.stockMilli = 40000, this.barcode});
  final String cat;
  final String en;
  final String bn;
  final int pricePaisa;
  final String emoji;
  final String unit;
  final int vatBp;
  final int stockMilli;
  final String? barcode;
}

const _categories = [
  _DemoCategory('rice', 'Rice', 'চাল', '#FFB300', '🍚'),
  _DemoCategory('oil', 'Oil & Ghee', 'তেল ও ঘি', '#FB8C00', '🫗'),
  _DemoCategory('grocery', 'Dal, Spices & Grocery', 'ডাল, মশলা ও মুদি', '#E53935', '🌶️'),
  _DemoCategory('fresh', 'Fish & Meat', 'মাছ ও মাংস', '#8E24AA', '🐟'),
  _DemoCategory('veg', 'Vegetables', 'শাকসবজি', '#43A047', '🥬'),
  _DemoCategory('snacks', 'Snacks & Biscuits', 'স্ন্যাকস ও বিস্কুট', '#F4511E', '🍪'),
  _DemoCategory('drinks', 'Beverages', 'পানীয়', '#1E88E5', '🥤'),
  _DemoCategory('dairy', 'Dairy & Eggs', 'দুধ ও ডিম', '#00ACC1', '🥛'),
  _DemoCategory('care', 'Personal Care', 'ব্যক্তিগত যত্ন', '#D81B60', '🧼'),
  _DemoCategory('clean', 'Household & Cleaning', 'গৃহস্থালি', '#3949AB', '🧺'),
];

const _products = [
  // Rice
  _DemoProduct('rice', 'Miniket Rice 5kg', 'মিনিকেট চাল ৫ কেজি', 47500, '🍚',
      barcode: '8941100500011', stockMilli: 30000),
  _DemoProduct('rice', 'Nazirshail Rice 5kg', 'নাজিরশাইল চাল ৫ কেজি', 45000, '🍚',
      stockMilli: 25000),
  _DemoProduct('rice', 'Chinigura Polao Rice 1kg', 'চিনিগুঁড়া চাল ১ কেজি', 16500, '🍛'),
  _DemoProduct('rice', 'Miniket Rice (loose)', 'মিনিকেট চাল (খোলা)', 9200, '🌾',
      unit: 'kg', stockMilli: 120000),
  // Oil & Ghee
  _DemoProduct('oil', 'Rupchanda Soybean Oil 5L', 'রূপচাঁদা সয়াবিন তেল ৫ লিটার', 87500, '🫗',
      barcode: '8941100200021', stockMilli: 20000),
  _DemoProduct('oil', 'Teer Soybean Oil 1L', 'তীর সয়াবিন তেল ১ লিটার', 17800, '🫗'),
  _DemoProduct('oil', 'Fresh Soybean Oil 2L', 'ফ্রেশ সয়াবিন তেল ২ লিটার', 35500, '🫗'),
  _DemoProduct('oil', 'Fortune Rice Bran Oil 1L', 'ফরচুন রাইস ব্র্যান তেল ১ লিটার', 19500, '🫗'),
  _DemoProduct('oil', 'Baghabari Ghee 400g', 'বাঘাবাড়ি ঘি ৪০০ গ্রাম', 65000, '🧈',
      stockMilli: 12000),
  // Dal, spices & grocery
  _DemoProduct('grocery', 'Masoor Dal', 'মসুর ডাল', 13500, '🥣',
      unit: 'kg', stockMilli: 80000),
  _DemoProduct('grocery', 'Mug Dal', 'মুগ ডাল', 16500, '🥣',
      unit: 'kg', stockMilli: 60000),
  _DemoProduct('grocery', 'Chola (Chickpeas)', 'ছোলা', 9500, '🫘',
      unit: 'kg', stockMilli: 70000),
  _DemoProduct('grocery', 'Radhuni Turmeric Powder 200g', 'রাঁধুনী হলুদ গুঁড়া ২০০ গ্রাম', 9000, '🌕'),
  _DemoProduct('grocery', 'Radhuni Chili Powder 200g', 'রাঁধুনী মরিচ গুঁড়া ২০০ গ্রাম', 11000, '🌶️'),
  _DemoProduct('grocery', 'Pran Hot Tomato Sauce 340g', 'প্রাণ টমেটো সস ৩৪০ গ্রাম', 9000, '🍅',
      vatBp: 500),
  _DemoProduct('grocery', 'ACI Pure Salt 1kg', 'এসিআই লবণ ১ কেজি', 4200, '🧂',
      barcode: '8941100300031'),
  _DemoProduct('grocery', 'Fresh Refined Sugar 1kg', 'ফ্রেশ চিনি ১ কেজি', 13000, '🍬'),
  _DemoProduct('grocery', 'Teer Atta 2kg', 'তীর আটা ২ কেজি', 13000, '🌾'),
  _DemoProduct('grocery', 'Bashundhara Maida 1kg', 'বসুন্ধরা ময়দা ১ কেজি', 7500, '🥖'),
  // Fish & meat
  _DemoProduct('fresh', 'Broiler Chicken', 'ব্রয়লার মুরগি', 21000, '🍗',
      unit: 'kg', stockMilli: 40000),
  _DemoProduct('fresh', 'Beef', 'গরুর মাংস', 78000, '🥩',
      unit: 'kg', stockMilli: 25000),
  _DemoProduct('fresh', 'Rui Fish', 'রুই মাছ', 38000, '🐟',
      unit: 'kg', stockMilli: 30000),
  _DemoProduct('dairy', 'Farm Eggs (dozen)', 'ফার্মের ডিম (ডজন)', 15500, '🥚',
      stockMilli: 50000),
  // Vegetables
  _DemoProduct('veg', 'Potato', 'আলু', 3500, '🥔', unit: 'kg', stockMilli: 200000),
  _DemoProduct('veg', 'Onion', 'পেঁয়াজ', 8000, '🧅', unit: 'kg', stockMilli: 150000),
  _DemoProduct('veg', 'Garlic', 'রসুন', 22000, '🧄', unit: 'kg', stockMilli: 40000),
  _DemoProduct('veg', 'Green Chili', 'কাঁচা মরিচ', 16000, '🌶️',
      unit: 'kg', stockMilli: 30000),
  _DemoProduct('veg', 'Tomato', 'টমেটো', 8000, '🍅', unit: 'kg', stockMilli: 60000),
  // Snacks & biscuits
  _DemoProduct('snacks', 'Ruchi BBQ Chanachur 350g', 'রুচি চানাচুর ৩৫০ গ্রাম', 9500, '🥜',
      vatBp: 500),
  _DemoProduct('snacks', 'Mr. Twist Chips', 'মিস্টার টুইস্ট', 2500, '🍟',
      vatBp: 500, stockMilli: 100000),
  _DemoProduct('snacks', 'Olympic Energy Plus Biscuit', 'অলিম্পিক এনার্জি প্লাস', 4000, '🍪',
      vatBp: 500, stockMilli: 120000, barcode: '8941100400041'),
  _DemoProduct('snacks', 'Dekko Toast Biscuit 350g', 'ডেকো টোস্ট ৩৫০ গ্রাম', 8500, '🍞',
      vatBp: 500),
  _DemoProduct('snacks', 'Maggi Noodles 8-pack', 'ম্যাগি নুডলস ৮ প্যাক', 22000, '🍜',
      vatBp: 500),
  _DemoProduct('snacks', 'Mr. Noodles Cup', 'মিস্টার নুডলস কাপ', 5500, '🍜',
      vatBp: 500, stockMilli: 80000),
  _DemoProduct('snacks', 'Pran Muri 500g', 'প্রাণ মুড়ি ৫০০ গ্রাম', 7500, '🍿'),
  // Beverages
  _DemoProduct('drinks', 'Mojo 1L', 'মোজো ১ লিটার', 9000, '🥤',
      vatBp: 500, stockMilli: 60000),
  _DemoProduct('drinks', 'Coca-Cola 1.25L', 'কোকা-কোলা ১.২৫ লিটার', 11000, '🥤',
      vatBp: 500, barcode: '5449000000439', stockMilli: 60000),
  _DemoProduct('drinks', 'Pran Frooto 1L', 'প্রাণ ফ্রুটো ১ লিটার', 12000, '🥭',
      vatBp: 500),
  _DemoProduct('drinks', 'Fresh Drinking Water 2L', 'ফ্রেশ পানি ২ লিটার', 4000, '💧',
      stockMilli: 100000),
  _DemoProduct('drinks', 'Ispahani Mirzapore Tea 400g', 'ইস্পাহানি মির্জাপুর চা ৪০০ গ্রাম', 22500, '🍵'),
  _DemoProduct('drinks', 'Nescafe Classic 50g', 'নেসক্যাফে ক্লাসিক ৫০ গ্রাম', 32500, '☕',
      vatBp: 500),
  // Dairy
  _DemoProduct('dairy', 'Milk Vita UHT Milk 1L', 'মিল্ক ভিটা দুধ ১ লিটার', 11500, '🥛'),
  _DemoProduct('dairy', 'Aarong Dairy Milk 1L', 'আড়ং দুধ ১ লিটার', 11500, '🥛'),
  _DemoProduct('dairy', 'Dano Power Milk Powder 1kg', 'ড্যানো গুঁড়া দুধ ১ কেজি', 89500, '🥛',
      stockMilli: 15000),
  _DemoProduct('dairy', 'Pran Sweet Yogurt 500g', 'প্রাণ মিষ্টি দই ৫০০ গ্রাম', 14000, '🍮',
      stockMilli: 20000),
  // Personal care
  _DemoProduct('care', 'Lifebuoy Soap 150g', 'লাইফবয় সাবান ১৫০ গ্রাম', 6500, '🧼',
      vatBp: 500, stockMilli: 80000),
  _DemoProduct('care', 'Lux Soap 150g', 'লাক্স সাবান ১৫০ গ্রাম', 7500, '🧼',
      vatBp: 500),
  _DemoProduct('care', 'Sunsilk Shampoo 340ml', 'সানসিল্ক শ্যাম্পু ৩৪০ মিলি', 38500, '🧴',
      vatBp: 500),
  _DemoProduct('care', 'Pepsodent Toothpaste 200g', 'পেপসোডেন্ট টুথপেস্ট ২০০ গ্রাম', 14500, '🪥',
      vatBp: 500),
  _DemoProduct('care', 'Bashundhara Facial Tissue', 'বসুন্ধরা টিস্যু', 5500, '🧻',
      vatBp: 500, stockMilli: 90000),
  // Household & cleaning
  _DemoProduct('clean', 'Wheel Washing Powder 1kg', 'হুইল ওয়াশিং পাউডার ১ কেজি', 10500, '🧺',
      vatBp: 500),
  _DemoProduct('clean', 'Surf Excel 1kg', 'সার্ফ এক্সেল ১ কেজি', 26500, '🧺',
      vatBp: 500),
  _DemoProduct('clean', 'Vim Dishwash Bar 300g', 'ভিম বার ৩০০ গ্রাম', 3500, '🍽️',
      vatBp: 500, stockMilli: 100000),
  _DemoProduct('clean', 'Harpic 750ml', 'হারপিক ৭৫০ মিলি', 15500, '🚽',
      vatBp: 500),
];

/// Restaurant demo menu — common Bangladeshi fast-food / rice-house fare.
const _restaurantCategories = [
  _DemoCategory('fastfood', 'Fast Food', 'ফাস্ট ফুড', '#E53935', '🍔'),
  _DemoCategory('rice', 'Rice & Biryani', 'ভাত ও বিরিয়ানি', '#FB8C00', '🍚'),
  _DemoCategory('kebab', 'Kebab & Grill', 'কাবাব ও গ্রিল', '#8E24AA', '🍢'),
  _DemoCategory('curry', 'Curry & Bhuna', 'তরকারি ও ভুনা', '#43A047', '🥘'),
  _DemoCategory('drinks', 'Beverages', 'পানীয়', '#1E88E5', '🥤'),
  _DemoCategory('dessert', 'Desserts', 'মিষ্টান্ন', '#D81B60', '🍮'),
];

const _restaurantProducts = [
  // Fast food
  _DemoProduct('fastfood', 'Beef Burger', 'বিফ বার্গার', 25000, '🍔', unit: 'pcs'),
  _DemoProduct('fastfood', 'Chicken Burger', 'চিকেন বার্গার', 22000, '🍔', unit: 'pcs'),
  _DemoProduct('fastfood', 'Chicken Sandwich', 'চিকেন স্যান্ডউইচ', 18000, '🥪', unit: 'pcs'),
  _DemoProduct('fastfood', 'Margherita Pizza', 'মার্গারিটা পিৎজা', 65000, '🍕', unit: 'pcs'),
  _DemoProduct('fastfood', 'French Fries', 'ফ্রেঞ্চ ফ্রাই', 12000, '🍟', unit: 'plate'),
  _DemoProduct('fastfood', 'Chicken Fry (2pc)', 'চিকেন ফ্রাই (২ পিস)', 20000, '🍗', unit: 'plate'),
  _DemoProduct('fastfood', 'Spring Roll', 'স্প্রিং রোল', 10000, '🌯', unit: 'pcs'),
  // Rice & biryani
  _DemoProduct('rice', 'Chicken Biryani', 'চিকেন বিরিয়ানি', 22000, '🍛', unit: 'plate'),
  _DemoProduct('rice', 'Kacchi Biryani', 'কাচ্চি বিরিয়ানি', 35000, '🍛', unit: 'plate'),
  _DemoProduct('rice', 'Beef Tehari', 'বিফ তেহারি', 20000, '🍚', unit: 'plate'),
  _DemoProduct('rice', 'Morog Polao', 'মোরগ পোলাও', 25000, '🍚', unit: 'plate'),
  _DemoProduct('rice', 'Fried Rice', 'ফ্রায়েড রাইস', 18000, '🍚', unit: 'plate'),
  _DemoProduct('rice', 'Plain Rice', 'সাদা ভাত', 4000, '🍚', unit: 'plate'),
  // Kebab & grill
  _DemoProduct('kebab', 'Chicken Kebab', 'চিকেন কাবাব', 18000, '🍢', unit: 'plate'),
  _DemoProduct('kebab', 'Beef Seekh Kebab', 'বিফ শিক কাবাব', 22000, '🍢', unit: 'plate'),
  _DemoProduct('kebab', 'Chicken Tikka', 'চিকেন টিক্কা', 20000, '🍗', unit: 'plate'),
  _DemoProduct('kebab', 'Naan', 'নান', 4000, '🫓', unit: 'pcs'),
  _DemoProduct('kebab', 'Paratha', 'পরোটা', 3000, '🫓', unit: 'pcs'),
  // Curry & bhuna
  _DemoProduct('curry', 'Chicken Curry', 'চিকেন কারি', 18000, '🍲', unit: 'plate'),
  _DemoProduct('curry', 'Beef Bhuna', 'বিফ ভুনা', 26000, '🥘', unit: 'plate'),
  _DemoProduct('curry', 'Dal', 'ডাল', 6000, '🍲', unit: 'plate'),
  _DemoProduct('curry', 'Mixed Vegetable', 'সবজি', 10000, '🥗', unit: 'plate'),
  // Beverages
  _DemoProduct('drinks', 'Borhani', 'বোরহানি', 6000, '🥛', unit: 'glass'),
  _DemoProduct('drinks', 'Lassi', 'লাচ্ছি', 8000, '🥤', unit: 'glass'),
  _DemoProduct('drinks', 'Fresh Lime', 'ফ্রেশ লেবু', 5000, '🍋', unit: 'glass'),
  _DemoProduct('drinks', 'Coca-Cola', 'কোকা-কোলা', 4000, '🥤', unit: 'pcs', vatBp: 500),
  _DemoProduct('drinks', 'Mineral Water', 'পানি', 2000, '💧', unit: 'pcs'),
  _DemoProduct('drinks', 'Tea', 'চা', 2500, '🍵', unit: 'cup'),
  _DemoProduct('drinks', 'Coffee', 'কফি', 6000, '☕', unit: 'cup'),
  // Desserts
  _DemoProduct('dessert', 'Firni', 'ফিরনি', 8000, '🍮', unit: 'bowl'),
  _DemoProduct('dessert', 'Roshmalai', 'রসমালাই', 12000, '🍥', unit: 'plate'),
  _DemoProduct('dessert', 'Ice Cream', 'আইসক্রিম', 9000, '🍨', unit: 'cup'),
  _DemoProduct('dessert', 'Jorda', 'জর্দা', 7000, '🍚', unit: 'plate'),
];

/// Loads the demo catalog for one module ('superShop' or 'restaurant'). No-op
/// (returns false) if that module already has any product — never contaminates
/// a real shop's data. Rows are tagged with [businessType] so the retail
/// catalog and the restaurant menu stay separate.
Future<bool> seedDemoData(AppDatabase db,
    {String businessType = 'superShop'}) async {
  final existing = await (db.select(db.products)
        ..where((p) => p.businessType.equals(businessType))
        ..limit(1))
      .get();
  if (existing.isNotEmpty) return false;

  final restaurant = businessType == 'restaurant';
  final categories = restaurant ? _restaurantCategories : _categories;
  final products = restaurant ? _restaurantProducts : _products;

  await db.transaction(() async {
    final categoryIds = <String, String>{};
    for (final cat in categories) {
      final row = await db.into(db.categories).insertReturning(
            CategoriesCompanion.insert(
              name: cat.en,
              nameBn: Value(cat.bn),
              colorHex: Value(cat.colorHex),
              sortOrder: Value(categories.indexOf(cat)),
              businessType: Value(businessType),
            ),
          );
      categoryIds[cat.key] = row.id;
    }

    for (final item in products) {
      final product = await db.productsDao.insertProduct(
        ProductsCompanion.insert(
          name: item.en,
          nameBn: Value(item.bn),
          categoryId: Value(categoryIds[item.cat]),
          unit: Value(item.unit),
          salePrice: Money(item.pricePaisa),
          vatRateBp: Value(item.vatBp),
          imagePath: Value('emoji:${item.emoji}'),
          barcode: Value(item.barcode),
          lowStockLevel: const Value(Qty(10000)),
          businessType: Value(businessType),
        ),
      );
      await db.stockDao.addMovement(
        productId: product.id,
        qtyDelta: Qty(item.stockMilli),
        type: MovementType.adjustment,
        note: 'demo seed',
      );
    }

    // Customers are shared across modules — seed them only with the retail set.
    if (!restaurant) {
      await db.customersDao.insertCustomer(CustomersCompanion.insert(
          name: 'করিম মিয়া', phone: const Value('01711-000001')));
      await db.customersDao.insertCustomer(CustomersCompanion.insert(
          name: 'রহিমা বেগম', phone: const Value('01812-000002')));
    }
  });
  return true;
}
