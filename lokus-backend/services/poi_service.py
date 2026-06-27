"""Overpass API ile yakın çevre POI — backend proxy."""

from __future__ import annotations

import logging
from typing import Dict, List, Optional

import aiohttp

from schemas.geo import POIData, POIItem

logger = logging.getLogger(__name__)

OVERPASS_URL = "https://overpass-api.de/api/interpreter"

CATEGORY_MAP = {
    "school": "okullar",
    "kindergarten": "okullar",
    "hospital": "hastaneler",
    "clinic": "hastaneler",
    "pharmacy": "hastaneler",
    "supermarket": "marketler",
    "convenience": "marketler",
    "park": "parklar",
    "bus_stop": "duraklar",
    "tram_stop": "duraklar",
    "subway_entrance": "duraklar",
}


async def fetch_poi(lat: float, lng: float, radius_m: int = 500) -> POIData:
    """OpenStreetMap Overpass üzerinden POI çeker."""
    query = f"""
    [out:json][timeout:15];
    (
      node["amenity"~"school|kindergarten|hospital|clinic|pharmacy"](around:{radius_m},{lat},{lng});
      node["shop"~"supermarket|convenience"](around:{radius_m},{lat},{lng});
      node["leisure"="park"](around:{radius_m},{lat},{lng});
      node["highway"="bus_stop"](around:{radius_m},{lat},{lng});
      node["railway"~"tram_stop|station"](around:{radius_m},{lat},{lng});
    );
    out body 30;
    """
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(OVERPASS_URL, data={"data": query}, timeout=aiohttp.ClientTimeout(total=20)) as resp:
                if resp.status != 200:
                    logger.warning("Overpass HTTP %s", resp.status)
                    return POIData()
                payload = await resp.json()
    except Exception as exc:
        logger.warning("Overpass hatası: %s", exc)
        return POIData()

    return _parse_overpass(payload, lat, lng)


def _parse_overpass(payload: dict, lat: float, lng: float) -> POIData:
    buckets: Dict[str, List[POIItem]] = {
        "okullar": [],
        "hastaneler": [],
        "marketler": [],
        "parklar": [],
        "duraklar": [],
    }

    for element in payload.get("elements", []):
        if element.get("type") != "node":
            continue
        tags = element.get("tags", {})
        category_key = _resolve_category(tags)
        if not category_key:
            continue

        name = tags.get("name") or tags.get("brand") or category_key.capitalize()
        elat = element.get("lat", lat)
        elng = element.get("lon", lng)
        distance = _approx_distance_m(lat, lng, elat, elng)

        item = POIItem(
            name=name,
            category=category_key,
            distance_m=distance,
            lat=elat,
            lng=elng,
        )
        buckets[category_key].append(item)

    for key in buckets:
        buckets[key] = sorted(buckets[key], key=lambda x: x.distance_m)[:10]

    return POIData(
        okullar=buckets["okullar"],
        hastaneler=buckets["hastaneler"],
        marketler=buckets["marketler"],
        parklar=buckets["parklar"],
        duraklar=buckets["duraklar"],
    )


def _resolve_category(tags: dict) -> Optional[str]:
    amenity = tags.get("amenity", "")
    shop = tags.get("shop", "")
    leisure = tags.get("leisure", "")
    highway = tags.get("highway", "")
    railway = tags.get("railway", "")

    for key in (amenity, shop, leisure, highway, railway):
        if key in CATEGORY_MAP:
            return CATEGORY_MAP[key]
    return None


def _approx_distance_m(lat1: float, lng1: float, lat2: float, lng2: float) -> int:
    from math import cos, radians, sqrt

    dx = (lng2 - lng1) * 111_320 * cos(radians((lat1 + lat2) / 2))
    dy = (lat2 - lat1) * 110_540
    return int(sqrt(dx * dx + dy * dy))
