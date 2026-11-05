-- Sentinel Network clinical-demo schema.
-- Browser access is deliberately denied: FastAPI is the only clinical-data gateway.

create table public.organizations (
  id varchar(36) primary key,
  code varchar(40) not null unique,
  name varchar(120) not null,
  district varchar(80) not null
);

create table public.users (
  id varchar(36) primary key,
  email varchar(180) not null unique,
  password_hash varchar(512) not null,
  role varchar(32) not null,
  organization_id varchar(36) references public.organizations(id),
  active boolean not null default true
);

create table public.patients (
  id varchar(36) primary key,
  reference varchar(40) not null unique,
  organization_id varchar(36) not null references public.organizations(id),
  care_setting varchar(40) not null,
  age_group varchar(32) not null,
  symptomatic boolean not null default false,
  pregnancy_related boolean not null default false,
  body_mass_index double precision,
  documented_complexity boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.observations (
  id varchar(36) primary key,
  patient_id varchar(36) not null references public.patients(id),
  code varchar(64) not null,
  value double precision,
  unit varchar(48),
  observed_at timestamptz not null,
  ingested_at timestamptz not null default now(),
  source_id varchar(64) not null,
  version integer not null default 1,
  is_corrected boolean not null default false,
  is_late_arrival boolean not null default false,
  constraint uq_source_version unique (source_id, version)
);

create table public.scans (
  id varchar(36) primary key,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status varchar(32) not null default 'running',
  trigger varchar(32) not null,
  scanned_count integer not null default 0,
  finding_count integer not null default 0,
  skipped_count integer not null default 0,
  error_summary text,
  events jsonb not null default '[]'::jsonb
);

create table public.findings (
  id varchar(36) primary key,
  scan_id varchar(36) not null references public.scans(id),
  patient_id varchar(36) not null references public.patients(id),
  rule_id varchar(80) not null,
  rule_version varchar(24) not null,
  category varchar(32) not null,
  status varchar(40) not null,
  evidence_hash varchar(64) not null,
  evidence jsonb not null,
  created_at timestamptz not null default now(),
  constraint uq_finding_evidence unique (patient_id, rule_id, evidence_hash)
);

create table public.alerts (
  id varchar(36) primary key,
  finding_id varchar(36) not null unique references public.findings(id),
  patient_id varchar(36) not null references public.patients(id),
  assigned_to varchar(36) references public.users(id),
  status varchar(24) not null default 'new',
  acknowledged_at timestamptz,
  acknowledged_by varchar(36) references public.users(id),
  resolved_at timestamptz,
  resolved_by varchar(36) references public.users(id),
  last_reminded_at timestamptz,
  escalated_at timestamptz
);

create table public.source_batches (
  id varchar(36) primary key,
  schema_version varchar(32) not null default 'sentinel-source-v1',
  nonce varchar(128) not null,
  manifest jsonb not null,
  commitment varchar(64) not null,
  on_chain_commitment varchar(66),
  chain_id integer,
  contract_address varchar(64),
  transaction_hash varchar(80),
  block_number integer,
  receipt_status varchar(32) not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.research_grants (
  id varchar(36) primary key,
  user_id varchar(36) not null references public.users(id),
  organization_id varchar(36) references public.organizations(id),
  purpose varchar(160) not null,
  scope varchar(160) not null,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  chain_grant_hash varchar(66)
);

create table public.audit_events (
  id varchar(36) primary key,
  actor_id varchar(36) references public.users(id),
  event_type varchar(80) not null,
  entity_type varchar(80) not null,
  entity_id varchar(80) not null,
  detail jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.governance_reviews (
  id varchar(36) primary key,
  actor_id varchar(36) not null references public.users(id),
  note text,
  evidence_snapshot jsonb not null default '{}'::jsonb,
  reviewed_at timestamptz not null default now()
);

create table public.notification_attempts (
  id varchar(36) primary key,
  finding_id varchar(36) not null references public.findings(id),
  recipient_user_id varchar(36) references public.users(id),
  state varchar(32) not null default 'queued',
  dedupe_key varchar(128) not null unique,
  attempts integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.agent_conversations (
  id varchar(36) primary key,
  user_id varchar(36) not null references public.users(id),
  created_at timestamptz not null default now()
);

create table public.agent_messages (
  id varchar(36) primary key,
  conversation_id varchar(36) not null references public.agent_conversations(id),
  role varchar(24) not null,
  content text not null,
  tool_events jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table public.delegated_tasks (
  id varchar(36) primary key,
  requester_id varchar(36) not null references public.users(id),
  task_type varchar(48) not null,
  input_data jsonb not null default '{}'::jsonb,
  output_data jsonb,
  status varchar(24) not null default 'queued',
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.mdt_reviews (
  id varchar(36) primary key,
  patient_id varchar(36) not null references public.patients(id),
  requested_by varchar(36) not null references public.users(id),
  report jsonb not null,
  clinician_attested_at timestamptz,
  clinician_attested_by varchar(36) references public.users(id),
  selected_pathways jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index patients_organization_id_idx on public.patients(organization_id);
create index patients_care_setting_idx on public.patients(care_setting);
create index observations_patient_id_idx on public.observations(patient_id);
create index observations_observed_at_idx on public.observations(observed_at);
create index observations_code_idx on public.observations(code);
create index findings_scan_id_idx on public.findings(scan_id);
create index findings_patient_id_idx on public.findings(patient_id);
create index alerts_patient_id_idx on public.alerts(patient_id);
create index audit_events_event_type_idx on public.audit_events(event_type);
create index governance_reviews_reviewed_at_idx on public.governance_reviews(reviewed_at);
create index notification_attempts_recipient_user_id_idx on public.notification_attempts(recipient_user_id);
create index delegated_tasks_requester_id_idx on public.delegated_tasks(requester_id);
create index delegated_tasks_task_type_idx on public.delegated_tasks(task_type);
create index mdt_reviews_patient_id_idx on public.mdt_reviews(patient_id);

-- These tables remain in public only to work with the server's direct Postgres
-- connection. RLS has no allow policies and Data API roles receive no grants.
alter table public.organizations enable row level security;
alter table public.users enable row level security;
alter table public.patients enable row level security;
alter table public.observations enable row level security;
alter table public.scans enable row level security;
alter table public.findings enable row level security;
alter table public.alerts enable row level security;
alter table public.source_batches enable row level security;
alter table public.research_grants enable row level security;
alter table public.audit_events enable row level security;
alter table public.governance_reviews enable row level security;
alter table public.notification_attempts enable row level security;
alter table public.agent_conversations enable row level security;
alter table public.agent_messages enable row level security;
alter table public.delegated_tasks enable row level security;
alter table public.mdt_reviews enable row level security;

revoke all privileges on table
  public.organizations, public.users, public.patients, public.observations,
  public.scans, public.findings, public.alerts, public.source_batches,
  public.research_grants, public.audit_events, public.governance_reviews,
  public.notification_attempts, public.agent_conversations, public.agent_messages,
  public.delegated_tasks, public.mdt_reviews
from anon, authenticated;
