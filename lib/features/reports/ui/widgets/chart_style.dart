import 'package:flutter/material.dart';

import '../../../../core/db/database.dart';

// Chart colors from the validated dataviz reference palette (light/dark are
// selected steps, not an automatic flip). Payment methods keep fixed entity
// colors: cash=blue, bKash=magenta, Nagad=orange, card=violet.
const seriesColorLight = Color(0xFF2A78D6);
const seriesColorDark = Color(0xFF3987E5);
const payColorsLight = {
  PayMethod.cash: Color(0xFF2A78D6),
  PayMethod.bkash: Color(0xFFE87BA4),
  PayMethod.nagad: Color(0xFFEB6834),
  PayMethod.card: Color(0xFF4A3AA7),
};
const payColorsDark = {
  PayMethod.cash: Color(0xFF3987E5),
  PayMethod.bkash: Color(0xFFD55181),
  PayMethod.nagad: Color(0xFFD95926),
  PayMethod.card: Color(0xFF9085E9),
};

/// The single-series hue for the current brightness.
Color seriesColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? seriesColorDark
        : seriesColorLight;

/// Card shell every chart on the dashboard sits in: title + content.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Compact ৳ axis label: 12.5k / 1.2L.
String compactTaka(double taka) {
  if (taka >= 100000) return '${(taka / 100000).toStringAsFixed(1)}L';
  if (taka >= 1000) return '${(taka / 1000).toStringAsFixed(0)}k';
  return taka.toStringAsFixed(0);
}
