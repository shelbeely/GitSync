import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:GitSync/type/git_provider.dart';
import 'package:GitSync/type/showcase_feature.dart';
import 'package:GitSync/ui/page/issues_page.dart';
import 'package:GitSync/ui/page/pull_requests_page.dart';
import 'package:GitSync/ui/page/releases_page.dart';
import 'package:GitSync/ui/page/actions_page.dart';
import 'package:GitSync/ui/page/tags_page.dart';
import 'package:GitSync/ui/page/create_issue_page.dart';
import 'package:GitSync/ui/page/create_pr_page.dart';

class ShowcaseFeatureButton extends StatelessWidget {
  const ShowcaseFeatureButton({
    super.key,
    required this.feature,
    required this.onPressed,
    this.onPinToggle,
    this.isPinned = false,
    this.onAdd,
    this.gitProvider,
    this.count,
    this.countLoading = false,
  });

  final ShowcaseFeature feature;
  final VoidCallback onPressed;
  final VoidCallback? onPinToggle;
  final bool isPinned;
  final VoidCallback? onAdd;
  final GitProvider? gitProvider;
  final int? count;
  final bool countLoading;

  @override
  Widget build(BuildContext context) {
    final tint = feature.tintColor(colours.darkMode);
    final iconCol = feature.iconColor(colours.darkMode);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.all(cornerRadiusSM),
              border: Border.all(color: iconCol.withAlpha(60), width: spaceXXXXS),
            ),
            padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceMD),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(feature.icon, color: iconCol, size: textXL),
                SizedBox(height: spaceXXXS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        feature.labelForProvider(gitProvider),
                        style: TextStyle(color: iconCol, fontSize: textXS, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    if (onAdd != null) ...[
                      SizedBox(width: spaceXXXS),
                      GestureDetector(
                        onTap: onAdd,
                        child: FaIcon(FontAwesomeIcons.plus, color: iconCol.withAlpha(180), size: textXXS),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // Badge count overlay — top-right
        if (countLoading && count == null)
          Positioned(
            top: -spaceXXXS,
            right: -spaceXXXS,
            child: SizedBox(
              width: textSM,
              height: textSM,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: iconCol),
            ),
          )
        else if (count != null && count! > 0)
          Positioned(
            top: -spaceXXXS,
            right: -spaceXXXS,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: spaceXXXS + 1, vertical: 1),
              decoration: BoxDecoration(color: iconCol, borderRadius: BorderRadius.all(cornerRadiusMax)),
              child: Text(
                count! > 99 ? '99+' : '$count',
                style: TextStyle(color: tint, fontSize: textXXS, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        // Pin toggle overlay — top-left (only shown in expanded commits view)
        if (onPinToggle != null)
          Positioned(
            left: -spaceXXXS,
            top: -spaceXXXS,
            child: GestureDetector(
              onTap: onPinToggle,
              child: Container(
                width: spaceMD,
                height: spaceMD,
                decoration: BoxDecoration(color: isPinned ? colours.primaryLight : colours.tertiaryDark, shape: BoxShape.circle),
                child: Center(
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: FaIcon(FontAwesomeIcons.thumbtack, color: isPinned ? colours.primaryDark : colours.tertiaryLight, size: textXXS),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

List<ShowcaseFeature>? togglePin(List<ShowcaseFeature> current, ShowcaseFeature feature) {
  final pinned = List<ShowcaseFeature>.of(current);

  if (pinned.contains(feature)) {
    pinned.remove(feature);
  } else {
    if (pinned.length >= 2) {
      pinned.removeAt(0);
    }
    pinned.add(feature);
  }

  return pinned;
}

VoidCallback? resolveFeatureOnAdd({
  required BuildContext context,
  required ShowcaseFeature feature,
  required GitProvider? gitProvider,
  required String? remoteWebUrl,
}) {
  if (feature != ShowcaseFeature.issues && feature != ShowcaseFeature.pullRequests) return null;
  return () async {
    if (remoteWebUrl == null || gitProvider == null) return;
    final githubAppOauth = await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth);
    final accessToken = (await uiSettingsManager.getGitHttpAuthCredentials()).$2;
    if (!context.mounted) return;
    if (feature == ShowcaseFeature.issues) {
      Navigator.of(context).push(
        createCreateIssuePageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
      );
    } else {
      Navigator.of(
        context,
      ).push(createCreatePrPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth));
    }
  };
}

VoidCallback resolveFeatureOnPressed({
  required BuildContext context,
  required ShowcaseFeature feature,
  required GitProvider? gitProvider,
  required String? remoteWebUrl,
}) {
  return () async {
    if (remoteWebUrl == null || gitProvider == null) return;
    final githubAppOauth = await uiSettingsManager.getBool(StorageKey.setman_githubScopedOauth);
    final accessToken = (await uiSettingsManager.getGitHttpAuthCredentials()).$2;
    if (!context.mounted) return;

    switch (feature) {
      case ShowcaseFeature.issues:
        Navigator.of(
          context,
        ).push(createIssuesPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth));
      case ShowcaseFeature.pullRequests:
        Navigator.of(context).push(
          createPullRequestsPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
        );
      case ShowcaseFeature.tags:
        Navigator.of(
          context,
        ).push(createTagsPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth));
      case ShowcaseFeature.releases:
        Navigator.of(context).push(
          createReleasesPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
        );
      case ShowcaseFeature.actions:
        Navigator.of(context).push(
          createActionsPageRoute(gitProvider: gitProvider, remoteWebUrl: remoteWebUrl, accessToken: accessToken, githubAppOauth: githubAppOauth),
        );
    }
  };
}
