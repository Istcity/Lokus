"""İmar planı ORM modeli."""

from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class ZoningPlanRecord(Base):
    __tablename__ = "zoning_plans"

    id: Mapped[int] = mapped_column(primary_key=True)
    il_kodu: Mapped[str] = mapped_column(String(2))
    plan_notu: Mapped[str | None] = mapped_column(Text, nullable=True)
    taks: Mapped[float | None] = mapped_column(Numeric(4, 2), nullable=True)
    kaks: Mapped[float | None] = mapped_column(Numeric(4, 2), nullable=True)
    yapilasma_turu: Mapped[str | None] = mapped_column(String(50), nullable=True)
    confidence_level: Mapped[str] = mapped_column(String(10), default="medium")
    geom = mapped_column(Geometry("MULTIPOLYGON", srid=4326))
    son_guncelleme: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    kaynak_kurum: Mapped[str | None] = mapped_column(String(150), nullable=True)
    veri_hash: Mapped[str | None] = mapped_column(String(64), nullable=True)
