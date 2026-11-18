import 'package:material_ui/material_ui.dart';

import '../theme/palette.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    required this.body,
    this.illustration = 'assets/illustrations/hero.webp',
  });
  final String title, body;
  final String illustration;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandNavy, brandNavyLift],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/branding/logo.png',
                  width: 64,
                  height: 36,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                Flexible(
                  child: Image.asset(
                    illustration,
                    width: 144,
                    height: 80,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: brandInk,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: brandInk),
            ),
          ],
        ),
      ),
    );
  }
}
