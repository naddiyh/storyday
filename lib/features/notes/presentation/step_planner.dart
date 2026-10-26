import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../memories/demo_memories.dart';
import '../../planner/domain/focus_controller.dart';
import '../data/note_repository.dart';
import '../domain/note.dart';

/// Manual task planning. No generated text or remote processing.
class StepPlanner extends ConsumerStatefulWidget {
  const StepPlanner({super.key});
  @override
  ConsumerState<StepPlanner> createState() => _StepPlannerState();
}

class _StepPlannerState extends ConsumerState<StepPlanner> {
  final goal = TextEditingController();
  final steps = List.generate(3, (_) => TextEditingController());
  bool saving = false;
  String? error;
  @override
  void dispose() {
    goal.dispose();
    for (final step in steps) {
      step.dispose();
    }
    super.dispose();
  }

  Future<void> start() async {
    if (saving ||
        goal.text.trim().isEmpty ||
        steps.any((s) => s.text.trim().isEmpty)) return;
    if (ref.read(focusProvider) case final active? when !active.saved) {
      setState(() => error = 'Finish your active focus session first.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final now = DateTime.now();
    try {
      await ref.read(ordinaryNotesProvider.notifier).save(OrdinaryNote(
          id: 'steps-${now.microsecondsSinceEpoch}',
          date: ref.read(selectedDateProvider),
          kind: NoteKind.checklist,
          title: goal.text.trim(),
          body: '',
          checklist:
              steps.map((s) => ChecklistItem(text: s.text.trim())).toList(),
          createdAt: now,
          updatedAt: now));
      if (!mounted) return;
      ref.read(focusProvider.notifier).start(steps.first.text.trim(), 5);
      context.push('/focus');
      setState(() => saving = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Could not save your steps. Your draft is still here.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = goal.text.trim().isNotEmpty &&
        steps.every((s) => s.text.trim().isNotEmpty);
    return ScrapbookPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
            child: Text('Too big to start? Break it down',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)))
      ]),
      const SizedBox(height: 12),
      TextField(
          controller: goal,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
              labelText: 'Your goal',
              hintText: 'A project you want to work on')),
      const SizedBox(height: 8),
      for (var i = 0; i < steps.length; i++)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('${i + 1}', style: theme.textTheme.labelSmall)),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: steps[i],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          labelText: 'Step ${i + 1}',
                          hintText: [
                            'Open the doc, write 3 sentences',
                            'List the references you need',
                            'Draft the first paragraph'
                          ][i],
                          filled: false,
                          border: InputBorder.none))),
              Text(['5 min', '15 min', '25 min'][i],
                  style: theme.textTheme.labelSmall),
            ])),
      Text('Write your own three steps. Start with five minutes.',
          style: theme.textTheme.bodySmall),
      if (error != null)
        Text(error!, style: TextStyle(color: theme.colorScheme.error)),
      const SizedBox(height: 12),
      FilledButton(
          onPressed: ready && !saving ? start : null,
          child:
              Text(saving ? 'Saving steps…' : 'Save checklist & start step 1')),
    ]));
  }
}
