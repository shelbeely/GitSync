import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Bridge to the Android 16 (`API 36`) `JobScheduler.getPendingJobReasons`
/// and `ApplicationStartInfo.getStartComponent` diagnostics. Returns empty
/// lists on iOS and on pre-API-36 Android devices so callers can append the
/// results unconditionally to bug-report payloads.
class SyncDiagnostics {
  SyncDiagnostics._();
  static final SyncDiagnostics instance = SyncDiagnostics._();

  static const MethodChannel _channel = MethodChannel('com.viscouspot.gitsync/sync_diagnostics');

  /// Returns human-readable reasons that the workmanager job with [jobId] is
  /// currently pending, or an empty list if unsupported / no pending reasons.
  Future<List<String>> getPendingJobReasons(int jobId) async {
    if (!Platform.isAndroid) return const <String>[];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getPendingJobReasons', {
        'jobId': jobId,
      });
      return raw?.whereType<String>().toList(growable: false) ?? const <String>[];
    } on PlatformException {
      return const <String>[];
    } on MissingPluginException {
      return const <String>[];
    }
  }

  /// Returns up to [limit] recent process start descriptors, formatted as
  /// `reason=<n> type=<n> component=<flat>` strings.
  Future<List<String>> getRecentStartComponents({int limit = 5}) async {
    if (!Platform.isAndroid) return const <String>[];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getRecentStartComponents', {
        'limit': limit,
      });
      return raw?.whereType<String>().toList(growable: false) ?? const <String>[];
    } on PlatformException {
      return const <String>[];
    } on MissingPluginException {
      return const <String>[];
    }
  }
}
