# Sentinel Network — MIT Hackathon DM

Sentinel Network is a local-first, synthetic-data-only hackathon MVP for transparent EMR anomaly surveillance, clinician review, privacy-bounded research aggregates, and blockchain-backed integrity checks.

> **Synthetic data — demonstration only.** This is not a diagnostic, prescribing, triage, referral, or production EMR system. Clinical decisions remain with a qualified clinician.

## Architecture

- `frontend/` — React + Vite desktop dashboard.
- `backend/` — FastAPI API, SQLAlchemy persistence, APScheduler worker, deterministic rule/CPG review tree.
- `contracts/` — Hardhat Solidity integrity and research-grant contract.
- `supabase/` — cloud Postgres migration and RLS policy tests; the browser never queries clinical data directly.

The default no-credential local mode uses SQLite. Supabase Postgres is the cloud data authority when `DATABASE_URL` is configured. A missing chain configuration is displayed as **unavailable/pending**; it is never represented as a simulated success.

## Evidence, Sentinel Agent, and MDT boundaries

- The data seed contains exactly 100 fictional profiles: **45 Outpatient Clinic, 25 Medical Ward, 18 Surgical Ward, and 12 O&G Ward** across three fictional hospital/district pairs.
- The deterministic, versioned CPG review tree performs data validity, applicability, evidence/confirmation, monitoring audit, and clinician-owned management/referral consideration. It is evidence support only—not diagnosis, treatment selection, urgency classification, or a referral order.
- O&G records marked pregnancy-related are deliberately returned as **out of scope**, because this CPG does not cover diabetes in pregnancy.
- **Sentinel Agent** is an authorised, persisted chat/orchestration layer. It can queue role-scoped evidence review, integrity verification, fixed aggregate-analysis handoff, or a public-source crawl restricted to HTTPS MOH/MEMS pages. It never passes patient data to the crawler.
- Its background workflow creates deduplicated **in-app** reminders and clinician-review-queue escalations only. It never contacts patients or external services.
- The three-person Diabetes MDT is intentionally deterministic rather than an ANN: an evidence/confirmation reviewer, data-quality/complexity reviewer, and care-coordination reviewer. It can present endocrinology, bariatric-surgery, or GP-continuity **considerations** only. A clinician must select and attest an offered consideration; no referral is sent.

The CPG mapping is a demo interpretation and requires a named Malaysian clinical owner to review it before any non-demo use.

## Local quick start — Windows PowerShell

```powershell
Copy-Item .env.example .env
.\scripts\start.ps1
```

Then open `http://localhost:5173`. The API is available at `http://localhost:8000/docs`.

Demo accounts are created only in the local synthetic database:

| Role | Email | Password |
| --- | --- | --- |
| Administrator | admin@sentinel.demo | SentinelDemo!2026 |
| Aster clinician | clinician.aster@sentinel.demo | SentinelDemo!2026 |
| Approved researcher | researcher.approved@sentinel.demo | SentinelDemo!2026 |
| Denied researcher | researcher.denied@sentinel.demo | SentinelDemo!2026 |

## AI governance lifecycle MVP

Administrators can open **AI Governance** to review Sentinel's evidence-backed lifecycle controls. The page maps the local MVP to ISO/IEC 42001:2023 management-system themes and ISO/IEC 5338:2023 lifecycle practices. It is an alignment demonstrator only—not ISO certification or a full compliance claim.

The future LLM-assisted Sentinel Agent is in scope, but no provider or model is configured in this build. The dashboard records the permitted and prohibited LLM inputs, mandatory structured-output validation and deterministic fallback, clinician-review boundary, live local evidence, known gaps, and an administrator's 30-day governance-review attestation. LLM activation remains blocked until its provider/model identity, synthetic-only evaluation, telemetry, validation, and safety acceptance evidence are implemented.

## Local blockchain demo

```powershell
Set-Location contracts
npm install
npm run chain
```

In another terminal:

```powershell
Set-Location contracts
npm run deploy:local
```

Copy the emitted `CHAIN_CONTRACT_ADDRESS` and local RPC URL to `.env`, restart the API, then use **Anchor batch** in the Integrity Ledger. The contract stores only commitments and metadata—never raw synthetic records. For a hosted Sepolia demo, use a dedicated test wallet, set `CHAIN_RPC_URL`, `CHAIN_PRIVATE_KEY`, `CHAIN_CONTRACT_ADDRESS`, and the public `CHAIN_RESEARCHER_ADDRESS`; then anchor the synthetic research grant before allowing an aggregate query. Revocation fails closed if the on-chain revocation transaction cannot be confirmed.

## Supabase data authority

The committed schema migration is [20261104163106_initial_sentinel_schema.sql](supabase/migrations/20261104163106_initial_sentinel_schema.sql). Every exposed `public` table has RLS enabled and neither `anon` nor `authenticated` is granted table access. The browser uses the FastAPI API only; it never includes a Supabase client or service credential. Run [001_rls_denial.sql](supabase/tests/001_rls_denial.sql) against a disposable Supabase database after applying the migration.

Use a server-only Postgres connection string for `DATABASE_URL` on Render. Do not put that URL, a Supabase service key, or a private key in `VITE_*` variables or the static site.

## Cloud release contract

1. Run Supabase migrations and RLS tests; do not expose direct table access to browser clients.
2. Deploy the API and worker as separate Render services with server-only database and Sepolia credentials.
3. Deploy the contract to Sepolia with a dedicated test wallet.
4. Push the secret-scanned repository to **MIT Hackathon DM**.
5. Publish `frontend/dist` privately to Sites. If that fails, deploy the identical static frontend to a protected Vercel project.

Before the static build, set `VITE_API_BASE_URL` to the HTTPS Render API URL plus `/api`; unlike Vite development mode, production has no proxy.

See [DEMO_SCRIPT.md](DEMO_SCRIPT.md) for the five-minute walkthrough.
