"""Parsel ORM modeli."""

from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class ParcelRecord(Base):
    __tablename__ = "parcels"

    id: Mapped[int] = mapped_column(primary_key=True)
    il_kodu: Mapped[str] = mapped_column(String(2))
    ilce_kodu: Mapped[str] = mapped_column(String(4))
    mahalle_kodu: Mapped[str | None] = mapped_column(String(12), nullable=True)
    ada: Mapped[str | None] = mapped_column(String(10), nullable=True)
    parsel: Mapped[str | None] = mapped_column(String(10), nullable=True)
    yuzolcum: Mapped[float | None] = mapped_column(Numeric(12, 2), nullable=True)
    malik_ozet: Mapped[str | None] = mapped_column(String(255), nullable=True)
    geom = mapped_column(Geometry("POLYGON", srid=4326))
    son_guncelleme: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    kaynak: Mapped[str | None] = mapped_column(String(100), nullable=True)
