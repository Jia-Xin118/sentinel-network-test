from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import Alert, AuditEvent, Finding, NotificationAttempt, Patient, User


def route_findings(db: Session, scan_id: str, analyses: list[tuple[Patient, dict]]) -> tuple[int, dict]:
    created = 0
    for patient, result in analyses:
        actionable = result["status"] in {"evidence_requires_clinician_review", "confirmation_gap", "data_quality_review"}
        if not actionable:
            continue
        exists = db.scalar(select(Finding).where(Finding.patient_id == patient.id, Finding.rule_id == "cpg-evidence-review", Finding.evidence_hash == result["evidence_hash"]))
        if exists:
            continue
        finding = Finding(scan_id=scan_id, patient_id=patient.id, rule_id="cpg-evidence-review", rule_version=result["rule_version"], category="data_quality" if result["status"] == "data_quality_review" else "clinical_evidence_review", status=result["status"], evidence_hash=result["evidence_hash"], evidence=result)
        db.add(finding)
        db.flush()
        assignee = db.scalar(select(User).where(User.organization_id == patient.organization_id, User.role == "clinician", User.active.is_(True)))
        alert = Alert(finding_id=finding.id, patient_id=patient.id, assigned_to=assignee.id if assignee else None)
        db.add(alert)
        db.flush()
        db.add(NotificationAttempt(finding_id=finding.id, recipient_user_id=alert.assigned_to, state="in_app_created", dedupe_key=f"new:{finding.id}", attempts=1))
        db.add(AuditEvent(event_type="sentinel.alert_created", entity_type="alert", entity_id=alert.id, detail={"finding_id": finding.id, "route": "in_app_only", "assigned_to": alert.assigned_to}))
        created += 1
    return created, {"stage": "route", "state": "completed", "new_alerts": created, "delivery": "in-app-only"}


def mark_alert(db: Session, alert: Alert, actor: User, action: str) -> Alert:
    now = datetime.now(timezone.utc)
    if action == "acknowledge":
        alert.status, alert.acknowledged_at, alert.acknowledged_by = "acknowledged", now, actor.id
    elif action == "resolve":
        alert.status, alert.resolved_at, alert.resolved_by = "resolved", now, actor.id
    else:
        raise ValueError("Unsupported alert action")
    db.add(AuditEvent(actor_id=actor.id, event_type=f"alert.{action}", entity_type="alert", entity_id=alert.id, detail={"status": alert.status}))
    return alert
