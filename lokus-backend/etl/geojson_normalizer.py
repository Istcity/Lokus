"""GeoJSON → PostGIS normalizer."""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def file_hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_geojson(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_zoning_features(collection: Dict[str, Any]) -> List[Dict[str, Any]]:
    rows = []
    now = datetime.now(timezone.utc)
    for feature in collection.get("features", []):
        props = feature.get("properties", {})
        geom = json.dumps(feature["geometry"])
        rows.append(
            {
                "il_kodu": props.get("il_kodu", "34"),
                "plan_notu": props.get("plan_notu"),
                "taks": props.get("taks"),
                "kaks": props.get("kaks"),
                "yapilasma_turu": props.get("yapilasma_turu"),
                "confidence_level": props.get("confidence_level", "medium"),
                "geom_geojson": geom,
                "son_guncelleme": now,
                "kaynak_kurum": props.get("kaynak_kurum", "seed"),
                "veri_hash": hashlib.sha256(geom.encode()).hexdigest()[:16],
            }
        )
    return rows


def normalize_parcel_features(collection: Dict[str, Any]) -> List[Dict[str, Any]]:
    rows = []
    now = datetime.now(timezone.utc)
    for feature in collection.get("features", []):
        props = feature.get("properties", {})
        geom = json.dumps(feature["geometry"])
        rows.append(
            {
                "il_kodu": props.get("il_kodu"),
                "ilce_kodu": props.get("ilce_kodu"),
                "mahalle_kodu": props.get("mahalle_kodu"),
                "ada": props.get("ada"),
                "parsel": props.get("parsel"),
                "yuzolcum": props.get("yuzolcum"),
                "malik_ozet": props.get("malik_ozet"),
                "geom_geojson": geom,
                "son_guncelleme": now,
                "kaynak": props.get("kaynak", "seed"),
            }
        )
    return rows


def normalize_infrastructure_features(collection: Dict[str, Any]) -> List[Dict[str, Any]]:
    rows = []
    now = datetime.now(timezone.utc)
    for feature in collection.get("features", []):
        props = feature.get("properties", {})
        geom = json.dumps(feature["geometry"])
        rows.append(
            {
                "tur": props.get("tur"),
                "geom_geojson": geom,
                "kaynak": props.get("kaynak", "seed"),
                "son_guncelleme": now,
            }
        )
    return rows
