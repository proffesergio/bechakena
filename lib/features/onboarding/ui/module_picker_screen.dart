import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/brand.dart';
import '../../../app/business_type.dart';
import '../../../app/providers.dart';
import '../../../core/seed/demo_catalog.dart';
import '../../../l10n/gen/app_localizations.dart';

/// First screen of all — shown before login. The operator picks which module
/// this device runs; the choice opens that module's own database (its own
/// staff, catalog and data) and is remembered, so later launches go straight to
/// that module's login. "Switch module" (login/Settings) returns here.
class ModulePickerScreen extends ConsumerWidget {
  const ModulePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(Brand.name)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.chooseModule,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(l10n.chooseModuleHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final cards = [
                      _ModuleCard(
                        icon: Icons.storefront,
                        title: l10n.bizSupershop,
                        description: l10n.bizSupershopDesc,
                        onTap: () => _pick(ref, BusinessType.superShop),
                      ),
                      _ModuleCard(
                        icon: Icons.restaurant,
                        title: l10n.bizRestaurant,
                        description: l10n.bizRestaurantDesc,
                        onTap: () => _pick(ref, BusinessType.restaurant),
                      ),
                    ];
                    return c.maxWidth < 520
                        ? Column(children: cards)
                        : Row(
                            children: [
                              for (final card in cards) Expanded(child: card),
                            ],
                          );
                  },
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(WidgetRef ref, BusinessType type) async {
    // Select the module first so [databaseProvider] switches to that module's
    // database, then seed a demo menu the first time Restaurant is opened
    // (no-op if it already has items). Retail keeps its manual demo button.
    await ref.read(businessTypeProvider.notifier).set(type);
    if (type == BusinessType.restaurant) {
      await seedDemoData(ref.read(databaseProvider),
          businessType: BusinessType.restaurant.name);
    }
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(icon, size: 32, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
