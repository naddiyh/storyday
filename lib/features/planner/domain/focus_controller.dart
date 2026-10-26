import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/planner_store.dart';
import 'planner.dart';

class FocusSnapshot {
  const FocusSnapshot(
      {required this.id,
      required this.task,
      required this.startedAt,
      required this.minutes,
      required this.remaining,
      required this.elapsed,
      this.running = false,
      this.completed = false,
      this.saved = false,
      this.error});
  final String id, task;
  final DateTime startedAt;
  final int minutes;
  final Duration remaining, elapsed;
  final bool running, completed, saved;
  final String? error;
  String get clockLabel {
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

final focusClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final focusProvider = StateNotifierProvider<FocusController, FocusSnapshot?>(
    (ref) => FocusController(
        clock: ref.watch(focusClockProvider),
        save: ref.read(plannerProvider.notifier).saveFocus));

class FocusController extends StateNotifier<FocusSnapshot?> {
  FocusController(
      {required this.clock, required this.save, this.automaticTick = true})
      : super(null);
  final bool automaticTick;
  void _startTicker() {
    if (automaticTick && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  void _stopTicker() {
    _timer?.cancel();
    _timer = null;
  }

  final DateTime Function() clock;
  final Future<void> Function(FocusRecord) save;
  Timer? _timer;
  DateTime? _anchor;
  Duration _baseRemaining = Duration.zero, _baseElapsed = Duration.zero;
  bool _saving = false;
  void start(String task, int minutes) {
    if (task.trim().isEmpty || minutes < 1 || minutes > 180) {
      throw ArgumentError('Choose a task and 1–180 minutes.');
    }
    if (state != null && !state!.saved) {
      throw StateError('Finish the active session first.');
    }
    final now = clock();
    _anchor = now;
    _baseRemaining = Duration(minutes: minutes);
    _baseElapsed = Duration.zero;
    state = FocusSnapshot(
        id: now.microsecondsSinceEpoch.toString(),
        task: task.trim(),
        startedAt: now,
        minutes: minutes,
        remaining: _baseRemaining,
        elapsed: Duration.zero,
        running: true);
    _startTicker();
  }

  FocusSnapshot _snapshot(
      {bool? running,
      bool? completed,
      bool? saved,
      String? error,
      Duration? remaining,
      Duration? elapsed}) {
    final s = state!;
    return FocusSnapshot(
        id: s.id,
        task: s.task,
        startedAt: s.startedAt,
        minutes: s.minutes,
        remaining: remaining ?? s.remaining,
        elapsed: elapsed ?? s.elapsed,
        running: running ?? s.running,
        completed: completed ?? s.completed,
        saved: saved ?? s.saved,
        error: error);
  }

  void _calculate() {
    if (_anchor == null || state == null || !state!.running) return;
    final delta = clock().difference(_anchor!);
    final elapsed = delta.isNegative
        ? Duration.zero
        : delta > _baseRemaining
            ? _baseRemaining
            : delta;
    state = _snapshot(
        remaining: _baseRemaining - elapsed, elapsed: _baseElapsed + elapsed);
  }

  void tick() {
    if (!mounted || state == null || !state!.running) return;
    _calculate();
    if (state!.remaining == Duration.zero) unawaited(finish());
  }

  void pause() {
    if (state == null || !state!.running) return;
    _calculate();
    _anchor = null;
    _baseRemaining = state!.remaining;
    _baseElapsed = state!.elapsed;
    _stopTicker();
    state = _snapshot(running: false);
  }

  void resume() {
    if (state == null || state!.running || state!.completed) return;
    _anchor = clock();
    _baseRemaining = state!.remaining;
    _baseElapsed = state!.elapsed;
    state = _snapshot(running: true);
    _startTicker();
  }

  Future<void> finish() async {
    if (state == null || _saving || state!.saved) return;
    _saving = true;
    _stopTicker();
    _calculate();
    _anchor = null;
    state =
        _snapshot(running: false, completed: true, remaining: Duration.zero);
    final s = state!;
    try {
      await save(FocusRecord(
          id: s.id,
          task: s.task,
          date: s.startedAt,
          elapsedSeconds: s.elapsed.inSeconds,
          targetMinutes: s.minutes));
      if (mounted) state = _snapshot(saved: true);
    } catch (_) {
      if (mounted) {
        state =
            _snapshot(error: 'Could not save this session. Tap Retry save.');
      }
    } finally {
      _saving = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
