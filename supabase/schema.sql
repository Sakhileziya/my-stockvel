-- ================================================================
-- MY STOCKVEL — Database Schema
-- Region: af-south-1 (POPIA data residency)
-- Doctrine: No custody. Ledger never forgets. Data minimisation.
-- ================================================================

-- Enable UUID generation
create extension if not exists "pgcrypto";

-- ================================================================
-- GROUPS (Stokvel groups managed by a treasurer)
-- ================================================================
create table groups (
  id            uuid primary key default gen_random_uuid(),
  treasurer_id  uuid references auth.users(id) on delete cascade not null,
  name          text not null,
  description   text,
  contribution_amount numeric(10,2) not null,
  currency      text not null default 'ZAR',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ================================================================
-- MEMBERS (Stokvel group members)
-- ================================================================
create table members (
  id              uuid primary key default gen_random_uuid(),
  group_id        uuid references groups(id) on delete cascade not null,
  full_name       text not null,
  phone_number    text not null,
  email           text,
  -- POPIA consent fields
  popia_consent   boolean not null default false,
  popia_consent_at timestamptz,
  popia_consent_ip text,
  -- Statement access token (login-free)
  statement_token uuid not null default gen_random_uuid(),
  is_active       boolean not null default true,
  sort_order      int not null default 0,
  created_at      timestamptz not null default now()
);

-- ================================================================
-- CYCLES (Contribution periods — monthly, weekly, etc.)
-- ================================================================
create table cycles (
  id            uuid primary key default gen_random_uuid(),
  group_id      uuid references groups(id) on delete cascade not null,
  name          text not null,
  start_date    date not null,
  end_date      date not null,
  frequency     text not null check (frequency in ('weekly','biweekly','monthly')),
  status        text not null default 'active' check (status in ('active','completed','cancelled')),
  created_at    timestamptz not null default now()
);

-- ================================================================
-- CONTRIBUTIONS (Individual payment records — immutable ledger)
-- ================================================================
create table contributions (
  id            uuid primary key default gen_random_uuid(),
  cycle_id      uuid references cycles(id) on delete cascade not null,
  member_id     uuid references members(id) on delete cascade not null,
  group_id      uuid references groups(id) on delete cascade not null,
  due_date      date not null,
  amount        numeric(10,2) not null,
  status        text not null default 'pending' check (status in ('pending','paid','late','waived')),
  paid_at       timestamptz,
  waived_reason text,
  -- Audit trail — who changed what and when
  recorded_by   uuid references auth.users(id),
  recorded_at   timestamptz not null default now(),
  -- Correction chain (if a record is corrected, point to the original)
  corrects_id   uuid references contributions(id),
  notes         text
);

-- ================================================================
-- PAYOUTS (Rotation tracking — who gets the pot)
-- ================================================================
create table payouts (
  id            uuid primary key default gen_random_uuid(),
  cycle_id      uuid references cycles(id) on delete cascade not null,
  member_id     uuid references members(id) on delete cascade not null,
  group_id      uuid references groups(id) on delete cascade not null,
  scheduled_date date not null,
  amount        numeric(10,2) not null,
  status        text not null default 'pending' check (status in ('pending','paid','skipped')),
  paid_at       timestamptz,
  recorded_by   uuid references auth.users(id),
  recorded_at   timestamptz not null default now(),
  notes         text
);

-- ================================================================
-- ROW LEVEL SECURITY — Treasurers only see their own groups
-- ================================================================
alter table groups       enable row level security;
alter table members      enable row level security;
alter table cycles       enable row level security;
alter table contributions enable row level security;
alter table payouts      enable row level security;

-- Groups: treasurer owns their groups
create policy "Treasurer manages own groups"
  on groups for all
  using (treasurer_id = auth.uid());

-- Members: treasurer sees members of their groups
create policy "Treasurer manages group members"
  on members for all
  using (group_id in (select id from groups where treasurer_id = auth.uid()));

-- Cycles: treasurer sees cycles of their groups
create policy "Treasurer manages cycles"
  on cycles for all
  using (group_id in (select id from groups where treasurer_id = auth.uid()));

-- Contributions: treasurer sees contributions of their groups
create policy "Treasurer manages contributions"
  on contributions for all
  using (group_id in (select id from groups where treasurer_id = auth.uid()));

-- Payouts: treasurer sees payouts of their groups
create policy "Treasurer manages payouts"
  on payouts for all
  using (group_id in (select id from groups where treasurer_id = auth.uid()));

-- ================================================================
-- MEMBER STATEMENT RPC — Login-free, token-gated public access
-- ================================================================
create or replace function get_member_statement(p_token uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_member members%rowtype;
  v_result json;
begin
  -- Resolve token to member
  select * into v_member from members where statement_token = p_token and is_active = true;

  if not found then
    raise exception 'Invalid or expired statement token';
  end if;

  -- Build statement JSON
  select json_build_object(
    'member', json_build_object(
      'full_name', v_member.full_name,
      'is_active', v_member.is_active
    ),
    'group', (
      select json_build_object(
        'name', g.name,
        'contribution_amount', g.contribution_amount,
        'currency', g.currency
      )
      from groups g where g.id = v_member.group_id
    ),
    'summary', (
      select json_build_object(
        'total_paid', coalesce(sum(amount) filter (where status = 'paid'), 0),
        'total_late', count(*) filter (where status = 'late'),
        'total_waived', count(*) filter (where status = 'waived'),
        'total_pending', count(*) filter (where status = 'pending'),
        'in_good_standing', (count(*) filter (where status in ('late','pending')) = 0)
      )
      from contributions where member_id = v_member.id
    ),
    'contributions', (
      select json_agg(
        json_build_object(
          'due_date', due_date,
          'amount', amount,
          'status', status,
          'paid_at', paid_at
        ) order by due_date desc
      )
      from contributions where member_id = v_member.id
    )
  ) into v_result;

  return v_result;
end;
$$;

-- Allow anonymous access to the statement function only
grant execute on function get_member_statement(uuid) to anon;

-- ================================================================
-- INDEXES for performance
-- ================================================================
create index idx_members_group_id on members(group_id);
create index idx_members_statement_token on members(statement_token);
create index idx_contributions_member_id on contributions(member_id);
create index idx_contributions_cycle_id on contributions(cycle_id);
create index idx_contributions_due_date on contributions(due_date);
create index idx_payouts_cycle_id on payouts(cycle_id);
create index idx_cycles_group_id on cycles(group_id);

-- ================================================================
-- UPDATED_AT trigger for groups
-- ================================================================
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger groups_updated_at
  before update on groups
  for each row execute function update_updated_at();
