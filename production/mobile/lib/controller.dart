import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'vault.dart';

class RexController extends ChangeNotifier {
  RexController(this.api, this.vault);
  final RexTransport api;
  final SessionVault vault;
  String? _token;
  String? _recoverableToken;
  Map<String, dynamic>? me;
  Map<String, dynamic>? table;
  Map<String, dynamic>? _pending;
  bool busy = false;
  bool initialized = false;
  bool recoveryRequired = false;
  bool _refreshing = false;
  bool _active = true;
  bool _disposed = false;
  String? error;
  Timer? _poll;
  static const bool candidateEnabled =
      kDebugMode && bool.fromEnvironment('REX_CANDIDATE_MATCH_UI');

  bool get signedIn => _token != null;
  bool get hasPendingAction => _pending != null;
  bool get canPreserveSession => recoveryRequired && _recoverableToken != null;

  bool _validPending(Object? value) {
    if (value is! Map<String, dynamic>) return false;
    final path = value['path'];
    final body = value['body'];
    if (path is! String || body is! Map<String, dynamic>) return false;
    final id = body['action_id'];
    if (id is! String || !RegExp(r'^[0-9a-f]{32}$').hasMatch(id)) {
      return false;
    }
    if (candidateEnabled &&
        RegExp(r'^/v1/tables/[0-9a-f]{32}/match/actions
  }

  Future<void> initialize() async {
    if (initialized || busy) return;
    await _run(() async {
      final saved = await vault.read();
      if (saved != null) {
        Map<String, dynamic> value;
        String? recoverableToken;
        try {
          final decoded = jsonDecode(saved);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('invalid saved session');
          }
          final token = decoded['token'];
          if (token is! String || token.isEmpty) {
            throw const FormatException('invalid saved token');
          }
          recoverableToken = token;
          if (decoded['pending'] != null &&
              !_validPending(decoded['pending'])) {
            throw const FormatException('invalid pending action');
          }
          value = decoded;
        } on FormatException {
          // Preserve the unreadable record until the player explicitly agrees
          // to reset it. Keep a valid token even if only its pending action is
          // damaged; losing the sole guest identity is avoidable in that case.
          _recoverableToken = recoverableToken;
          recoveryRequired = true;
          error = recoverableToken == null
              ? 'invalid_local_session'
              : 'invalid_local_action';
          return;
        }
        _token = value['token'] as String;
        _pending = value['pending'] as Map<String, dynamic>?;
        if (_token != null) {
          await _replay();
          await _refresh();
        }
      }
      initialized = true;
    });
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> resetCorruptSession() => _run(() async {
    if (!recoveryRequired) return;
    final token = _recoverableToken;
    await vault.write(
      token == null ? null : jsonEncode({'token': token, 'pending': null}),
    );
    _token = token;
    _recoverableToken = null;
    _pending = null;
    me = null;
    table = null;
    recoveryRequired = false;
    initialized = true;
    if (token != null) await _refresh();
  });

  Future<void> _save() => vault.write(
    _token == null ? null : jsonEncode({'token': _token, 'pending': _pending}),
  );

  Future<void> enterGuest() => _run(() async {
    final result = await api.request('POST', '/v1/guests', body: {});
    final token = result['token'] as String;
    final identity = result['me'] as Map<String, dynamic>;
    try {
      await vault.write(jsonEncode({'token': token, 'pending': null}));
    } catch (_) {
      // Do not publish a guest that cannot survive a process restart. Revoke
      // the newly issued session if the server is reachable; never log it.
      try {
        await api.request('DELETE', '/v1/session', token: token);
      } catch (_) {
        /* Best effort; no locally usable session is exposed. */
      }
      rethrow;
    }
    _token = token;
    me = identity;
    initialized = true;
  });

  Future<void> create(String game) => _act('/v1/tables', {'game': game});
  Future<void> join(String invite) =>
      _act('/v1/tables/join', {'invite': invite.trim()});
  Future<void> ready(bool value) => _act('/v1/tables/${table!['id']}/ready', {
    'expected_version': table!['version'],
    'ready': value,
  });
  Future<void> leave() => _act('/v1/tables/${table!['id']}/leave', {
    'expected_version': table!['version'],
  });

  Future<Map<String, dynamic>> candidateView(String roomId) {
    if (!candidateEnabled || !signedIn ||
        !RegExp(r'^[0-9a-f]{32}
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(path)) {
      const keys = {'action_id', 'expected_version', 'type', 'contract', 'card'};
      if (!body.keys.every(keys.contains) ||
          body['expected_version'] is! int ||
          (body['expected_version'] as int) < 1 ||
          body['type'] is! String) return false;
      if (body['type'] == 'choose_contract') {
        return {'complex', 'trix'}.contains(body['contract']) &&
            !body.containsKey('card');
      }
      if (body['type'] == 'pass') {
        return !body.containsKey('card') && !body.containsKey('contract');
      }
      if (body['type'] == 'play_card' &&
          !body.containsKey('contract') &&
          body['card'] is Map<String, dynamic>) {
        final card = body['card'] as Map<String, dynamic>;
        return card.length == 2 &&
            card.keys.every({'suit', 'rank'}.contains) &&
            card['suit'] is int && (card['suit'] as int) >= 0 &&
            (card['suit'] as int) < 4 &&
            card['rank'] is int && (card['rank'] as int) >= 2 &&
            (card['rank'] as int) <= 14;
      }
      return false;
    }
    return path == '/v1/tables' ||
        path == '/v1/tables/join' ||
        RegExp(r'^/v1/tables/[0-9a-f]{32}/(ready|leave)
  }

  Future<void> initialize() async {
    if (initialized || busy) return;
    await _run(() async {
      final saved = await vault.read();
      if (saved != null) {
        Map<String, dynamic> value;
        String? recoverableToken;
        try {
          final decoded = jsonDecode(saved);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('invalid saved session');
          }
          final token = decoded['token'];
          if (token is! String || token.isEmpty) {
            throw const FormatException('invalid saved token');
          }
          recoverableToken = token;
          if (decoded['pending'] != null &&
              !_validPending(decoded['pending'])) {
            throw const FormatException('invalid pending action');
          }
          value = decoded;
        } on FormatException {
          // Preserve the unreadable record until the player explicitly agrees
          // to reset it. Keep a valid token even if only its pending action is
          // damaged; losing the sole guest identity is avoidable in that case.
          _recoverableToken = recoverableToken;
          recoveryRequired = true;
          error = recoverableToken == null
              ? 'invalid_local_session'
              : 'invalid_local_action';
          return;
        }
        _token = value['token'] as String;
        _pending = value['pending'] as Map<String, dynamic>?;
        if (_token != null) {
          await _replay();
          await _refresh();
        }
      }
      initialized = true;
    });
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> resetCorruptSession() => _run(() async {
    if (!recoveryRequired) return;
    final token = _recoverableToken;
    await vault.write(
      token == null ? null : jsonEncode({'token': token, 'pending': null}),
    );
    _token = token;
    _recoverableToken = null;
    _pending = null;
    me = null;
    table = null;
    recoveryRequired = false;
    initialized = true;
    if (token != null) await _refresh();
  });

  Future<void> _save() => vault.write(
    _token == null ? null : jsonEncode({'token': _token, 'pending': _pending}),
  );

  Future<void> enterGuest() => _run(() async {
    final result = await api.request('POST', '/v1/guests', body: {});
    final token = result['token'] as String;
    final identity = result['me'] as Map<String, dynamic>;
    try {
      await vault.write(jsonEncode({'token': token, 'pending': null}));
    } catch (_) {
      // Do not publish a guest that cannot survive a process restart. Revoke
      // the newly issued session if the server is reachable; never log it.
      try {
        await api.request('DELETE', '/v1/session', token: token);
      } catch (_) {
        /* Best effort; no locally usable session is exposed. */
      }
      rethrow;
    }
    _token = token;
    me = identity;
    initialized = true;
  });

  Future<void> create(String game) => _act('/v1/tables', {'game': game});
  Future<void> join(String invite) =>
      _act('/v1/tables/join', {'invite': invite.trim()});
  Future<void> ready(bool value) => _act('/v1/tables/${table!['id']}/ready', {
    'expected_version': table!['version'],
    'ready': value,
  });
  Future<void> leave() => _act('/v1/tables/${table!['id']}/leave', {
    'expected_version': table!['version'],
  });

  Future<void> _act(String path, Map<String, dynamic> body) => _run(() async {
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(path);
  }

  Future<void> initialize() async {
    if (initialized || busy) return;
    await _run(() async {
      final saved = await vault.read();
      if (saved != null) {
        Map<String, dynamic> value;
        String? recoverableToken;
        try {
          final decoded = jsonDecode(saved);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('invalid saved session');
          }
          final token = decoded['token'];
          if (token is! String || token.isEmpty) {
            throw const FormatException('invalid saved token');
          }
          recoverableToken = token;
          if (decoded['pending'] != null &&
              !_validPending(decoded['pending'])) {
            throw const FormatException('invalid pending action');
          }
          value = decoded;
        } on FormatException {
          // Preserve the unreadable record until the player explicitly agrees
          // to reset it. Keep a valid token even if only its pending action is
          // damaged; losing the sole guest identity is avoidable in that case.
          _recoverableToken = recoverableToken;
          recoveryRequired = true;
          error = recoverableToken == null
              ? 'invalid_local_session'
              : 'invalid_local_action';
          return;
        }
        _token = value['token'] as String;
        _pending = value['pending'] as Map<String, dynamic>?;
        if (_token != null) {
          await _replay();
          await _refresh();
        }
      }
      initialized = true;
    });
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> resetCorruptSession() => _run(() async {
    if (!recoveryRequired) return;
    final token = _recoverableToken;
    await vault.write(
      token == null ? null : jsonEncode({'token': token, 'pending': null}),
    );
    _token = token;
    _recoverableToken = null;
    _pending = null;
    me = null;
    table = null;
    recoveryRequired = false;
    initialized = true;
    if (token != null) await _refresh();
  });

  Future<void> _save() => vault.write(
    _token == null ? null : jsonEncode({'token': _token, 'pending': _pending}),
  );

  Future<void> enterGuest() => _run(() async {
    final result = await api.request('POST', '/v1/guests', body: {});
    final token = result['token'] as String;
    final identity = result['me'] as Map<String, dynamic>;
    try {
      await vault.write(jsonEncode({'token': token, 'pending': null}));
    } catch (_) {
      // Do not publish a guest that cannot survive a process restart. Revoke
      // the newly issued session if the server is reachable; never log it.
      try {
        await api.request('DELETE', '/v1/session', token: token);
      } catch (_) {
        /* Best effort; no locally usable session is exposed. */
      }
      rethrow;
    }
    _token = token;
    me = identity;
    initialized = true;
  });

  Future<void> create(String game) => _act('/v1/tables', {'game': game});
  Future<void> join(String invite) =>
      _act('/v1/tables/join', {'invite': invite.trim()});
  Future<void> ready(bool value) => _act('/v1/tables/${table!['id']}/ready', {
    'expected_version': table!['version'],
    'ready': value,
  });
  Future<void> leave() => _act('/v1/tables/${table!['id']}/leave', {
    'expected_version': table!['version'],
  });

  Future<void> _act(String path, Map<String, dynamic> body) => _run(() async {
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(roomId)) {
      throw const ApiFailure('candidate_disabled', status: 403);
    }
    return api.request('GET', '/v1/tables/$roomId/match', token: _token);
  }

  Future<void> candidateStart(String roomId) {
    if (!candidateEnabled || !signedIn ||
        !RegExp(r'^[0-9a-f]{32}
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(path)) {
      const keys = {'action_id', 'expected_version', 'type', 'contract', 'card'};
      if (!body.keys.every(keys.contains) ||
          body['expected_version'] is! int ||
          (body['expected_version'] as int) < 1 ||
          body['type'] is! String) return false;
      if (body['type'] == 'choose_contract') {
        return {'complex', 'trix'}.contains(body['contract']) &&
            !body.containsKey('card');
      }
      if (body['type'] == 'pass') {
        return !body.containsKey('card') && !body.containsKey('contract');
      }
      if (body['type'] == 'play_card' &&
          !body.containsKey('contract') &&
          body['card'] is Map<String, dynamic>) {
        final card = body['card'] as Map<String, dynamic>;
        return card.length == 2 &&
            card.keys.every({'suit', 'rank'}.contains) &&
            card['suit'] is int && (card['suit'] as int) >= 0 &&
            (card['suit'] as int) < 4 &&
            card['rank'] is int && (card['rank'] as int) >= 2 &&
            (card['rank'] as int) <= 14;
      }
      return false;
    }
    return path == '/v1/tables' ||
        path == '/v1/tables/join' ||
        RegExp(r'^/v1/tables/[0-9a-f]{32}/(ready|leave)
  }

  Future<void> initialize() async {
    if (initialized || busy) return;
    await _run(() async {
      final saved = await vault.read();
      if (saved != null) {
        Map<String, dynamic> value;
        String? recoverableToken;
        try {
          final decoded = jsonDecode(saved);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('invalid saved session');
          }
          final token = decoded['token'];
          if (token is! String || token.isEmpty) {
            throw const FormatException('invalid saved token');
          }
          recoverableToken = token;
          if (decoded['pending'] != null &&
              !_validPending(decoded['pending'])) {
            throw const FormatException('invalid pending action');
          }
          value = decoded;
        } on FormatException {
          // Preserve the unreadable record until the player explicitly agrees
          // to reset it. Keep a valid token even if only its pending action is
          // damaged; losing the sole guest identity is avoidable in that case.
          _recoverableToken = recoverableToken;
          recoveryRequired = true;
          error = recoverableToken == null
              ? 'invalid_local_session'
              : 'invalid_local_action';
          return;
        }
        _token = value['token'] as String;
        _pending = value['pending'] as Map<String, dynamic>?;
        if (_token != null) {
          await _replay();
          await _refresh();
        }
      }
      initialized = true;
    });
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> resetCorruptSession() => _run(() async {
    if (!recoveryRequired) return;
    final token = _recoverableToken;
    await vault.write(
      token == null ? null : jsonEncode({'token': token, 'pending': null}),
    );
    _token = token;
    _recoverableToken = null;
    _pending = null;
    me = null;
    table = null;
    recoveryRequired = false;
    initialized = true;
    if (token != null) await _refresh();
  });

  Future<void> _save() => vault.write(
    _token == null ? null : jsonEncode({'token': _token, 'pending': _pending}),
  );

  Future<void> enterGuest() => _run(() async {
    final result = await api.request('POST', '/v1/guests', body: {});
    final token = result['token'] as String;
    final identity = result['me'] as Map<String, dynamic>;
    try {
      await vault.write(jsonEncode({'token': token, 'pending': null}));
    } catch (_) {
      // Do not publish a guest that cannot survive a process restart. Revoke
      // the newly issued session if the server is reachable; never log it.
      try {
        await api.request('DELETE', '/v1/session', token: token);
      } catch (_) {
        /* Best effort; no locally usable session is exposed. */
      }
      rethrow;
    }
    _token = token;
    me = identity;
    initialized = true;
  });

  Future<void> create(String game) => _act('/v1/tables', {'game': game});
  Future<void> join(String invite) =>
      _act('/v1/tables/join', {'invite': invite.trim()});
  Future<void> ready(bool value) => _act('/v1/tables/${table!['id']}/ready', {
    'expected_version': table!['version'],
    'ready': value,
  });
  Future<void> leave() => _act('/v1/tables/${table!['id']}/leave', {
    'expected_version': table!['version'],
  });

  Future<void> _act(String path, Map<String, dynamic> body) => _run(() async {
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(path);
  }

  Future<void> initialize() async {
    if (initialized || busy) return;
    await _run(() async {
      final saved = await vault.read();
      if (saved != null) {
        Map<String, dynamic> value;
        String? recoverableToken;
        try {
          final decoded = jsonDecode(saved);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('invalid saved session');
          }
          final token = decoded['token'];
          if (token is! String || token.isEmpty) {
            throw const FormatException('invalid saved token');
          }
          recoverableToken = token;
          if (decoded['pending'] != null &&
              !_validPending(decoded['pending'])) {
            throw const FormatException('invalid pending action');
          }
          value = decoded;
        } on FormatException {
          // Preserve the unreadable record until the player explicitly agrees
          // to reset it. Keep a valid token even if only its pending action is
          // damaged; losing the sole guest identity is avoidable in that case.
          _recoverableToken = recoverableToken;
          recoveryRequired = true;
          error = recoverableToken == null
              ? 'invalid_local_session'
              : 'invalid_local_action';
          return;
        }
        _token = value['token'] as String;
        _pending = value['pending'] as Map<String, dynamic>?;
        if (_token != null) {
          await _replay();
          await _refresh();
        }
      }
      initialized = true;
    });
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> resetCorruptSession() => _run(() async {
    if (!recoveryRequired) return;
    final token = _recoverableToken;
    await vault.write(
      token == null ? null : jsonEncode({'token': token, 'pending': null}),
    );
    _token = token;
    _recoverableToken = null;
    _pending = null;
    me = null;
    table = null;
    recoveryRequired = false;
    initialized = true;
    if (token != null) await _refresh();
  });

  Future<void> _save() => vault.write(
    _token == null ? null : jsonEncode({'token': _token, 'pending': _pending}),
  );

  Future<void> enterGuest() => _run(() async {
    final result = await api.request('POST', '/v1/guests', body: {});
    final token = result['token'] as String;
    final identity = result['me'] as Map<String, dynamic>;
    try {
      await vault.write(jsonEncode({'token': token, 'pending': null}));
    } catch (_) {
      // Do not publish a guest that cannot survive a process restart. Revoke
      // the newly issued session if the server is reachable; never log it.
      try {
        await api.request('DELETE', '/v1/session', token: token);
      } catch (_) {
        /* Best effort; no locally usable session is exposed. */
      }
      rethrow;
    }
    _token = token;
    me = identity;
    initialized = true;
  });

  Future<void> create(String game) => _act('/v1/tables', {'game': game});
  Future<void> join(String invite) =>
      _act('/v1/tables/join', {'invite': invite.trim()});
  Future<void> ready(bool value) => _act('/v1/tables/${table!['id']}/ready', {
    'expected_version': table!['version'],
    'ready': value,
  });
  Future<void> leave() => _act('/v1/tables/${table!['id']}/leave', {
    'expected_version': table!['version'],
  });

  Future<void> _act(String path, Map<String, dynamic> body) => _run(() async {
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(roomId)) {
      throw const ApiFailure('candidate_disabled', status: 403);
    }
    return _run(() async {
      await api.request('POST', '/v1/tables/$roomId/match/start',
          token: _token, body: {});
    });
  }

  Future<void> candidateAction(String roomId, Map<String, dynamic> body) {
    if (!candidateEnabled || !signedIn ||
        !RegExp(r'^[0-9a-f]{32}
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(path)) {
      const keys = {'action_id', 'expected_version', 'type', 'contract', 'card'};
      if (!body.keys.every(keys.contains) ||
          body['expected_version'] is! int ||
          (body['expected_version'] as int) < 1 ||
          body['type'] is! String) return false;
      if (body['type'] == 'choose_contract') {
        return {'complex', 'trix'}.contains(body['contract']) &&
            !body.containsKey('card');
      }
      if (body['type'] == 'pass') {
        return !body.containsKey('card') && !body.containsKey('contract');
      }
      if (body['type'] == 'play_card' &&
          !body.containsKey('contract') &&
          body['card'] is Map<String, dynamic>) {
        final card = body['card'] as Map<String, dynamic>;
        return card.length == 2 &&
            card.keys.every({'suit', 'rank'}.contains) &&
            card['suit'] is int && (card['suit'] as int) >= 0 &&
            (card['suit'] as int) < 4 &&
            card['rank'] is int && (card['rank'] as int) >= 2 &&
            (card['rank'] as int) <= 14;
      }
      return false;
    }
    return path == '/v1/tables' ||
        path == '/v1/tables/join' ||
        RegExp(r'^/v1/tables/[0-9a-f]{32}/(ready|leave)
  }

  Future<void> initialize() async {
    if (initialized || busy) return;
    await _run(() async {
      final saved = await vault.read();
      if (saved != null) {
        Map<String, dynamic> value;
        String? recoverableToken;
        try {
          final decoded = jsonDecode(saved);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('invalid saved session');
          }
          final token = decoded['token'];
          if (token is! String || token.isEmpty) {
            throw const FormatException('invalid saved token');
          }
          recoverableToken = token;
          if (decoded['pending'] != null &&
              !_validPending(decoded['pending'])) {
            throw const FormatException('invalid pending action');
          }
          value = decoded;
        } on FormatException {
          // Preserve the unreadable record until the player explicitly agrees
          // to reset it. Keep a valid token even if only its pending action is
          // damaged; losing the sole guest identity is avoidable in that case.
          _recoverableToken = recoverableToken;
          recoveryRequired = true;
          error = recoverableToken == null
              ? 'invalid_local_session'
              : 'invalid_local_action';
          return;
        }
        _token = value['token'] as String;
        _pending = value['pending'] as Map<String, dynamic>?;
        if (_token != null) {
          await _replay();
          await _refresh();
        }
      }
      initialized = true;
    });
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> resetCorruptSession() => _run(() async {
    if (!recoveryRequired) return;
    final token = _recoverableToken;
    await vault.write(
      token == null ? null : jsonEncode({'token': token, 'pending': null}),
    );
    _token = token;
    _recoverableToken = null;
    _pending = null;
    me = null;
    table = null;
    recoveryRequired = false;
    initialized = true;
    if (token != null) await _refresh();
  });

  Future<void> _save() => vault.write(
    _token == null ? null : jsonEncode({'token': _token, 'pending': _pending}),
  );

  Future<void> enterGuest() => _run(() async {
    final result = await api.request('POST', '/v1/guests', body: {});
    final token = result['token'] as String;
    final identity = result['me'] as Map<String, dynamic>;
    try {
      await vault.write(jsonEncode({'token': token, 'pending': null}));
    } catch (_) {
      // Do not publish a guest that cannot survive a process restart. Revoke
      // the newly issued session if the server is reachable; never log it.
      try {
        await api.request('DELETE', '/v1/session', token: token);
      } catch (_) {
        /* Best effort; no locally usable session is exposed. */
      }
      rethrow;
    }
    _token = token;
    me = identity;
    initialized = true;
  });

  Future<void> create(String game) => _act('/v1/tables', {'game': game});
  Future<void> join(String invite) =>
      _act('/v1/tables/join', {'invite': invite.trim()});
  Future<void> ready(bool value) => _act('/v1/tables/${table!['id']}/ready', {
    'expected_version': table!['version'],
    'ready': value,
  });
  Future<void> leave() => _act('/v1/tables/${table!['id']}/leave', {
    'expected_version': table!['version'],
  });

  Future<void> _act(String path, Map<String, dynamic> body) => _run(() async {
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(path);
  }

  Future<void> initialize() async {
    if (initialized || busy) return;
    await _run(() async {
      final saved = await vault.read();
      if (saved != null) {
        Map<String, dynamic> value;
        String? recoverableToken;
        try {
          final decoded = jsonDecode(saved);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('invalid saved session');
          }
          final token = decoded['token'];
          if (token is! String || token.isEmpty) {
            throw const FormatException('invalid saved token');
          }
          recoverableToken = token;
          if (decoded['pending'] != null &&
              !_validPending(decoded['pending'])) {
            throw const FormatException('invalid pending action');
          }
          value = decoded;
        } on FormatException {
          // Preserve the unreadable record until the player explicitly agrees
          // to reset it. Keep a valid token even if only its pending action is
          // damaged; losing the sole guest identity is avoidable in that case.
          _recoverableToken = recoverableToken;
          recoveryRequired = true;
          error = recoverableToken == null
              ? 'invalid_local_session'
              : 'invalid_local_action';
          return;
        }
        _token = value['token'] as String;
        _pending = value['pending'] as Map<String, dynamic>?;
        if (_token != null) {
          await _replay();
          await _refresh();
        }
      }
      initialized = true;
    });
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> resetCorruptSession() => _run(() async {
    if (!recoveryRequired) return;
    final token = _recoverableToken;
    await vault.write(
      token == null ? null : jsonEncode({'token': token, 'pending': null}),
    );
    _token = token;
    _recoverableToken = null;
    _pending = null;
    me = null;
    table = null;
    recoveryRequired = false;
    initialized = true;
    if (token != null) await _refresh();
  });

  Future<void> _save() => vault.write(
    _token == null ? null : jsonEncode({'token': _token, 'pending': _pending}),
  );

  Future<void> enterGuest() => _run(() async {
    final result = await api.request('POST', '/v1/guests', body: {});
    final token = result['token'] as String;
    final identity = result['me'] as Map<String, dynamic>;
    try {
      await vault.write(jsonEncode({'token': token, 'pending': null}));
    } catch (_) {
      // Do not publish a guest that cannot survive a process restart. Revoke
      // the newly issued session if the server is reachable; never log it.
      try {
        await api.request('DELETE', '/v1/session', token: token);
      } catch (_) {
        /* Best effort; no locally usable session is exposed. */
      }
      rethrow;
    }
    _token = token;
    me = identity;
    initialized = true;
  });

  Future<void> create(String game) => _act('/v1/tables', {'game': game});
  Future<void> join(String invite) =>
      _act('/v1/tables/join', {'invite': invite.trim()});
  Future<void> ready(bool value) => _act('/v1/tables/${table!['id']}/ready', {
    'expected_version': table!['version'],
    'ready': value,
  });
  Future<void> leave() => _act('/v1/tables/${table!['id']}/leave', {
    'expected_version': table!['version'],
  });

  Future<void> _act(String path, Map<String, dynamic> body) => _run(() async {
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(roomId) ||
        body.containsKey('action_id')) {
      throw const ApiFailure('candidate_disabled', status: 403);
    }
    final path = '/v1/tables/$roomId/match/actions';
    if (!_validPending({'path': path, 'body': {'action_id': '0' * 32, ...body}})) {
      throw const ApiFailure('invalid_input', status: 400);
    }
    return _act(path, body);
  }

  Future<void> _act(String path, Map<String, dynamic> body) => _run(() async {
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(path)) {
      const keys = {'action_id', 'expected_version', 'type', 'contract', 'card'};
      if (!body.keys.every(keys.contains) ||
          body['expected_version'] is! int ||
          (body['expected_version'] as int) < 1 ||
          body['type'] is! String) return false;
      if (body['type'] == 'choose_contract') {
        return {'complex', 'trix'}.contains(body['contract']) &&
            !body.containsKey('card');
      }
      if (body['type'] == 'pass') {
        return !body.containsKey('card') && !body.containsKey('contract');
      }
      if (body['type'] == 'play_card' &&
          !body.containsKey('contract') &&
          body['card'] is Map<String, dynamic>) {
        final card = body['card'] as Map<String, dynamic>;
        return card.length == 2 &&
            card.keys.every({'suit', 'rank'}.contains) &&
            card['suit'] is int && (card['suit'] as int) >= 0 &&
            (card['suit'] as int) < 4 &&
            card['rank'] is int && (card['rank'] as int) >= 2 &&
            (card['rank'] as int) <= 14;
      }
      return false;
    }
    return path == '/v1/tables' ||
        path == '/v1/tables/join' ||
        RegExp(r'^/v1/tables/[0-9a-f]{32}/(ready|leave)
  }

  Future<void> initialize() async {
    if (initialized || busy) return;
    await _run(() async {
      final saved = await vault.read();
      if (saved != null) {
        Map<String, dynamic> value;
        String? recoverableToken;
        try {
          final decoded = jsonDecode(saved);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('invalid saved session');
          }
          final token = decoded['token'];
          if (token is! String || token.isEmpty) {
            throw const FormatException('invalid saved token');
          }
          recoverableToken = token;
          if (decoded['pending'] != null &&
              !_validPending(decoded['pending'])) {
            throw const FormatException('invalid pending action');
          }
          value = decoded;
        } on FormatException {
          // Preserve the unreadable record until the player explicitly agrees
          // to reset it. Keep a valid token even if only its pending action is
          // damaged; losing the sole guest identity is avoidable in that case.
          _recoverableToken = recoverableToken;
          recoveryRequired = true;
          error = recoverableToken == null
              ? 'invalid_local_session'
              : 'invalid_local_action';
          return;
        }
        _token = value['token'] as String;
        _pending = value['pending'] as Map<String, dynamic>?;
        if (_token != null) {
          await _replay();
          await _refresh();
        }
      }
      initialized = true;
    });
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> resetCorruptSession() => _run(() async {
    if (!recoveryRequired) return;
    final token = _recoverableToken;
    await vault.write(
      token == null ? null : jsonEncode({'token': token, 'pending': null}),
    );
    _token = token;
    _recoverableToken = null;
    _pending = null;
    me = null;
    table = null;
    recoveryRequired = false;
    initialized = true;
    if (token != null) await _refresh();
  });

  Future<void> _save() => vault.write(
    _token == null ? null : jsonEncode({'token': _token, 'pending': _pending}),
  );

  Future<void> enterGuest() => _run(() async {
    final result = await api.request('POST', '/v1/guests', body: {});
    final token = result['token'] as String;
    final identity = result['me'] as Map<String, dynamic>;
    try {
      await vault.write(jsonEncode({'token': token, 'pending': null}));
    } catch (_) {
      // Do not publish a guest that cannot survive a process restart. Revoke
      // the newly issued session if the server is reachable; never log it.
      try {
        await api.request('DELETE', '/v1/session', token: token);
      } catch (_) {
        /* Best effort; no locally usable session is exposed. */
      }
      rethrow;
    }
    _token = token;
    me = identity;
    initialized = true;
  });

  Future<void> create(String game) => _act('/v1/tables', {'game': game});
  Future<void> join(String invite) =>
      _act('/v1/tables/join', {'invite': invite.trim()});
  Future<void> ready(bool value) => _act('/v1/tables/${table!['id']}/ready', {
    'expected_version': table!['version'],
    'ready': value,
  });
  Future<void> leave() => _act('/v1/tables/${table!['id']}/leave', {
    'expected_version': table!['version'],
  });

  Future<void> _act(String path, Map<String, dynamic> body) => _run(() async {
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
).hasMatch(path);
  }

  Future<void> initialize() async {
    if (initialized || busy) return;
    await _run(() async {
      final saved = await vault.read();
      if (saved != null) {
        Map<String, dynamic> value;
        String? recoverableToken;
        try {
          final decoded = jsonDecode(saved);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('invalid saved session');
          }
          final token = decoded['token'];
          if (token is! String || token.isEmpty) {
            throw const FormatException('invalid saved token');
          }
          recoverableToken = token;
          if (decoded['pending'] != null &&
              !_validPending(decoded['pending'])) {
            throw const FormatException('invalid pending action');
          }
          value = decoded;
        } on FormatException {
          // Preserve the unreadable record until the player explicitly agrees
          // to reset it. Keep a valid token even if only its pending action is
          // damaged; losing the sole guest identity is avoidable in that case.
          _recoverableToken = recoverableToken;
          recoveryRequired = true;
          error = recoverableToken == null
              ? 'invalid_local_session'
              : 'invalid_local_action';
          return;
        }
        _token = value['token'] as String;
        _pending = value['pending'] as Map<String, dynamic>?;
        if (_token != null) {
          await _replay();
          await _refresh();
        }
      }
      initialized = true;
    });
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }

  Future<void> resetCorruptSession() => _run(() async {
    if (!recoveryRequired) return;
    final token = _recoverableToken;
    await vault.write(
      token == null ? null : jsonEncode({'token': token, 'pending': null}),
    );
    _token = token;
    _recoverableToken = null;
    _pending = null;
    me = null;
    table = null;
    recoveryRequired = false;
    initialized = true;
    if (token != null) await _refresh();
  });

  Future<void> _save() => vault.write(
    _token == null ? null : jsonEncode({'token': _token, 'pending': _pending}),
  );

  Future<void> enterGuest() => _run(() async {
    final result = await api.request('POST', '/v1/guests', body: {});
    final token = result['token'] as String;
    final identity = result['me'] as Map<String, dynamic>;
    try {
      await vault.write(jsonEncode({'token': token, 'pending': null}));
    } catch (_) {
      // Do not publish a guest that cannot survive a process restart. Revoke
      // the newly issued session if the server is reachable; never log it.
      try {
        await api.request('DELETE', '/v1/session', token: token);
      } catch (_) {
        /* Best effort; no locally usable session is exposed. */
      }
      rethrow;
    }
    _token = token;
    me = identity;
    initialized = true;
  });

  Future<void> create(String game) => _act('/v1/tables', {'game': game});
  Future<void> join(String invite) =>
      _act('/v1/tables/join', {'invite': invite.trim()});
  Future<void> ready(bool value) => _act('/v1/tables/${table!['id']}/ready', {
    'expected_version': table!['version'],
    'ready': value,
  });
  Future<void> leave() => _act('/v1/tables/${table!['id']}/leave', {
    'expected_version': table!['version'],
  });

  Future<void> _act(String path, Map<String, dynamic> body) => _run(() async {
    if (_pending != null) {
      throw const ApiFailure('pending_action');
    }
    _pending = {
      'path': path,
      'body': {'action_id': actionId(), ...body},
    };
    // Save the action ID before transmission, including across process death.
    try {
      await _save();
    } catch (_) {
      // No network mutation may outlive an action that failed to become
      // durable. A later attempt creates a fresh intention after storage works.
      _pending = null;
      rethrow;
    }
    await _replay();
    await _refresh();
  });

  Future<void> retry() => _run(() async {
    await _save();
    await _replay();
    await _refresh();
  });

  Future<void> _replay() async {
    final pending = _pending;
    if (pending == null) return;
    // Also enforce persistence on restored/retried actions, not just first send.
    await _save();
    try {
      await api.request(
        'POST',
        pending['path'] as String,
        token: _token,
        body: pending['body'] as Map<String, dynamic>,
      );
    } on ApiFailure catch (failure) {
      if (!failure.uncertain) {
        _pending = null;
        await _save();
      }
      rethrow;
    }
    _pending = null;
    await _save();
  }

  Future<void> logout() => _run(() async {
    if (_pending != null) throw const ApiFailure('pending_action');
    // Release a waiting seat before revoking the guest's only session.
    if (table != null) {
      _pending = {
        'path': '/v1/tables/${table!['id']}/leave',
        'body': {
          'action_id': actionId(),
          'expected_version': table!['version'],
        },
      };
      await _save();
      await _replay();
    }
    try {
      await api.request('DELETE', '/v1/session', token: _token);
    } on ApiFailure catch (failure) {
      if (failure.status != 401) rethrow;
    }
    _token = null;
    me = null;
    table = null;
    await _save();
  });

  Future<void> refresh() async {
    if (!_active || busy || _refreshing || !signedIn) return;
    _refreshing = true;
    try {
      // An ambiguous command is retried explicitly with its original ID.
      if (_pending == null) await _refresh();
      _notify();
    } on ApiFailure catch (failure) {
      await _handle(failure);
    } catch (_) {
      error = 'connection_failed';
      _notify();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final current = await api.request('GET', '/v1/me', token: _token);
    final id = current['table_id'] as String?;
    final latest = id == null
        ? null
        : await api.request('GET', '/v1/tables/$id', token: _token);
    me = current;
    table = latest;
    error = null;
  }

  void setActive(bool active) {
    _active = active;
    if (active) unawaited(refresh());
  }

  Future<void> _run(Future<void> Function() work) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      // Let an in-flight read finish before mutating; do not silently discard
      // a user action just because a background poll is active.
      while (_refreshing && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (_disposed) return;
      await work();
    } on ApiFailure catch (failure) {
      await _handle(failure);
      if (failure.status == 409 || failure.status == 404) {
        try {
          await _refresh();
        } catch (_) {
          /* Keep the original failure. */
        }
        error = failure.code;
      }
    } catch (_) {
      error = 'secure_storage_or_response_failed';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _handle(ApiFailure failure) async {
    error = failure.code;
    if (failure.status == 401) {
      _token = null;
      _pending = null;
      me = null;
      table = null;
      try {
        await _save();
      } catch (_) {
        error = 'secure_storage_or_response_failed';
      }
      initialized = true;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    api.close();
    super.dispose();
  }
}
