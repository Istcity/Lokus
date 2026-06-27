"""Ana koordinat sorgu endpoint'i."""

from typing import Optional

from fastapi import APIRouter, Depends, Query, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from deps import get_optional_db
from schemas.geo import LocationQueryResponse
from services.geo_service import query_location

router = APIRouter(prefix="/api", tags=["geo"])
limiter = Limiter(key_func=get_remote_address)


@router.get(
    "/query",
    response_model=LocationQueryResponse,
    summary="Koordinat analizi",
    description="""
    Seçilen koordinat için parsel, imar, altyapı ve POI katmanlarını döner.

    **Örnek (Kadıköy pilot):** `lat=40.9927&lng=29.0277&radius_m=500`

    **Örnek yanıt:**
    ```json
    {
      "parcel": {"ada": "1234", "parsel": "5", "yuzolcum": 450.0},
      "zoning": {"taks": 0.40, "kaks": 2.00, "yapilasma_turu": "Konut"},
      "infrastructure": {"yol": true, "su": true, "elektrik": true},
      "poi": {"okullar": [], "hastaneler": []},
      "data_sources": [{"katman": "imar", "kaynak": "İBB", "guncelleme_tarihi": "2025-06-01"}]
    }
    ```
    """,
)
@limiter.limit(f"{settings.rate_limit_per_minute}/minute")
async def query_location_endpoint(
    request: Request,
    lat: float = Query(..., ge=-90, le=90, description="Enlem (WGS84)"),
    lng: float = Query(..., ge=-180, le=180, description="Boylam (WGS84)"),
    radius_m: int = Query(500, ge=100, le=5000, description="POI arama yarıçapı (metre)"),
    db: Optional[AsyncSession] = Depends(get_optional_db),
) -> LocationQueryResponse:
    return await query_location(lat, lng, radius_m, db)
