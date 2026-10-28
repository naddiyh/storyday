import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lenote/core/cloud/cloud_connection.dart';
import 'package:lenote/features/notes/data/note_repository.dart';
import 'package:lenote/features/notes/data/journal_sync.dart';
import 'package:lenote/features/notes/domain/note.dart';

class Disk extends Fake implements SharedPreferencesAsync {
  final data = <String, String>{};
  final _flags = [false];
  bool get fail => _flags.first;
  set fail(bool value) => _flags[0] = value;
  @override
  Future<String?> getString(String key) async => data[key];
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('disk full');
    data[key] = value;
  }
}

OrdinaryNote note(String id, [String body = 'draft']) => OrdinaryNote(
    id: id,
    date: DateTime(2026, 10, 28),
    kind: NoteKind.mixed,
    title: id,
    body: body,
    checklist: const [
      ChecklistItem(text: 'first'),
      ChecklistItem(text: 'second')
    ],
    createdAt: DateTime(2026, 10, 28),
    updatedAt: DateTime(2026, 10, 28));

class Remote implements JournalRemote {
  final records = <String, CloudNote>{};
  final mutations = <String, String>{};
  bool offline = false;
  Completer<void>? gate;
  @override
  Future<List<CloudNote>> fetchAll() async {
    if (offline) throw StateError('offline');
    return records.values.toList();
  }

  @override
  Future<CloudNote> push(
      OrdinaryNote n, int revision, bool deleted, String mutation) async {
    await gate?.future;
    if (offline) throw StateError('offline');
    final current = records[n.id];
    if (mutations[n.id] == mutation) return current!;
    if ((current?.revision ?? 0) != revision) throw const JournalConflict();
    final next = CloudNote(n, revision + 1, deleted);
    records[n.id] = next;
    mutations[n.id] = mutation;
    return next;
  }
}

void main() {
  test('Supabase adapter maps HTTP 409/PT409 to a conflict without retrying',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var rpcRequests = 0;
    server.listen((request) async {
      await request.drain<void>();
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/auth/v1/token') {
        request.response.write(jsonEncode({
          'access_token': 'test-session',
          'refresh_token': 'test-refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': 'owner',
            'app_metadata': {},
            'user_metadata': {},
            'aud': 'authenticated',
            'created_at': '2026-10-28T00:00:00Z'
          },
        }));
      } else {
        rpcRequests++;
        request.response.statusCode = HttpStatus.conflict;
        request.response.write(jsonEncode({
          'code': 'PT409',
          'message': 'Journal revision conflict',
          'details': null,
          'hint': null
        }));
      }
      await request.response.close();
    });
    final client = SupabaseClient(
        'http://127.0.0.1:${server.port}', 'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(() async {
      await client.dispose();
      await server.close(force: true);
    });
    await client.auth.signInWithPassword(
        email: 'test@example.invalid', password: 'test-password');
    await expectLater(
        SupabaseJournalRemote(client, 'owner')
            .push(note('n'), 0, false, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
        throwsA(isA<JournalConflict>()));
    expect(rpcRequests, 1);
    await expectLater(SupabaseJournalRemote(client, 'other-owner').fetchAll(),
        throwsStateError);
    expect(rpcRequests, 1);
  });
  test('corrupt legacy collection blocks mutation and keeps original bytes',
      () async {
    final disk = Disk()..data['ordinary-notes.v1'] = '{broken';
    final controller =
        OrdinaryNoteController(PreferencesOrdinaryNoteRepository(disk));
    addTearDown(controller.dispose);
    await expectLater(controller.save(note('new')), throwsFormatException);
    expect(disk.data['ordinary-notes.v1'], '{broken');
    expect(controller.state, isEmpty);
  });
  test(
      'concurrent saves wait for initial data, checklist toggles merge, failed write retries',
      () async {
    final disk = Disk();
    final repo = PreferencesOrdinaryNoteRepository(disk);
    await repo.save(note('existing'));
    final controller = OrdinaryNoteController(repo);
    addTearDown(controller.dispose);
    await Future.wait([
      controller.load(),
      controller.save(note('a')),
      controller.save(note('b'))
    ]);
    expect(controller.state.map((n) => n.id).toSet(), {'existing', 'a', 'b'});
    await Future.wait([
      controller.setChecklistItem('a', 0, true),
      controller.setChecklistItem('a', 1, true)
    ]);
    expect(
        controller.state
            .firstWhere((n) => n.id == 'a')
            .checklist
            .every((i) => i.done),
        isTrue);
    disk.fail = true;
    await expectLater(controller.save(note('failed')), throwsStateError);
    disk.fail = false;
    await controller.save(note('retry'));
    expect(controller.state.any((n) => n.id == 'failed'), isFalse);
    expect(controller.state.any((n) => n.id == 'retry'), isTrue);
  });
  test('offline outbox survives restart, deletion propagates to another device',
      () async {
    final disk = Disk(), cloud = Remote()..offline = true;
    var repo = SyncedJournalRepository(disk, 'a', cloud);
    await repo.save(note('n'));
    await repo.sync();
    repo.dispose();
    repo = SyncedJournalRepository(disk, 'a', cloud);
    addTearDown(repo.dispose);
    expect((await repo.loadAll()).single.body, 'draft');
    cloud.offline = false;
    await repo.sync();
    final second = SyncedJournalRepository(Disk(), 'a', cloud);
    addTearDown(second.dispose);
    await second.sync();
    expect((await second.loadAll()).single.id, 'n');
    await repo.delete('n');
    await repo.sync();
    await second.sync();
    expect(await second.loadAll(), isEmpty);
    expect(cloud.records['n']!.deleted, isTrue);
  });
  test(
      'edit while upload is in flight stays queued and is not overwritten by pull',
      () async {
    final cloud = Remote()..gate = Completer<void>();
    final repo = SyncedJournalRepository(Disk(), 'a', cloud);
    addTearDown(repo.dispose);
    await repo.save(note('n', 'first'));
    final sync = repo.sync();
    await Future<void>.delayed(Duration.zero);
    await repo.save(note('n', 'second'));
    cloud.gate!.complete();
    await sync;
    cloud.gate = null;
    expect((await repo.loadAll()).single.body, 'second');
    await repo.sync();
    expect(cloud.records['n']!.note.body, 'second');
  });
  test('two-device conflict preserves cloud original and local conflict copy',
      () async {
    final cloud = Remote();
    final a = SyncedJournalRepository(Disk(), 'a', cloud),
        b = SyncedJournalRepository(Disk(), 'a', cloud);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await a.save(note('n'));
    await a.sync();
    await b.sync();
    await a.save(note('n', 'device A'));
    await a.sync();
    await b.save(note('n', 'device B'));
    await b.sync();
    final saved = await b.loadAll();
    expect(saved.firstWhere((n) => n.id == 'n').body, 'device A');
    expect(
        saved.firstWhere((n) => n.id.startsWith('conflict-')).body, 'device B');
    await b.sync();
    expect(cloud.records.length, 2);
  });
  test(
      'account caches are isolated; re-import does not resurrect a deleted note',
      () async {
    final disk = Disk(), cloudA = Remote(), cloudB = Remote();
    final a = SyncedJournalRepository(disk, 'a', cloudA),
        b = SyncedJournalRepository(disk, 'b', cloudB);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await a.importGuestNotes([note('guest')]);
    expect(await b.loadAll(), isEmpty);
    await a.delete('local-guest');
    await a.importGuestNotes([note('guest')]);
    expect(await a.loadAll(), isEmpty);
    expect(await b.loadAll(), isEmpty);
  });
  test('corrupt account envelope is not overwritten by edits or sync',
      () async {
    final disk = Disk()..data['ordinary-notes.user.a.v1'] = 'broken';
    final repo = SyncedJournalRepository(disk, 'a', Remote());
    addTearDown(repo.dispose);
    await expectLater(repo.save(note('n')), throwsFormatException);
    await repo.sync();
    expect(disk.data[repo.key], 'broken');
  });
  test('disposed account stops applying an in-flight response', () async {
    final disk = Disk(), cloud = Remote()..gate = Completer<void>();
    final repo = SyncedJournalRepository(disk, 'a', cloud);
    await repo.save(note('n'));
    final sync = repo.sync();
    await Future<void>.delayed(Duration.zero);
    repo.dispose();
    cloud.gate!.complete();
    await sync;
    final record = (jsonDecode(disk.data[repo.key]!)['records'] as List).single;
    expect(record['dirty'], isTrue);
  });
  test('config rejects server secrets and partial configuration', () {
    expect(
        () => const CloudConfig(
                'https://example.supabase.co', 'sb_secret_private')
            .validate(),
        throwsFormatException);
    expect(() => const CloudConfig('', 'sb_publishable_public').validate(),
        throwsFormatException);
    expect(
        () => const CloudConfig(
                'https://example.supabase.co', 'sb_publishable_public')
            .validate(),
        returnsNormally);
    final key = 'header.${base64Url.encode(utf8.encode(jsonEncode({
          'role': 'service_role'
        })))}.sig';
    expect(() => CloudConfig('https://example.supabase.co', key).validate(),
        throwsFormatException);
  });
}
