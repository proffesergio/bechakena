import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/brand.dart';
import '../../../app/providers.dart';
import '../../../core/db/open.dart';
import '../../../core/printing/escpos.dart';
import '../../../core/seed/demo_catalog.dart';
import '../../../core/printing/print_service.dart';
import '../../../l10n/gen/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _shopName = TextEditingController();
  final _shopPhone = TextEditingController();
  final _shopAddress = TextEditingController();
  final _footer = TextEditingController();
  final _printerHost = TextEditingController();
  final _printerPort = TextEditingController();
  String _paperWidth = '32';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(databaseProvider).settingsDao;
    _shopName.text = await settings.getValue('shop.name') ?? '';
    _shopPhone.text = await settings.getValue('shop.phone') ?? '';
    _shopAddress.text = await settings.getValue('shop.address') ?? '';
    _footer.text = await settings.getValue('receipt.footer') ?? '';
    _printerHost.text = await settings.getValue('printer.host') ?? '';
    _printerPort.text = await settings.getValue('printer.port') ?? '9100';
    _paperWidth = await settings.getValue('printer.width') ?? '32';
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _shopName.dispose();
    _shopPhone.dispose();
    _shopAddress.dispose();
    _footer.dispose();
    _printerHost.dispose();
    _printerPort.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final settings = ref.read(databaseProvider).settingsDao;
    await settings.setValue('shop.name', _shopName.text.trim());
    await settings.setValue('shop.phone', _shopPhone.text.trim());
    await settings.setValue('shop.address', _shopAddress.text.trim());
    await settings.setValue('receipt.footer', _footer.text.trim());
    await settings.setValue('printer.host', _printerHost.text.trim());
    await settings.setValue('printer.port', _printerPort.text.trim());
    await settings.setValue('printer.width', _paperWidth);
    messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
  }

  Future<void> _testPrint() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final host = _printerHost.text.trim();
      if (host.isEmpty) throw StateError(l10n.printerHost);
      final port = int.tryParse(_printerPort.text.trim()) ?? 9100;
      final width = int.tryParse(_paperWidth) ?? 32;
      final line = '=' * width;
      await printToNetwork(
        host,
        port,
        escPosBytes('$line\n${Brand.name} — ${l10n.testPrint}\n$line'),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.printFailed('$e'))));
    }
  }

  Future<void> _backup() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);
    final path = '${dir.path}/BechaKena-backup-$stamp.db';
    // VACUUM INTO writes a clean, consistent single-file snapshot.
    await db.customStatement('VACUUM INTO ?', [path]);
    messenger.showSnackBar(SnackBar(content: Text(l10n.backupSaved(path))));
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'BechaKena backup', extensions: ['db']),
    ]);
    if (picked == null) return;
    final target = await pendingRestoreFile();
    await picked.saveTo(target.path);
    messenger.showSnackBar(SnackBar(content: Text(l10n.restoreDone)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider) ?? Localizations.localeOf(context);
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.storefront),
          title: Text(Brand.name),
          subtitle: Text(Brand.company),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          trailing: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'bn', label: Text('বাংলা')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (selection) => ref
                .read(localeProvider.notifier)
                .set(Locale(selection.first)),
          ),
        ),
        const Divider(height: 32),
        Text(l10n.shopSection, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
            controller: _shopName,
            decoration: InputDecoration(labelText: l10n.shopNameLabel)),
        const SizedBox(height: 12),
        TextField(
            controller: _shopPhone,
            decoration: InputDecoration(labelText: l10n.shopPhone)),
        const SizedBox(height: 12),
        TextField(
            controller: _shopAddress,
            decoration: InputDecoration(labelText: l10n.shopAddress)),
        const SizedBox(height: 12),
        TextField(
            controller: _footer,
            decoration: InputDecoration(labelText: l10n.receiptFooterLabel)),
        const Divider(height: 32),
        Text(l10n.printerSection,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                  controller: _printerHost,
                  decoration: InputDecoration(labelText: l10n.printerHost)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                  controller: _printerPort,
                  decoration: InputDecoration(labelText: l10n.printerPort)),
            ),
            const SizedBox(width: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '32', label: Text('58mm')),
                ButtonSegment(value: '48', label: Text('80mm')),
              ],
              selected: {_paperWidth},
              onSelectionChanged: (s) => setState(() => _paperWidth = s.first),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.print),
              label: Text(l10n.testPrint),
              onPressed: _testPrint,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.save),
          label: Text(l10n.save),
          onPressed: _saveAll,
        ),
        const Divider(height: 32),
        Text(l10n.backupSection,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.backup),
              label: Text(l10n.backupNow),
              onPressed: _backup,
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.restore),
              label: Text(l10n.restoreBackup),
              onPressed: _restore,
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.loadDemo),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final loaded =
                    await seedDemoData(ref.read(databaseProvider));
                messenger.showSnackBar(SnackBar(
                    content:
                        Text(loaded ? l10n.demoLoaded : l10n.demoSkipped)));
              },
            ),
          ],
        ),
      ],
    );
  }
}
