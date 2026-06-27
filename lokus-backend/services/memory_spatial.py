"""Shapely tabanlı bellek içi spatial sorgu — PostGIS olmadan pilot."""

from __future__ import annotations

import json
import logging
from datetime import date, datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from shapely.geometry import LineString, Point, shape
from shapely.strtree import STRtree

from schemas.geo import (
    DataSource,
    InfrastructureData,
    LocationQueryResponse,
    ParcelInfo,
    POIData,
    ZoningResponse,
)

logger = logging.getLogger(__name__)
SEED_DIR = Path(__file__).resolve().parent.parent / "data" / "seeds"


@lru_cache(maxsize=1)
def _load_layers() -> Tuple[List[Any], List[Any], List[Any]]:
    zoning = _load_features(SEED_DIR / "kadikoy_zoning.geojson")
    parcels = _load_features(SEED_DIR / "kadikoy_parcels.geojson")
    infra = _load_features(SEED_DIR / "kadikoy_infrastructure.geojson")
    return zoning, parcels, infra


def _load_features(path: Path) -> List[Tuple[Any, Dict[str, Any]]]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    items = []
    for feature in data.get("features", []):
        try:
            items.append((shape(feature["geometry"]), feature.get("properties", {})))
        except Exception as exc:
            logger.warning("Geometri atlandı %s: %s", path.name, exc)
    return items


def _contains(items: List[Tuple[Any, Dict]], point: Point) -> Optional[Dict]:
    for geom, props in items:
        if geom.contains(point) or geom.distance(point) < 0.00005:
            return props
    return None


def _nearby_infra(items: List[Tuple[Any, Dict]], point: Point, radius_deg: float = 0.003) -> InfrastructureData:
    flags = {"yol": False, "su": False, "elektrik": False, "dogalgaz": False, "fiber": False}
    for geom, props in items:
        if geom.distance(point) <= radius_deg:
            tur = props.get("tur")
            if tur in flags:
                flags[tur] = True
    return InfrastructureData(
        yol=flags["yol"],
        su=flags["su"],
        elektrik=flags["elektrik"],
        dogalgaz=flags["dogalgaz"],
        fiber=flags["fiber"],
        toplu_tasima=flags["yol"],
    )


def memory_query(lat: float, lng: float, radius_m: int = 500) -> Optional[LocationQueryResponse]:
    """Seed GeoJSON ile bellek içi sorgu. Kadıköy pilot alanı dışında None."""
    point = Point(lng, lat)
    zoning_items, parcel_items, infra_items = _load_layers()

    if not zoning_items and not parcel_items:
        return None

    z_props = _contains(zoning_items, point)
    p_props = _contains(parcel_items, point)
    if not z_props and not p_props:
        return None

    now = datetime.now(timezone.utc)
    sources = [
        DataSource(
            katman="imar",
            kaynak="İBB Açık Veri Portalı (seed)",
            guncelleme_tarihi=date(2025, 6, 1),
            lisans="CC BY 4.0",
        ),
        DataSource(
            katman="parsel",
            kaynak="TKGM WFS (seed)",
            guncelleme_tarihi=date(2025, 5, 15),
            lisans="Kamu Verisi",
        ),
    ]

    parcel = None
    if p_props:
        parcel = ParcelInfo(
            ada=p_props.get("ada"),
            parsel=p_props.get("parsel"),
            yuzolcum=float(p_props["yuzolcum"]) if p_props.get("yuzolcum") else None,
            malik_ozet=p_props.get("malik_ozet"),
            il="İstanbul",
            ilce="Kadıköy",
            mahalle="Caferağa",
            confidence_level="high",
        )

    zoning = None
    if z_props:
        zoning = ZoningResponse(
            plan_notu=z_props.get("plan_notu"),
            taks=float(z_props["taks"]) if z_props.get("taks") is not None else None,
            kaks=float(z_props["kaks"]) if z_props.get("kaks") is not None else None,
            yapilasma_turu=z_props.get("yapilasma_turu"),
            max_kat=z_props.get("max_kat"),
            son_guncelleme=now,
            confidence_level=z_props.get("confidence_level", "high"),
        )

    infra = _nearby_infra(infra_items, point)

    return LocationQueryResponse(
        parcel=parcel,
        zoning=zoning,
        infrastructure=infra,
        poi=POIData(),
        data_sources=sources,
    )
