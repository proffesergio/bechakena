import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/logic/session.dart';
import 'order_editor_screen.dart';

/// Restaurant floor. Each card is a dining table: tap a free one to open a new
/// dine-in order, or a busy one to resume its running tab. An "edit" toggle
/// flips the floor into management mode for adding/editing/removing tables.
class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  bool _manage = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tables = ref.watch(diningTablesProvider);
    final openOrders = ref.watch(openOrdersProvider).value ?? const <DineOrder>[];
    // Which table each open dine-in order is sitting on.
    final orderByTable = {
      for (final o in openOrders)
        if (o.tableId != null) o.tableId!: o,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTables),
        actions: [
          IconButton(
            tooltip: _manage ? l10n.doneManaging : l10n.manageTables,
            icon: Icon(_manage ? Icons.check : Icons.edit),
            onPressed: () => setState(() => _manage = !_manage),
          ),
        ],
      ),
      body: tables.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.noTables))
            : GridView.extent(
                padding: const EdgeInsets.all(16),
                maxCrossAxisExtent: 210,
                childAspectRatio: 1.15,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final t in list)
                    _TableCard(
                      table: t,
                      order: orderByTable[t.id],
                      manage: _manage,
                    ),
                ],
              ),
      ),
      floatingActionButton: _manage
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l10n.addTable),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const TableEditDialog(),
              ),
            )
          : null,
    );
  }
}

class _TableCard extends ConsumerWidget {
  const _TableCard(
      {required this.table, required this.order, required this.manage});

  final DiningTable table;
  final DineOrder? order;
  final bool manage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final occupied = order != null;
    // Running total for an occupied table (live).
    final items = occupied
        ? (ref.watch(orderItemsProvider(order!.id)).value ??
            const <DineOrderItem>[])
        : const <DineOrderItem>[];
    final total = items.fold(
        Money.zero, (Money s, i) => s + i.unitPrice.timesQty(i.qty));

    return Card(
      color: occupied ? scheme.tertiaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: manage
            ? () => showDialog<void>(
                context: context,
                builder: (_) => TableEditDialog(table: table))
            : () => _openTable(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_restaurant,
                      color: occupied ? scheme.onTertiaryContainer : null),
                  const Spacer(),
                  if (manage)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.deleteTable,
                      onPressed: () => _confirmDelete(context, ref),
                    )
                  else
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                          occupied ? l10n.tableOccupied : l10n.tableFree),
                    ),
                ],
              ),
              const Spacer(),
              Text(table.name,
                  style: Theme.of(context).textTheme.titleMedium),
              if (table.area != null && table.area!.isNotEmpty)
                Text(table.area!,
                    style: Theme.of(context).textTheme.bodySmall),
              if (occupied)
                Text(
                  '${formatTaka(total, locale: locale)} · ${l10n.itemsCount(items.length.toString())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600),
                )
              else if (table.seats > 0)
                Text('${table.seats} 🪑',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTable(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(databaseProvider).ordersDao;
    final navigator = Navigator.of(context);
    var current = order ?? await dao.openOrderForTable(table.id);
    current ??= await dao.createOrder(
      tableId: table.id,
      orderType: OrderType.dineIn,
      staffId: ref.read(currentStaffProvider)?.id,
    );
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => OrderEditorScreen(order: current!, title: table.name),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l10n.deleteTable),
        content: Text('${table.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dctx).colorScheme.error),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l10n.deleteTable),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(databaseProvider);
    await (db.update(db.diningTables)..where((t) => t.id.equals(table.id)))
        .write(DiningTablesCompanion(
      deletedAt: Value(DateTime.now().toUtc()),
      updatedAt: Value(DateTime.now().toUtc()),
    ));
    messenger.showSnackBar(SnackBar(content: Text(l10n.tableDeleted)));
  }
}

class TableEditDialog extends ConsumerStatefulWidget {
  const TableEditDialog({super.key, this.table});

  final DiningTable? table;

  @override
  ConsumerState<TableEditDialog> createState() => _TableEditDialogState();
}

class _TableEditDialogState extends ConsumerState<TableEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _area;
  late final TextEditingController _seats;

  bool get _isEdit => widget.table != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.table?.name ?? '');
    _area = TextEditingController(text: widget.table?.area ?? '');
    _seats = TextEditingController(
        text: (widget.table?.seats ?? 0) == 0 ? '' : '${widget.table!.seats}');
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _seats.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_isEdit ? l10n.editTable : l10n.addTable),
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
                decoration: InputDecoration(labelText: l10n.tableName),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _area,
                decoration: InputDecoration(labelText: l10n.tableArea),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _seats,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.tableSeats),
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
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final db = ref.read(databaseProvider);
    final name = _name.text.trim();
    final area = _area.text.trim();
    final seats = int.tryParse(_seats.text.trim()) ?? 0;

    if (_isEdit) {
      await db.update(db.diningTables).replace(widget.table!.copyWith(
            name: name,
            area: Value(area.isEmpty ? null : area),
            seats: seats,
            updatedAt: DateTime.now().toUtc(),
          ));
    } else {
      await db.into(db.diningTables).insert(DiningTablesCompanion.insert(
            name: name,
            area: Value(area.isEmpty ? null : area),
            seats: Value(seats),
          ));
    }
    if (mounted) navigator.pop();
  }
}
