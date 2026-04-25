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

    final card = GestureDetector(
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
    );

    // Wrap the card with an M3 Badge.count when there's a count to display.
    // Use a shimmer-style pulsing indicator while counts are being fetched.
    final Widget cardWithBadge;
    if (countLoading && count == null) {
      cardWithBadge = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -spaceXXS,
            right: -spaceXXS,
            child: _ShimmerDot(color: iconCol),
          ),
        ],
      );
    } else if (count != null && count! > 0) {
      cardWithBadge = Badge.count(
        count: count!,
        backgroundColor: iconCol,
        textColor: tint,
        textStyle: TextStyle(color: tint, fontSize: textXXS, fontWeight: FontWeight.bold),
        alignment: AlignmentDirectional.topEnd,
        child: card,
      );
    } else {
      cardWithBadge = card;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        cardWithBadge,
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

/// Pulsing dot used as a "shimmer" placeholder while feature counts are being fetched.
class _ShimmerDot extends StatefulWidget {
  const _ShimmerDot({required this.color});

  final Color color;

  @override
  State<_ShimmerDot> createState() => _ShimmerDotState();
}

class _ShimmerDotState extends State<_ShimmerDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: textSM,
        height: textSM,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
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
