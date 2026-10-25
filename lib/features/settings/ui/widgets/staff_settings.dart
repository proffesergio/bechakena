import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../core/db/database.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/logic/permissions.dart';
import '../../../auth/logic/session.dart';

class StaffSettings extends ConsumerWidget {
  const StaffSettings({super.key, required this.allow, required this.onSwitchModule});
  final bool Function(Capability) allow;
  final VoidCallback onSwitchModule;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentStaffProvider);
    final staff = ref.watch(staffListProvider).value ?? const <StaffData>[];
    final caps = ref.watch(capabilitiesProvider);
    // Managers can add cashiers; only owners can add managers or delete staff.
    final canAddStaff = caps.contains(Capability.addCashier);
    final canManageStaff = caps.contains(Capability.manageStaff);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.staffSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (canAddStaff)
              TextButton.icon(
                icon: const Icon(Icons.person_add),
                label: Text(l10n.addStaff),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _AddStaffDialog(),
                ),
              ),
          ],
        ),
        for (final s in staff)
          ListTile(
            dense: true,
            leading: const Icon(Icons.badge),
            title: Text(s.name),
            subtitle: Text(_roleLabel(l10n, s.role)),
            trailing: canManageStaff && s.id != me?.id
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          content: Text(l10n.removeStaff(s.name)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dctx).pop(false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(dctx).pop(true),
                              child: Text(l10n.remove),
                            ),
                          ],
                        ),
                      );
                      if (ok ?? false) {
                        if (!context.mounted || !allow(Capability.manageStaff)) return;
                        await ref
                            .read(databaseProvider)
                            .staffDao
                            .softDelete(s.id);
                      }
                    },
                  )
                : null,
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (me != null)
              Expanded(
                child: Text(
                  l10n.loggedInAs(me.name),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (caps.contains(Capability.switchModule)) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: Text(l10n.switchModule),
                onPressed: onSwitchModule,
              ),
              const SizedBox(width: 12),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              onPressed: () => ref.read(currentStaffProvider.notifier).logout(),
            ),
          ],
        ),
      ],
    );
  }

  String _roleLabel(AppLocalizations l10n, StaffRole role) => switch (role) {
    StaffRole.owner => l10n.roleOwner,
    StaffRole.manager => l10n.roleManager,
    StaffRole.cashier => l10n.roleCashier,
  };
}

class _AddStaffDialog extends ConsumerStatefulWidget {
  const _AddStaffDialog();

  @override
  ConsumerState<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends ConsumerState<_AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _pin = TextEditingController();
  StaffRole _role = StaffRole.cashier;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Only full staff managers (owners) can grant the manager role; managers
    // may add cashiers only.
    final canAddManager = ref
        .watch(capabilitiesProvider)
        .contains(Capability.manageStaff);
    return AlertDialog(
      title: Text(l10n.addStaff),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                validator: (v) => (v == null || v.trim().length < 4)
                    ? l10n.pinTooShort
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StaffRole>(
                initialValue: _role,
                decoration: InputDecoration(labelText: l10n.role),
                items: [
                  if (canAddManager)
                    DropdownMenuItem(
                      value: StaffRole.manager,
                      child: Text(l10n.roleManager),
                    ),
                  DropdownMenuItem(
                    value: StaffRole.cashier,
                    child: Text(l10n.roleCashier),
                  ),
                ],
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final requiredCapability = _role == StaffRole.cashier
                ? Capability.addCashier
                : Capability.manageStaff;
            if (!ref.read(capabilitiesProvider).contains(requiredCapability)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.globalPermissionDenied)),
              );
              return;
            }
            final navigator = Navigator.of(context);
            await ref
                .read(databaseProvider)
                .staffDao
                .createStaff(
                  name: _name.text.trim(),
                  pin: _pin.text.trim(),
                  role: _role,
                );
            if (mounted) navigator.pop();
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
