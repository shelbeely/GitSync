import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Abstract contract for a persistent real-time event channel.
///
/// Concrete implementations include [HttpLongPollChannel] (ETag-based
/// conditional polling, suitable for the GitHub REST API) and
/// [WebSocketEventChannel] (for providers that expose a real WS endpoint).
abstract class RemoteEventChannel<T> {
  /// Broadcast stream of events emitted by this channel.
  Stream<T> get events;

  /// Opens the connection / starts the polling loop.
  Future<void> connect();

  /// Cancels the loop and closes the stream controller.
  void disconnect();
}

/// A [RemoteEventChannel] that drives updates via ETag-conditional HTTP GET
/// requests.
///
/// On a **200** response the [parseItems] callback decodes the response body
/// and returns a list of items that are added to [events]. The ETag is stored
/// and sent with the next request as `If-None-Match` so the server can respond
/// with **304 Not Modified** (holding the connection for up to
/// `X-Poll-Interval` seconds) when nothing changed.
///
/// On **304** the loop retries immediately (the server already imposed the
/// wait). On network errors or 5xx responses the loop backs off
/// exponentially from 2 s up to 60 s.
class HttpLongPollChannel<T> implements RemoteEventChannel<T> {
  final Uri uri;
  final Map<String, String> baseHeaders;

  /// Decodes the parsed JSON body (either a Map or a List) and returns the
  /// list of strongly-typed items to emit.
  final List<T> Function(dynamic json) parseItems;

  final StreamController<T> _controller = StreamController<T>.broadcast();
  http.Client? _client;
  bool _connected = false;
  String? _etag;

  HttpLongPollChannel({
    required this.uri,
    required this.baseHeaders,
    required this.parseItems,
  });

  @override
  Stream<T> get events => _controller.stream;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _connected = true;
    _client = http.Client();
    unawaited(_loop());
  }

  @override
  void disconnect() {
    _connected = false;
    _client?.close();
    _client = null;
    if (!_controller.isClosed) _controller.close();
  }

  Future<void> _loop() async {
    int backoffSeconds = 2;
    while (_connected) {
      try {
        final headers = Map<String, String>.from(baseHeaders);
        if (_etag != null) headers['If-None-Match'] = _etag!;

        final response = await _client!
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 60));
        if (!_connected) break;

        final pollInterval = int.tryParse(response.headers['x-poll-interval'] ?? '') ?? 0;

        if (response.statusCode == 304) {
          backoffSeconds = 2;
          // Only apply a guard delay if the server gave no indication that it
          // already held the connection. A non-zero X-Poll-Interval header on a
          // 304 response means the server imposed the wait itself; adding a
          // further delay would double the effective polling interval.
          if (pollInterval == 0) await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        if (response.statusCode == 200) {
          final newEtag = response.headers['etag'];
          if (newEtag != null) _etag = newEtag;

          try {
            final body = jsonDecode(response.body);
            final items = parseItems(body);
            for (final item in items) {
              if (!_controller.isClosed) _controller.add(item);
            }
          } catch (_) {
            // Parsing error — keep the loop alive.
          }

          backoffSeconds = 2;
          if (pollInterval > 0) await Future.delayed(Duration(seconds: pollInterval));
          continue;
        }

        // Non-200/304 response: back off.
        await Future.delayed(Duration(seconds: backoffSeconds));
        backoffSeconds = (backoffSeconds * 2).clamp(2, 60);
      } catch (_) {
        if (!_connected) break;
        await Future.delayed(Duration(seconds: backoffSeconds));
        backoffSeconds = (backoffSeconds * 2).clamp(2, 60);
      }
    }
  }
}

/// A [RemoteEventChannel] backed by a real WebSocket connection.
///
/// Suitable for providers that expose a native WS endpoint (e.g. self-hosted
/// Gitea `/events`, or a custom relay). Reconnects with exponential back-off
/// on close or error.
class WebSocketEventChannel<T> implements RemoteEventChannel<T> {
  final Uri uri;

  /// Converts a raw WebSocket text message into a JSON map.
  final Map<String, dynamic> Function(String message) parseMessage;

  /// Converts the decoded JSON map to a typed event.  Returns `null` to
  /// discard the message.
  final T? Function(Map<String, dynamic> json) factory;

  final StreamController<T> _controller = StreamController<T>.broadcast();
  WebSocketChannel? _ws;
  StreamSubscription? _sub;
  bool _connected = false;

  WebSocketEventChannel({
    required this.uri,
    required this.parseMessage,
    required this.factory,
  });

  @override
  Stream<T> get events => _controller.stream;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _connected = true;
    unawaited(_loop());
  }

  @override
  void disconnect() {
    _connected = false;
    _sub?.cancel();
    _sub = null;
    _ws?.sink.close();
    _ws = null;
    if (!_controller.isClosed) _controller.close();
  }

  Future<void> _loop() async {
    int backoffSeconds = 2;
    while (_connected) {
      try {
        _ws = WebSocketChannel.connect(uri);
        final completer = Completer<void>();

        _sub = _ws!.stream.listen(
          (msg) {
            if (!_connected || _controller.isClosed) return;
            try {
              final json = parseMessage(msg as String);
              final event = factory(json);
              if (event != null) _controller.add(event);
            } catch (_) {}
          },
          onDone: () => completer.complete(),
          onError: (Object e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
          cancelOnError: true,
        );

        await completer.future;
        if (!_connected) break;

        // Normal close — reconnect with back-off.
        await Future.delayed(Duration(seconds: backoffSeconds));
        backoffSeconds = (backoffSeconds * 2).clamp(2, 60);
      } catch (_) {
        if (!_connected) break;
        await Future.delayed(Duration(seconds: backoffSeconds));
        backoffSeconds = (backoffSeconds * 2).clamp(2, 60);
      } finally {
        await _sub?.cancel();
        _sub = null;
        _ws = null;
      }
    }
  }
}
