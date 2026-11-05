from apscheduler.schedulers.blocking import BlockingScheduler

from .config import get_settings
from .db import SessionLocal, initialise_database
from .main import execute_scan
from .models import AuditEvent
from .agent import process_pending_tasks
from .services.sentinel_agent import advance_notification_workflows


def scheduled_scan() -> None:
    with SessionLocal() as db:
        execute_scan(db, trigger="scheduled")
        db.add(AuditEvent(event_type="worker.heartbeat", entity_type="worker", entity_id="sentinel-scheduler", detail={"schedule": "scan"}))
        db.commit()


def sentinel_tick() -> None:
    with SessionLocal() as db:
        result = advance_notification_workflows(db)
        delegated = process_pending_tasks(db)
        db.add(AuditEvent(event_type="worker.heartbeat", entity_type="worker", entity_id="sentinel-scheduler", detail={"sentinel": result, "delegated_tasks": delegated}))
        db.commit()


def main() -> None:
    initialise_database()
    settings = get_settings()
    scheduler = BlockingScheduler(timezone=settings.schedule_timezone)
    scheduler.add_job(sentinel_tick, "interval", minutes=1, id="sentinel-tick", replace_existing=True)
    if settings.schedule_enabled:
        scheduler.add_job(scheduled_scan, "cron", hour=settings.schedule_hour, minute=0, id="scheduled-scan", replace_existing=True)
    scheduler.start()


if __name__ == "__main__":
    main()
