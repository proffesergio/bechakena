import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/product_picker.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../logic/cart_controller.dart';
import 'widgets/cart_pane.dart';
import 'widgets/empty_catalog.dart';

/// POS orchestrator: product picker on the left, invoice pane on the right.
/// The pane, checkout/ manual-item dialogs and the demo-catalog empty state
/// live in `widgets/`.
class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ProductPicker(
            onPick: (p) => ref.read(cartProvider.notifier).addProduct(p),
            emptyBuilder: (_) => EmptyCatalog(message: l10n.noProducts),
          ),
        ),
        const VerticalDivider(width: 1),
        const SizedBox(width: 380, child: CartPane()),
      ],
    );
  }
}
