import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charlie_chat/data/symbol_group_tags.dart';
import 'sync_service.dart';

class SymbolMetadata {
  final List<String> tags;

  SymbolMetadata({required this.tags});

  Map<String, dynamic> toMap() => {'tags': tags};
  factory SymbolMetadata.fromMap(Map<String, dynamic> map) => SymbolMetadata(
    tags: List<String>.from(map['tags'] ?? []),
  );
}

class SymbolMetadataService {
  static SymbolMetadataService? _instance;
  late SharedPreferences _prefs;
  Map<String, SymbolMetadata> _cache = {};
  static const _storageKey = 'aac_symbol_metadata_v1';

  SymbolMetadataService._();

  static Future<SymbolMetadataService> init() async {
    if (_instance != null) return _instance!;
    final service = SymbolMetadataService._();
    service._prefs = await SharedPreferences.getInstance();
    await service._load();
    _instance = service;
    return service;
  }

  Future<void> _load() async {
    final raw = _prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(raw);
        _cache = decoded.map((k, v) => MapEntry(k, SymbolMetadata.fromMap(v)));
      } catch (_) {
        _cache = {};
      }
    }
  }

  Future<void> _save({List<String>? changedSymbolIds}) async {
    final raw = json.encode(_cache.map((k, v) => MapEntry(k, v.toMap())));
    await _prefs.setString(_storageKey, raw);
    
    final sync = await SyncService.init();
    
    // If we have specific changes, sync them individually to keep payloads small
    if (changedSymbolIds != null && changedSymbolIds.isNotEmpty) {
      final requests = changedSymbolIds.map((id) => SyncRecordRequest(
        entityType: SyncEntityType.settings,
        entityId: 'symbol_metadata_$id',
        operation: SyncOperation.upsert,
        payload: {'symbolId': id, 'metadata': _cache[id]?.toMap()},
      )).toList();
      await sync.recordBatchChanges(requests);
    } else {
      // Fallback for full sync - SyncService will cap this if it's too large (>100KB)
      await sync.recordChange(
        entityType: SyncEntityType.settings,
        entityId: 'all_symbol_metadata',
        operation: SyncOperation.upsert,
        payload: {'metadata': _cache.map((k, v) => MapEntry(k, v.toMap()))},
      );
    }
  }

  List<String> getTags(String symbolId) {
    final userTags = _cache[symbolId]?.tags ?? [];
    final groupTags = groupSymbolTags[symbolId] ?? [];
    if (userTags.isEmpty && groupTags.isEmpty) return [];
    return {...userTags, ...groupTags}.toList();
  }

  /// Appends a single tag to a symbol's existing tags (no-op if tag already present).
  Future<void> addTag(String symbolId, String tag) async {
    final clean = tag.trim().toLowerCase();
    if (clean.isEmpty) return;
    final existing = _cache[symbolId]?.tags ?? [];
    if (existing.contains(clean)) return;
    _cache[symbolId] = SymbolMetadata(tags: [...existing, clean]);
    await _save(changedSymbolIds: [symbolId]);
  }

  /// Adds multiple tags in bulk.  Only writes to storage once at the end.
  /// [updates] maps symbolId -> list of tags to add for that symbol.
  Future<void> batchAddTags(Map<String, List<String>> updates) async {
    final changedIds = <String>[];
    for (final entry in updates.entries) {
      final symbolId = entry.key;
      bool symbolChanged = false;
      for (final tag in entry.value) {
        final clean = tag.trim().toLowerCase();
        if (clean.isEmpty) continue;
        final existing = _cache[symbolId]?.tags ?? [];
        if (existing.contains(clean)) continue;
        _cache[symbolId] = SymbolMetadata(tags: [...existing, clean]);
        symbolChanged = true;
      }
      if (symbolChanged) changedIds.add(symbolId);
    }
    if (changedIds.isNotEmpty) await _save(changedSymbolIds: changedIds);
  }

  Future<void> setTags(String symbolId, List<String> tags) async {
    // Clean tags: trim, lowercase, remove empty, deduplicate
    final cleanTags = tags
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    
    if (cleanTags.isEmpty) {
      if (_cache.containsKey(symbolId)) {
        _cache.remove(symbolId);
        await _save(changedSymbolIds: [symbolId]);
      }
    } else {
      final existing = _cache[symbolId]?.tags ?? [];
      // Check if actually changed
      if (existing.length != cleanTags.length || !existing.every(cleanTags.contains)) {
        _cache[symbolId] = SymbolMetadata(tags: cleanTags);
        await _save(changedSymbolIds: [symbolId]);
      }
    }
  }

  /// Returns true if the query matches any tag of the symbol
  bool matchesQuery(String symbolId, String query) {
    final tags = getTags(symbolId);
    if (tags.isEmpty) return false;
    
    final q = query.trim().toLowerCase();
    // Vowel normalization for fuzzy matching if needed, 
    // but for now let's keep it consistent with the label search vowel-leniency if possible.
    // Actually, simple contains or exact match on tags is usually expected.
    
    return tags.any((tag) => tag.contains(q));
  }
  
  Map<String, List<String>> getAllMetadata() {
    return _cache.map((k, v) => MapEntry(k, v.tags));
  }
}
