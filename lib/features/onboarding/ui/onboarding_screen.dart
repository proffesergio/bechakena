import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/business_type.dart';
import '../../../l10n/gen/app_localizations.dart';

/// First-launch step 2: a short, skippable feature tour. Adapts a couple of
/// labels to the chosen business type. Completing or skipping sets
/// `app.onboarded` so it never shows again (until a data reset).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_TourPage> _pages(AppLocalizations l10n, bool restaurant) => [
        _TourPage(
          icon: Icons.waving_hand,
          title: l10n.tourWelcomeTitle,
          body: l10n.tourWelcomeBody,
        ),
        _TourPage(
          icon: restaurant ? Icons.restaurant_menu : Icons.point_of_sale,
          title: restaurant ? l10n.tourOrdersTitle : l10n.tourSellTitle,
          body: restaurant ? l10n.tourOrdersBody : l10n.tourSellBody,
        ),
        _TourPage(
          icon: Icons.warehouse,
          title: l10n.tourStockTitle,
          body: l10n.tourStockBody,
        ),
        _TourPage(
          icon: Icons.insights,
          title: l10n.tourReportsTitle,
          body: l10n.tourReportsBody,
        ),
      ];

  Future<void> _finish() => markOnboarded(ref);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final restaurant =
        ref.watch(businessTypeProvider) == BusinessType.restaurant;
    final pages = _pages(l10n, restaurant);
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l10n.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 360,
                child: FilledButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? l10n.getStarted : l10n.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourPage extends StatelessWidget {
  const _TourPage(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: scheme.primaryContainer,
            child: Icon(icon, size: 56, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 32),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
