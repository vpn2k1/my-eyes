import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/copy.dart';
import '../models/scene.dart';
import '../theme/palette.dart';
import '../vision/filters.dart';
import '../vision/vision_copy.dart';
import '../widgets/app_icon.dart';
import '../widgets/page_column.dart';

class Explore extends StatelessWidget {
  const Explore({super.key, required this.openScene});
  final ValueChanged<Scene> openScene;

  Future<void> _openReference(BuildContext context, String url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Show a readable and copyable URL below if the device cannot open it.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t('Could not open the link.', 'Không mở được liên kết.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: Text(context.t('Explore and learn', 'Khám phá và tìm hiểu')),
        bottom: TabBar(
          tabs: [
            Tab(text: context.t('Scenes', 'Tình huống')),
            Tab(text: context.t('Learn', 'Kiến thức')),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          PageColumn(children: [_SceneLibrary(openScene: openScene)]),
          PageColumn(
            children: [
              Text(context.copy(simulationNotice)),
              const SizedBox(height: 12),
              for (final filter in allFilters)
                Card(
                  child: ListTile(
                    title: Text(filterName(context, filter)),
                    subtitle: Text(context.copy(filterNote(filter))),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                context.t('References', 'Nguồn tham khảo'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final ref in const [
                (
                  'National Eye Institute',
                  'https://www.nei.nih.gov/learn-about-eye-health/eye-conditions-and-diseases/color-blindness',
                ),
                (
                  'Machado, Oliveira & Fernandes (2009)',
                  'https://doi.org/10.1109/TVCG.2009.113',
                ),
                ('W3C — WCAG 2.2', 'https://www.w3.org/TR/WCAG22/'),
              ])
                ListTile(
                  title: Text(ref.$1),
                  subtitle: SelectableText(ref.$2),
                  trailing: IconButton(
                    tooltip: context.t('Open source', 'Mở nguồn tham khảo'),
                    onPressed: () => _openReference(context, ref.$2),
                    icon: const AppIcon(AppIcons.external),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SceneLibrary extends StatelessWidget {
  const _SceneLibrary({required this.openScene});
  final ValueChanged<Scene> openScene;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final cardWidth = width >= 560 ? (width - 12) / 2 : width;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final scene in scenes)
            SizedBox(
              width: cardWidth,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => openScene(scene),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: 900 / 560,
                        child: Image.asset(
                          scene.asset,
                          fit: BoxFit.cover,
                          semanticLabel: context.copy(scene.alt),
                          errorBuilder: (_, _, _) =>
                              const AppIcon(AppIcons.brokenImage),
                        ),
                      ),
                      ListTile(
                        title: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppAccents.of(context).explore.accent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                context.copy(scene.title),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppAccents.of(
                                        context,
                                      ).explore.onAccent,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        subtitle: Text(context.copy(scene.barrier)),
                        trailing: const AppIcon(AppIcons.chevron),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
