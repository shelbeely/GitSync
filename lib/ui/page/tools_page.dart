import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/providers/riverpod_providers.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:GitSync/ui/component/provider_builder.dart';
import 'package:GitSync/ui/component/showcase_feature_button.dart';

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
          builder: (context, remoteUrlLinkAsync) => ProviderBuilder<Map<ShowcaseFeature, int?>>(
            provider: featureCountsProvider,
            builder: (context, featureCountsAsync) {
              final gitProvider = gitProviderAsync.valueOrNull ?? GitProvider.GITHUB;
              final isAuthenticated = isAuthAsync.valueOrNull ?? false;
              final remoteWebUrl = remoteUrlLinkAsync.valueOrNull?.$2;
              final countsMap = featureCountsAsync.valueOrNull ?? {};
              final countsLoading = featureCountsAsync.isLoading;

              final isConnected = isAuthenticated && remoteWebUrl != null && gitProvider.isOAuthProvider;

              return Scaffold(
                backgroundColor: colours.primaryDark,
                body: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.only(bottom: spaceMD),
                          child: Text(
                            t.providerTools.toUpperCase(),
                            style: TextStyle(
                              color: colours.secondaryLight,
                              fontSize: textXXS,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        if (!isConnected)
                          _buildEmptyState(context)
                        else
                          _buildGrid(context, gitProvider, remoteWebUrl!, countsMap, countsLoading),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.layerGroup,
                color: colours.tertiaryLight,
                size: spaceXL,
              ),
              SizedBox(height: spaceMD),
              Text(
                t.toolsEmptyTitle,
                style: TextStyle(
                  color: colours.primaryLight,
                  fontSize: textLG,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spaceXS),
              Text(
                t.toolsEmptySubtitle,
                style: TextStyle(color: colours.secondaryLight, fontSize: textSM),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    GitProvider gitProvider,
    String remoteWebUrl,
    Map<ShowcaseFeature, int?> countsMap,
    bool countsLoading,
  ) {
    final features = ShowcaseFeature.availableFor(gitProvider);
    final rows = <Widget>[];

    for (var i = 0; i < features.length; i += 2) {
      final first = features[i];
      final second = i + 1 < features.length ? features[i + 1] : null;

      rows.add(
        Row(
          children: [
            Expanded(
              child: ShowcaseFeatureButton(
                feature: first,
                gitProvider: gitProvider,
                count: countsMap[first],
                countLoading: countsLoading,
                onAdd: resolveFeatureOnAdd(
                  context: context,
                  feature: first,
                  gitProvider: gitProvider,
                  remoteWebUrl: remoteWebUrl,
                ),
                onPressed: resolveFeatureOnPressed(
                  context: context,
                  feature: first,
                  gitProvider: gitProvider,
                  remoteWebUrl: remoteWebUrl,
                ),
              ),
            ),
            if (second != null) ...[
              SizedBox(width: spaceXS),
              Expanded(
                child: ShowcaseFeatureButton(
                  feature: second,
                  gitProvider: gitProvider,
                  count: countsMap[second],
                  countLoading: countsLoading,
                  onAdd: resolveFeatureOnAdd(
                    context: context,
                    feature: second,
                    gitProvider: gitProvider,
                    remoteWebUrl: remoteWebUrl,
                  ),
                  onPressed: resolveFeatureOnPressed(
                    context: context,
                    feature: second,
                    gitProvider: gitProvider,
                    remoteWebUrl: remoteWebUrl,
                  ),
                ),
              ),
            ] else
              Expanded(child: SizedBox.shrink()),
          ],
        ),
      );

      if (i + 2 < features.length) {
        rows.add(SizedBox(height: spaceXS));
      }
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Column(children: rows),
      ),
    );
  }
}
