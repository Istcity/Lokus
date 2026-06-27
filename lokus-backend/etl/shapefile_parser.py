"""Shapefile → GeoJSON dönüştürücü (Fiona opsiyonel)."""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any, Dict

logger = logging.getLogger(__name__)


def shapefile_to_geojson(path: Path) -> Dict[str, Any]:
    """Shapefile'ı GeoJSON FeatureCollection'a çevirir."""
    try:
        import fiona
        from fiona.transform import transform_geom
        from shapely.geometry import mapping, shape
    except ImportError as exc:
        raise RuntimeError("fiona/shapely gerekli: pip install fiona") from exc

    features = []
    with fiona.open(path) as src:
        for feat in src:
            geom = transform_geom(src.crs, "EPSG:4326", feat["geometry"])
            features.append({"type": "Feature", "geometry": geom, "properties": dict(feat["properties"])})

    return {"type": "FeatureCollection", "features": features}


def save_geojson(collection: Dict[str, Any], output: Path) -> None:
    output.write_text(json.dumps(collection, ensure_ascii=False, indent=2), encoding="utf-8")
