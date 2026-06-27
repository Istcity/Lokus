"""PostGIS spatial sorguları."""

from __future__ import annotations

import logging
from datetime import date
from typing import List, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from schemas.geo import (
    DataSource,
    InfrastructureData,
    LocationQueryResponse,
    ParcelInfo,
    POIData,
    ZoningResponse,
)

logger = logging.getLogger(__name__)


async def query_postgis(
    session: AsyncSession,
    lat: float,
    lng: float,
    radius_m: int,
) -> Optional[LocationQueryResponse]:
    """Koordinat için PostGIS ST_Contains / ST_DWithin sorguları."""
    parcel_row = await session.execute(
        text(
            """
            SELECT ada, parsel, yuzolcum, malik_ozet, kaynak, son_guncelleme
            FROM parcels
            WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326))
            ORDER BY yuzolcum ASC NULLS LAST
            LIMIT 1
            """
        ),
        {"lat": lat, "lng": lng},
    )
    parcel_data = parcel_row.mappings().first()

    zoning_row = await session.execute(
        text(
            """
            SELECT plan_notu, taks, kaks, yapilasma_turu, confidence_level,
                   kaynak_kurum, son_guncelleme
            FROM zoning_plans
            WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326))
            LIMIT 1
            """
        ),
        {"lat": lat, "lng": lng},
    )
    zoning_data = zoning_row.mappings().first()

    if not parcel_data and not zoning_data:
        return None

    infra_row = await session.execute(
        text(
            """
            SELECT
                bool_or(tur = 'yol') AS yol,
                bool_or(tur = 'su') AS su,
                bool_or(tur = 'elektrik') AS elektrik,
                bool_or(tur = 'dogalgaz') AS dogalgaz,
                bool_or(tur = 'fiber') AS fiber
            FROM infrastructure
            WHERE ST_DWithin(
                geom::geography,
                ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
                :radius
            )
            """
        ),
        {"lat": lat, "lng": lng, "radius": radius_m},
    )
    infra_data = infra_row.mappings().first() or {}

    sources: List[DataSource] = []
    if zoning_data and zoning_data.get("kaynak_kurum"):
        sources.append(
            DataSource(
                katman="imar",
                kaynak=zoning_data["kaynak_kurum"],
                guncelleme_tarihi=_as_date(zoning_data.get("son_guncelleme")),
                lisans="CC BY 4.0",
            )
        )
    if parcel_data and parcel_data.get("kaynak"):
        sources.append(
            DataSource(
                katman="parsel",
                kaynak=parcel_data["kaynak"],
                guncelleme_tarihi=_as_date(parcel_data.get("son_guncelleme")),
                lisans="Kamu Verisi",
            )
        )

    parcel = None
    if parcel_data:
        parcel = ParcelInfo(
            ada=parcel_data.get("ada"),
            parsel=parcel_data.get("parsel"),
            yuzolcum=float(parcel_data["yuzolcum"]) if parcel_data.get("yuzolcum") else None,
            malik_ozet=parcel_data.get("malik_ozet"),
            il="İstanbul",
            ilce="Kadıköy",
            confidence_level="high",
        )

    zoning = None
    if zoning_data:
        zoning = ZoningResponse(
            plan_notu=zoning_data.get("plan_notu"),
            taks=float(zoning_data["taks"]) if zoning_data.get("taks") is not None else None,
            kaks=float(zoning_data["kaks"]) if zoning_data.get("kaks") is not None else None,
            yapilasma_turu=zoning_data.get("yapilasma_turu"),
            son_guncelleme=zoning_data.get("son_guncelleme"),
            confidence_level=zoning_data.get("confidence_level", "medium"),
        )

    infra = InfrastructureData(
        yol=bool(infra_data.get("yol")),
        su=bool(infra_data.get("su")),
        elektrik=bool(infra_data.get("elektrik")),
        dogalgaz=bool(infra_data.get("dogalgaz")),
        fiber=bool(infra_data.get("fiber")),
        toplu_tasima=bool(infra_data.get("yol")),
    )

    return LocationQueryResponse(
        parcel=parcel,
        zoning=zoning,
        infrastructure=infra,
        poi=POIData(),
        data_sources=sources,
    )


def _as_date(value) -> date:
    if value is None:
        return date.today()
    if hasattr(value, "date"):
        return value.date()
    return date.today()
