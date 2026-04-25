import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:GitSync/ui/component/provider_builder.dart';
import 'package:GitSync/ui/component/showcase_feature_button.dart';
import 'package:GitSync/ui/dialog/auth.dart' as AuthDialog;

/// Always-visible page that surfaces every repository tool (Issues, PRs, Tags,
/// Releases, Actions) as large color-coded cards. Implements step 18 of the
/// ADHD-friendly UI plan.
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderBuilder<GitProvider>(
      provider: gitProviderProvider,
      builder: (context, gitProviderAsync) => ProviderBuilder<bool>(
        provider: isAuthenticatedProvider,
        builder: (context, isAuthAsync) => ProviderBuilder<(String, String)?>(
          provider: remoteUrlLinkProvider,
          builder: (context, remoteUrlLinkAsync) => ProviderBuilder<List<String>>(
            provider: repoNamesProvider,
            builder: (context, repoNamesAsync) => ProviderBuilder<int>(
              provider: repoIndexProvider,
              builder: (context, repoIndexAsync) => ProviderBuilder<Map<ShowcaseFeature, int?>>(
                provider: featureCountsProvider,
                builder: (context, featureCountsAsync) {
                  final gitProvider = gitProviderAsync.valueOrNull ?? GitProvider.GITHUB;
                  final isAuthenticated = isAuthAsync.valueOrNull ?? false;
                  final remoteWebUrl = remoteUrlLinkAsync.valueOrNull?.$2;
                  final countsMap = featureCountsAsync.valueOrNull ?? {};
                  final countsLoading = featureCountsAsync.isLoading;
                  final repoNames = repoNamesAsync.valueOrNull ?? [];
                  final repoIndex = repoIndexAsync.valueOrNull ?? 0;
                  final repoName = (repoNames.isNotEmpty && repoIndex < repoNames.length) ? repoNames[repoIndex] : null;

                  final isConnected = isAuthenticated && remoteWebUrl != null && gitProvider.isOAuthProvider;

                  return Scaffold(
                    backgroundColor: colours.primaryDark,
                    body: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(spaceMD),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _RepositoryHeader(repoName: repoName, gitProvider: gitProvider, isConnected: isConnected),
                            SizedBox(height: spaceMD),
                            if (!isConnected)
                              _EmptyState(isAuthenticated: isAuthenticated, gitProvider: gitProvider)
                            else
                              _ToolsGrid(
                                gitProvider: gitProvider,
                                remoteWebUrl: remoteWebUrl!,
                                countsMap: countsMap,
                                countsLoading: countsLoading,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepositoryHeader extends StatelessWidget {
  const _RepositoryHeader({required this.repoName, required this.gitProvider, required this.isConnected});

  final String? repoName;
  final GitProvider gitProvider;
  final bool isConnected;

  IconData _providerIcon() {
    if (gitProvider == GitProvider.GITHUB) {
      return Platform.isIOS ? FontAwesomeIcons.gitAlt : FontAwesomeIcons.github;
    }
    return FontAwesomeIcons.gitAlt;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colours.secondaryDark,
        borderRadius: BorderRadius.all(cornerRadiusMD),
      ),
      padding: EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
      child: Row(
        children: [
          FaIcon(_providerIcon(), color: colours.tertiaryInfo, size: textLG),
          SizedBox(width: spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.providerTools.toUpperCase(),
                  style: TextStyle(
                    color: colours.secondaryLight,
                    fontSize: textXXS,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  repoName?.toUpperCase() ?? '',
                  style: TextStyle(
                    color: colours.primaryLight,
                    fontSize: textMD,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isConnected)
            FaIcon(FontAwesomeIcons.solidCircleCheck, color: colours.primaryPositive, size: textSM),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isAuthenticated, required this.gitProvider});

  final bool isAuthenticated;
  final GitProvider gitProvider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.layerGroup, color: colours.tertiaryLight, size: spaceXL),
              SizedBox(height: spaceMD),
              Text(
                t.toolsEmptyTitle,
                style: TextStyle(color: colours.primaryLight, fontSize: textLG, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spaceXS),
              Text(
                t.toolsEmptySubtitle,
                style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spaceLG),
              if (!isAuthenticated)
                TextButton.icon(
                  onPressed: () async {
                    await AuthDialog.showDialog(context, () async {});
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(colours.tertiaryInfo),
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceSM)),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD)),
                    ),
                  ),
                  icon: FaIcon(FontAwesomeIcons.key, color: colours.primaryLight, size: textMD),
                  label: Text(
                    t.toolsConnectCta.toUpperCase(),
                    style: TextStyle(color: colours.primaryLight, fontSize: textMD, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolsGrid extends StatelessWidget {
  const _ToolsGrid({
    required this.gitProvider,
    required this.remoteWebUrl,
    required this.countsMap,
    required this.countsLoading,
  });

  final GitProvider gitProvider;
  final String remoteWebUrl;
  final Map<ShowcaseFeature, int?> countsMap;
  final bool countsLoading;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: uiSettingsManager.getStringList(StorageKey.setman_pinnedShowcaseFeatures),
      builder: (context, snapshot) {
        final pinnedKeys = snapshot.data ?? const <String>[];
        final pinned = ShowcaseFeature.fromStorageKeys(pinnedKeys);
        final all = ShowcaseFeature.availableFor(gitProvider);
        // Pin order: pinned features first (in saved order), then the rest.
        final ordered = <ShowcaseFeature>[
          ...pinned.where(all.contains),
          ...all.where((f) => !pinned.contains(f)),
        ];

        final rows = <Widget>[];
        for (var i = 0; i < ordered.length; i += 2) {
          final first = ordered[i];
          final second = i + 1 < ordered.length ? ordered[i + 1] : null;
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildCard(context, first)),
                if (second != null) ...[
                  SizedBox(width: spaceXS),
                  Expanded(child: _buildCard(context, second)),
                ] else
                  Spacer(),
              ],
            ),
          );
          if (i + 2 < ordered.length) rows.add(SizedBox(height: spaceXS));
        }

        return Expanded(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, ShowcaseFeature feature) {
    return ShowcaseFeatureButton(
      feature: feature,
      gitProvider: gitProvider,
      count: countsMap[feature],
      countLoading: countsLoading,
      onAdd: resolveFeatureOnAdd(
        context: context,
        feature: feature,
        gitProvider: gitProvider,
        remoteWebUrl: remoteWebUrl,
      ),
      onPressed: resolveFeatureOnPressed(
        context: context,
        feature: feature,
        gitProvider: gitProvider,
        remoteWebUrl: remoteWebUrl,
      ),
    );
  }
}
