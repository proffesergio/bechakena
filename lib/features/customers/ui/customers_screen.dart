import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand.dart';
import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/sms/templates.dart';
import '../../../l10n/gen/app_localizations.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customers = ref.watch(customersProvider);

    return Scaffold(
      body: customers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) => all.isEmpty
            ? Center(child: Text(l10n.noCustomers))
            : ListView.separated(
                itemCount: all.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _CustomerTile(customer: all[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addCustomer),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const AddCustomerDialog(),
        ),
      ),
    );
  }
}

class _CustomerTile extends ConsumerWidget {
  const _CustomerTile({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final due = ref.watch(customerDueProvider(customer.id));
    final dueMoney = due.value ?? Money.zero;

    final canRemind = dueMoney > Money.zero && (customer.phone?.isNotEmpty ?? false);
    return ListTile(
      title: Text(customer.name),
      subtitle: customer.phone == null ? null : Text(customer.phone!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canRemind)
            IconButton(
              tooltip: l10n.dueReminderSms,
              icon: const Icon(Icons.sms),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => DueReminderDialog(
                    customer: customer, due: dueMoney),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l10n.dueLabel,
                  style: Theme.of(context).textTheme.bodySmall),
              Text(
                formatTaka(dueMoney, locale: locale),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: dueMoney > Money.zero
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
              ),
            ],
          ),
        ],
      ),
      onTap: dueMoney > Money.zero
          ? () => showDialog<void>(
                context: context,
                builder: (_) => ReceivePaymentDialog(
                    customerId: customer.id, outstanding: dueMoney),
              )
          : null,
    );
  }
}

/// Previews the due-reminder SMS and queues it in the local outbox. Actual
/// delivery happens via the Cloud Plan dispatcher (offline-first: additive).
class DueReminderDialog extends ConsumerWidget {
  const DueReminderDialog({super.key, required this.customer, required this.due});

  final Customer customer;
  final Money due;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final message = renderDueReminderSms(
      shopName: Brand.name,
      customerName: customer.name,
      due: due,
      locale: locale,
    );

    return AlertDialog(
      title: Text(l10n.dueReminderSms),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.phone ?? '',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.sms),
          label: Text(l10n.queueSms),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final shopName =
                await ref.read(databaseProvider).settingsDao.getValue('shop.name');
            await ref.read(databaseProvider).smsDao.enqueue(
                  phone: customer.phone!,
                  kind: SmsKind.dueReminder,
                  body: renderDueReminderSms(
                    shopName: shopName ?? Brand.name,
                    customerName: customer.name,
                    due: due,
                    locale: locale,
                  ),
                  customerId: Value(customer.id),
                );
            navigator.pop();
            messenger.showSnackBar(SnackBar(content: Text(l10n.smsQueued)));
          },
        ),
      ],
    );
  }
}

class AddCustomerDialog extends ConsumerStatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addCustomer),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.customerName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(labelText: l10n.phone),
                keyboardType: TextInputType.phone,
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
            final navigator = Navigator.of(context);
            final phone = _phone.text.trim();
            await ref
                .read(databaseProvider)
                .customersDao
                .insertCustomer(CustomersCompanion.insert(
                  name: _name.text.trim(),
                  phone: Value(phone.isEmpty ? null : phone),
                ));
            if (mounted) navigator.pop();
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class ReceivePaymentDialog extends ConsumerStatefulWidget {
  const ReceivePaymentDialog(
      {super.key, required this.customerId, required this.outstanding});

  final String customerId;
  final Money outstanding;

  @override
  ConsumerState<ReceivePaymentDialog> createState() =>
      _ReceivePaymentDialogState();
}

class _ReceivePaymentDialogState extends ConsumerState<ReceivePaymentDialog> {
  late final TextEditingController _amount =
      TextEditingController(text: widget.outstanding.asDecimalString);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Money? get _amountMoney {
    try {
      final m = Money.parse(_amount.text);
      return (m.isZero || m.isNegative) ? null : m;
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = _amountMoney;
    return AlertDialog(
      title: Text(l10n.receivePayment),
      content: TextField(
        controller: _amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.amount,
          errorText: amount == null ? l10n.invalidAmount : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: amount == null
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  await ref.read(databaseProvider).customersDao.addDuePayment(
                        customerId: widget.customerId,
                        amount: amount,
                        method: PayMethod.cash,
                      );
                  ref.invalidate(customerDueProvider(widget.customerId));
                  if (mounted) navigator.pop();
                },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
