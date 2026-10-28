import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/serial_executor.dart';
import '../domain/note.dart';
import 'note_repository.dart';

class CloudNote {
  const CloudNote(this.note, this.revision, this.deleted);
  final OrdinaryNote note;
  final int revision;
  final bool deleted;
}

class JournalConflict implements Exception {
  const JournalConflict();
}

abstract interface class JournalRemote {
  Future<List<CloudNote>> fetchAll();
  Future<CloudNote> push(
      OrdinaryNote note, int revision, bool deleted, String mutation);
}

class SupabaseJournalRemote implements JournalRemote {
  SupabaseJournalRemote(this.client, this.owner);
  final SupabaseClient client;
  final String owner;
  void _checkOwner() {
    if (client.auth.currentUser?.id != owner) {
      throw StateError('Account changed.');
    }
  }

  CloudNote _decode(Map<String, dynamic> row) => CloudNote(
      OrdinaryNote.fromMap(Map<String, dynamic>.from(row['payload'] as Map)),
      row['revision'] as int,
      row['deleted'] as bool);
  @override
  Future<List<CloudNote>> fetchAll() async {
    final result = <CloudNote>[];
    String? cursor;
    while (true) {
      _checkOwner();
      var query = client.from('journal_notes').select().eq('user_id', owner);
      if (cursor != null) query = query.gt('note_id', cursor);
      final rows = await query
          .order('note_id')
          .limit(200)
          .timeout(const Duration(seconds: 15));
      _checkOwner();
      result.addAll(rows.map(_decode));
      if (rows.length < 200) break;
      cursor = rows.last['note_id'] as String;
    }
    return result;
  }

  @override
  Future<CloudNote> push(
      OrdinaryNote note, int revision, bool deleted, String mutation) async {
    _checkOwner();
    try {
      final row = await client
          .rpc('sync_journal_note', params: {
            'p_note_id': note.id,
            'p_expected_revision': revision,
            'p_payload': note.toMap(),
            'p_deleted': deleted,
            'p_mutation': mutation,
          })
          .single()
          .timeout(const Duration(seconds: 15));
      _checkOwner();
      return _decode(row);
    } on PostgrestException catch (e) {
      if (e.code == 'PT409') throw const JournalConflict();
      rethrow;
    }
  }
}

class PendingNote {
  const PendingNote(this.note,
      {this.revision = 0,
      this.dirty = true,
      this.deleted = false,
      required this.mutation});
  final OrdinaryNote note;
  final int revision;
  final bool dirty, deleted;
  final String mutation;
  Map<String, dynamic> toMap() => {
        'note': note.toMap(),
        'revision': revision,
        'dirty': dirty,
        'deleted': deleted,
        'mutation': mutation
      };
  factory PendingNote.fromMap(Map<String, dynamic> m) => PendingNote(
      OrdinaryNote.fromMap(Map<String, dynamic>.from(m['note'] as Map)),
      revision: m['revision'] as int,
      dirty: m['dirty'] as bool,
      deleted: m['deleted'] as bool,
      mutation: m['mutation'] as String);
}

/// One durable envelope holds notes AND pending mutations, so a restart cannot
/// lose a queued edit between separate note/outbox writes. Each user has a key.
class SyncedJournalRepository implements OrdinaryNoteRepository {
  SyncedJournalRepository(this.preferences, this.owner, this.remote,
      {this.onChanged, this.onStatus});
  final SharedPreferencesAsync preferences;
  final String owner;
  final JournalRemote remote;
  final Future<void> Function()? onChanged;
  final void Function(String)? onStatus;
  final _disk = SerialExecutor();
  Future<void>? _syncing;
  Timer? _retry;
  bool _disposed = false;
  String get key => 'ordinary-notes.user.$owner.v1';
  static String mutationId() => const Uuid().v4();

  Future<List<PendingNote>> _read() async {
    final raw = await preferences.getString(key);
    if (raw == null) return [];
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['version'] != 1) {
      throw const FormatException('Unsupported journal version.');
    }
    final rows = (map['records'] as List)
        .map((r) => PendingNote.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
    if (rows.map((r) => r.note.id).toSet().length != rows.length) {
      throw const FormatException(
          'Duplicate journal IDs. Original data has been kept.');
    }
    return rows;
  }

  Future<void> _write(List<PendingNote> rows) => preferences.setString(
      key,
      jsonEncode(
          {'version': 1, 'records': rows.map((r) => r.toMap()).toList()}));
  @override
  Future<List<OrdinaryNote>> loadAll() => _disk.run(() async =>
      (await _read()).where((r) => !r.deleted).map((r) => r.note).toList());
  @override
  Future<void> saveAll(List<OrdinaryNote> notes) =>
      _disk.run(() => _replace(notes));
  Future<void> _replace(List<OrdinaryNote> notes) async {
    final rows = await _read();
    final next = {for (final r in rows) r.note.id: r};
    final ids = notes.map((n) => n.id).toSet();
    if (ids.length != notes.length) throw ArgumentError('Duplicate note IDs.');
    for (final note in notes) {
      final old = next[note.id];
      if (old == null ||
          old.deleted ||
          jsonEncode(old.note.toMap()) != jsonEncode(note.toMap())) {
        next[note.id] = PendingNote(note,
            revision: old?.revision ?? 0, mutation: mutationId());
      }
    }
    for (final r in rows.where((r) => !r.deleted && !ids.contains(r.note.id))) {
      next[r.note.id] = PendingNote(r.note,
          revision: r.revision, deleted: true, mutation: mutationId());
    }
    await _write(next.values.toList());
    onStatus?.call('Saved on this device. Waiting to sync.');
    _schedule();
  }

  @override
  Future<void> save(OrdinaryNote note) => _disk.run(() async {
        final notes =
            (await _read()).where((r) => !r.deleted).map((r) => r.note);
        await _replace([...notes.where((n) => n.id != note.id), note]);
      });
  @override
  Future<void> delete(String id) => _disk.run(() async {
        final notes = (await _read())
            .where((r) => !r.deleted && r.note.id != id)
            .map((r) => r.note)
            .toList();
        await _replace(notes);
      });
  Future<void> importGuestNotes(List<OrdinaryNote> notes) =>
      _disk.run(() async {
        final rows = await _read();
        final ids = rows.map((r) => r.note.id).toSet();
        for (final n in notes) {
          final id = 'local-${n.id}';
          // Includes tombstones: re-import must not resurrect a deleted import.
          if (ids.contains(id)) continue;
          rows.add(PendingNote(OrdinaryNote.fromMap(n.toMap()..['id'] = id),
              mutation: mutationId()));
          ids.add(id);
        }
        await _write(rows);
        _schedule();
      });
  @override
  List<OrdinaryNote> filterByDate(List<OrdinaryNote> notes, DateTime date) =>
      notes.where((n) => DateUtils.isSameDay(n.date, date)).toList();

  void _schedule() {
    if (_disposed) return;
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 2), () => unawaited(sync()));
  }

  Future<void> sync() {
    if (_disposed) return Future.value();
    return _syncing ??= _synchronize().whenComplete(() => _syncing = null);
  }

  Future<void> _synchronize() async {
    try {
      onStatus?.call('Syncing journal...');
      final snapshot = await _disk.run(_read);
      var conflicts = 0;
      for (final row in snapshot.where((r) => r.dirty)) {
        if (_disposed) return;
        try {
          final ack = await remote.push(
              row.note, row.revision, row.deleted, row.mutation);
          if (_disposed) return;
          await _disk.run(() async {
            final rows = await _read();
            final index = rows.indexWhere((r) => r.note.id == row.note.id);
            if (index < 0) return;
            final latest = rows[index];
            // A new edit made while the request was in flight stays dirty,
            // rebased onto the acknowledged revision for the next retry.
            rows[index] = PendingNote(latest.note,
                revision: ack.revision,
                dirty: latest.mutation != row.mutation,
                deleted: latest.deleted,
                mutation: latest.mutation);
            await _write(rows);
          });
        } on JournalConflict {
          conflicts++;
          // Preserve the local version under a deterministic new ID. Never
          // silently overwrite the remote edit or lose the offline draft.
          final cloud = await remote.fetchAll();
          if (_disposed) return;
          final original = cloud.where((r) => r.note.id == row.note.id).first;
          await _disk.run(() async {
            final rows = await _read();
            final index = rows.indexWhere((r) => r.note.id == row.note.id);
            if (index < 0) return;
            final latest = rows[index];
            final m = latest.note.toMap();
            m['id'] = 'conflict-${latest.mutation}';
            m['title'] = '${latest.note.title} (conflict copy)';
            rows.add(
                PendingNote(OrdinaryNote.fromMap(m), mutation: mutationId()));
            rows[index] = PendingNote(original.note,
                revision: original.revision,
                dirty: false,
                deleted: original.deleted,
                mutation: mutationId());
            await _write(rows);
          });
        }
      }
      final cloud = await remote.fetchAll();
      if (_disposed) return;
      final pending = await _disk.run(() async {
        final rows = {for (final r in await _read()) r.note.id: r};
        for (final r in cloud) {
          if (rows[r.note.id]?.dirty == true) continue;
          rows[r.note.id] = PendingNote(r.note,
              revision: r.revision,
              dirty: false,
              deleted: r.deleted,
              mutation: mutationId());
        }
        await _write(rows.values.toList());
        return rows.values.where((r) => r.dirty).length;
      });
      await onChanged?.call();
      onStatus?.call(conflicts > 0
          ? 'Cloud changed too. Both versions kept; review conflict copies.'
          : pending > 0
              ? '$pending changes waiting to sync.'
              : 'Journal is up to date.');
      if (pending > 0) _schedule();
    } catch (_) {
      if (!_disposed) {
        onStatus?.call(
            'Sync unavailable. Local changes are kept. Retry when online.');
      }
    }
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
  }
}
