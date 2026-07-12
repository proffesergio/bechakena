import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/brand.dart';
import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/db/open.dart';
import '../../../core/seed/demo_catalog.dart';
import '../../../core/printing/print_service.dart';
import '../../../core/printing/printer_transport.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/logic/session.dart';

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
  PrinterTransportType _transport = PrinterTransportType.lan;
  String _device = '';
  String _deviceName = '';
  String? _logoPath;
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
    _transport =
        PrinterConfig.parseType(await settings.getValue('printer.transport'));
    _device = await settings.getValue('printer.device') ?? '';
    _deviceName = await settings.getValue('printer.deviceName') ?? _device;
    _logoPath = await settings.getValue('shop.logoPath');
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
    await settings.setValue(
        'printer.transport', PrinterConfig.encodeType(_transport));
    await settings.setValue('printer.device', _device);
    await settings.setValue('printer.deviceName', _deviceName);
    messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
  }

  PrinterConfig get _currentConfig => PrinterConfig(
        type: _transport,
        host: _printerHost.text.trim(),
        port: int.tryParse(_printerPort.text.trim()) ?? 9100,
        width: int.tryParse(_paperWidth) ?? 32,
        device: _device,
      );

  Future<void> _testPrint() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final settings = ref.read(databaseProvider).settingsDao;
    try {
      final cfg = _currentConfig;
      final line = '=' * cfg.width;
      final bytes = await composeReceiptBytes(
        settings: settings,
        text: '$line\n${Brand.name} — ${l10n.testPrint}\n$line',
        widthDots: cfg.widthDots,
      );
      await sendToPrinter(cfg, bytes);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.printFailed('$e'))));
    }
  }

  Future<void> _selectDevice() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final devices = await discoverPrinters(_transport);
    if (devices.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noDevices)));
      return;
    }
    if (!mounted) return;
    final picked = await showDialog<PrinterDevice>(
      context: context,
      builder: (dctx) => SimpleDialog(
        title: Text(l10n.selectDevice),
        children: [
          for (final d in devices)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dctx).pop(d),
              child: Text(d.name),
            ),
        ],
      ),
    );
    if (picked != null) {
      setState(() {
        _device = picked.id;
        _deviceName = picked.name;
      });
    }
  }

  Future<void> _chooseLogo() async {
    final settings = ref.read(databaseProvider).settingsDao;
    final picked = await openFile(acceptedTypeGroups: [
      const XTypeGroup(
          label: 'Image', extensions: ['png', 'jpg', 'jpeg', 'bmp']),
    ]);
    if (picked == null) return;
    final dir = await getApplicationSupportDirectory();
    final dest = File(p.join(dir.path, 'shop_logo.img'));
    await picked.saveTo(dest.path);
    await settings.setValue('shop.logoPath', dest.path);
    if (mounted) setState(() => _logoPath = dest.path);
  }

  Future<void> _removeLogo() async {
    final settings = ref.read(databaseProvider).settingsDao;
    await settings.setValue('shop.logoPath', '');
    if (mounted) setState(() => _logoPath = null);
  }

  Future<void> _clearData() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l10n.clearData),
        content: Text(l10n.clearDataWarning),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dctx).colorScheme.error),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l10n.clearData),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Arm the wipe; the DB file is dropped on next launch.
    final sentinel = await pendingWipeFile();
    await sentinel.writeAsString('wipe');
    messenger.showSnackBar(SnackBar(content: Text(l10n.clearDataDone)));
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
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: Text(l10n.theme),
          trailing: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto),
                  tooltip: l10n.themeSystem),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode),
                  tooltip: l10n.themeLight),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode),
                  tooltip: l10n.themeDark),
            ],
            selected: {ref.watch(themeModeProvider)},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
        ),
        const Divider(height: 32),
        _buildBranchSection(context, l10n),
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
        const SizedBox(height: 16),
        _buildLogoRow(context, l10n),
        const Divider(height: 32),
        Text(l10n.printerSection,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<PrinterTransportType>(
          segments: [
            ButtonSegment(
                value: PrinterTransportType.lan,
                icon: const Icon(Icons.lan),
                label: Text(l10n.transportLan)),
            ButtonSegment(
                value: PrinterTransportType.usb,
                icon: const Icon(Icons.usb),
                label: Text(l10n.transportUsb)),
            ButtonSegment(
                value: PrinterTransportType.bluetooth,
                icon: const Icon(Icons.bluetooth),
                label: Text(l10n.transportBt)),
          ],
          selected: {_transport},
          onSelectionChanged: (s) => setState(() => _transport = s.first),
        ),
        const SizedBox(height: 12),
        if (_transport == PrinterTransportType.lan)
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
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: Text(
                  _deviceName.isEmpty ? l10n.noDeviceSelected : _deviceName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.search),
                label: Text(l10n.selectDevice),
                onPressed: _selectDevice,
              ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
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
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: Icon(Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error),
              label: Text(l10n.clearData,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: _clearData,
            ),
          ],
        ),
        const Divider(height: 32),
        _buildStaffSection(context, l10n),
      ],
    );
  }

  Widget _buildBranchSection(BuildContext context, AppLocalizations l10n) {
    final branches = ref.watch(branchesProvider).value ?? const <Shop>[];
    final current = ref.watch(currentBranchProvider);
    final value =
        (current != null && branches.any((b) => b.id == current)) ? current : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.branchSection,
            style: Theme.of(context).textTheme.titleMedium),
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
              child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final db = ref.read(databaseProvider);
    await db.into(db.shops).insert(ShopsCompanion.insert(name: name));
    messenger.showSnackBar(SnackBar(content: Text(l10n.branchAdded)));
  }

  Widget _buildStaffSection(BuildContext context, AppLocalizations l10n) {
    final me = ref.watch(currentStaffProvider);
    final staff = ref.watch(staffListProvider).value ?? const <StaffData>[];
    // Only owners/managers manage staff.
    final canManage =
        me != null && me.role != StaffRole.cashier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(l10n.staffSection,
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (canManage)
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
            trailing: canManage && s.id != me.id
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          content: Text(l10n.removeStaff(s.name)),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(dctx).pop(false),
                                child: Text(l10n.cancel)),
                            FilledButton(
                                onPressed: () =>
                                    Navigator.of(dctx).pop(true),
                                child: Text(l10n.remove)),
                          ],
                        ),
                      );
                      if (ok ?? false) {
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
                child: Text(l10n.loggedInAs(me.name),
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              onPressed: () =>
                  ref.read(currentStaffProvider.notifier).logout(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoRow(BuildContext context, AppLocalizations l10n) {
    final hasLogo = _logoPath != null &&
        _logoPath!.isNotEmpty &&
        File(_logoPath!).existsSync();
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: hasLogo
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  // Key on the path so a re-picked logo repaints.
                  child: Image.file(File(_logoPath!),
                      key: ValueKey(_logoPath), fit: BoxFit.contain),
                )
              : const Icon(Icons.image_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(l10n.shopLogoHint,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload),
          label: Text(l10n.chooseLogo),
          onPressed: _chooseLogo,
        ),
        if (hasLogo)
          IconButton(
            tooltip: l10n.removeLogo,
            icon: const Icon(Icons.close),
            onPressed: _removeLogo,
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
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.requiredField
                    : null,
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
                  DropdownMenuItem(
                      value: StaffRole.manager, child: Text(l10n.roleManager)),
                  DropdownMenuItem(
                      value: StaffRole.cashier, child: Text(l10n.roleCashier)),
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
            final navigator = Navigator.of(context);
            await ref.read(databaseProvider).staffDao.createStaff(
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
