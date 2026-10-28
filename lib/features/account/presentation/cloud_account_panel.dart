import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/cloud/cloud_connection.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/data/journal_sync.dart';

final guestNotesRepositoryProvider =
    Provider<OrdinaryNoteRepository>((ref) => MemoryOrdinaryNoteRepository());

class CloudAccountPanel extends ConsumerStatefulWidget {
  const CloudAccountPanel({super.key});
  @override
  ConsumerState<CloudAccountPanel> createState() => _CloudAccountPanelState();
}

class _CloudAccountPanelState extends ConsumerState<CloudAccountPanel> {
  bool busy = false;
  String? error;
  Future<void> run(Future<void> Function() work) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await work();
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Could not complete this action. Your saved data has been kept.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(cloudConnectionProvider);
    final user = ref.watch(cloudUserProvider);
    final repo = ref.watch(ordinaryNotesRepositoryProvider);
    return ScrapbookPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Account & journal sync',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (user == null) ...[
        Text(connection.problem ??
            (connection.client == null
                ? 'Cloud is not configured. Your journal stays on this device.'
                : 'Local journal. Sign in to open your account journal.')),
        TextButton(
            onPressed: () => context.push('/account/login'),
            child: const Text('Log in / create account')),
      ] else ...[
        Text(user.email ?? 'Signed in'),
        Text(ref.watch(journalSyncStatusProvider)),
        const Text(
            'Journals and checklists sync. Schedules, focus, profile and appearance still stay on this device.'),
        const SizedBox(height: 8),
        FilledButton.tonal(
            onPressed: busy
                ? null
                : () => run(() async {
                      if (repo is SyncedJournalRepository) {
                        await repo.sync();
                      }
                    }),
            child: const Text('Sync now')),
        TextButton(
            onPressed: busy
                ? null
                : () => run(() async {
                      final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                                  title: const Text(
                                      'Copy local notes to this account?'),
                                  content: const Text(
                                      'Only journal and checklist notes from this device will be copied to the signed-in account. The local originals are kept. This does not import schedules or focus sessions.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Copy notes'))
                                  ]));
                      if (confirmed != true || !mounted) return;
                      final owner = user.id;
                      final guest = await ref
                          .read(guestNotesRepositoryProvider)
                          .loadAll();
                      if (ref.read(cloudUserProvider)?.id != owner) {
                        throw StateError('Account changed');
                      }
                      if (repo is! SyncedJournalRepository) {
                        throw StateError('Account journal unavailable');
                      }
                      await repo.importGuestNotes(guest);
                      await ref.read(ordinaryNotesProvider.notifier).load();
                      await repo.sync();
                    }),
            child: const Text('Copy local notes to my account')),
        TextButton(
            onPressed: busy ? null : () => context.push('/account/password'),
            child: const Text('Change password')),
        TextButton(
            onPressed: busy
                ? null
                : () => run(() async {
                      final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                                  title: const Text('Log out?'),
                                  content: const Text(
                                      'Unsynced account notes stay in this account’s local cache. Log back into the same account to retry. Your separate local journal will reopen.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Stay')),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Log out'))
                                  ]));
                      if (confirmed == true) {
                        await connection.client!.auth
                            .signOut(scope: SignOutScope.local);
                      }
                    }),
            child: const Text('Log out')),
      ],
      if (busy) const LinearProgressIndicator(),
      if (error != null)
        Text(error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ]));
  }
}
