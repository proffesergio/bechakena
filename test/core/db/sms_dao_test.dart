import 'package:bechakena/core/db/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  group('SmsDao', () {
    test('enqueue persists a queued message', () async {
      final sms = await db.smsDao.enqueue(
        phone: '01711000000',
        kind: SmsKind.dueReminder,
        body: 'Your due is Tk 100.',
      );
      expect(sms.status, SmsStatus.queued);
      expect(sms.phone, '01711000000');
      final queued = await db.smsDao.watchQueued().first;
      expect(queued, hasLength(1));
    });

    test('markSent moves a message out of the queue', () async {
      final sms = await db.smsDao.enqueue(
        phone: '01711000000',
        kind: SmsKind.receipt,
        body: 'Receipt',
      );
      await db.smsDao.markSent(sms.id);
      expect(await db.smsDao.watchQueued().first, isEmpty);
      final all = await db.smsDao.watchLog().first;
      expect(all.single.status, SmsStatus.sent);
    });

    test('markFailed records the failure but keeps the log entry', () async {
      final sms = await db.smsDao
          .enqueue(phone: '019', kind: SmsKind.receipt, body: 'x');
      await db.smsDao.markFailed(sms.id);
      final all = await db.smsDao.watchLog().first;
      expect(all.single.status, SmsStatus.failed);
      expect(await db.smsDao.watchQueued().first, isEmpty);
    });

    test('log is newest-first', () async {
      await db.smsDao.enqueue(
          phone: '1', kind: SmsKind.receipt, body: 'a', at: DateTime.utc(2025, 1, 1));
      await db.smsDao.enqueue(
          phone: '2', kind: SmsKind.receipt, body: 'b', at: DateTime.utc(2025, 1, 2));
      final log = await db.smsDao.watchLog().first;
      expect(log.first.phone, '2');
    });

    test('enqueue can attach a customer', () async {
      final customer = await db.customersDao
          .insertCustomer(CustomersCompanion.insert(name: 'X'));
      final sms = await db.smsDao.enqueue(
          phone: '1',
          kind: SmsKind.dueReminder,
          body: 'y',
          customerId: Value(customer.id));
      expect(sms.customerId, customer.id);
    });
  });
}
