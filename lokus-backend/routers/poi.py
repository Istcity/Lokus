"""Yakın çevre POI endpoint'i — Overpass proxy."""

from __future__ import annotations

from fastapi import APIRouter, Query, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from config import settings
from schemas.geo import POIData
from services.poi_service import fetch_poi

router = APIRouter(prefix="/api/poi", tags=["poi"])
limiter = Limiter(key_func=get_remote_address)


@router.get("", response_model=POIData, summary="Yakın çevre hizmet noktaları")
@limiter.limit(f"{settings.rate_limit_per_minute}/minute")
async def nearby_poi(
    request: Request,
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_m: int = Query(500, ge=100, le=5000),
) -> POIData:
    return await fetch_poi(lat, lng, radius_m)
