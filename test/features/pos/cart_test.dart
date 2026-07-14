import 'package:bechakena/core/db/database.dart';
import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/qty.dart';
import 'package:bechakena/features/pos/logic/cart_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Product product({
  String id = 'p1',
  String name = 'Rice 1kg',
  int pricePaisa = 5000,
  int vatRateBp = 0,
}) {
  final now = DateTime.utc(2025);
  return Product(
    id: id,
    updatedAt: now,
    deviceId: 'test',
    name: name,
    unit: 'pcs',
    salePrice: Money(pricePaisa),
    costPrice: Money.zero,
    vatRateBp: vatRateBp,
    lowStockLevel: Qty.zero,
    isActive: true,
    businessType: 'superShop',
  );
}

void main() {
  late ProviderContainer container;
  late CartController cart;

  setUp(() {
    container = ProviderContainer();
    cart = container.read(cartProvider.notifier);
  });

  tearDown(() => container.dispose());

  CartState state() => container.read(cartProvider);

  test('starts empty', () {
    expect(state().isEmpty, isTrue);
    expect(state().total, Money.zero);
  });

  test('adding a product creates a line of qty 1', () {
    cart.addProduct(product());
    expect(state().lines.length, 1);
    expect(state().lines.single.qty, Qty.fromCount(1));
    expect(state().total, const Money(5000));
  });

  test('adding the same product again merges into one line', () {
    cart.addProduct(product());
    cart.addProduct(product());
    expect(state().lines.length, 1);
    expect(state().lines.single.qty, Qty.fromCount(2));
    expect(state().total, const Money(10000));
  });

  test('different products get separate lines', () {
    cart.addProduct(product(id: 'p1'));
    cart.addProduct(product(id: 'p2', name: 'Oil', pricePaisa: 18000));
    expect(state().lines.length, 2);
    expect(state().total, const Money(23000));
  });

  test('setQty to zero removes the line', () {
    cart.addProduct(product());
    cart.setQty(0, Qty.zero);
    expect(state().isEmpty, isTrue);
  });

  test('manual (unlisted) item', () {
    cart.addManual(name: 'Polythene bag', price: const Money(500));
    expect(state().lines.single.productId, null);
    expect(state().total, const Money(500));
  });

  test('VAT sums per line from inclusive prices', () {
    cart.addProduct(product(pricePaisa: 11500, vatRateBp: 1500));
    expect(state().vat, const Money(1500));
    expect(state().total, const Money(11500));
  });

  test('bill discount reduces total but not subtotal', () {
    cart.addProduct(product(pricePaisa: 10000));
    cart.setBillDiscount(const Money(1000));
    expect(state().subtotal, const Money(10000));
    expect(state().total, const Money(9000));
  });

  test('clear resets everything', () {
    cart.addProduct(product());
    cart.setBillDiscount(const Money(100));
    cart.clear();
    expect(state().isEmpty, isTrue);
    expect(state().billDiscount, Money.zero);
  });

  test('toDraftItems maps lines for finalizeSale', () {
    cart.addProduct(product(pricePaisa: 11500, vatRateBp: 1500));
    cart.addManual(name: 'Bag', price: const Money(500));
    final drafts = cart.toDraftItems();
    expect(drafts.length, 2);
    expect(drafts[0].productId, 'p1');
    expect(drafts[0].vatRateBp, 1500);
    expect(drafts[1].productId, null);
    expect(drafts[1].nameSnapshot, 'Bag');
  });
}
