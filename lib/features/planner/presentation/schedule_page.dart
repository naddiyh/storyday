import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../memories/demo_memories.dart';
import '../data/planner_store.dart';
import '../domain/planner.dart';
import 'schedule_symbols.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key, this.id});
  final String? id;
  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _notes = TextEditingController(),
      _location = TextEditingController(),
      _cost = TextEditingController();
  late DateTime _date;
  int _start = 20 * 60, _end = 21 * 60 + 30;
  int? _reminder = 10;
  RepeatRule _repeat = RepeatRule.once;
  String? _symbol;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _date = ref.read(selectedDateProvider);
    final matches =
        ref.read(plannerProvider).schedules.where((s) => s.id == widget.id);
    if (matches.isNotEmpty) {
      final s = matches.first;
      _title.text = s.title;
      _notes.text = s.notes;
      _location.text = s.location;
      _cost.text = s.cost;
      _date = s.date;
      _start = s.startMinute;
      _end = s.endMinute;
      _repeat = s.repeat;
      _reminder = s.reminderMinutes;
      _symbol = s.symbol;
    } else if (widget.id != null) {
      _error = 'This schedule is no longer available.';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _location.dispose();
    _cost.dispose();
    super.dispose();
  }

  void close() => context.canPop() ? context.pop() : context.go('/calendar');
  Future<void> save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_end <= _start) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(plannerProvider.notifier).saveSchedule(Schedule(
          id: widget.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          title: _title.text.trim(),
          date: _date,
          startMinute: _start,
          endMinute: _end,
          location: _location.text.trim(),
          cost: _cost.text.trim(),
          notes: _notes.text.trim(),
          repeat: _repeat,
          reminderMinutes: _reminder,
          symbol: _symbol ?? suggestSymbol(_title.text)));
      if (mounted) close();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Your schedule is still here. Try again.';
        });
      }
    }
  }

  Future<void> pickTime() async {
    final start = await showTimePicker(
        context: context,
        helpText: 'Start time',
        initialTime: TimeOfDay(hour: _start ~/ 60, minute: _start % 60));
    if (start == null || !mounted) return;
    final end = await showTimePicker(
        context: context,
        helpText: 'End time',
        initialTime: TimeOfDay(hour: _end ~/ 60, minute: _end % 60));
    if (end != null && mounted) {
      setState(() {
        _start = start.hour * 60 + start.minute;
        _end = end.hour * 60 + end.minute;
      });
    }
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Delete schedule?'),
                content: const Text(
                    'This removes the schedule and its repeating occurrences.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'))
                ]));
    if (confirmed != true || !mounted || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(plannerProvider.notifier).deleteSchedule(widget.id!);
      if (mounted) close();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not delete. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = _symbol ?? suggestSymbol(_title.text);
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              tooltip: 'Close schedule',
              onPressed: _saving ? null : close,
              icon: const Icon(Icons.close)),
          centerTitle: true,
          title: Text(widget.id == null ? 'New schedule' : 'Edit schedule',
              style: theme.textTheme.titleMedium),
          actions: [
            Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton(
                    onPressed: _saving ? null : save,
                    child: Text(_saving ? 'Saving…' : 'Save')))
          ]),
      body: Theme(
          data: theme.copyWith(
              inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none)),
          child: SafeArea(
              child: Form(
                  key: _form,
                  child: PageContent(children: [
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!,
                              style:
                                  TextStyle(color: theme.colorScheme.error))),
                    ScrapbookPanel(
                        child: Row(children: [
                      IconButton(
                          tooltip: 'Choose schedule icon',
                          icon: Icon(scheduleSymbols[symbol]),
                          onPressed: () async {
                            final picked = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                    title: const Text('Schedule icon'),
                                    content: Wrap(children: [
                                      for (final item
                                          in scheduleSymbols.entries)
                                        IconButton(
                                            tooltip: item.key,
                                            icon: Icon(item.value),
                                            onPressed: () => Navigator.pop(
                                                context, item.key))
                                    ])));
                            if (picked != null && mounted) {
                              setState(() => _symbol = picked);
                            }
                          }),
                      const SizedBox(width: 8),
                      Expanded(
                          child: TextFormField(
                              controller: _title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              onChanged: (_) => setState(() {}),
                              maxLength: 120,
                              decoration: const InputDecoration(
                                  labelText: 'Title',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  hintText: 'Watch a series',
                                  counterText: ''),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Add a title'
                                      : null)),
                    ])),
                    const SizedBox(height: 8),
                    Text('An icon is picked from your title. Tap it to change.',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                    ScrapbookPanel(
                        child: Column(children: [
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today_outlined),
                          dense: true,
                          title: const Text('Date'),
                          subtitle:
                              MediaQuery.textScalerOf(context).scale(14) > 20
                                  ? Text(DateFormat('EEE, d MMM').format(_date))
                                  : null,
                          trailing:
                              MediaQuery.textScalerOf(context).scale(14) > 20
                                  ? null
                                  : Text(DateFormat('EEE, d MMM').format(_date),
                                      style: theme.textTheme.labelMedium),
                          onTap: () async {
                            final date = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100));
                            if (date != null && mounted) {
                              setState(() => _date = date);
                            }
                          }),
                      const Divider(height: 1),
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule),
                          dense: true,
                          title: const Text('Time'),
                          subtitle: MediaQuery.textScalerOf(context).scale(14) >
                                  20
                              ? Text(
                                  '${Schedule.timeLabel(_start)} - ${Schedule.timeLabel(_end)}')
                              : null,
                          trailing: MediaQuery.textScalerOf(context).scale(14) >
                                  20
                              ? null
                              : Text(
                                  '${Schedule.timeLabel(_start)} – ${Schedule.timeLabel(_end)}'),
                          onTap: pickTime),
                      const Divider(height: 1),
                      TextFormField(
                          controller: _location,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.location_on_outlined),
                              labelText: 'Location',
                              hintText: 'Add (optional)')),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                          value: _reminder ?? -1,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.notifications_none),
                              labelText: 'Reminder'),
                          items: [
                            for (final minutes in [-1, 0, 5, 10, 30])
                              DropdownMenuItem(
                                  value: minutes,
                                  child: Text(minutes == -1
                                      ? 'Off'
                                      : minutes == 0
                                          ? 'At start time'
                                          : '$minutes min before'))
                          ],
                          onChanged: (value) => setState(
                              () => _reminder = value == -1 ? null : value)),
                      const Divider(height: 1),
                      TextFormField(
                          controller: _cost,
                          decoration: const InputDecoration(
                              prefixIcon:
                                  Icon(Icons.account_balance_wallet_outlined),
                              labelText: 'Cost',
                              hintText: 'Add (for bills & subscriptions)')),
                    ])),
                    const SizedBox(height: 8),
                    Text(
                        'Reminder timing is saved. Device notifications are not enabled yet.',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                    Text('Repeat', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, children: [
                      for (final value in RepeatRule.values)
                        ChoiceChip(
                            label: Text(value.name[0].toUpperCase() +
                                value.name.substring(1)),
                            selected: _repeat == value,
                            onSelected: (_) => setState(() => _repeat = value))
                    ]),
                    const SizedBox(height: 16),
                    Text('Notes', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                        controller: _notes,
                        minLines: 1,
                        maxLines: 6,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerLowest,
                            hintText: 'A little detail to remember…')),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          Icon(scheduleSymbols[symbol]),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  '${_date.day} · ${_title.text.trim().isEmpty ? 'Your schedule' : _title.text.trim()}\nThis will appear on your calendar.'))
                        ])),
                    if (widget.id != null) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                          onPressed: _saving ? null : delete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete schedule'))
                    ],
                  ])))),
    );
  }
}
