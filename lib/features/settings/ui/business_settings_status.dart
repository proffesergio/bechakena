import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Never briefly display BDT or accept input before the saved currency loads.
Widget? businessSettingsStatus(WidgetRef ref, BuildContext context) {
  final settings = ref.watch(businessSettingsProvider);
  if (settings.hasValue) return null;
  if (settings.hasError) {
    return Center(
      child: Text(AppLocalizations.of(context).globalSettingsLoadFailed),
    );
  }
  return const Center(child: CircularProgressIndicator());
}
