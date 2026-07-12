import 'package:drift/drift.dart';

import '../database.dart';

part 'sms_dao.g.dart';

/// Local SMS outbox. Messages are queued offline (offline-first); a cloud
/// dispatcher (Cloud Plan) later sends them and calls [markSent]/[markFailed].
@DriftAccessor(tables: [SmsLog])
class SmsDao extends DatabaseAccessor<AppDatabase> with _$SmsDaoMixin {
  SmsDao(super.db);

  Future<SmsLogData> enqueue({
    required String phone,
    required SmsKind kind,
    required String body,
    Value<String?> customerId = const Value.absent(),
    DateTime? at,
  }) =>
      into(smsLog).insertReturning(SmsLogCompanion.insert(
        phone: phone,
        kind: kind,
        body: body,
        status: SmsStatus.queued,
        customerId: customerId,
        createdAt: at == null ? const Value.absent() : Value(at),
      ));

  Stream<List<SmsLogData>> watchQueued() => (select(smsLog)
        ..where((s) => s.status.equalsValue(SmsStatus.queued))
        ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
      .watch();

  Stream<List<SmsLogData>> watchLog({int limit = 200}) => (select(smsLog)
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
        ..limit(limit))
      .watch();

  Future<void> markSent(String id) => _setStatus(id, SmsStatus.sent);
  Future<void> markFailed(String id) => _setStatus(id, SmsStatus.failed);

  Future<void> _setStatus(String id, SmsStatus status) =>
      (update(smsLog)..where((s) => s.id.equals(id))).write(SmsLogCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now().toUtc()),
      ));
}
