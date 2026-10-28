-- Run with psql -v ON_ERROR_STOP=1 against an ephemeral Supabase database.
-- Fixtures and helper functions are rolled back. No real user data is needed.
begin;
insert into auth.users(id,email) values
 ('11111111-1111-4111-8111-111111111111','journal-a@example.invalid'),
 ('22222222-2222-4222-8222-222222222222','journal-b@example.invalid');
create function pg_temp.note_payload(note_id text, body_text text) returns jsonb
language sql as $$ select jsonb_build_object('id',note_id,'kind','journal',
 'title','Test','body',body_text,'date','2026-10-28T00:00:00',
 'checklist','[]'::jsonb,'createdAt','2026-10-28T00:00:00','updatedAt','2026-10-28T00:00:00') $$;

set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
select * from public.sync_journal_note('same-id',0,pg_temp.note_payload('same-id','A'),false,
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
do $$ begin
 if (select count(*) from public.journal_notes) <> 1 then raise exception 'A cannot read own row'; end if;
end $$;
-- Retry after a lost acknowledgement must not increment revision again.
select * from public.sync_journal_note('same-id',0,pg_temp.note_payload('same-id','A'),false,
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
do $$ begin
 if (select revision from public.journal_notes) <> 1 then raise exception 'Retry is not idempotent'; end if;
 begin
  perform public.sync_journal_note('same-id',0,pg_temp.note_payload('same-id','stale'),false,
   'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
  raise exception 'Stale revision accepted';
 exception when sqlstate 'PT409' then null; end;
 begin
  update public.journal_notes set payload = pg_temp.note_payload('same-id','bypass');
  raise exception 'Direct writes accepted';
 exception when insufficient_privilege then null; end;
 begin
  delete from public.journal_notes;
  raise exception 'Hard delete accepted';
 exception when insufficient_privilege then null; end;
 begin
  perform public.sync_journal_note('bad',0,pg_temp.note_payload('bad','x') || '{"secret":true}'::jsonb,false,
   'cccccccc-cccc-4ccc-8ccc-cccccccccccc');
  raise exception 'Unknown payload fields accepted';
 exception when invalid_parameter_value then null; end;
end $$;

set local request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';
do $$ begin
 if (select count(*) from public.journal_notes) <> 0 then raise exception 'B can read A data'; end if;
 begin
  perform public.sync_journal_note('same-id',1,pg_temp.note_payload('same-id','B attempts A revision'),false,
   'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
  raise exception 'B updated A row';
 exception when sqlstate 'PT409' then null; end;
end $$;
select * from public.sync_journal_note('same-id',0,pg_temp.note_payload('same-id','B'),false,
 'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
do $$ begin
 if (select payload->>'body' from public.journal_notes) <> 'B' then raise exception 'B row incorrect'; end if;
end $$;
set local request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
do $$ begin
 if (select payload->>'body' from public.journal_notes) <> 'A' then raise exception 'A overwritten by B'; end if;
end $$;
select * from public.sync_journal_note('same-id',1,pg_temp.note_payload('same-id','A'),true,
 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee');
do $$ begin
 if not (select deleted and revision = 2 from public.journal_notes) then raise exception 'Tombstone not retained'; end if;
end $$;
set local role anon;
do $$ begin
 begin
  perform * from public.journal_notes;
  raise exception 'Anon can read notes';
 exception when insufficient_privilege then null; end;
 begin
  perform public.sync_journal_note('x',0,pg_temp.note_payload('x','anon'),false,
   'ffffffff-ffff-4fff-8fff-ffffffffffff');
  raise exception 'Anon can mutate notes';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'Journal RLS, ownership, RPC guards, idempotency, conflicts and tombstones passed' as result;
