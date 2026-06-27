"""Coğrafi sorgu servisi — PostGIS, bellek seed veya mock."""

from __future__ import annotations

import logging
from datetime import date
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from schemas.geo import DataSource, LocationQueryResponse, POIData
from services.memory_spatial import memory_query
from services.mock_data import mock_query
from services.poi_service import fetch_poi
from services.spatial_query import query_postgis

logger = logging.getLogger(__name__)


async def query_location(
    lat: float,
    lng: float,
    radius_m: int,
    db: Optional[AsyncSession] = None,
) -> LocationQueryResponse:
    """
    Koordinat için tüm katmanları döner.
    Öncelik: PostGIS → bellek seed → mock.
    POI: Overpass API (backend proxy).
    """
    result: Optional[LocationQueryResponse] = None

    if settings.use_mock_data:
        result = mock_query(lat, lng, radius_m)
    else:
        if db is not None:
            try:
                result = await query_postgis(db, lat, lng, radius_m)
            except Exception as exc:
                logger.warning("PostGIS sorgu hatası: %s", exc)

        if result is None:
            result = memory_query(lat, lng, radius_m)

        if result is None:
            result = mock_query(lat, lng, radius_m)

    poi = await fetch_poi(lat, lng, radius_m)
    return _merge_poi(result, poi)


def _merge_poi(result: LocationQueryResponse, poi: POIData) -> LocationQueryResponse:
    has_existing = any([
        result.poi.okullar,
        result.poi.hastaneler,
        result.poi.marketler,
        result.poi.parklar,
        result.poi.duraklar,
    ])
    if has_existing:
        return result

    sources = list(result.data_sources)
    if any([poi.okullar, poi.hastaneler, poi.marketler, poi.parklar, poi.duraklar]):
        sources.append(
            DataSource(
                katman="poi",
                kaynak="OpenStreetMap / Overpass API",
                guncelleme_tarihi=date.today(),
                lisans="ODbL",
            )
        )

    return LocationQueryResponse(
        parcel=result.parcel,
        zoning=result.zoning,
        infrastructure=result.infrastructure,
        poi=poi,
        data_sources=sources,
        cached=result.cached,
    )
