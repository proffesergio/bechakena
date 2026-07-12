import 'package:bechakena/core/invoice_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2025, 7, 9);

  group('formatInvoiceNo', () {
    test('prefix-YYMMDD-seq, seq padded to 4', () {
      expect(
        formatInvoiceNo(prefix: 'BK', date: day, seq: 42),
        'BK-250709-0042',
      );
    });

    test('first invoice of the day', () {
      expect(
        formatInvoiceNo(prefix: 'BK', date: day, seq: 1),
        'BK-250709-0001',
      );
    });

    test('device number joins the prefix for multi-device shops', () {
      expect(
        formatInvoiceNo(prefix: 'BK', date: day, seq: 1, deviceNo: 2),
        'BK2-250709-0001',
      );
    });

    test('deviceNo 0 means single-device: bare prefix', () {
      expect(
        formatInvoiceNo(prefix: 'BK', date: day, seq: 7, deviceNo: 0),
        'BK-250709-0007',
      );
    });

    test('seq beyond 9999 grows without truncation', () {
      expect(
        formatInvoiceNo(prefix: 'BK', date: day, seq: 10000),
        'BK-250709-10000',
      );
    });

    test('month and day are zero-padded', () {
      expect(
        formatInvoiceNo(prefix: 'BK', date: DateTime(2026, 1, 5), seq: 3),
        'BK-260105-0003',
      );
    });
  });
}
