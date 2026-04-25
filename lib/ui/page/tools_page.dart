import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:GitSync/ui/component/showcase_feature_button.dart';

/// Dedicated tab page that surfaces all repository tools (Issues, PRs,
/// Actions, Releases, Tags) as prominent tappable cards. This makes the
/// feature set discoverable from first launch — no need to drill into the
/// expanded commits screen first.
class ToolsPage extends ConsumerWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gitProviderAsync = ref.watch(gitProviderProvider);
    final isAuthenticatedAsync = ref.watch(isAuthenticatedProvider);
    final remoteUrlLinkAsync = ref.watch(remoteUrlLinkProvider);
    final featureCountsAsync = ref.watch(featureCountsProvider);

    final gitProvider = gitProviderAsync.valueOrNull;
    final authenticated = isAuthenticatedAsync.valueOrNull ?? false;
    final remoteUrlLink = remoteUrlLinkAsync.valueOrNull;
    final remoteWebUrl = remoteUrlLink?.$2;
    final featureCounts = featureCountsAsync.valueOrNull ?? const <ShowcaseFeature, int?>{};
    final countsLoading = featureCountsAsync.isLoading;

    final canShowTools =
        authenticated && remoteWebUrl != null && gitProvider != null && gitProvider.isOAuthProvider;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD),
      child: canShowTools
          ? _ToolsContent(
              gitProvider: gitProvider,
              remoteWebUrl: remoteWebUrl,
              featureCounts: featureCounts,
              countsLoading: countsLoading,
            )
          : const _EmptyState(),
    );
  }
}

class _ToolsContent extends StatelessWidget {
  const _ToolsContent({
    required this.gitProvider,
    required this.remoteWebUrl,
    required this.featureCounts,
    required this.countsLoading,
  });

  final GitProvider gitProvider;
  final String remoteWebUrl;
  final Map<ShowcaseFeature, int?> featureCounts;
  final bool countsLoading;

  @override
  Widget build(BuildContext context) {
    final features = ShowcaseFeature.availableFor(gitProvider);
    final repoUri = Uri.tryParse(remoteWebUrl);
    final repoName = repoUri != null && repoUri.pathSegments.length >= 2
        ? '${repoUri.pathSegments[0]}/${repoUri.pathSegments[1].replaceAll('.git', '')}'
        : remoteWebUrl;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            color: colours.surfaceContainer,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
              child: Row(
                children: [
                  FaIcon(_iconForProvider(gitProvider), color: colours.onSurfaceVariant, size: textLG),
                  SizedBox(width: spaceSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Repository',
                          style: TextStyle(
                            color: colours.onSurfaceVariant,
                            fontSize: labelSmall,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          repoName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colours.primaryLight, fontSize: titleLarge, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(padding: EdgeInsets.only(top: spaceMD)),
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spaceSM,
            crossAxisSpacing: spaceSM,
            childAspectRatio: 1.4,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final feature = features[index];
              return ShowcaseFeatureButton(
                feature: feature,
                gitProvider: gitProvider,
                count: featureCounts[feature],
                countLoading: countsLoading,
                onPressed: resolveFeatureOnPressed(
                  context: context,
                  feature: feature,
                  gitProvider: gitProvider,
                  remoteWebUrl: remoteWebUrl,
                ),
                onAdd: resolveFeatureOnAdd(
                  context: context,
                  feature: feature,
                  gitProvider: gitProvider,
                  remoteWebUrl: remoteWebUrl,
                ),
              );
            },
            childCount: features.length,
          ),
        ),
      ],
    );
  }

  IconData _iconForProvider(GitProvider provider) {
    switch (provider) {
      case GitProvider.GITHUB:
        return FontAwesomeIcons.github;
      case GitProvider.GITLAB:
        return FontAwesomeIcons.gitlab;
      default:
        return FontAwesomeIcons.codeBranch;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.toolbox, color: colours.onSurfaceVariant, size: spaceXL),
          SizedBox(height: spaceMD),
          Text(
            'Repository Tools',
            style: TextStyle(color: colours.primaryLight, fontSize: titleLarge, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: spaceXS),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spaceLG),
            child: Text(
              'Connect to GitHub, GitLab, Gitea or Codeberg to see Issues, Pull Requests, Actions, Releases and Tags here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colours.secondaryLight, fontSize: bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
