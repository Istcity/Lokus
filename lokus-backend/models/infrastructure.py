"""Altyapı ORM modeli."""

from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, String
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class InfrastructureRecord(Base):
    __tablename__ = "infrastructure"

    id: Mapped[int] = mapped_column(primary_key=True)
    tur: Mapped[str] = mapped_column(String(30))
    geom = mapped_column(Geometry("LINESTRING", srid=4326))
    kaynak: Mapped[str | None] = mapped_column(String(100), nullable=True)
    son_guncelleme: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
