# Sentinel Network implementation checklist

- [x] Define synthetic-only, clinician-review-only boundaries.
- [x] Define the 100-profile care-setting mix and guideline decision-tree contract.
- [x] Build and test the FastAPI Sync -> Analyse -> Route vertical slice.
- [x] Build the React dashboard against live API responses.
- [x] Validate the local Hardhat contract and integrity flow.
- [x] Add Supabase migrations, RLS tests, GitHub CI, and deployment manifests.
- [ ] Verify a private static publish, with Vercel fallback only if needed.

The application must never ingest real patient data, autonomously diagnose, prescribe, classify urgency, or submit referrals.
