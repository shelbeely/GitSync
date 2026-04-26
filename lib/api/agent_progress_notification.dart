import 'dart:io';

import 'package:flutter/services.dart';
import 'package:GitSync/api/sync_progress_notification.dart';

/// Wrapper around the native Android 16 `Notification.ProgressStyle` helper
/// for GitHub Copilot agent-session progress.
///
/// On Android 16+ this drives a persistent progress notification through the
/// `com.viscouspot.gitsync/agent_progress` method channel. On older Android
/// versions and on iOS [isSupported] returns `false`.
///
/// The `isSupported()` check delegates to
/// [SyncProgressNotification.instance.isSupported] so the SDK lookup is
/// performed only once per app session.
class AgentProgressNotification {
  AgentProgressNotification._();
  static final AgentProgressNotification instance = AgentProgressNotification._();

  static const MethodChannel _channel = MethodChannel('com.viscouspot.gitsync/agent_progress');

  /// Returns `true` only on Android API 36+ where `Notification.ProgressStyle`
  /// is available. Delegates to [SyncProgressNotification] to avoid a redundant
  /// `device_info_plus` lookup.
  Future<bool> isSupported() => SyncProgressNotification.instance.isSupported();

  /// Shows or updates the agent progress notification at [stage].
  ///
  /// [stage] must be one of `creating`, `working`.
  /// Returns `true` if the native call ran, `false` if unsupported.
  Future<bool> showProgress({
    required String stage,
    required String title,
    required String text,
  }) async {
    if (!Platform.isAndroid) return false;
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

  /// Marks the progress notification as complete and schedules an auto-dismiss.
  Future<bool> completeProgress({
    required bool success,
    required String title,
    required String text,
    Duration autoCancel = const Duration(seconds: 3),
  }) async {
    if (!Platform.isAndroid) return false;
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
    if (!Platform.isAndroid) return;
    if (!await isSupported()) return;
    try {
      await _channel.invokeMethod<void>('cancelProgress');
    } on PlatformException {
      // best effort.
    } on MissingPluginException {
      // best effort.
    }
  }
}
