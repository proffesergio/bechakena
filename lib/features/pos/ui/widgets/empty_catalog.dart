import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/seed/demo_catalog.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// First-run empty state: offer the demo catalog. On the web demo the catalog
/// seeds itself so visitors land on a populated POS without extra clicks.
class EmptyCatalog extends ConsumerStatefulWidget {
  const EmptyCatalog({super.key, required this.message});

  final String message;

  @override
  ConsumerState<EmptyCatalog> createState() => _EmptyCatalogState();
}

class _EmptyCatalogState extends ConsumerState<EmptyCatalog> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) _autoSeedForDemo();
  }

  /// Browser demo convenience: seed the sample catalog once per visitor
  /// (guarded by a settings flag so Clear/`?fresh=1` is the only reset).
  Future<void> _autoSeedForDemo() async {
    final db = ref.read(databaseProvider);
    if (await db.settingsDao.getValue('demo.seeded') == '1') return;
    final seeded = await seedDemoData(db);
    if (seeded) await db.settingsDao.setValue('demo.seeded', '1');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(widget.message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.loadDemo),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final loaded = await seedDemoData(ref.read(databaseProvider));
              messenger.showSnackBar(SnackBar(
                  content:
                      Text(loaded ? l10n.demoLoaded : l10n.demoSkipped)));
            },
          ),
        ],
      ),
    );
  }
}
