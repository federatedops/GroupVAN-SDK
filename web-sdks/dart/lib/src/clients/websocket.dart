/// Streaming WebSocket plumbing shared by the catalogs and search clients.
///
/// Houses the single multiplexed socket, the stream adapter that turns a
/// socket request into a `Stream<T>`, and the helpers that fold streamed
/// asset/pricing/equivalent frames onto a list of [Part]s.
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import '../auth/auth_manager.dart';
import '../auth/auth_models.dart' as auth_models;
import '../core/exceptions.dart';
import '../core/http_client.dart';
import '../logging.dart';
import '../models/models.dart';

/// Apply asset data from a WebSocket message to a list of parts.
void applyAssets(List<Part> parts, Map<String, dynamic> assets) {
  for (final part in parts) {
    final assetData = assets[part.id.toString()];
    if (assetData != null) {
      part.assets = Asset.fromJson(assetData as Map<String, dynamic>);
    }
  }
}

/// Apply pricing data from a WebSocket message to a list of parts.
/// Also extracts alternates (status_code 2), supercessions (status_code 3),
/// and equivalents (status_code 4) and nests them under their
/// original part matched by original_mfr + original_part.
///
/// When [isPrimary] is true, the pricing fields (comment, descriptions, etc.)
/// are used to build the part's pricing model — any locations accumulated from
/// earlier non-primary messages are preserved. When false, only locations are
/// appended to the existing pricing.
void applyPricing(List<Part> parts, Map<String, dynamic> pricing, {required bool isPrimary}) {
  final partLookup = <String, Part>{};
  for (final part in parts) {
    partLookup['${part.mfrCode}_${part.partNumber}'] = part;
    final pricingData = pricing[part.id.toString()];
    if (pricingData != null) {
      final newPricing = ItemPricing.fromJson(pricingData as Map<String, dynamic>);
      if (isPrimary) {
        // Primary response owns the part-level fields; keep any locations
        // that arrived from earlier non-primary messages.
        if (part.pricing != null) {
          newPricing.locations.addAll(part.pricing!.locations);
        }
        part.pricing = newPricing;
      } else {
        if (part.pricing != null) {
          part.pricing!.locations.addAll(newPricing.locations);
        } else {
          // Primary hasn't arrived yet — store a blank shell with just locations.
          part.pricing = ItemPricing(
            comment: '',
            id: newPricing.id,
            locations: newPricing.locations,
            mfrCode: '',
            mfrDescription: '',
            partDescription: '',
            partNumber: '',
            statusCode: newPricing.statusCode,
          );
        }
      }
    }
  }
  for (final entry in pricing.entries) {
    final item = entry.value as Map<String, dynamic>;
    final statusCode = item['status_code'];
    if (statusCode == null ||
        statusCode == 1 ||
        item['original_part'] == null ||
        item['original_mfr'] == null) continue;
    final parentPart = partLookup['${item['original_mfr']}_${item['original_part']}'];
    if (parentPart == null) continue;

    // Select the correct list based on status_code
    final List<Part> targetList;
    switch (statusCode) {
      case 2:
        targetList = parentPart.alternates;
        break;
      case 3:
        targetList = parentPart.supercessions;
        break;
      case 4:
        targetList = parentPart.equivalents;
        break;
      default:
        continue;
    }

    final existing = targetList.where(
      (p) => p.mfrCode == item['mfr_code'] && p.partNumber == item['part_number'],
    );
    final newPricing = ItemPricing.fromJson(item);
    if (existing.isEmpty) {
      final pricing = isPrimary
          ? newPricing
          : ItemPricing(
              comment: '',
              id: newPricing.id,
              locations: newPricing.locations,
              mfrCode: '',
              mfrDescription: '',
              partDescription: '',
              partNumber: '',
              statusCode: newPricing.statusCode,
            );
      targetList.add(Part(
        id: 0,
        itemType: parentPart.itemType,
        sku: 0,
        rank: 0,
        tier: 0,
        mfrCode: item['mfr_code'],
        mfrName: '',
        partNumber: item['part_number'],
        buyersGuide: false,
        primaryImageExists: false,
        secondaryImageExists: false,
        documentExists: false,
        spinExists: false,
        attributeExists: false,
        interchange: false,
        applications: [],
        pricing: pricing,
      ));
    } else {
      final p = existing.first;
      if (isPrimary) {
        if (p.pricing != null) {
          newPricing.locations.addAll(p.pricing!.locations);
        }
        p.pricing = newPricing;
      } else {
        if (p.pricing != null) {
          p.pricing!.locations.addAll(newPricing.locations);
        } else {
          p.pricing = ItemPricing(
            comment: '',
            id: newPricing.id,
            locations: newPricing.locations,
            mfrCode: '',
            mfrDescription: '',
            partDescription: '',
            partNumber: '',
            statusCode: newPricing.statusCode,
          );
        }
      }
    }
  }
}

/// Apply equivalents data from a WebSocket message to a list of parts.
void applyEquivalents(List<Part> parts, Map<String, dynamic> equivalents) {
  for (final part in parts) {
    final eqList = equivalents[part.id.toString()];
    if (eqList == null) continue;
    for (final eq in eqList) {
      part.equivalents.add(Part(
        id: 0,
        itemType: part.itemType,
        sku: 0,
        rank: 0,
        tier: 0,
        mfrCode: eq['mfr_code'],
        mfrName: '',
        partNumber: eq['part_number'],
        buyersGuide: false,
        primaryImageExists: false,
        secondaryImageExists: false,
        documentExists: false,
        spinExists: false,
        attributeExists: false,
        interchange: false,
        applications: [],
      ));
    }
  }
}

/// Apply equivalent pricing data from a WebSocket message to a list of parts.
void applyEquivalentPricing(List<Part> parts, Map<String, dynamic> eqPricing) {
  for (final part in parts) {
    for (final eq in part.equivalents) {
      final pricingData = eqPricing['${eq.mfrCode}_${eq.partNumber}'];
      if (pricingData != null) {
        eq.pricing = ItemPricing.fromJson(pricingData as Map<String, dynamic>);
      }
    }
  }
}

/// Single persistent WebSocket to `/v3/ws/stream` that multiplexes every
/// streaming feature (omni search, products search, products listing).
///
/// Each logical request is tagged with a client-generated `request_id` that
/// the server echoes back on every frame. Inbound frames are routed to a
/// handler keyed by that id, which lets multiple concurrent callers share
/// the same socket without stepping on each other.
///
/// - Lazy-connects on first request.
/// - Authenticates via a first-frame `{type: auth, token}` and waits for
///   `{type: auth_ok}` before releasing queued sends.
/// - Re-authenticates in-band on [AuthManager] token rotation, so the
///   10-minute JWT never forces a reconnect.
class MultiplexedSocket {
  static const _authTimeout = Duration(seconds: 10);

  final GroupVanHttpClient _httpClient;
  final AuthManager _authManager;
  final _uuid = const Uuid();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  StreamSubscription<auth_models.AuthStatus>? _authSub;
  Completer<void>? _authReady;
  String? _authedToken;

  // One handler per outstanding request_id. Each call to [sendRequest]
  // installs an entry and removes it when the request ends (via a `done`
  // frame, an error, or explicit cancellation).
  final Map<String, void Function(Map<String, dynamic>)> _handlers = {};

  MultiplexedSocket(this._httpClient, this._authManager) {
    _authSub = _authManager.statusStream.listen((status) {
      final token = status.accessToken;
      if (_channel == null || token == null || token == _authedToken) return;
      _sendRaw({'type': 're_auth', 'token': token});
      _authedToken = token;
    });
  }

  /// Fire a request over the shared socket and route responses to [onFrame]
  /// until the server sends `{done: true}` for this request id.
  ///
  /// Returns the request id so the caller can cancel early via [cancel].
  Future<String> sendRequest({
    required String type,
    required Map<String, dynamic> payload,
    required void Function(Map<String, dynamic>) onFrame,
  }) async {
    await ensureConnected();
    final requestId = _uuid.v4();
    _handlers[requestId] = onFrame;
    _sendRaw({
      'type': type,
      'request_id': requestId,
      'payload': payload,
    });
    return requestId;
  }

  /// Stop routing frames for a request. Late-arriving frames with this id
  /// will be dropped.
  void cancel(String requestId) {
    _handlers.remove(requestId);
  }

  /// Open and authenticate the socket if it isn't already. Safe to call
  /// repeatedly — subsequent calls return the cached ready future.
  Future<void> ensureConnected() async {
    if (_channel != null && _authReady != null) {
      return _authReady!.future;
    }

    final token = _authManager.currentStatus.accessToken;
    if (token == null) {
      throw AuthenticationException(
        'Not authenticated. Please call auth.login() first.',
        errorType: AuthErrorType.missingToken,
      );
    }

    final baseUri = Uri.parse(_httpClient.baseUrl);
    final wsUri = Uri(
      scheme: baseUri.scheme == 'http' ? 'ws' : 'wss',
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '/v3/ws/stream',
    );

    final channel = WebSocketChannel.connect(wsUri);
    _channel = channel;
    _authReady = Completer<void>();

    _channelSub = channel.stream.listen(
      _onMessage,
      onError: _onChannelError,
      onDone: _onChannelDone,
    );

    _sendRaw({'type': 'auth', 'token': token});
    _authedToken = token;

    return _authReady!.future.timeout(
      _authTimeout,
      onTimeout: () {
        final err = NetworkException(
          'Timed out waiting for WebSocket auth_ok frame.',
        );
        _failAndReset(err);
        throw err;
      },
    );
  }

  void _sendRaw(Map<String, dynamic> frame) {
    _channel?.sink.add(jsonEncode(frame));
  }

  void _onMessage(dynamic message) {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(message as String) as Map<String, dynamic>;
    } catch (e) {
      GroupVanLogger.sdk.severe('Failed to decode multiplex frame: $e');
      return;
    }

    if (data['type'] == 'auth_ok') {
      if (!(_authReady?.isCompleted ?? true)) _authReady!.complete();
      return;
    }

    final requestId = data['request_id'] as String?;
    if (data.containsKey('error')) {
      final err = _exceptionFromErrorFrame(data);
      if (requestId != null) {
        final handler = _handlers.remove(requestId);
        handler?.call({'__error': err});
      } else {
        // Connection-level error with no request id — fail every outstanding
        // request and reset the socket.
        _failAndReset(err);
      }
      return;
    }

    if (requestId == null) {
      GroupVanLogger.sdk.warning(
        'Received multiplex frame with no request_id: ${data.keys}',
      );
      return;
    }

    final handler = _handlers[requestId];
    if (handler == null) {
      // Late frame for a cancelled/completed request — drop silently.
      return;
    }

    handler(data);

    if (data['done'] == true) {
      _handlers.remove(requestId);
    }
  }

  GroupVanException _exceptionFromErrorFrame(Map<String, dynamic> data) {
    final title = (data['error'] ?? '').toString();
    final detail = (data['detail'] ?? '').toString();
    final message = detail.isEmpty ? title : '$title: $detail';
    final lower = title.toLowerCase();
    if (lower.contains('token')) {
      final isExpired = lower.contains('expired');
      return AuthenticationException(
        message,
        errorType: isExpired
            ? AuthErrorType.expiredToken
            : AuthErrorType.invalidToken,
      );
    }
    return NetworkException('WebSocket error: $message');
  }

  void _onChannelError(Object error) {
    _failAndReset(error);
  }

  void _onChannelDone() {
    final closeCode = _channel?.closeCode;
    final closeReason = _channel?.closeReason ?? '';
    final Object error;
    if (closeCode == 1011 && closeReason.toLowerCase().contains('expired')) {
      error = AuthenticationException(
        'WebSocket closed by server: $closeReason',
        errorType: AuthErrorType.expiredToken,
      );
    } else {
      error = NetworkException(
        'WebSocket closed by server.'
        '${closeCode != null ? ' (code: $closeCode)' : ''}'
        '${closeReason.isNotEmpty ? ' $closeReason' : ''}',
      );
    }
    _failAndReset(error);
  }

  void _failAndReset(Object error) {
    _tearDown();
    if (error is AuthenticationException &&
        error.errorType == AuthErrorType.expiredToken) {
      // Try to refresh the access token and reconnect silently. Handlers
      // only see an error if the refresh itself fails.
      unawaited(_recoverFromExpiredToken(error));
      return;
    }
    _surfaceError(error);
  }

  void _tearDown() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;
    _authReady = null;
    _authedToken = null;
  }

  void _surfaceError(Object error) {
    if (!(_authReady?.isCompleted ?? true)) {
      _authReady!.completeError(error);
    }
    final toNotify = _handlers.values.toList();
    _handlers.clear();
    for (final handler in toNotify) {
      try {
        handler({'__error': error});
      } catch (_) {}
    }
  }

  Future<void> _recoverFromExpiredToken(
    AuthenticationException original,
  ) async {
    try {
      await _authManager.refreshToken();
    } catch (_) {
      _surfaceError(original);
      return;
    }
    if (_handlers.isEmpty) {
      // No one is listening — don't eagerly reopen the socket.
      return;
    }
    // Outstanding requests can't be replayed after a drop; surface the
    // original error and let callers re-issue.
    _surfaceError(original);
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
    await _channelSub?.cancel();
    _channelSub = null;
    await _channel?.sink.close();
    _channel = null;
    _authReady = null;
    _handlers.clear();
  }
}

/// Adapter: turn a multiplexed-socket request into a `Stream<T>`.
///
/// [onData] is invoked for every data frame and should return the caller's
/// accumulated value to emit. The stream closes on the server's `done`
/// frame, on error, or when the subscription is cancelled.
Stream<T> streamMultiplexRequest<T>({
  required MultiplexedSocket socket,
  required String type,
  required Map<String, dynamic> payload,
  required T Function(Map<String, dynamic> data) onData,
}) {
  final controller = StreamController<T>();
  String? requestId;

  controller.onListen = () async {
    try {
      requestId = await socket.sendRequest(
        type: type,
        payload: payload,
        onFrame: (frame) {
          if (frame.containsKey('__error')) {
            controller.addError(frame['__error'] as Object);
            controller.close();
            return;
          }
          try {
            controller.add(onData(frame));
          } catch (e, st) {
            controller.addError(e, st);
            controller.close();
            return;
          }
          if (frame['done'] == true) {
            controller.close();
          }
        },
      );
    } catch (e, st) {
      controller.addError(e, st);
      await controller.close();
    }
  };

  controller.onCancel = () {
    final id = requestId;
    if (id != null) socket.cancel(id);
  };

  return controller.stream;
}
