from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..models import Alert, AuditEvent, Finding, NotificationAttempt, User


def _as_utc(value: datetime) -> datetime:
    """SQLite returns naive timestamps; production Postgres returns aware ones."""
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


def advance_notification_workflows(db: Session) -> dict:
    """Create only auditable in-app reminders/escalations; never contact patients or services."""
    settings = get_settings()
    now = datetime.now(timezone.utc)
    reminder_cutoff = now - timedelta(minutes=settings.alert_reminder_minutes)
    escalation_cutoff = now - timedelta(minutes=settings.alert_escalation_minutes)
    reminders = escalations = 0
    for alert in db.scalars(select(Alert).where(Alert.status == "new")).all():
        finding = db.get(Finding, alert.finding_id)
        if not finding:
            continue
        created_at = _as_utc(finding.created_at)
        if created_at <= reminder_cutoff and not alert.last_reminded_at:
            alert.last_reminded_at = now
            db.add(NotificationAttempt(finding_id=finding.id, recipient_user_id=alert.assigned_to, state="in_app_reminder", dedupe_key=f"reminder:{alert.id}", attempts=1))
            db.add(AuditEvent(event_type="sentinel.reminder_created", entity_type="alert", entity_id=alert.id, detail={"channel": "in_app", "clinical_interpretation": "none"}))
            reminders += 1
        if created_at <= escalation_cutoff and not alert.escalated_at:
            admin = db.scalar(select(User).where(User.role == "administrator", User.active.is_(True)))
            alert.escalated_at = now
            db.add(NotificationAttempt(finding_id=finding.id, recipient_user_id=admin.id if admin else None, state="clinical_review_queue", dedupe_key=f"escalation:{alert.id}", attempts=1))
            db.add(AuditEvent(event_type="sentinel.review_queue_escalated", entity_type="alert", entity_id=alert.id, detail={"channel": "in_app", "clinical_interpretation": "none", "requires_human_review": True}))
            escalations += 1
    return {"reminders": reminders, "review_queue_escalations": escalations}
