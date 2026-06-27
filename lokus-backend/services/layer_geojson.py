"""Bbox GeoJSON katman servisi — harita overlay için."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional

from shapely.geometry import box, mapping, shape

from services.memory_spatial import SEED_DIR, _load_features

LAYER_FILES = {
    "zoning": SEED_DIR / "kadikoy_zoning.geojson",
    "parcels": SEED_DIR / "kadikoy_parcels.geojson",
    "infrastructure": SEED_DIR / "kadikoy_infrastructure.geojson",
}


def _bbox_filter(
    items: List[Any],
    min_lng: float,
    min_lat: float,
    max_lng: float,
    max_lat: float,
) -> Dict[str, Any]:
    bounds = box(min_lng, min_lat, max_lng, max_lat)
    features = []
    for geom, props in items:
        if not bounds.intersects(geom):
            continue
        features.append(
            {
                "type": "Feature",
                "geometry": mapping(geom),
                "properties": props,
            }
        )
    return {"type": "FeatureCollection", "features": features}


def fetch_layer_geojson(
    layer: str,
    min_lng: float,
    min_lat: float,
    max_lng: float,
    max_lat: float,
) -> Optional[Dict[str, Any]]:
    """Seed GeoJSON'dan bbox içindeki özellikleri döner."""
    path = LAYER_FILES.get(layer)
    if path is None:
        return None
    items = _load_features(path)
    if not items:
        return None
    return _bbox_filter(items, min_lng, min_lat, max_lng, max_lat)
