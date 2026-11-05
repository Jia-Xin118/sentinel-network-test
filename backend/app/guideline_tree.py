from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Iterable

from .models import Observation, Patient

RULES = json.loads((Path(__file__).parent / "rules" / "t2dm_demo_rules.json").read_text(encoding="utf-8"))


def assessment(patient: Patient, observations: Iterable[Observation]) -> dict:
    """Return transparent CPG evidence/audit states, never a diagnosis or prescription."""
    items = sorted(list(observations), key=lambda item: item.observed_at)
    nodes: list[dict] = []
    invalid = [item for item in items if item.code in RULES["accepted_units"] and item.unit not in RULES["accepted_units"][item.code]]
    if invalid:
        nodes.append({"id": "data-validity", "state": "invalid", "reference": RULES["references"]["diagnosis"], "detail": "One or more measurements has an incompatible or missing unit."})
        return _result("data_quality_review", nodes, items, ["Correct or verify units before comparison."])
    nodes.append({"id": "data-validity", "state": "valid", "reference": RULES["references"]["diagnosis"], "detail": "Comparable measurement units are present."})

    if patient.pregnancy_related:
        nodes.append({"id": "applicability", "state": "out_of_scope", "reference": RULES["references"]["scope"], "detail": "Pregnancy-related record is not evaluated by this T2DM decision tree."})
        return _result("out_of_scope", nodes, items, ["Use the applicable local pregnancy pathway; no automated recommendation is provided."])
    nodes.append({"id": "applicability", "state": "in_scope", "reference": RULES["references"]["diagnosis"], "detail": "Synthetic adult T2DM evidence-review scope."})

    latest: dict[str, Observation] = {}
    for item in items:
        latest[item.code] = item
    positive = []
    if (item := latest.get("fpg")) and (item.value or 0) >= 7.0:
        positive.append("fasting plasma glucose")
    if (item := latest.get("rpg")) and (item.value or 0) >= 11.1:
        positive.append("random plasma glucose")
    if (item := latest.get("hba1c")) and (item.value or 0) >= 6.3:
        positive.append("HbA1c")

    if patient.symptomatic and positive:
        diagnostic_state = "evidence_requires_clinician_review"
        detail = "A qualifying synthetic result is present in a record marked symptomatic; clinician confirmation is required."
    elif len(positive) >= 2:
        diagnostic_state = "evidence_requires_clinician_review"
        detail = "Two qualifying synthetic evidence items are present; clinician confirmation is required."
    elif positive:
        diagnostic_state = "confirmation_gap"
        detail = "One qualifying synthetic evidence item is present without the required confirmation context."
    else:
        diagnostic_state = "no_qualifying_evidence"
        detail = "No configured diagnostic-evidence threshold is met in available synthetic observations."
    nodes.append({"id": "diagnostic-evidence", "state": diagnostic_state, "reference": RULES["references"]["diagnosis"], "detail": detail, "positive_evidence": positive})

    required = {"hba1c", "fpg", "egfr"}
    missing = sorted(required - set(latest))
    nodes.append({"id": "baseline-audit", "state": "incomplete" if missing else "complete", "reference": RULES["references"]["initial_assessment"], "detail": "Missing illustrative baseline data: " + ", ".join(missing) if missing else "Illustrative baseline data present."})
    nodes.append({"id": "clinician-action", "state": "review_required", "reference": RULES["references"]["monitoring"], "detail": "The clinician may record review, local-pathway follow-up, or referral consideration. No action is submitted by the system."})
    return _result(diagnostic_state, nodes, items, ["Review supplied evidence and missing context.", "Document clinician decision outside this system's automated logic."])


def _result(status: str, nodes: list[dict], observations: list[Observation], considerations: list[str]) -> dict:
    evidence = [{"id": item.id, "code": item.code, "value": item.value, "unit": item.unit, "observed_at": item.observed_at.isoformat()} for item in observations]
    raw = json.dumps({"status": status, "nodes": nodes, "evidence": evidence}, sort_keys=True, separators=(",", ":"))
    return {"status": status, "rule_version": RULES["version"], "nodes": nodes, "evidence": evidence, "considerations": considerations, "evidence_hash": hashlib.sha256(raw.encode()).hexdigest()}
