import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/note.dart';

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
      return const [];
    }
  }

  @override
  Future<void> saveAll(List<OrdinaryNote> notes) async {
    final payload = jsonEncode(notes.map((note) => note.toMap()).toList());
    await preferences.setString(_key, payload);
  }

  @override
  Future<void> save(OrdinaryNote note) async {
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
  }

  @override
  Future<void> delete(String id) async {
    final notes = await loadAll();
    await saveAll(notes.where((note) => note.id != id).toList());
  }

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
  OrdinaryNoteController(this.repository) : super(const []);

  final OrdinaryNoteRepository repository;

  Future<void> load() async {
    state = await repository.loadAll();
  }

  Future<void> save(OrdinaryNote note) async {
    final updated = [...state];
    final index = updated.indexWhere((entry) => entry.id == note.id);
    if (index >= 0) {
      updated[index] = note;
    } else {
      updated.add(note);
    }
    updated.sort((a, b) => a.date.compareTo(b.date));
    await repository.saveAll(updated);
    if (mounted) state = updated;
  }

  Future<void> delete(String id) async {
    final updated = state.where((note) => note.id != id).toList();
    await repository.delete(id);
    if (mounted) state = updated;
  }
}

final ordinaryNotesProvider =
    StateNotifierProvider<OrdinaryNoteController, List<OrdinaryNote>>((ref) {
  final repository = ref.watch(ordinaryNotesRepositoryProvider);
  final controller = OrdinaryNoteController(repository);
  controller.load();
  return controller;
});
