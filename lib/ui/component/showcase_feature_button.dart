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

/// Container/foreground color pair for a [ShowcaseFeature], aligned with
/// M3 tonal container roles to provide ADHD-friendly color anchoring.
class FeatureColorPair {
  const FeatureColorPair({required this.container, required this.foreground});
  final Color container;
  final Color foreground;
}

FeatureColorPair colorsForFeature(ShowcaseFeature feature) {
  switch (feature) {
    case ShowcaseFeature.issues:
      return FeatureColorPair(container: colours.errorContainer, foreground: colours.onErrorContainer);
    case ShowcaseFeature.pullRequests:
      return FeatureColorPair(container: colours.primaryContainer, foreground: colours.onPrimaryContainer);
    case ShowcaseFeature.actions:
      return FeatureColorPair(container: colours.tertiaryContainer, foreground: colours.onTertiaryContainer);
    case ShowcaseFeature.releases:
      return FeatureColorPair(container: colours.secondaryContainer, foreground: colours.onSecondaryContainer);
    case ShowcaseFeature.tags:
      return FeatureColorPair(container: colours.surfaceContainerHigh, foreground: colours.primaryLight);
  }
}

class ShowcaseFeatureButton extends StatefulWidget {
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
    this.compact = false,
  });

  final ShowcaseFeature feature;
  final VoidCallback onPressed;
  final VoidCallback? onPinToggle;
  final bool isPinned;
  final VoidCallback? onAdd;
  final GitProvider? gitProvider;
  final int? count;
  final bool countLoading;

  /// When true, render the legacy compact single-row layout. The default is
  /// the M3 launcher-grid card (~72 dp tall) with icon centered above the label.
  final bool compact;

  @override
  State<ShowcaseFeatureButton> createState() => _ShowcaseFeatureButtonState();
}

class _ShowcaseFeatureButtonState extends State<ShowcaseFeatureButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildCompact(context);
    return _buildLauncherCard(context);
  }

  Widget _buildLauncherCard(BuildContext context) {
    final palette = colorsForFeature(widget.feature);
    final iconColor = palette.foreground;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: palette.container,
          borderRadius: BorderRadius.all(cornerRadiusMD),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: EdgeInsets.symmetric(horizontal: spaceSM, vertical: spaceSM),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(widget.feature.icon, color: iconColor, size: textXL),
                  SizedBox(height: spaceXXS),
                  Text(
                    widget.feature.labelForProvider(widget.gitProvider),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(color: iconColor, fontSize: labelSmall, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.countLoading && widget.count == null)
          Positioned(
            right: -spaceXXXS,
            top: -spaceXXXS,
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (context, _) => Opacity(
                opacity: 0.4 + (_shimmer.value * 0.6),
                child: Container(
                  width: spaceMD,
                  height: spaceMD,
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.4), shape: BoxShape.circle),
                ),
              ),
            ),
          )
        else if (widget.count != null && widget.count! > 0)
          Positioned(
            right: -spaceXXXS,
            top: -spaceXXXS,
            child: Badge.count(
              count: widget.count!,
              backgroundColor: iconColor,
              textColor: palette.container,
            ),
          ),
        if (widget.onPinToggle != null)
          Positioned(
            left: -spaceXXXS,
            top: -spaceXXXS,
            child: GestureDetector(
              onTap: widget.onPinToggle,
              child: Container(
                width: spaceMD,
                height: spaceMD,
                decoration: BoxDecoration(color: widget.isPinned ? colours.primaryLight : colours.tertiaryDark, shape: BoxShape.circle),
                child: Center(
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: FaIcon(FontAwesomeIcons.thumbtack, color: widget.isPinned ? colours.primaryDark : colours.tertiaryLight, size: textXXS),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            decoration: BoxDecoration(
              color: colours.showcaseBg,
              borderRadius: BorderRadius.all(cornerRadiusSM),
              border: Border.all(color: colours.showcaseBorder, width: spaceXXXXS),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: spaceSM),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: spaceSM),
                    child: FaIcon(widget.feature.icon, color: colours.showcaseFeatureIcon, size: textMD),
                  ),
                  SizedBox(width: spaceXXS),
                  Expanded(
                    child: Center(
                      widthFactor: 1,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.feature.labelForProvider(widget.gitProvider),
                          style: TextStyle(color: colours.showcaseFeatureIcon, fontSize: textSM, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  if (widget.countLoading && widget.count == null) ...[
                    SizedBox(width: spaceXXXS),
                    Center(
                      child: SizedBox(
                        width: textXXS,
                        height: textXXS,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: colours.showcaseFeatureIcon),
                      ),
                    ),
                  ] else if (widget.count != null && widget.count! > 0) ...[
                    SizedBox(width: spaceXXXS),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: spaceXXXS + 1, vertical: 1),
                        decoration: BoxDecoration(color: colours.showcaseBorder, borderRadius: BorderRadius.all(cornerRadiusMax)),
                        child: Text(
                          widget.count! > 99 ? '99+' : '${widget.count}',
                          style: TextStyle(color: colours.showcaseFeatureIcon, fontSize: textXXS, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: spaceXXS),
                  if (widget.onAdd != null)
                    AspectRatio(
                      aspectRatio: 2.25 / 3,
                      child: TextButton(
                        onPressed: widget.onAdd,
                        style: TextButton.styleFrom(
                          backgroundColor: colours.showcaseBorder,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: FaIcon(FontAwesomeIcons.plus, color: colours.showcaseFeatureIcon, size: textSM),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.onPinToggle != null)
          Positioned(
            left: -spaceXXXS,
            top: -spaceXXXS,
            child: GestureDetector(
              onTap: widget.onPinToggle,
              child: Container(
                width: spaceMD,
                height: spaceMD,
                decoration: BoxDecoration(color: widget.isPinned ? colours.primaryLight : colours.tertiaryDark, shape: BoxShape.circle),
                child: Center(
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: FaIcon(FontAwesomeIcons.thumbtack, color: widget.isPinned ? colours.primaryDark : colours.tertiaryLight, size: textXXS),
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
