from collections import defaultdict

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..guideline_tree import assessment
from ..models import Observation, Patient


def analyse_patients(db: Session) -> tuple[list[tuple[Patient, dict]], dict]:
    by_patient: dict[str, list[Observation]] = defaultdict(list)
    for observation in db.scalars(select(Observation).order_by(Observation.observed_at)).all():
        by_patient[observation.patient_id].append(observation)
    results = []
    for patient in db.scalars(select(Patient)).all():
        results.append((patient, assessment(patient, by_patient.get(patient.id, []))))
    return results, {"stage": "analyse", "state": "completed", "patients_evaluated": len(results), "engine": "deterministic-cpg-review-tree"}
