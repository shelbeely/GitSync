import 'package:flutter/material.dart';
import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';

/// M3 settings section: a `labelLarge` header followed by a filled [Card]
/// that visually groups related setting rows.
///
/// The card uses `surfaceContainerLow` as a subtle surface so it doesn't
/// clash with item rows that already paint their own `tertiaryDark`
/// background. Pass [headerColor] to override the header tint
/// (e.g. negative for a "danger zone").
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    this.title,
    required this.children,
    this.headerColor,
    this.cardColor,
  });

  final String? title;
  final List<Widget> children;
  final Color? headerColor;
  final Color? cardColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
      color: headerColor ?? colours.primaryLight,
      fontWeight: FontWeight.bold,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.only(left: spaceMD, right: spaceMD, bottom: spaceSM),
            child: Text(title!.toUpperCase(), style: labelStyle),
          ),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: cardColor ?? Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}
