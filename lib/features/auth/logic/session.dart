import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';

/// The currently signed-in staff member, or null when locked.
/// Sales are attributed to this staff; the app shell is gated behind it.
class SessionController extends Notifier<StaffData?> {
  @override
  StaffData? build() => null;

  void login(StaffData staff) => state = staff;
  void logout() => state = null;
}

final currentStaffProvider =
    NotifierProvider<SessionController, StaffData?>(SessionController.new);

/// All active staff (login picker, staff management).
final staffListProvider = StreamProvider<List<StaffData>>(
    (ref) => ref.watch(databaseProvider).staffDao.watchStaff());

/// Whether any staff exists — drives first-run owner setup.
final hasStaffProvider = FutureProvider<bool>(
    (ref) => ref.watch(databaseProvider).staffDao.hasAnyStaff());
