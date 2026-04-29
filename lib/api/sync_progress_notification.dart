import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

/// Wrapper around the native Android 16 `Notification.ProgressStyle` helper.
///
/// On Android 16+ this drives a persistent progress notification through the
/// `com.shelbeely.gitcommand/sync_progress` method channel. On older Android
/// versions [isSupported] returns `false` so callers can fall back to the
/// existing toast / `flutter_local_notifications` UX.
class SyncProgressNotification {
  SyncProgressNotification._();
  static final SyncProgressNotification instance = SyncProgressNotification._();

  static const MethodChannel _channel = MethodChannel('com.shelbeely.gitcommand/sync_progress');

  // Android 16 maps to API level 36 (BAKLAVA).
  static const int _android16Sdk = 36;

  bool? _supported;
  Future<bool>? _supportedFuture;

  /// Returns `true` only on Android API 36+ where `Notification.ProgressStyle`
  /// is available. Cached after the first lookup.
  Future<bool> isSupported() {
    if (_supported != null) return Future.value(_supported);
    return _supportedFuture ??= _resolveSupported();
  }

  Future<bool> _resolveSupported() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt < _android16Sdk) {
        _supported = false;
        return false;
      }
    } catch (_) {
      _supported = false;
      return false;
    }

    // Confirm with the native side as well — older devices that somehow report
    // API 36 but lack the symbols will return false here.
    try {
      final native = await _channel.invokeMethod<bool>('isSupported');
      _supported = native ?? false;
    } on PlatformException {
      _supported = false;
    } on MissingPluginException {
      _supported = false;
    }
    return _supported!;
  }

  /// Shows or updates the progress notification at [stage].
  ///
  /// [stage] must be one of `detecting`, `pulling`, `pushing`.
  /// Returns `true` if the native call ran (Android 16+), `false` if the
  /// caller should fall back to its legacy notification path.
  Future<bool> showProgress({
    required String stage,
    required String title,
    required String text,
  }) async {
    if (!await isSupported()) return false;
    try {
      await _channel.invokeMethod<void>('showProgress', {
        'stage': stage,
        'title': title,
        'text': text,
      });
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Marks the progress notification as complete and schedules an auto-dismiss
  /// after [autoCancel].
  Future<bool> completeProgress({
    required bool success,
    required String title,
    required String text,
    Duration autoCancel = const Duration(seconds: 2),
  }) async {
    if (!await isSupported()) return false;
    try {
      await _channel.invokeMethod<void>('completeProgress', {
        'success': success,
        'title': title,
        'text': text,
        'autoCancelMs': autoCancel.inMilliseconds,
      });
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Immediately removes the progress notification.
  Future<void> cancelProgress() async {
    if (!await isSupported()) return;
    try {
      await _channel.invokeMethod<void>('cancelProgress');
    } on PlatformException {
      // best effort — nothing to do.
    } on MissingPluginException {
      // best effort — nothing to do.
    }
  }
}
