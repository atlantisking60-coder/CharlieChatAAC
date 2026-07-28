import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum SyncEntityType {
  board,
  favorites,
  phraseHistory,
  profile,
  settings,
}

enum SyncOperation {
  upsert,
  delete,
  clear,
}

enum SyncRecordStatus {
  pending,
  inFlight,
  synced,
  failed,
  conflict,
}

enum ConflictResolution {
  localWins,
  remoteWins,
  manual,
}

class SyncRecord {
  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int localRevision;
  final int? baseRemoteRevision;
  final SyncRecordStatus status;
  final ConflictResolution conflictResolution;
  final String errorMessage;
  final Map<String, dynamic>? remotePayload;

  const SyncRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    required this.localRevision,
    this.baseRemoteRevision,
    this.status = SyncRecordStatus.pending,
    this.conflictResolution = ConflictResolution.localWins,
    this.errorMessage = '',
    this.remotePayload,
  });

  bool get needsUpload =>
      status == SyncRecordStatus.pending ||
      status == SyncRecordStatus.failed;

  SyncRecord copyWith({
    SyncOperation? operation,
    Map<String, dynamic>? payload,
    DateTime? updatedAt,
    int? localRevision,
    int? baseRemoteRevision,
    SyncRecordStatus? status,
    ConflictResolution? conflictResolution,
    String? errorMessage,
    Map<String, dynamic>? remotePayload,
    bool clearRemotePayload = false,
  }) {
    return SyncRecord(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localRevision: localRevision ?? this.localRevision,
      baseRemoteRevision: baseRemoteRevision ?? this.baseRemoteRevision,
      status: status ?? this.status,
      conflictResolution: conflictResolution ?? this.conflictResolution,
      errorMessage: errorMessage ?? this.errorMessage,
      remotePayload:
          clearRemotePayload ? null : (remotePayload ?? this.remotePayload),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityType': entityType.name,
        'entityId': entityId,
        'operation': operation.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'localRevision': localRevision,
        'baseRemoteRevision': baseRemoteRevision,
        'status': status.name,
        'conflictResolution': conflictResolution.name,
        'errorMessage': errorMessage,
        'remotePayload': remotePayload,
      };

  factory SyncRecord.fromMap(Map<String, dynamic> map) {
    return SyncRecord(
      id: map['id']?.toString() ?? '',
      entityType: _enumByName(
        SyncEntityType.values,
        map['entityType'],
        SyncEntityType.settings,
      ),
      entityId: map['entityId']?.toString() ?? '',
      operation: _enumByName(
        SyncOperation.values,
        map['operation'],
        SyncOperation.upsert,
      ),
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
      localRevision: (map['localRevision'] is num)
          ? (map['localRevision'] as num).toInt()
          : 0,
      baseRemoteRevision: (map['baseRemoteRevision'] is num)
          ? (map['baseRemoteRevision'] as num).toInt()
          : null,
      status: _enumByName(
        SyncRecordStatus.values,
        map['status'],
        SyncRecordStatus.pending,
      ),
      conflictResolution: _enumByName(
        ConflictResolution.values,
        map['conflictResolution'],
        ConflictResolution.localWins,
      ),
      errorMessage: map['errorMessage']?.toString() ?? '',
      remotePayload: map['remotePayload'] is Map
          ? Map<String, dynamic>.from(map['remotePayload'] as Map)
          : null,
    );
  }
}

class SyncStatus {
  final int pendingCount;
  final int inFlightCount;
  final int failedCount;
  final int conflictCount;
  final DateTime? lastSyncedAt;

  const SyncStatus({
    required this.pendingCount,
    required this.inFlightCount,
    required this.failedCount,
    required this.conflictCount,
    required this.lastSyncedAt,
  });

  bool get hasWork => pendingCount > 0 || failedCount > 0 || conflictCount > 0;
  bool get isSyncing => inFlightCount > 0;

  String get label {
    if (conflictCount > 0) return '$conflictCount sync conflict(s)';
    if (failedCount > 0) return '$failedCount sync failure(s)';
    if (inFlightCount > 0) return 'Syncing changes';
    if (pendingCount > 0) return '$pendingCount change(s) waiting to sync';
    return 'All local changes synced';
  }
}

class SyncConflict {
  final SyncRecord localRecord;
  final int remoteRevision;
  final Map<String, dynamic> remotePayload;
  final String reason;

  const SyncConflict({
    required this.localRecord,
    required this.remoteRevision,
    required this.remotePayload,
    required this.reason,
  });
}

class SyncConflictRules {
  const SyncConflictRules._();

  static SyncConflict? evaluateRemoteChange({
    required SyncRecord localRecord,
    required int remoteRevision,
    required Map<String, dynamic> remotePayload,
  }) {
    final baseRevision = localRecord.baseRemoteRevision ?? 0;
    if (remoteRevision <= baseRevision ||
        localRecord.status == SyncRecordStatus.synced) {
      return null;
    }

    final reason = switch (localRecord.operation) {
      SyncOperation.delete => 'Remote item changed after local delete',
      SyncOperation.clear => 'Remote collection changed after local clear',
      SyncOperation.upsert => 'Local and remote edits both changed this item',
    };

    return SyncConflict(
      localRecord: localRecord,
      remoteRevision: remoteRevision,
      remotePayload: remotePayload,
      reason: reason,
    );
  }
}

class SyncRecordRequest {
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final int? baseRemoteRevision;
  final ConflictResolution conflictResolution;

  const SyncRecordRequest({
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payload = const {},
    this.baseRemoteRevision,
    this.conflictResolution = ConflictResolution.localWins,
  });
}

class SyncService {
  static const _recordsKey = 'aac_sync_records'; // Legacy giant key
  static const _recordIdsKey = 'aac_sync_ids_v2';
  static const _recordPrefix = 'aac_sync_record_';
  static const _lastSyncedAtKey = 'aac_sync_last_synced_at';
  static const _deviceIdKey = 'aac_sync_device_id';

  static SyncService? _instance;
  final SharedPreferences _prefs;
  List<SyncRecord>? _cache;

  SyncService._(this._prefs);

  static Future<SyncService> init() async {
    if (_instance != null) return _instance!;
    
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_deviceIdKey)) {
      await prefs.setString(
        _deviceIdKey,
        DateTime.now().microsecondsSinceEpoch.toString(),
      );
    }
    _instance = SyncService._(prefs);
    return _instance!;
  }

  String get deviceId => _prefs.getString(_deviceIdKey) ?? 'local-device';

  List<SyncRecord> get records {
    if (_cache != null) return _cache!;

    // Migration: If legacy key exists, clear it
    if (_prefs.containsKey(_recordsKey)) {
      _prefs.remove(_recordsKey);
    }

    final idsRaw = _prefs.getString(_recordIdsKey);
    if (idsRaw == null || idsRaw.isEmpty) {
      _cache = [];
      return [];
    }

    try {
      final List<dynamic> ids = json.decode(idsRaw);
      final List<SyncRecord> loaded = [];
      for (final id in ids) {
        final raw = _prefs.getString('$_recordPrefix$id');
        if (raw != null) {
          loaded.add(SyncRecord.fromMap(json.decode(raw)));
        }
      }
      loaded.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _cache = loaded;
      return loaded;
    } catch (_) {
      _cache = [];
      return [];
    }
  }

  List<SyncRecord> get pendingRecords =>
      records.where((record) => record.needsUpload).toList();

  void refreshRecords() {
    _cache = null;
  }

  List<SyncRecord> get conflictedRecords => records
      .where((record) => record.status == SyncRecordStatus.conflict)
      .toList();

  SyncStatus get status {
    final current = records;
    return SyncStatus(
      pendingCount: current
          .where((record) => record.status == SyncRecordStatus.pending)
          .length,
      inFlightCount: current
          .where((record) => record.status == SyncRecordStatus.inFlight)
          .length,
      failedCount: current
          .where((record) => record.status == SyncRecordStatus.failed)
          .length,
      conflictCount: current
          .where((record) => record.status == SyncRecordStatus.conflict)
          .length,
      lastSyncedAt: _dateOrNull(_prefs.getString(_lastSyncedAtKey)),
    );
  }

  Future<SyncRecord> recordChange({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    Map<String, dynamic> payload = const {},
    int? baseRemoteRevision,
    ConflictResolution conflictResolution = ConflictResolution.localWins,
  }) async {
    final safePayload = _getSafePayload(payload, entityType, entityId);
    final now = DateTime.now().toUtc();
    final current = List<SyncRecord>.from(records);
    final existingIndex = current.indexWhere(
      (record) =>
          record.entityType == entityType &&
          record.entityId == entityId &&
          record.status != SyncRecordStatus.synced,
    );

    final nextRevision = _nextLocalRevision(current);
    late final SyncRecord record;
    bool isNew = false;
    if (existingIndex >= 0) {
      record = current[existingIndex].copyWith(
        operation: operation,
        payload: safePayload,
        updatedAt: now,
        localRevision: nextRevision,
        baseRemoteRevision: baseRemoteRevision,
        status: SyncRecordStatus.pending,
        conflictResolution: conflictResolution,
        errorMessage: '',
        clearRemotePayload: true,
      );
      current[existingIndex] = record;
    } else {
      isNew = true;
      record = SyncRecord(
        id: '${now.microsecondsSinceEpoch}_${current.length}',
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: safePayload,
        createdAt: now,
        updatedAt: now,
        localRevision: nextRevision,
        baseRemoteRevision: baseRemoteRevision,
        conflictResolution: conflictResolution,
      );
      current.add(record);
    }

    _cache = current;
    await _saveRecord(record);
    if (isNew) {
      await _saveIndex(current);
    }
    return record;
  }

  /// Batch update multiple changes at once to avoid O(N^2) index writes.
  Future<void> recordBatchChanges(List<SyncRecordRequest> requests) async {
    final now = DateTime.now().toUtc();
    final current = List<SyncRecord>.from(records);
    bool indexChanged = false;

    for (final req in requests) {
      final safePayload = _getSafePayload(req.payload, req.entityType, req.entityId);
      final existingIndex = current.indexWhere(
        (record) =>
            record.entityType == req.entityType &&
            record.entityId == req.entityId &&
            record.status != SyncRecordStatus.synced,
      );

      final nextRevision = _nextLocalRevision(current);
      late final SyncRecord record;
      if (existingIndex >= 0) {
        record = current[existingIndex].copyWith(
          operation: req.operation,
          payload: safePayload,
          updatedAt: now,
          localRevision: nextRevision,
          baseRemoteRevision: req.baseRemoteRevision,
          status: SyncRecordStatus.pending,
          conflictResolution: req.conflictResolution,
          errorMessage: '',
          clearRemotePayload: true,
        );
        current[existingIndex] = record;
      } else {
        indexChanged = true;
        record = SyncRecord(
          id: '${now.microsecondsSinceEpoch}_${current.length}_${requests.indexOf(req)}',
          entityType: req.entityType,
          entityId: req.entityId,
          operation: req.operation,
          payload: safePayload,
          createdAt: now,
          updatedAt: now,
          localRevision: nextRevision,
          baseRemoteRevision: req.baseRemoteRevision,
          conflictResolution: req.conflictResolution,
        );
        current.add(record);
      }
      await _saveRecord(record);
    }

    _cache = current;
    if (indexChanged) {
      await _saveIndex(current);
    }
  }

  Map<String, dynamic> _getSafePayload(
      Map<String, dynamic> payload, SyncEntityType type, String id) {
    final payloadSize = json.encode(payload).length;
    if (payloadSize > 102400) {
      // 100KB
      return {
        '__omitted': true,
        'reason': 'Payload too large ($payloadSize bytes)',
        'type': type.name,
        'id': id,
      };
    }
    return payload;
  }

  Future<void> markInFlight(String recordId) async {
    final current = records;
    final index = current.indexWhere((r) => r.id == recordId);
    if (index < 0) return;

    final updated = current[index].copyWith(
      status: SyncRecordStatus.inFlight,
      updatedAt: DateTime.now().toUtc(),
      errorMessage: '',
    );
    _cache![index] = updated;
    await _saveRecord(updated);
  }

  Future<void> markSynced(String recordId, {int? remoteRevision}) async {
    final current = records;
    final index = current.indexWhere((r) => r.id == recordId);
    if (index < 0) return;

    final updated = current[index].copyWith(
      status: SyncRecordStatus.synced,
      updatedAt: DateTime.now().toUtc(),
      baseRemoteRevision: remoteRevision,
      errorMessage: '',
      clearRemotePayload: true,
    );
    _cache![index] = updated;
    await _saveRecord(updated);

    await _prefs.setString(
        _lastSyncedAtKey, DateTime.now().toUtc().toIso8601String());

    // Auto-cleanup: If there are many synced records, purge them
    if (current.length > 50) {
      await clearSyncedRecords();
    }
  }

  Future<void> markFailed(String recordId, String message) async {
    final current = records;
    final index = current.indexWhere((r) => r.id == recordId);
    if (index < 0) return;

    final updated = current[index].copyWith(
      status: SyncRecordStatus.failed,
      updatedAt: DateTime.now().toUtc(),
      errorMessage: message,
    );
    _cache![index] = updated;
    await _saveRecord(updated);
  }

  Future<void> markConflict({
    required String recordId,
    required Map<String, dynamic> remotePayload,
    required String reason,
  }) async {
    final current = records;
    final index = current.indexWhere((r) => r.id == recordId);
    if (index < 0) return;

    final updated = current[index].copyWith(
      status: SyncRecordStatus.conflict,
      updatedAt: DateTime.now().toUtc(),
      remotePayload: remotePayload,
      errorMessage: reason,
    );
    _cache![index] = updated;
    await _saveRecord(updated);
  }

  Future<void> resolveConflict({
    required String recordId,
    required ConflictResolution resolution,
  }) async {
    final current = records;
    final index = current.indexWhere((r) => r.id == recordId);
    if (index < 0) return;

    final updated = current[index].copyWith(
      status: resolution == ConflictResolution.manual
          ? SyncRecordStatus.conflict
          : SyncRecordStatus.pending,
      conflictResolution: resolution,
      updatedAt: DateTime.now().toUtc(),
      errorMessage: '',
    );
    _cache![index] = updated;
    await _saveRecord(updated);
  }

  /// Push all pending/failed records. Currently simulates a successful upload;
  /// replace with real network logic when a cloud backend is available.
  Future<void> pushAllPending() async {
    for (final record in List<SyncRecord>.from(pendingRecords)) {
      await pushRecord(record.id);
    }
  }

  /// Push a single pending/failed record.
  Future<void> pushRecord(String recordId) async {
    final current = records;
    final index = current.indexWhere((r) => r.id == recordId);
    if (index < 0) return;
    final record = current[index];
    if (!record.needsUpload || record.status == SyncRecordStatus.inFlight) return;
    await markInFlight(recordId);
    await markSynced(recordId);
  }

  Future<void> clearSyncedRecords() async {
    final all = List<SyncRecord>.from(records);
    final synced =
        all.where((r) => r.status == SyncRecordStatus.synced).toList();
    for (final r in synced) {
      await _prefs.remove('$_recordPrefix${r.id}');
    }
    final active =
        all.where((r) => r.status != SyncRecordStatus.synced).toList();
    _cache = active;
    await _saveIndex(active);
  }

  Future<void> clearAllRecords() async {
    final all = List<SyncRecord>.from(records);
    for (final r in all) {
      await _prefs.remove('$_recordPrefix${r.id}');
    }
    _cache = [];
    await _prefs.remove(_recordIdsKey);
  }

  Future<void> _saveRecord(SyncRecord record) async {
    await _prefs.setString(
        '$_recordPrefix${record.id}', json.encode(record.toMap()));
  }

  Future<void> _saveIndex(List<SyncRecord> records) async {
    final ids = records.map((r) => r.id).toList();
    await _prefs.setString(_recordIdsKey, json.encode(ids));
  }

  int _nextLocalRevision(List<SyncRecord> records) {
    if (records.isEmpty) return 1;
    return records
            .map((record) => record.localRevision)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name?.toString()) return value;
  }
  return fallback;
}

DateTime _dateFromValue(Object? value) {
  return _dateOrNull(value?.toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _dateOrNull(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
