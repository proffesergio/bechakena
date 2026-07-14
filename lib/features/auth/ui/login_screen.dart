import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand.dart';
import '../../../app/business_type.dart';
import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../logic/session.dart';

/// Full-screen gate: first-run owner setup when no staff exists, otherwise a
/// staff picker + PIN entry. Verified fully offline.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasStaff = ref.watch(hasStaffProvider);
    final restaurant = ref.watch(isRestaurantProvider);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(restaurant ? '🍽️' : '🛒',
                        style: const TextStyle(fontSize: 56))
                    .animate()
                    .scaleXY(begin: 0.6, curve: Curves.easeOutBack),
                const SizedBox(height: 8),
                Text(Brand.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(restaurant ? l10n.bizRestaurant : l10n.bizSupershop,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 24),
                hasStaff.when(
                  loading: () =>
                      const Padding(padding: EdgeInsets.all(24), child:
                          CircularProgressIndicator()),
                  error: (e, _) => Text('$e'),
                  data: (exists) =>
                      exists ? const _PinLogin() : const _OwnerSetup(),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l10n.switchModule),
                  onPressed: () =>
                      ref.read(businessTypeProvider.notifier).clear(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerSetup extends ConsumerStatefulWidget {
  const _OwnerSetup();

  @override
  ConsumerState<_OwnerSetup> createState() => _OwnerSetupState();
}

class _OwnerSetupState extends ConsumerState<_OwnerSetup> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.setupOwnerTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.setupOwnerSubtitle,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.staffName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.pin),
                validator: (v) =>
                    (v == null || v.trim().length < 4) ? l10n.pinTooShort : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.confirmPin),
                validator: (v) =>
                    v != _pin.text ? l10n.pinMismatch : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _create,
                child: Text(l10n.createAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final db = ref.read(databaseProvider);
    final owner = await db.staffDao.createStaff(
      name: _name.text.trim(),
      pin: _pin.text.trim(),
      role: StaffRole.owner,
    );
    ref.invalidate(hasStaffProvider);
    ref.read(currentStaffProvider.notifier).login(owner);
  }
}

class _PinLogin extends ConsumerStatefulWidget {
  const _PinLogin();

  @override
  ConsumerState<_PinLogin> createState() => _PinLoginState();
}

class _PinLoginState extends ConsumerState<_PinLogin> {
  String? _staffId;
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final staff = ref.watch(staffListProvider).value ?? const <StaffData>[];
    // Keep the selection valid against the *current* staff list. After a module
    // switch the DB (and its staff) changes, so a cached _staffId can point at a
    // member that no longer exists — feeding the dropdown a value absent from
    // its items trips a framework assertion. Fall back to the first member.
    if (_staffId == null || staff.every((s) => s.id != _staffId)) {
      _staffId = staff.isNotEmpty ? staff.first.id : null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.loginTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _staffId,
              decoration: InputDecoration(labelText: l10n.staffName),
              items: [
                for (final s in staff)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() {
                _staffId = v;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pin,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.pin,
                errorText: _error,
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy || _staffId == null ? null : _login,
              child: Text(l10n.login),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final db = ref.read(databaseProvider);
    final ok = await db.staffDao.verifyPin(_staffId!, _pin.text.trim());
    if (ok == null) {
      setState(() {
        _busy = false;
        _error = l10n.wrongPin;
      });
      return;
    }
    ref.read(currentStaffProvider.notifier).login(ok);
  }
}
