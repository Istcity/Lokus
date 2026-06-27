"""GeoJSON katman endpoint — iOS harita overlay."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from services.layer_geojson import fetch_layer_geojson

router = APIRouter(prefix="/api/layers", tags=["layers"])

ALLOWED = {"zoning", "parcels", "infrastructure"}


@router.get("/{layer}/geojson", summary="Bbox GeoJSON katmanı")
async def layer_geojson(
    layer: str,
    min_lng: float = Query(..., description="Batı sınırı"),
    min_lat: float = Query(..., description="Güney sınırı"),
    max_lng: float = Query(..., description="Doğu sınırı"),
    max_lat: float = Query(..., description="Kuzey sınırı"),
) -> dict:
    if layer not in ALLOWED:
        raise HTTPException(status_code=404, detail=f"Bilinmeyen katman: {layer}")
    if min_lng >= max_lng or min_lat >= max_lat:
        raise HTTPException(status_code=422, detail="Geçersiz bbox")

    data = fetch_layer_geojson(layer, min_lng, min_lat, max_lng, max_lat)
    if data is None:
        return {"type": "FeatureCollection", "features": []}
    return data
