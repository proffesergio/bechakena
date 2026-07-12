// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_dao.dart';

// ignore_for_file: type=lint
mixin _$SmsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
  $SmsLogTable get smsLog => attachedDatabase.smsLog;
  SmsDaoManager get managers => SmsDaoManager(this);
}

class SmsDaoManager {
  final _$SmsDaoMixin _db;
  SmsDaoManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$SmsLogTableTableManager get smsLog =>
      $$SmsLogTableTableManager(_db.attachedDatabase, _db.smsLog);
}
