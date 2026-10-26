import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/planner.dart';

abstract interface class PlannerStore {
  Future<PlannerData> load();
  Future<void> save(PlannerData data);
}

class PreferencesPlannerStore implements PlannerStore {
  PreferencesPlannerStore(this.preferences);
  final SharedPreferencesAsync preferences;
  static const key = 'planner.v1';
  @override
  Future<PlannerData> load() async {
    final raw = await preferences.getString(key);
    return raw == null
        ? const PlannerData()
        : PlannerData.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(PlannerData data) =>
      preferences.setString(key, jsonEncode(data.toMap()));
}

class MemoryPlannerStore implements PlannerStore {
  PlannerData data = const PlannerData();
  @override
  Future<PlannerData> load() async => data;
  @override
  Future<void> save(PlannerData next) async {
    data = next;
  }
}

final plannerStoreProvider =
    Provider<PlannerStore>((ref) => MemoryPlannerStore());
final initialPlannerProvider =
    Provider<PlannerData>((ref) => const PlannerData());
final plannerProvider = StateNotifierProvider<PlannerController, PlannerData>(
    (ref) => PlannerController(
        ref.watch(plannerStoreProvider), ref.watch(initialPlannerProvider)));

class PlannerController extends StateNotifier<PlannerData> {
  PlannerController(this.store, super.state);
  final PlannerStore store;
  Future<void> _pending = Future.value();
  Future<void> _update(PlannerData Function(PlannerData) update) {
    final next = _pending.then((_) async {
      final data = update(state);
      await store.save(data);
      if (mounted) state = data;
    });
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> saveSchedule(Schedule schedule) =>
      _update((data) => PlannerData(schedules: [
            ...data.schedules.where((s) => s.id != schedule.id),
            schedule
          ], focusRecords: data.focusRecords));
  Future<void> deleteSchedule(String id) => _update((data) => PlannerData(
      schedules: data.schedules.where((s) => s.id != id).toList(),
      focusRecords: data.focusRecords));
  Future<void> saveFocus(FocusRecord record) =>
      _update((data) => PlannerData(schedules: data.schedules, focusRecords: [
            ...data.focusRecords.where((s) => s.id != record.id),
            record
          ]));
}
