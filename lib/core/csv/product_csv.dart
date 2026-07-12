import '../money.dart';
import '../qty.dart';

/// A product parsed from / to be written to CSV (transport shape, decoupled
/// from Drift rows so it stays pure and testable).
class ProductCsvRow {
  const ProductCsvRow({
    required this.name,
    this.nameBn,
    this.barcode,
    this.unit = 'pcs',
    required this.salePrice,
    this.vatRateBp = 0,
    this.openingStock = Qty.zero,
  });

  final String name;
  final String? nameBn;
  final String? barcode;
  final String unit;
  final Money salePrice;
  final int vatRateBp;
  final Qty openingStock;
}

class ProductImportResult {
  const ProductImportResult({required this.products, required this.errors});
  final List<ProductCsvRow> products;

  /// Human-readable, one per rejected row; import proceeds with the rest.
  final List<String> errors;
}

const _columns = [
  'name',
  'nameBn',
  'barcode',
  'unit',
  'price',
  'vatBp',
  'openingStock',
];

/// RFC-4180-ish CSV parser: quoted fields, escaped quotes (`""`), embedded
/// commas and newlines, CRLF or LF. Returns rows of string cells.
List<List<String>> parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  while (i < input.length) {
    final ch = input[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(ch);
      i++;
      continue;
    }
    switch (ch) {
      case '"':
        inQuotes = true;
      case ',':
        endField();
      case '\r':
        if (i + 1 < input.length && input[i + 1] == '\n') i++;
        endRow();
      case '\n':
        endRow();
      default:
        field.write(ch);
    }
    i++;
  }
  // Flush the final field/row unless the input ended on a clean row break.
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// Encodes rows to CSV, quoting any cell containing a comma, quote, or newline.
String encodeCsv(List<List<String>> rows) {
  String cell(String value) {
    if (value.contains(RegExp(r'[",\r\n]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  return rows.map((r) => r.map(cell).join(',')).join('\r\n');
}

/// Parses product rows with a tolerant header (any column order; optional
/// columns may be absent). Row-level failures are collected, not thrown.
ProductImportResult parseProductRows(String csv) {
  final rows = parseCsv(csv);
  if (rows.isEmpty) {
    return const ProductImportResult(products: [], errors: ['Empty file']);
  }
  final header = rows.first.map((h) => h.trim()).toList();
  final index = {for (var i = 0; i < header.length; i++) header[i]: i};
  for (final required in ['name', 'price']) {
    if (!index.containsKey(required)) {
      return ProductImportResult(
          products: const [], errors: ['Missing required column: $required']);
    }
  }

  final products = <ProductCsvRow>[];
  final errors = <String>[];
  String? cell(List<String> r, String col) {
    final i = index[col];
    if (i == null || i >= r.length) return null;
    final v = r[i].trim();
    return v.isEmpty ? null : v;
  }

  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    final rowNo = r + 1; // 1-based, header is row 1
    try {
      final name = cell(row, 'name');
      if (name == null) throw const FormatException('name is required');
      final priceStr = cell(row, 'price');
      if (priceStr == null) throw const FormatException('price is required');
      final stock = cell(row, 'openingStock');
      products.add(ProductCsvRow(
        name: name,
        nameBn: cell(row, 'nameBn'),
        barcode: cell(row, 'barcode'),
        unit: cell(row, 'unit') ?? 'pcs',
        salePrice: Money.parse(priceStr),
        vatRateBp: int.tryParse(cell(row, 'vatBp') ?? '0') ?? 0,
        openingStock: stock == null ? Qty.zero : Qty.parse(stock),
      ));
    } on FormatException catch (e) {
      errors.add('Row $rowNo: ${e.message}');
    }
  }
  return ProductImportResult(products: products, errors: errors);
}

/// Serializes products to CSV with the canonical header.
String productsToCsv(List<ProductCsvRow> products) {
  final rows = <List<String>>[
    _columns,
    for (final p in products)
      [
        p.name,
        p.nameBn ?? '',
        p.barcode ?? '',
        p.unit,
        p.salePrice.asDecimalString,
        '${p.vatRateBp}',
        p.openingStock.isZero ? '' : p.openingStock.display,
      ],
  ];
  return encodeCsv(rows);
}
