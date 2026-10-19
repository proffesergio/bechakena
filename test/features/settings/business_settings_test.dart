import 'dart:io';
import 'dart:async';

import 'package:bechakena/app/providers.dart';
import 'package:bechakena/core/currency.dart';
import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/db/device_store.dart';
import 'package:bechakena/core/db/sale_draft.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/printing/print_service.dart';
import 'package:bechakena/core/printing/receipt.dart';
import 'package:bechakena/core/qty.dart';
import 'package:bechakena/features/settings/data/business_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BusinessSettingsStore store;
  setUp(() { db = AppDatabase(NativeDatabase.memory()); store = BusinessSettingsStore(db); });
  tearDown(() => db.close());

  test('defaults preserve legacy BDT; persisted settings survive a new store', () async {
    expect((await store.load()).currency, ShopCurrency.bdt);
    await store.save(const BusinessSettings(currency: ShopCurrency.usd,
      taxLabel: 'GST', taxId: 'US-123'), canManage: () => true);
    final restored = await BusinessSettingsStore(db).load();
    expect(restored.currency, ShopCurrency.usd);
    expect(restored.taxLabel, 'GST'); expect(restored.taxId, 'US-123');
  });

  test('runtime permission denial and mid-save revocation roll back', () async {
    const value = BusinessSettings(currency: ShopCurrency.eur);
    await expectLater(store.save(value, canManage: () => false), throwsA(isA<BusinessSettingsException>()));
    var checks = 0;
    await expectLater(store.save(value, canManage: () => ++checks < 3), throwsA(isA<BusinessSettingsException>()));
    expect((await store.load()).currency, ShopCurrency.bdt);
    expect(await db.settingsDao.getValue('business.currency'), isNull);
  });

  test('catalog prices lock currency, including soft-deleted prices', () async {
    final product = await db.productsDao.insertProduct(
      ProductsCompanion.insert(name: 'Rice', salePrice: const Money(1250)));
    await db.productsDao.softDelete(product.id);
    expect(await store.currencyLocked(), isTrue);
    await expectLater(store.save(const BusinessSettings(currency: ShopCurrency.gbp),
      canManage: () => true), throwsA(isA<BusinessSettingsException>()));
    await store.save(const BusinessSettings(taxLabel: 'GST', taxId: '123'), canManage: () => true);
    expect((await store.load()).taxLabel, 'GST');
  });

  test('manual sales lock currency and receipt/reprint carry saved tax details', () async {
    await store.save(const BusinessSettings(currency: ShopCurrency.aed,
      taxLabel: 'VAT', taxId: 'AE123456'), canManage: () => true);
    final sale = await db.salesDao.finalizeSale(invoicePrefix: 'TEST',
      items: [const SaleDraftItem(nameSnapshot: 'Coffee', qty: Qty(1000), unitPrice: Money(1250))],
      tenders: [const TenderDraft(method: PayMethod.cash, amount: Money(1250))]);
    final data = receiptFromSale(sale: sale, items: await db.salesDao.itemsOf(sale.id),
      shopName: 'Shop', business: await BusinessSettingsStore(db).load());
    final text = renderReceiptText(data);
    expect(text, contains('AED 12.50'));
    expect(text, contains('VAT ID: AE123456'));
    expect(text, isNot(contains('Tk')));
    expect(data.copyWith(paid: const Money(1000)).currency, ShopCurrency.aed);
    await expectLater(store.save(const BusinessSettings(currency: ShopCurrency.usd),
      canManage: () => true), throwsA(isA<BusinessSettingsException>()));
  });

  test('tax details reject receipt control characters atomically', () async {
    await expectLater(store.save(const BusinessSettings(currency: ShopCurrency.usd,
      taxLabel: 'GST\nTOTAL', taxId: '123'), canManage: () => true),
      throwsA(isA<BusinessSettingsException>()));
    expect((await store.load()).currency, ShopCurrency.bdt);
  });

  test('providers react to saved currency without shared global state', () async {
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final sub = container.listen(businessSettingsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(businessSettingsProvider.future);
    expect(container.read(shopCurrencyProvider), ShopCurrency.bdt);
    final updated = Completer<void>();
    final change = container.listen(businessSettingsProvider, (_, next) {
      if (next.value?.currency == ShopCurrency.eur && !updated.isCompleted) updated.complete();
    });
    addTearDown(change.close);
    await store.save(const BusinessSettings(currency: ShopCurrency.eur), canManage: () => true);
    await updated.future.timeout(const Duration(seconds: 5));
    expect(container.read(shopCurrencyProvider), ShopCurrency.eur);
  });

  test('language selection survives provider recreation', () async {
    final dir = await Directory.systemTemp.createTemp('business-language-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/device.json');
    final device = DeviceStore(file, {});
    final first = ProviderContainer(overrides: [deviceStoreProvider.overrideWithValue(device)]);
    await first.read(localeProvider.notifier).set(const Locale('bn'));
    first.dispose();
    final second = ProviderContainer(overrides: [deviceStoreProvider.overrideWithValue(device)]);
    addTearDown(second.dispose);
    expect(second.read(localeProvider), const Locale('bn'));
    expect(await file.readAsString(), contains('bn'));
  });
}
