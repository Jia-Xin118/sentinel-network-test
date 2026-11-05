from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from .config import get_settings
from .config import ROOT


class Base(DeclarativeBase):
    pass


def database_url() -> str:
    url = get_settings().database_url
    if url == "sqlite:///./sentinel.db":
        return f"sqlite:///{(ROOT / 'backend' / 'sentinel.db').as_posix()}"
    return url


def build_engine():
    url = database_url()
    return create_engine(url, connect_args={"check_same_thread": False} if url.startswith("sqlite") else {}, pool_pre_ping=True)


engine = build_engine()
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def initialise_database() -> None:
    from . import models  # noqa: F401
    Base.metadata.create_all(engine)
