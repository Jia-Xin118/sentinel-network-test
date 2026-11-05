# Sentinel Network — project instructions

## Goal and scope

Build a working local hackathon MVP with two controlled workflows:

1. Clinical: scheduled retrieval of new synthetic EMR records, deterministic anomaly detection, evidence-linked briefing, and clinician alerts.
2. Research: authorised, aggregate district-level surveillance, backed by a verifiable source-batch audit trail.

Use synthetic data exclusively. Every screen and export must state `Synthetic data — demonstration only`. This is clinical decision support for review, not validated prediction or autonomous clinical care. The system never prescribes, changes medication, or contacts real patients.

The three pipeline stages are Sync, Analyse, and Route. Implement them as clear services; three separate LLM agents or a multi-agent framework are unnecessary. Do not create theatrical agent dialogue.

## Engineering approach

- Inspect existing files and runtimes first; preserve existing user work.
- Preferred stack: React + TypeScript + Vite frontend, FastAPI + SQLAlchemy backend, SQLite database, APScheduler in a single dedicated worker, and Solidity + Hardhat local development chain with a compatible maintained Ethereum client library.
- Use a supported Python and Node LTS combination after checking current dependency requirements. Pin compatible versions and commit lockfiles. Avoid pre-release dependencies.
- If an existing viable stack is present, adapt rather than rewrite. Record material substitutions in README.
- No mandatory Docker, Supabase, cloud account, IPFS, wallet browser extension, or API subscription. Use local disk and loopback network services.
- Implement backend data and a working vertical slice before adding visual polish. Keep modules small and explicit; avoid unnecessary abstractions.
- The README must cover Windows PowerShell first, then macOS/Linux. Include installation prerequisites, environment setup, migrations, seeding, contract deployment, startup, shutdown and reset commands. A fresh checkout must be reproducible.
- Do not add public deployment or paid integrations to the critical path. Do not send external notifications during development without an explicit owner request and a known test destination.

## Data model and synthetic fixture

Include organisations, users/roles, patients, observations, scans, rule findings, alerts, acknowledgements, notification attempts, source batches, chain receipts, research grants and audit events.

Seed roughly 200 synthetic patients across three fictional hospitals and three fictional districts. Include two comparable reporting periods and enough longitudinal observations for patient trend charts. Keep identities out of district names and use synthetic UUIDs.

Create reproducible fixtures for stable measurements, worsening glycaemic trend, renal-function trend, missing data, inconsistent units, duplicate observations, corrected results, late-arriving results, and a district rate increase. Document expected findings and denominators. Values and rule thresholds are illustrative fixtures, not clinical guidance.

Store measurement value, unit, observed_at, ingested_at, source/version and provenance. Normalise or explicitly reject units before comparing values. Do not compare incompatible units or silently treat missing values as zero. Preserve observation versions so corrections can be audited. Reprocess affected timelines when corrected or late observations arrive.

## Clinical detection and brief

- Implement rules in a readable configuration file with IDs, versions, required units, lookback windows, minimum measurements, thresholds and explanatory text.
- Label all bundled thresholds `illustrative demo rules; clinician validation required`. Do not invent guideline endorsements or use an LLM to set thresholds at runtime.
- Separate data-quality findings from clinical trend findings. Missing or invalid data must produce an explicit insufficient-data result when appropriate.
- Each finding includes rule/version, patient reference, source observation IDs, values, dates, units, computed change, and the exact reason it triggered.
- No diagnostic inference from medication lists or claims of adherence. Do not label declining renal measurements as confirmed CKD or glycaemic trends as impending complications.
- Brief format: observation summary, rule trigger, evidence, missing context, and `Clinician review requested`. Avoid treatment advice and unsupported urgency classifications.
- Default summaries are deterministic templates. An optional server-side LLM may rewrite supplied evidence into this schema. Validate its output; if it fails, contradicts evidence or adds unsupported claims, retain the template. Clearly display template versus LLM mode. Rule detection must work without any LLM.
- The clinical alert state supports new, acknowledged and resolved with timestamp and actor. Resolution is a clinician action, never an automatic treatment outcome.

## Real scheduling and reliability

- Run a persistent scheduler worker independent of the browser. Default nightly scan at 02:00 Asia/Kuala_Lumpur; configurable accelerated demo interval, disabled until selected. Persist settings.
- Scan Now and scheduled execution call the same service. Use a database-backed single-run lock or equivalent so overlapping invocations cannot double-process.
- Use an ingestion cursor/high-water mark plus durable processed IDs, not only a fixed last-24-hours filter. Load the necessary patient history for each changed record. Advance progress only after successful processing; handle partial failures and retries.
- A repeated scan without changed source data must not create duplicate findings or notifications. Define an explicit idempotency key using patient, rule version and evidence version; material new evidence may create an updated finding.
- Persist scan start/end, scanned counts, skipped records, findings and errors. Display last successful run, next scheduled run, timezone and worker heartbeat. An offline worker must not appear healthy.
- Use a persisted notification outbox for reliable retries and deduplication. In-app notifications are the default. External adapters remain disabled/unconfigured until explicitly set up.
- External messages, if later enabled, contain only a generic alert and an authenticated dashboard link, not lab values or patient identity. Record queued/sent/failed honestly; never claim delivery from a queued message.

## Roles and research boundary

- Implement minimal server-side authentication with seeded local demo accounts and hashed passwords. Local-only defaults are acceptable if plainly documented; never expose a public unauthenticated backend.
- Roles: hospital clinician (own organisation's clinical records), researcher (approved aggregate queries only), and administrator (grant management and synthetic demo controls).
- Do not trust client role headers, hidden UI controls, wallet addresses supplied in requests, or query parameters as authentication. Bind a logged-in user to its organisation and any registered wallet server-side.
- Researchers cannot fetch individual records, notes, observations, patient-level exports, or clinical alerts, even by guessing API paths or identifiers.
- Research grants specify organisation/user, permitted purpose and dataset scope, reporting periods, expiry and revoked status. Enforce them on the server for every research request.
- For this MVP, expose only fixed district, broad-age-group and period queries. Apply a configurable minimum eligible cohort size (default 20 for demonstration), plus protection against revealing suppressed cells through totals or differencing. Do not expose arbitrary filters or drill-down that bypass suppression. Document that these controls are not proof of anonymity.
- Never send a complete patient database to an LLM for regional analysis. Compute aggregates in ordinary code.

## Regional analytics

- Display `Anomaly rate among monitored patients`, not population prevalence or incidence.
- Define denominator: unique eligible patients with sufficient valid observations for the stated rule and reporting period. Numerator: unique eligible patients meeting that same rule. Do not count repeated labs as additional patients.
- Compare equivalent periods using the same cohort definition; display counts, period boundaries, eligibility rules, missingness and cohort changes. Provide a fixed-cohort comparison for the scripted demo.
- Distinguish percentage-point change from relative percentage change; handle a zero prior denominator/rate explicitly. Do not invent a statistical significance claim or population-level outbreak conclusion.
- Use a district tile map or labelled schematic when geographic boundaries are unavailable; do not invent precise real-world hotspot locations.

## Blockchain implementation

- Use a real local development chain and a minimal contract for hospital wallet allowlisting, batch commitments and scope-bound research grants/revocation. Label it `Local development chain — consortium prototype`, never a live consortium or decentralised hospital network.
- Real records, lab values, patient identifiers, district/age combinations, notes, raw query outputs, encryption keys and credentials remain off-chain. No individual low-entropy lab-value hashes on-chain.
- Commit a canonical, versioned source-batch representation using a fresh cryptographically random nonce and a cryptographic hash. Keep the nonce and batch mapping in protected off-chain storage. Document canonicalisation, field order, timestamp/number representation and digest algorithm. Do not use Python's process-specific hash().
- Contract batch fields: random batch ID, commitment, submitting authorised wallet, block timestamp and schema version. Restrict publishing and grant management to appropriate wallets.
- Record actual chain ID, contract address, transaction hash, block number and receipt status. Display confirmed only after a successful mined receipt. Never fabricate blockchain transactions.
- The backend is the enforcement point for off-chain data. For research access, require the database policy AND the matching unexpired, unrevoked on-chain grant. Bind grants to identity, scope, purpose and dataset; fail closed if chain state cannot be verified. Clinical scanning remains available during chain outage, with anchoring visibly pending.
- If the local chain is unavailable, show unavailable/pending and provide restart instructions. Persist pending anchors for retry, but never auto-re-anchor a modified batch under its original identity or overwrite its original commitment. A new version requires a new batch ID.
- Tamper demonstration must modify a synthetic source record while keeping its original immutable batch membership/manifest. Verification recomputes the commitment from the current source records and original nonce, and detects the mismatch against the original chain value. Do not merely compare two copies of the same cached digest.
- Provide administrator-only tamper and restore controls for a designated synthetic batch. Log both actions; restoration preserves audit history.
- Document: a commitment demonstrates consistency with submitted data, not original clinical truth; allowlisting is not privacy compliance; a single local chain is not independent multi-party governance. No patient care may depend on chain availability.

## UI and demo

Create Overview, Patients with longitudinal charts, Alerts with evidence and acknowledgement, Regional Surveillance, Research Access, Integrity Ledger, and System Status. Role-based navigation complements server-side access checks.

Use white/slate/teal styling, legible typography, subtle status colours, loading/empty/error states, responsive PC layout and accessible labels. Show demo labels consistently. Display timestamps in Asia/Kuala_Lumpur with timezone labels while storing UTC internally.

Include real stage events for Sync, Analyse and Route. The UI must show API results, not hardcoded success. Clearly distinguish live local components, disabled adapters and template summaries.

DEMO_SCRIPT.md must cover a five-minute reproducible sequence: baseline scan; inject synthetic abnormal observation; scan; inspect and acknowledge finding; review regional counts; verify mined commitment; tamper and detect mismatch; restore; deny an unauthorised researcher query; revoke an approved grant and demonstrate denial.

## Acceptance and tests

Write meaningful tests for:

1. Stable versus deliberately abnormal fixtures and evidence calculations.
2. Missing units, invalid values, missing history, corrected and late-arriving observations.
3. Rerun idempotency, overlapping scans, worker scheduling and restart behaviour.
4. Alert acknowledgement persistence and notification retry/deduplication.
5. Unique-patient denominators, percentage-point calculation, zero baselines and small-cell suppression including complementary disclosure.
6. Researcher denial of individual data, cross-hospital clinician isolation, grant scope/expiry/revocation, and fail-closed research access during chain outage.
7. Real contract access control, batch receipt confirmation, canonicalisation reproducibility, tamper mismatch and successful restoration.
8. An end-to-end vertical slice through backend and dashboard; inspect the UI with available browser tooling, or clearly report that visual verification was unavailable.

Run relevant lint/type checks, backend tests, contract tests and production frontend build. Separate actual executed results from checks not run. Never mark incomplete or untested integrations complete.

## Required handover

Deliver working source; dependency lockfiles; schema/migrations; deterministic seeding; .env.example with placeholders; secret-safe .gitignore; contract deployment and metadata; a cross-platform startup helper; README; PLAN.md with honest progress; and DEMO_SCRIPT.md.

Document which processes must stay running, local URLs, test accounts, reset/restore behaviour and limitations. Keep development-chain keys local, use no real wallets or funds, and never commit real credentials.

Proceed with reasonable reversible implementation decisions. Ask only when blocked by missing essential information or before destructive actions. A plan or attractive static mockup alone does not satisfy this project.
