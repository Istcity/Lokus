"""Mapbox Vector Tile sunucu."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from database import SessionLocal
from services.tile_service import fetch_mvt_tile

router = APIRouter(prefix="/tiles", tags=["tiles"])

ALLOWED_LAYERS = {"zoning", "parcels", "infrastructure"}


async def get_db_session() -> AsyncSession:
    async with SessionLocal() as session:
        yield session


@router.get("/{layer}/{z}/{x}/{y}.mvt", summary="Vector tile (MVT)")
async def serve_tile(
    layer: str,
    z: int,
    x: int,
    y: int,
    session: AsyncSession = Depends(get_db_session),
) -> Response:
    if layer not in ALLOWED_LAYERS:
        raise HTTPException(status_code=404, detail=f"Bilinmeyen katman: {layer}")
    if not (0 <= z <= 18):
        raise HTTPException(status_code=422, detail="Geçersiz zoom seviyesi")

    if settings.use_mock_data:
        return Response(content=b"", media_type="application/x-protobuf")

    tile_data = await fetch_mvt_tile(session, layer, z, x, y) or b""
    return Response(
        content=tile_data,
        media_type="application/x-protobuf",
        headers={"Cache-Control": "public, max-age=86400"},
    )
