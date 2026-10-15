-- One private workspace snapshot per authenticated Supabase user.
-- The Vault is intentionally excluded; only WorkspaceData JSON is stored here.

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users (id) on delete cascade,
  name text not null default 'Personal workspace'
    check (char_length(name) between 1 and 120),
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table if not exists public.workspace_data (
  workspace_id uuid primary key references public.workspaces (id) on delete cascade,
  payload jsonb not null check (pg_catalog.jsonb_typeof(payload) = 'object'),
  revision bigint not null default 1 check (revision > 0),
  updated_at timestamptz not null default pg_catalog.now(),
  updated_by uuid not null references auth.users (id) on delete cascade
);

alter table public.workspaces enable row level security;
alter table public.workspace_data enable row level security;

grant usage on schema public to authenticated;
revoke all on table public.workspaces from public, anon, authenticated;
revoke all on table public.workspace_data from public, anon, authenticated;
grant select, insert, update, delete on table public.workspaces to authenticated;
grant select on table public.workspace_data to authenticated;

drop policy if exists "workspace owners can read their workspace" on public.workspaces;
create policy "workspace owners can read their workspace"
  on public.workspaces for select to authenticated
  using (owner_id = (select auth.uid()));

drop policy if exists "users can create their own workspace" on public.workspaces;
create policy "users can create their own workspace"
  on public.workspaces for insert to authenticated
  with check (owner_id = (select auth.uid()));

drop policy if exists "workspace owners can update their workspace" on public.workspaces;
create policy "workspace owners can update their workspace"
  on public.workspaces for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

drop policy if exists "workspace owners can delete their workspace" on public.workspaces;
create policy "workspace owners can delete their workspace"
  on public.workspaces for delete to authenticated
  using (owner_id = (select auth.uid()));

drop policy if exists "workspace owners can read their snapshot" on public.workspace_data;
create policy "workspace owners can read their snapshot"
  on public.workspace_data for select to authenticated
  using (
    exists (
      select 1
      from public.workspaces as w
      where w.id = workspace_data.workspace_id
        and w.owner_id = (select auth.uid())
    )
  );

create or replace function public.save_workspace_snapshot(
  p_workspace_id uuid,
  p_payload jsonb,
  p_expected_revision bigint
)
returns table (revision bigint, updated_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_current_revision bigint;
  v_new_revision bigint;
  v_updated_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  if p_payload is null or pg_catalog.jsonb_typeof(p_payload) <> 'object' then
    raise exception 'workspace_payload_must_be_a_json_object' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.workspaces as w
    where w.id = p_workspace_id
      and w.owner_id = v_user_id
  ) then
    raise exception 'workspace_not_found' using errcode = '42501';
  end if;

  select d.revision
    into v_current_revision
    from public.workspace_data as d
   where d.workspace_id = p_workspace_id
   for update;

  if not found then
    if coalesce(p_expected_revision, 0) <> 0 then
      raise exception 'sync_conflict' using errcode = '40001';
    end if;

    begin
      insert into public.workspace_data (
        workspace_id, payload, revision, updated_at, updated_by
      ) values (
        p_workspace_id, p_payload, 1, pg_catalog.now(), v_user_id
      ) returning workspace_data.revision, workspace_data.updated_at
        into v_new_revision, v_updated_at;
    exception when unique_violation then
      raise exception 'sync_conflict' using errcode = '40001';
    end;
  else
    if p_expected_revision is null or p_expected_revision <> v_current_revision then
      raise exception 'sync_conflict' using errcode = '40001';
    end if;

    update public.workspace_data as d
       set payload = p_payload,
           revision = v_current_revision + 1,
           updated_at = pg_catalog.now(),
           updated_by = v_user_id
     where d.workspace_id = p_workspace_id
     returning d.revision, d.updated_at into v_new_revision, v_updated_at;
  end if;

  update public.workspaces as w
     set updated_at = v_updated_at
   where w.id = p_workspace_id
     and w.owner_id = v_user_id;

  return query select v_new_revision, v_updated_at;
end;
$function$;

revoke all on function public.save_workspace_snapshot(uuid, jsonb, bigint) from public, anon;
grant execute on function public.save_workspace_snapshot(uuid, jsonb, bigint) to authenticated;

comment on table public.workspaces is
  'One private Comrade Vault workspace per authenticated Supabase user.';
comment on table public.workspace_data is
  'Versioned JSONB snapshots of non-Vault WorkspaceData. RLS limits reads to the owner; writes go through save_workspace_snapshot.';
comment on column public.workspace_data.payload is
  'Readable workspace metadata. Do not store Vault credentials or service-role keys in this JSON document.';
