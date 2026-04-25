import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/app_refresh_bus.dart';

class OfflineSyncService {
  OfflineSyncService._();
  static final OfflineSyncService instance = OfflineSyncService._();

  static const _cacheBoxName = 'offline_cache_v1';
  static const _opsBoxName = 'offline_ops_v1';
  static const _retainDailyLogsDays = 120;
  static const _maxCachedDailyLogs = 5000;
  static const _maxPendingOps = 1500;
  static const _compactEverySyncCount = 12;

  Box<dynamic>? _cacheBox;
  Box<dynamic>? _opsBox;
  String? _userId;
  bool _syncing = false;
  Timer? _syncTimer;
  int _syncCounter = 0;

  Future<void> initForUser(String userId) async {
    _cacheBox ??= await Hive.openBox<dynamic>(_cacheBoxName);
    _opsBox ??= await Hive.openBox<dynamic>(_opsBoxName);
    _userId = userId;

    await _housekeeping();
    await _ensureSeededFromNetworkIfEmpty();
    _startSyncLoop();
    unawaited(syncNow());
  }

  Future<void> stop() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _userId = null;
  }

  Future<void> _ensureSeededFromNetworkIfEmpty() async {
    if (_userId == null) return;
    final directives = _getCachedList('directives');
    final logs = _getCachedList('daily_logs');
    final skills = _getCachedList('skills');

    if (directives.isNotEmpty || logs.isNotEmpty || skills.isNotEmpty) return;
    await syncNow();
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(syncNow());
    });
  }

  String _cacheKey(String table) => '${_userId ?? ''}:$table';
  String _opsKey() => '${_userId ?? ''}:ops';

  List<Map<String, dynamic>> _getCachedList(String table) {
    final raw = _cacheBox?.get(_cacheKey(table));
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _setCachedList(String table, List<Map<String, dynamic>> value) async {
    if (table == 'daily_logs') {
      value = _pruneDailyLogs(value);
    }
    await _cacheBox?.put(_cacheKey(table), value);
  }

  List<Map<String, dynamic>> _getPendingOps() {
    final raw = _opsBox?.get(_opsKey());
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _setPendingOps(List<Map<String, dynamic>> ops) async {
    await _opsBox?.put(_opsKey(), ops);
  }

  Future<void> _enqueueOp(Map<String, dynamic> op) async {
    final ops = _compactOps(_getPendingOps(), incoming: op);
    await _setPendingOps(ops);
  }

  Future<void> syncNow() async {
    if (_syncing || _userId == null || _cacheBox == null || _opsBox == null) return;
    _syncing = true;
    try {
      await _flushPendingOps();
      await _pullFromNetwork();
      _syncCounter++;
      if (_syncCounter % _compactEverySyncCount == 0) {
        await _housekeeping();
      }
      AppRefreshBus.bump();
    } catch (_) {
      // Stay silent offline; pending ops remain queued.
    } finally {
      _syncing = false;
    }
  }

  Future<void> _flushPendingOps() async {
    final client = Supabase.instance.client;
    final ops = _compactOps(_getPendingOps());
    if (ops.isEmpty) return;

    final failedOps = <Map<String, dynamic>>[];
    for (final op in ops) {
      try {
        final table = op['table'] as String;
        final action = op['action'] as String;
        final payload = Map<String, dynamic>.from((op['payload'] as Map?) ?? {});

        if (action == 'upsert') {
          final onConflict = op['on_conflict'] as String?;
          if (onConflict != null && onConflict.isNotEmpty) {
            await client.from(table).upsert(payload, onConflict: onConflict);
          } else {
            await client.from(table).upsert(payload);
          }
        } else if (action == 'delete') {
          final where = Map<String, dynamic>.from((op['where'] as Map?) ?? {});
          var q = client.from(table).delete();
          for (final entry in where.entries) {
            q = q.eq(entry.key, entry.value);
          }
          await q;
        } else if (action == 'update') {
          final where = Map<String, dynamic>.from((op['where'] as Map?) ?? {});
          var q = client.from(table).update(payload);
          for (final entry in where.entries) {
            q = q.eq(entry.key, entry.value);
          }
          await q;
        }
      } catch (_) {
        failedOps.add(op);
      }
    }

    await _setPendingOps(_compactOps(failedOps));
  }

  Future<void> _pullFromNetwork() async {
    if (_userId == null) return;
    final client = Supabase.instance.client;

    final directives = await client
        .from('directives')
        .select()
        .eq('user_id', _userId!);
    await _setCachedList('directives',
        (directives as List<dynamic>).cast<Map<String, dynamic>>());

    final logs = await client
        .from('daily_logs')
        .select()
        .eq('user_id', _userId!)
        .gte('log_date', _retainedLogsStartDateString());
    await _setCachedList(
        'daily_logs', (logs as List<dynamic>).cast<Map<String, dynamic>>());

    final skills = await client
        .from('skills')
        .select()
        .eq('user_id', _userId!);
    await _setCachedList(
        'skills', (skills as List<dynamic>).cast<Map<String, dynamic>>());

    final profile = await client
        .from('profiles')
        .select()
        .eq('id', _userId!)
        .maybeSingle();
    if (profile != null) {
      await _cacheBox?.put(_cacheKey('profile'), profile);
    }
  }

  List<Map<String, dynamic>> getDirectivesLocal() => _getCachedList('directives');

  List<Map<String, dynamic>> getDailyLogsLocal() => _getCachedList('daily_logs');

  List<Map<String, dynamic>> getSkillsLocal() => _getCachedList('skills');

  Map<String, dynamic>? getProfileLocal() {
    final raw = _cacheBox?.get(_cacheKey('profile'));
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> upsertDirective(Map<String, dynamic> row) async {
    if (_userId == null) return;
    final current = _getCachedList('directives');
    final id = (row['id'] as String?)?.trim().isNotEmpty == true
        ? row['id'] as String
        : _uuidV4();
    row['id'] = id;
    row['user_id'] = _userId;

    final idx = current.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      current[idx] = {...current[idx], ...row};
    } else {
      current.add(row);
    }
    await _setCachedList('directives', current);
    await _enqueueOp({
      'table': 'directives',
      'action': 'upsert',
      'payload': row,
      'on_conflict': 'id',
    });
    AppRefreshBus.bump();
    unawaited(syncNow());
  }

  Future<void> updateDirective(String id, Map<String, dynamic> patch) async {
    if (_userId == null) return;
    final current = _getCachedList('directives');
    final idx = current.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      current[idx] = {...current[idx], ...patch};
      await _setCachedList('directives', current);
    }
    await _enqueueOp({
      'table': 'directives',
      'action': 'update',
      'payload': patch,
      'where': {'id': id},
    });
    AppRefreshBus.bump();
    unawaited(syncNow());
  }

  Future<void> deleteDirective(String id) async {
    final current = _getCachedList('directives')..removeWhere((e) => e['id'] == id);
    await _setCachedList('directives', current);
    await _enqueueOp({
      'table': 'directives',
      'action': 'delete',
      'where': {'id': id},
    });
    AppRefreshBus.bump();
    unawaited(syncNow());
  }

  Future<Map<String, dynamic>> upsertDailyLog({
    required String directiveId,
    required String logDate,
    bool? isDone,
    double? progressValue,
  }) async {
    if (_userId == null) return {};
    final current = _getCachedList('daily_logs');
    final idx = current.indexWhere(
      (e) => e['directive_id'] == directiveId && e['log_date'] == logDate,
    );
    final payload = {
      if (idx >= 0) 'id': current[idx]['id'],
      'id': idx >= 0 ? current[idx]['id'] : _uuidV4(),
      'user_id': _userId,
      'directive_id': directiveId,
      'log_date': logDate,
      if (isDone != null) 'is_done': isDone,
      if (progressValue != null) 'progress_value': progressValue,
    };

    if (idx >= 0) {
      current[idx] = {...current[idx], ...payload};
    } else {
      current.add(payload);
    }
    await _setCachedList('daily_logs', _pruneDailyLogs(current));
    await _enqueueOp({
      'table': 'daily_logs',
      'action': 'upsert',
      'payload': payload,
      'on_conflict': 'directive_id,log_date',
    });
    AppRefreshBus.bump();
    unawaited(syncNow());
    return Map<String, dynamic>.from(payload);
  }

  Future<Map<String, dynamic>> setDailyLogBinaryState({
    required String directiveId,
    required String logDate,
    required bool? isDone,
  }) async {
    if (_userId == null) return {};
    final current = _getCachedList('daily_logs');
    final idx = current.indexWhere(
      (e) => e['directive_id'] == directiveId && e['log_date'] == logDate,
    );
    final id = idx >= 0 ? current[idx]['id'] : _uuidV4();
    final payload = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'directive_id': directiveId,
      'log_date': logDate,
      'is_done': isDone,
      'progress_value': null,
    };

    if (idx >= 0) {
      current[idx] = {...current[idx], ...payload};
    } else {
      current.add(payload);
    }
    await _setCachedList('daily_logs', _pruneDailyLogs(current));
    await _enqueueOp({
      'table': 'daily_logs',
      'action': 'upsert',
      'payload': payload,
      'on_conflict': 'directive_id,log_date',
    });
    AppRefreshBus.bump();
    unawaited(syncNow());
    return Map<String, dynamic>.from(payload);
  }

  Future<void> upsertSkill(Map<String, dynamic> row) async {
    if (_userId == null) return;
    final current = _getCachedList('skills');
    final id = (row['id'] as String?)?.trim().isNotEmpty == true
        ? row['id'] as String
        : _uuidV4();
    row['id'] = id;
    row['user_id'] = _userId;

    final idx = current.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      current[idx] = {...current[idx], ...row};
    } else {
      current.add(row);
    }
    await _setCachedList('skills', current);
    await _enqueueOp({
      'table': 'skills',
      'action': 'upsert',
      'payload': row,
      'on_conflict': 'id',
    });
    AppRefreshBus.bump();
    unawaited(syncNow());
  }

  Future<void> updateSkill(String id, Map<String, dynamic> patch) async {
    final current = _getCachedList('skills');
    final idx = current.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      current[idx] = {...current[idx], ...patch};
      await _setCachedList('skills', current);
    }
    await _enqueueOp({
      'table': 'skills',
      'action': 'update',
      'payload': patch,
      'where': {'id': id},
    });
    AppRefreshBus.bump();
    unawaited(syncNow());
  }

  Future<void> deleteSkill(String id) async {
    final current = _getCachedList('skills')..removeWhere((e) => e['id'] == id);
    await _setCachedList('skills', current);
    await _enqueueOp({
      'table': 'skills',
      'action': 'delete',
      'where': {'id': id},
    });
    AppRefreshBus.bump();
    unawaited(syncNow());
  }

  String _uuidV4() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final b = bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${b.substring(0, 8)}-${b.substring(8, 12)}-${b.substring(12, 16)}-${b.substring(16, 20)}-${b.substring(20, 32)}';
  }

  String _retainedLogsStartDateString() {
    final cutoff = DateTime.now().subtract(const Duration(days: _retainDailyLogsDays));
    return '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseYmd(String? ymd) {
    if (ymd == null || ymd.length < 10) return null;
    final core = ymd.substring(0, 10);
    final parts = core.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  List<Map<String, dynamic>> _pruneDailyLogs(List<Map<String, dynamic>> logs) {
    final cutoff = DateTime.now().subtract(const Duration(days: _retainDailyLogsDays));
    final kept = logs.where((row) {
      final dt = _parseYmd(row['log_date']?.toString());
      if (dt == null) return true;
      return !dt.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day));
    }).toList()
      ..sort((a, b) {
        final ad = a['log_date']?.toString() ?? '';
        final bd = b['log_date']?.toString() ?? '';
        return bd.compareTo(ad);
      });

    if (kept.length > _maxCachedDailyLogs) {
      return kept.sublist(0, _maxCachedDailyLogs);
    }
    return kept;
  }

  String? _entityKeyForOp(Map<String, dynamic> op) {
    final table = op['table']?.toString() ?? '';
    final where = Map<String, dynamic>.from((op['where'] as Map?) ?? const {});
    final payload = Map<String, dynamic>.from((op['payload'] as Map?) ?? const {});

    final whereId = where['id']?.toString();
    if (whereId != null && whereId.isNotEmpty) return '$table|id:$whereId';

    final payloadId = payload['id']?.toString();
    if (payloadId != null && payloadId.isNotEmpty) return '$table|id:$payloadId';

    final dId = payload['directive_id']?.toString() ?? where['directive_id']?.toString();
    final date = payload['log_date']?.toString() ?? where['log_date']?.toString();
    if (dId != null && dId.isNotEmpty && date != null && date.isNotEmpty) {
      return '$table|directive:$dId|date:$date';
    }
    return null;
  }

  bool _isUpsertOrUpdate(Map<String, dynamic> op) {
    final action = op['action']?.toString();
    return action == 'upsert' || action == 'update';
  }

  List<Map<String, dynamic>> _compactOps(
    List<Map<String, dynamic>> ops, {
    Map<String, dynamic>? incoming,
  }) {
    final source = <Map<String, dynamic>>[
      ...ops.map((e) => Map<String, dynamic>.from(e)),
      if (incoming != null) Map<String, dynamic>.from(incoming),
    ];

    final result = <Map<String, dynamic>>[];
    final lastByEntity = <String, Map<String, dynamic>>{};
    final passthrough = <Map<String, dynamic>>[];

    for (final op in source) {
      final entityKey = _entityKeyForOp(op);
      if (entityKey == null) {
        passthrough.add(op);
        continue;
      }
      final existing = lastByEntity[entityKey];
      if (existing == null) {
        lastByEntity[entityKey] = op;
        continue;
      }

      final newAction = op['action']?.toString() ?? '';
      final oldAction = existing['action']?.toString() ?? '';

      if (newAction == 'delete') {
        lastByEntity[entityKey] = op;
        continue;
      }

      if (oldAction == 'delete' && _isUpsertOrUpdate(op)) {
        lastByEntity[entityKey] = op;
        continue;
      }

      if (_isUpsertOrUpdate(existing) && _isUpsertOrUpdate(op)) {
        final mergedPayload = {
          ...Map<String, dynamic>.from((existing['payload'] as Map?) ?? const {}),
          ...Map<String, dynamic>.from((op['payload'] as Map?) ?? const {}),
        };
        final merged = Map<String, dynamic>.from(op)..['payload'] = mergedPayload;
        if ((existing['action']?.toString() == 'upsert') ||
            (op['action']?.toString() == 'upsert')) {
          merged['action'] = 'upsert';
          merged['on_conflict'] = op['on_conflict'] ?? existing['on_conflict'];
        }
        merged['where'] = op['where'] ?? existing['where'];
        lastByEntity[entityKey] = merged;
        continue;
      }

      lastByEntity[entityKey] = op;
    }

    result.addAll(passthrough);
    result.addAll(lastByEntity.values);

    if (result.length > _maxPendingOps) {
      return result.sublist(result.length - _maxPendingOps);
    }
    return result;
  }

  Future<void> _housekeeping() async {
    final logs = _pruneDailyLogs(_getCachedList('daily_logs'));
    await _setCachedList('daily_logs', logs);
    await _setPendingOps(_compactOps(_getPendingOps()));
    await _cacheBox?.compact();
    await _opsBox?.compact();
  }

  String exportLocalDebugJson() {
    final data = {
      'user_id': _userId,
      'directives': getDirectivesLocal(),
      'daily_logs': getDailyLogsLocal(),
      'skills': getSkillsLocal(),
      'pending_ops': _getPendingOps(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
