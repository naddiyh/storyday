import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/note.dart';
import '../../../core/storage/serial_executor.dart';

abstract interface class OrdinaryNoteRepository {
  Future<List<OrdinaryNote>> loadAll();
  Future<void> saveAll(List<OrdinaryNote> notes);
  Future<void> save(OrdinaryNote note);
  Future<void> delete(String id);
  List<OrdinaryNote> filterByDate(List<OrdinaryNote> notes, DateTime date);
}

class PreferencesOrdinaryNoteRepository implements OrdinaryNoteRepository {
  PreferencesOrdinaryNoteRepository(this.preferences);

  static const _key = 'ordinary-notes.v1';
  final SharedPreferencesAsync preferences;
  final _writes = SerialExecutor();

  @override
  Future<List<OrdinaryNote>> loadAll() async {
    try {
      final raw = await preferences.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => OrdinaryNote.fromMap(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const FormatException(
          'Saved notes could not be read. Original data has been kept.');
    }
  }

  @override
  Future<void> saveAll(List<OrdinaryNote> notes) async {
    // Never overwrite an unreadable collection with a fresh empty snapshot.
    await loadAll();
    final payload = jsonEncode(notes.map((note) => note.toMap()).toList());
    await preferences.setString(_key, payload);
  }

  @override
  Future<void> save(OrdinaryNote note) => _writes.run(() async {
        final notes = await loadAll();
        final next = [...notes];
        final index = next.indexWhere((entry) => entry.id == note.id);
        if (index >= 0) {
          next[index] = note;
        } else {
          next.add(note);
        }
        next.sort((a, b) => a.date.compareTo(b.date));
        await saveAll(next);
      });

  @override
  Future<void> delete(String id) => _writes.run(() async {
        final notes = await loadAll();
        await saveAll(notes.where((note) => note.id != id).toList());
      });

  @override
  List<OrdinaryNote> filterByDate(List<OrdinaryNote> notes, DateTime date) {
    final target = DateUtils.dateOnly(date);
    return notes
        .where((note) => DateUtils.dateOnly(note.date) == target)
        .toList();
  }
}

class MemoryOrdinaryNoteRepository implements OrdinaryNoteRepository {
  MemoryOrdinaryNoteRepository([List<OrdinaryNote>? initial])
      : _notes = List<OrdinaryNote>.from(initial ?? const []);

  final List<OrdinaryNote> _notes;

  @override
  Future<List<OrdinaryNote>> loadAll() async => [..._notes];

  @override
  Future<void> saveAll(List<OrdinaryNote> notes) async {
    _notes
      ..clear()
      ..addAll(notes);
  }

  @override
  Future<void> save(OrdinaryNote note) async {
    final notes = [..._notes];
    final index = notes.indexWhere((entry) => entry.id == note.id);
    if (index >= 0) {
      notes[index] = note;
    } else {
      notes.add(note);
    }
    await saveAll(notes);
  }

  @override
  Future<void> delete(String id) async {
    await saveAll(_notes.where((note) => note.id != id).toList());
  }

  @override
  List<OrdinaryNote> filterByDate(List<OrdinaryNote> notes, DateTime date) {
    final target = DateUtils.dateOnly(date);
    return notes
        .where((note) => DateUtils.dateOnly(note.date) == target)
        .toList();
  }
}

final ordinaryNotesRepositoryProvider =
    Provider<OrdinaryNoteRepository>((ref) => MemoryOrdinaryNoteRepository());

class OrdinaryNoteController extends StateNotifier<List<OrdinaryNote>> {
  OrdinaryNoteController(this.repository, {this.onLoadStatus})
      : super(const []);

  final OrdinaryNoteRepository repository;
  final void Function(AsyncValue<void>)? onLoadStatus;
  final _operations = SerialExecutor();
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    onLoadStatus?.call(const AsyncLoading());
    try {
      final notes = await repository.loadAll();
      if (!mounted) return;
      state = notes;
      _loaded = true;
      onLoadStatus?.call(const AsyncData(null));
    } catch (error, stack) {
      onLoadStatus?.call(AsyncError(error, stack));
      rethrow;
    }
  }

  Future<void> load() => _operations.run(() async {
        _loaded = false;
        await _load();
      });

  Future<void> save(OrdinaryNote note) => _operations.run(() async {
        await _load();
        await repository.save(note);
        final persisted = await repository.loadAll();
        if (mounted) state = persisted;
      });

  Future<void> delete(String id) => _operations.run(() async {
        await _load();
        await repository.delete(id);
        final persisted = await repository.loadAll();
        if (mounted) state = persisted;
      });

  Future<void> setChecklistItem(String id, int index, bool done) =>
      _operations.run(() async {
        await _load();
        final note = (await repository.loadAll()).firstWhere((n) => n.id == id);
        final items = [...note.checklist];
        items[index] = ChecklistItem(text: items[index].text, done: done);
        await repository.save(note.withChecklist(items));
        final persisted = await repository.loadAll();
        if (mounted) state = persisted;
      });
}

final notesLoadStatusProvider =
    StateProvider<AsyncValue<void>>((ref) => const AsyncData(null));

final ordinaryNotesProvider =
    StateNotifierProvider<OrdinaryNoteController, List<OrdinaryNote>>((ref) {
  final repository = ref.watch(ordinaryNotesRepositoryProvider);
  var controllerAlive = true;
  final controller = OrdinaryNoteController(repository, onLoadStatus: (status) {
    // Loading can complete after a scope switch/sign-out.
    if (controllerAlive) {
      ref.read(notesLoadStatusProvider.notifier).state = status;
    }
  });
  unawaited(Future<void>.microtask(() async {
    try {
      await controller.load();
    } catch (_) {/* Exposed through load status. */}
  }));
  ref.onDispose(() => controllerAlive = false);
  return controller;
});
