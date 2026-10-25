import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/widgets/product_picker.dart';
import '../../../core/db/database.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../logic/order_math.dart';
import '../../auth/logic/access.dart';
import 'widgets/order_pane.dart';

/// The running-order surface: menu grid on the left, the live tab on the right.
/// Items persist to the DB as they're added, so the tab survives navigation and
/// restarts. From here the waiter fires a kitchen ticket and settles the bill;
/// the pane and dialogs live in `widgets/`.
class OrderEditorScreen extends ConsumerWidget {
  const OrderEditorScreen({super.key, required this.order, required this.title});

  final DineOrder order;

  /// Human label for the order (table name, or guest/order type).
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (!canViewBranch(ref.watch(readScopeBranchProvider), order.branchId)) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(l10n.accessRestricted)));
    }
    return Scaffold(
      appBar: AppBar(
        // Explicit back affordance to the floor/hub, always available.
        leading: const BackButton(),
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(label: Text(orderTypeLabel(l10n, order.orderType))),
          ),
          IconButton(
            tooltip: l10n.cancelOrder,
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _confirmCancel(context, ref),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: ProductPicker(
              onPick: (p) =>
                  ref.read(databaseProvider).ordersDao.addProduct(order.id, p),
              emptyBuilder: (_) => Center(child: Text(l10n.noProducts)),
            ),
          ),
          const VerticalDivider(width: 1),
          SizedBox(width: 380, child: OrderPane(order: order, title: title)),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l10n.cancelOrder),
        content: Text(l10n.cancelOrderConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dctx).colorScheme.error),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l10n.cancelOrder),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).ordersDao.cancelOrder(order.id);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.orderCancelled)));
  }
}
