-- Reference schema for a future hosted PostgreSQL backend.
-- Local JSON remains the offline cache and backup/export format.

create table if not exists families (
  id text primary key,
  name text not null default '',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists people (
  id text primary key,
  family_id text not null references families(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists marriage_relations (
  id text primary key,
  family_id text not null references families(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists family_links (
  id text primary key,
  family_id text not null references families(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists family_codes (
  id text primary key,
  family_id text not null references families(id),
  code_hash text not null default '',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists admins (
  id text primary key,
  family_id text not null references families(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists family_history (
  id text primary key,
  family_id text not null references families(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists family_council_members (
  id text primary key,
  family_id text not null references families(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists notifications (
  id text primary key,
  family_id text not null references families(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists bug_reports (
  id text primary key,
  family_id text not null references families(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists audit_logs (
  id text primary key,
  family_id text not null references families(id),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create table if not exists sync_operations (
  id text primary key,
  family_id text not null references families(id),
  entity_type text not null,
  entity_id text not null,
  action text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending',
  retry_count integer not null default 0,
  last_error text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text not null default '',
  version integer not null default 1,
  deleted_at timestamptz
);

create index if not exists idx_people_family_id on people(family_id);
create index if not exists idx_sync_operations_family_status
  on sync_operations(family_id, status);
