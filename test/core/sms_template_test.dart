import 'package:bechakena/core/money.dart';
import 'package:bechakena/core/sms/templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('renderDueReminderSms', () {
    test('en: names the customer, shop and amount', () {
      final sms = renderDueReminderSms(
        shopName: 'Karim Store',
        customerName: 'Rahim',
        due: const Money(125000),
      );
      expect(sms, contains('Rahim'));
      expect(sms, contains('Karim Store'));
      expect(sms, contains('Tk 1,250.00'));
    });

    test('bn: uses ৳ and Bangla digits', () {
      final sms = renderDueReminderSms(
        shopName: 'করিম স্টোর',
        customerName: 'রহিম',
        due: const Money(125000),
        locale: 'bn',
      );
      expect(sms, contains('রহিম'));
      expect(sms, contains('৳১,২৫০.০০'));
    });
  });

  group('renderReceiptSms', () {
    test('includes invoice and total; adds a due clause only when owed', () {
      final paid = renderReceiptSms(
        shopName: 'Karim Store',
        invoiceNo: 'BK-250709-0001',
        total: const Money(50000),
        due: Money.zero,
      );
      expect(paid, contains('BK-250709-0001'));
      expect(paid, contains('Tk 500.00'));
      expect(paid.toLowerCase(), isNot(contains('due')));

      final withDue = renderReceiptSms(
        shopName: 'Karim Store',
        invoiceNo: 'BK-250709-0002',
        total: const Money(50000),
        due: const Money(20000),
      );
      expect(withDue.toLowerCase(), contains('due'));
      expect(withDue, contains('Tk 200.00'));
    });
  });
}
