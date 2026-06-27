"""WFS / açık veri kaynakları — ETL."""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Dict

from sqlalchemy.ext.asyncio import AsyncSession

from etl.load_seed import SEED_DIR, load_all_seeds, load_seed_file

logger = logging.getLogger(__name__)

WFS_SOURCES = [
    {
        "name": "IBB_IMAR_SEED",
        "path": SEED_DIR / "kadikoy_zoning.geojson",
        "layer": "zoning",
        "update_frequency": "monthly",
        "license": "CC BY 4.0",
        "attribution": "İstanbul Büyükşehir Belediyesi Açık Veri Portalı",
    },
    {
        "name": "TKGM_PARCEL_SEED",
        "path": SEED_DIR / "kadikoy_parcels.geojson",
        "layer": "parcels",
        "update_frequency": "monthly",
        "license": "Kamu Verisi",
        "attribution": "TKGM",
    },
    {
        "name": "INFRA_SEED",
        "path": SEED_DIR / "kadikoy_infrastructure.geojson",
        "layer": "infrastructure",
        "update_frequency": "monthly",
        "license": "Pilot",
        "attribution": "Lokus Seed",
    },
]


async def fetch_and_store(session: AsyncSession, source: Dict[str, Any]) -> int:
    """Tek kaynağı indir/yükle; hash değişmediyse atla."""
    path = Path(source["path"])
    layer = source["layer"]
    count = await load_seed_file(session, path, layer)
    await session.commit()
    logger.info("ETL %s: %s kayıt", source["name"], count)
    return count


async def run_full_etl(session: AsyncSession) -> Dict[str, int]:
    """Tüm kaynakları sırayla yükler."""
    results: Dict[str, int] = {}
    for source in WFS_SOURCES:
        results[source["name"]] = await fetch_and_store(session, source)
    return results


async def run_seed_bootstrap(session: AsyncSession) -> Dict[str, int]:
    """Pilot seed paketini tek seferde yükler."""
    return await load_all_seeds(session)
