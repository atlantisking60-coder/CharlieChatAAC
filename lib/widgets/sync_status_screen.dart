import 'package:flutter/material.dart';

import '../services/board_service.dart';
import '../services/sync_service.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  bool _loading = true;
  late SyncService _syncService;
  SyncStatus? _status;
  List<SyncRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _syncService = await SyncService.init();
    _syncService.refreshRecords();
    setState(() {
      _status = _syncService.status;
      _records = _syncService.records.reversed.toList();
      _loading = false;
    });
  }

  Future<void> _clearSynced() async {
    await _syncService.clearSyncedRecords();
    await _load();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Sync Records?'),
        content: const Text(
            'This will permanently remove all local change history and pending syncs. Use this only if you want to reset your local view to match the server.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _syncService.clearAllRecords();
      await _load();
    }
  }

  Future<void> _pushAll() async {
    setState(() => _loading = true);
    try {
      // Push every local board to the dev server as prebuilt source files.
      final boardService = await BoardService.getInstance();
      await boardService.pushAllToProject();
      // Legacy cloud-sync placeholder still runs to mark records as synced.
      await _syncService.pushAllPending();
    } finally {
      await _load();
    }
  }

  Future<void> _pushRecord(SyncRecord record) async {
    await _syncService.pushRecord(record.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Offline Sync'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Push all to project',
            onPressed: _pushAll,
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Clear synced records',
            onPressed: _clearSynced,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined),
            tooltip: 'Force Reset All',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: _loading || status == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatusSummary(status: status),
                  const SizedBox(height: 16),
                  Text(
                    'Local change records',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No local changes recorded.')),
                    )
                  else
                    ..._records.map((record) => _SyncRecordTile(
                          record: record,
                          onPush: record.needsUpload ? () => _pushRecord(record) : null,
                        )),
                ],
              ),
            ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  final SyncStatus status;

  const _StatusSummary({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = status.conflictCount > 0
        ? colorScheme.errorContainer
        : status.hasWork
            ? colorScheme.secondaryContainer
            : colorScheme.primaryContainer;

    return Material(
      color: statusColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(status.hasWork ? Icons.cloud_queue : Icons.cloud_done),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CountChip(label: 'Pending', count: status.pendingCount),
                _CountChip(label: 'Syncing', count: status.inFlightCount),
                _CountChip(label: 'Failed', count: status.failedCount),
                _CountChip(label: 'Conflicts', count: status.conflictCount),
              ],
            ),
            if (status.lastSyncedAt != null) ...[
              const SizedBox(height: 12),
              Text('Last synced: ${status.lastSyncedAt!.toLocal()}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;

  const _CountChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $count'));
  }
}

class _SyncRecordTile extends StatelessWidget {
  final SyncRecord record;
  final VoidCallback? onPush;

  const _SyncRecordTile({required this.record, this.onPush});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(_iconForStatus(record.status)),
        title: Text('${record.entityType.name} / ${record.entityId}'),
        subtitle: Text(
          '${record.operation.name} - ${record.status.name}'
          '\nRevision ${record.localRevision} - ${record.updatedAt.toLocal()}'
          '${record.errorMessage.isNotEmpty ? '\n${record.errorMessage}' : ''}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(record.conflictResolution.name),
            ),
            if (onPush != null)
              IconButton(
                icon: const Icon(Icons.cloud_upload, size: 20),
                tooltip: 'Push now',
                onPressed: onPush,
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForStatus(SyncRecordStatus status) {
    return switch (status) {
      SyncRecordStatus.pending => Icons.schedule,
      SyncRecordStatus.inFlight => Icons.sync,
      SyncRecordStatus.synced => Icons.cloud_done,
      SyncRecordStatus.failed => Icons.error_outline,
      SyncRecordStatus.conflict => Icons.warning_amber,
    };
  }
}
