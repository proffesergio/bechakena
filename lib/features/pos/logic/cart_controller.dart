import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/sale_draft.dart';
import '../../../core/money.dart';
import '../../../core/qty.dart';

class CartLine {
  const CartLine({
    this.productId,
    required this.name,
    required this.unitPrice,
    required this.qty,
    this.vatRateBp = 0,
    this.lineDiscount = Money.zero,
  });

  final String? productId;
  final String name;
  final Money unitPrice;
  final Qty qty;
  final int vatRateBp;
  final Money lineDiscount;

  Money get lineTotal => unitPrice.timesQty(qty) - lineDiscount;

  CartLine copyWith({Qty? qty, Money? lineDiscount}) => CartLine(
        productId: productId,
        name: name,
        unitPrice: unitPrice,
        qty: qty ?? this.qty,
        vatRateBp: vatRateBp,
        lineDiscount: lineDiscount ?? this.lineDiscount,
      );
}

class CartState {
  const CartState({this.lines = const [], this.billDiscount = Money.zero});

  final List<CartLine> lines;
  final Money billDiscount;

  bool get isEmpty => lines.isEmpty;

  Money get subtotal =>
      lines.fold(Money.zero, (sum, line) => sum + line.lineTotal);

  Money get vat => lines.fold(Money.zero,
      (sum, line) => sum + line.lineTotal.vatPortionInclusive(line.vatRateBp));

  Money get total => subtotal - billDiscount;
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addProduct(Product product) {
    final index = state.lines.indexWhere((l) => l.productId == product.id);
    if (index >= 0) {
      setQty(index, state.lines[index].qty + Qty.fromCount(1));
      return;
    }
    state = CartState(
      lines: [
        ...state.lines,
        CartLine(
          productId: product.id,
          name: product.name,
          unitPrice: product.salePrice,
          qty: Qty.fromCount(1),
          vatRateBp: product.vatRateBp,
        ),
      ],
      billDiscount: state.billDiscount,
    );
  }

  void addManual({
    required String name,
    required Money price,
    Qty qty = const Qty(1000),
  }) {
    state = CartState(
      lines: [
        ...state.lines,
        CartLine(name: name, unitPrice: price, qty: qty),
      ],
      billDiscount: state.billDiscount,
    );
  }

  void setQty(int index, Qty qty) {
    final lines = [...state.lines];
    if (qty <= Qty.zero) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(qty: qty);
    }
    state = CartState(lines: lines, billDiscount: state.billDiscount);
  }

  void removeAt(int index) => setQty(index, Qty.zero);

  void setBillDiscount(Money discount) {
    state = CartState(lines: state.lines, billDiscount: discount);
  }

  void clear() => state = const CartState();

  List<SaleDraftItem> toDraftItems() => [
        for (final line in state.lines)
          SaleDraftItem(
            productId: line.productId,
            nameSnapshot: line.name,
            qty: line.qty,
            unitPrice: line.unitPrice,
            lineDiscount: line.lineDiscount,
            vatRateBp: line.vatRateBp,
          ),
      ];
}

final cartProvider =
    NotifierProvider<CartController, CartState>(CartController.new);
