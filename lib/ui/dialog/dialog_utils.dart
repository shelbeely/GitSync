import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';

/// Default translucent barrier colour used by every app dialog so the M3
/// dialog surface always reads against a consistent scrim.
const Color kAppDialogBarrierColor = Colors.black54;

/// Wrapper around Flutter's [showDialog] that injects a consistent translucent
/// [barrierColor] across every call site. Pass an explicit [barrierColor] to
/// override (e.g. for a transparent scrim).
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor = kAppDialogBarrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
}) {
  return mat.showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
  );
}
