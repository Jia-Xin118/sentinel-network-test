from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import Observation


def sync_synthetic_records(db: Session) -> tuple[list[Observation], dict]:
    """Controlled synthetic source retrieval. A production connector is intentionally absent."""
    records = list(db.scalars(select(Observation).order_by(Observation.ingested_at)).all())
    return records, {"stage": "sync", "state": "completed", "records_received": len(records), "source": "synthetic-fixture"}
