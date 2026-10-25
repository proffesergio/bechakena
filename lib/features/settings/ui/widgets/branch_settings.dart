import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../core/db/database.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/logic/permissions.dart';

class BranchSettings extends ConsumerStatefulWidget {
  const BranchSettings({super.key, required this.allow});
  final bool Function(Capability) allow;
  @override
  ConsumerState<BranchSettings> createState() => _BranchSettingsState();
}

class _BranchSettingsState extends ConsumerState<BranchSettings> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final branches = ref.watch(branchesProvider).value ?? const <Shop>[];
    final current = ref.watch(currentBranchProvider);
    final value = (current != null && branches.any((b) => b.id == current))
        ? current
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.branchSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.store_mall_directory),
          title: Text(l10n.currentBranch),
          subtitle: Text(l10n.branchHint),
          trailing: DropdownButton<String>(
            value: value,
            items: [
              for (final b in branches)
                DropdownMenuItem(value: b.id, child: Text(b.name)),
            ],
            onChanged: (id) {
              if (!widget.allow(Capability.manageBranches)) return;
              if (id != null) {
                ref.read(currentBranchProvider.notifier).set(id);
              }
            },
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add_business),
            label: Text(l10n.addBranch),
            onPressed: _addBranch,
          ),
        ),
      ],
    );
  }

  Future<void> _addBranch() async {
    if (!widget.allow(Capability.manageBranches)) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l10n.addBranch),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.branchName),
          onSubmitted: (v) => Navigator.of(dctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    if (!mounted || !widget.allow(Capability.manageBranches)) return;
    final db = ref.read(databaseProvider);
    await db.into(db.shops).insert(ShopsCompanion.insert(name: name));
    messenger.showSnackBar(SnackBar(content: Text(l10n.branchAdded)));
  }

}
