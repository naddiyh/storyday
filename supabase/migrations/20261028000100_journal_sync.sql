-- Ordinary journal data only. No vault/secret content belongs in this schema.
create table public.journal_notes (
  user_id uuid not null references auth.users(id) on delete cascade,
  note_id text not null check (length(note_id) between 1 and 200),
  entry_date date not null,
  payload jsonb not null check (jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 1048576),
  revision bigint not null default 1 check (revision > 0),
  deleted boolean not null default false,
  last_mutation uuid not null,
  server_updated_at timestamptz not null default now(),
  primary key (user_id, note_id),
  check (payload->>'id' = note_id),
  check (payload->>'kind' in ('journal','checklist','mixed'))
);
create index journal_notes_user_date on public.journal_notes (user_id, entry_date);
alter table public.journal_notes enable row level security;
create policy journal_read_own on public.journal_notes for select to authenticated
  using ((select auth.uid()) = user_id);
revoke all on public.journal_notes from public, anon, authenticated;
grant select on public.journal_notes to authenticated;

-- Only this guarded RPC may mutate journal rows. User ID is always derived
-- from the verified session, never supplied by the Flutter client.
create function public.sync_journal_note(
  p_note_id text,
  p_expected_revision bigint,
  p_payload jsonb,
  p_deleted boolean,
  p_mutation uuid
) returns setof public.journal_notes
language plpgsql security definer set search_path = '' as $$
declare
  caller uuid := auth.uid();
  existing public.journal_notes;
begin
  if caller is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if p_expected_revision is null or p_expected_revision < 0 or p_deleted is null or p_mutation is null
    or p_note_id is null or length(p_note_id) not between 1 and 200
    or p_payload is null or jsonb_typeof(p_payload) <> 'object'
    or octet_length(p_payload::text) > 1048576
    or p_payload->>'id' is distinct from p_note_id
    or p_payload->>'kind' is null or p_payload->>'kind' not in ('journal','checklist','mixed')
    or p_payload->>'date' is null
    or jsonb_typeof(p_payload->'title') is distinct from 'string'
    or jsonb_typeof(p_payload->'body') is distinct from 'string'
    or jsonb_typeof(p_payload->'checklist') is distinct from 'array'
    or (p_payload - array['id','date','kind','title','body','checklist','createdAt','updatedAt',
      'bold','italic','underline','fontSize','stickers','category']) <> '{}'::jsonb
  then raise exception 'Invalid ordinary note payload' using errcode = '22023'; end if;

  if jsonb_typeof(p_payload->'createdAt') is distinct from 'string'
    or jsonb_typeof(p_payload->'updatedAt') is distinct from 'string'
    or exists (select 1 from jsonb_array_elements(p_payload->'checklist') as item
      where jsonb_typeof(item) <> 'object'
        or jsonb_typeof(item->'text') is distinct from 'string'
        or jsonb_typeof(item->'done') is distinct from 'boolean')
  then raise exception 'Invalid note metadata' using errcode = '22023'; end if;
  perform (p_payload->>'createdAt')::timestamptz, (p_payload->>'updatedAt')::timestamptz;

  -- Covers concurrent first inserts as well as edits. Locks are scoped to
  -- this account+note and released at transaction end.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(caller::text || ':' || p_note_id, 0));
  select * into existing from public.journal_notes where user_id = caller and note_id = p_note_id for update;
  if found then
    if existing.last_mutation = p_mutation then
      return next existing;
      return;
    end if;
    if existing.revision <> p_expected_revision then
      raise exception 'Journal revision conflict' using errcode = '40001';
    end if;
    update public.journal_notes set payload = p_payload,
      entry_date = (split_part(p_payload->>'date', 'T', 1))::date,
      revision = revision + 1, deleted = p_deleted, last_mutation = p_mutation,
      server_updated_at = now()
      where user_id = caller and note_id = p_note_id;
  else
    if p_expected_revision <> 0 then
      raise exception 'Journal revision conflict' using errcode = '40001';
    end if;
    insert into public.journal_notes(user_id,note_id,entry_date,payload,deleted,last_mutation)
      values(caller,p_note_id,(split_part(p_payload->>'date', 'T', 1))::date,p_payload,p_deleted,p_mutation);
  end if;
  return query select * from public.journal_notes where user_id = caller and note_id = p_note_id;
end;
$$;
revoke all on function public.sync_journal_note(text,bigint,jsonb,boolean,uuid) from public, anon;
grant execute on function public.sync_journal_note(text,bigint,jsonb,boolean,uuid) to authenticated;
