import 'package:GitSync/constant/dimens.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// M3 button role variant for [ButtonSetting]. Defaults to [neutral] which
/// preserves the legacy filled-with-tertiary-dark appearance.
enum ButtonSettingType { primary, secondary, destructive, neutral }

class ButtonSetting extends StatefulWidget {
  const ButtonSetting({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.sub = false,
    this.loads = false,
    this.textColor,
    this.iconColor,
    this.buttonColor,
    this.initiallyExpanded = false,
    this.subButtons,
    this.type = ButtonSettingType.neutral,
    this.tooltip,
    super.key,
  });

  final bool sub;
  final bool loads;
  final bool initiallyExpanded;
  final String text;
  final FaIconData icon;
  final Color? textColor;
  final Color? iconColor;
  final Color? buttonColor;
  final List<Widget>? subButtons;
  final Future<void> Function()? onPressed;
  final ButtonSettingType type;

  /// Optional tooltip shown on long-press, useful for explaining what
  /// an action does without executing it (ADHD-friendly affordance).
  final String? tooltip;

  @override
  State<ButtonSetting> createState() => _ButtonSettingState();
}

class _ButtonSettingState extends State<ButtonSetting> {
  bool expanded = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyExpanded;
  }

  void onPressed() async {
    if (mounted) setState(() => loading = true);
    if (widget.onPressed != null) await widget.onPressed!();
    if (mounted) setState(() => loading = false);
  }

  /// Resolve the effective background color from the [type] role, falling
  /// back to the explicit [buttonColor] override and finally the legacy
  /// neutral tertiary-dark color. Returning `null` for some types lets
  /// the underlying Material widget handle defaults.
  Color _backgroundColor() {
    if (widget.buttonColor != null) return widget.buttonColor!;
    switch (widget.type) {
      case ButtonSettingType.primary:
        return colours.primaryInfo;
      case ButtonSettingType.secondary:
        return colours.primaryContainer;
      case ButtonSettingType.destructive:
        return colours.errorContainer;
      case ButtonSettingType.neutral:
        return colours.tertiaryDark;
    }
  }

  Color _foregroundColor() {
    if (widget.textColor != null) return widget.textColor!;
    switch (widget.type) {
      case ButtonSettingType.primary:
        return colours.darkMode ? colours.primaryDark : colours.primaryLight;
      case ButtonSettingType.secondary:
        return colours.onPrimaryContainer;
      case ButtonSettingType.destructive:
        return colours.onErrorContainer;
      case ButtonSettingType.neutral:
        return colours.primaryLight;
    }
  }

  Widget getIcon() => widget.loads && loading
      ? SizedBox.square(
          dimension: textXL,
          child: CircularProgressIndicator(padding: EdgeInsets.all(spaceXXXXS), color: widget.iconColor ?? _foregroundColor()),
        )
      : FaIcon(widget.icon, color: widget.iconColor ?? _foregroundColor(), size: textXL);

  @override
  Widget build(BuildContext context) {
    final Widget button = widget.subButtons == null || widget.subButtons!.isEmpty
        ? TextButton.icon(
            onPressed: widget.onPressed != null ? onPressed : null,
            style: ButtonStyle(
              alignment: Alignment.centerLeft,
              backgroundColor: WidgetStatePropertyAll(_backgroundColor()),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: widget.sub ? BorderRadius.zero : BorderRadius.all(cornerRadiusMD), side: BorderSide.none),
              ),
            ),
            icon: getIcon(),
            label: Padding(
              padding: EdgeInsets.only(left: spaceXS),
              child: Text(
                widget.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _foregroundColor(), fontSize: textMD, fontWeight: FontWeight.bold),
              ),
            ),
          )
        : Container(
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.all(cornerRadiusMD), color: _backgroundColor()),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onPressed != null ? onPressed : null,
                      style: ButtonStyle(
                        alignment: Alignment.centerLeft,
                        backgroundColor: WidgetStatePropertyAll(_backgroundColor()),
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                      ),
                      icon: getIcon(),
                      label: Padding(
                        padding: EdgeInsets.only(left: spaceXS),
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _foregroundColor(), fontSize: textMD, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: animFast,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: expanded ? widget.subButtons! : []),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: () => setState(() {
                      expanded = !expanded;
                    }),
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStatePropertyAll(_backgroundColor()),
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceMD)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(cornerRadiusMD), side: BorderSide.none)),
                    ),
                    icon: FaIcon(
                      expanded ? FontAwesomeIcons.caretUp : FontAwesomeIcons.caretDown,
                      color: widget.iconColor ?? _foregroundColor(),
                      size: textLG,
                    ),
                  ),
                ),
              ],
            ),
          );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        triggerMode: TooltipTriggerMode.longPress,
        waitDuration: animShort,
        child: button,
      );
    }
    return button;
  }
}
