"""GeoJSON seed dosyalarını PostGIS'e yükler."""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from etl.geojson_normalizer import (
    file_hash,
    load_geojson,
    normalize_infrastructure_features,
    normalize_parcel_features,
    normalize_zoning_features,
)

logger = logging.getLogger(__name__)

SEED_DIR = Path(__file__).resolve().parent.parent / "data" / "seeds"


async def upsert_zoning(session: AsyncSession, rows: list) -> int:
    count = 0
    for row in rows:
        await session.execute(
            text(
                """
                INSERT INTO zoning_plans
                    (il_kodu, plan_notu, taks, kaks, yapilasma_turu, confidence_level,
                     geom, son_guncelleme, kaynak_kurum, veri_hash)
                VALUES
                    (:il_kodu, :plan_notu, :taks, :kaks, :yapilasma_turu, :confidence_level,
                     ST_SetSRID(ST_GeomFromGeoJSON(:geom_geojson), 4326), :son_guncelleme,
                     :kaynak_kurum, :veri_hash)
                """
            ),
            row,
        )
        count += 1
    return count


async def upsert_parcels(session: AsyncSession, rows: list) -> int:
    count = 0
    for row in rows:
        await session.execute(
            text(
                """
                INSERT INTO parcels
                    (il_kodu, ilce_kodu, mahalle_kodu, ada, parsel, yuzolcum, malik_ozet,
                     geom, son_guncelleme, kaynak)
                VALUES
                    (:il_kodu, :ilce_kodu, :mahalle_kodu, :ada, :parsel, :yuzolcum, :malik_ozet,
                     ST_SetSRID(ST_GeomFromGeoJSON(:geom_geojson), 4326), :son_guncelleme, :kaynak)
                """
            ),
            row,
        )
        count += 1
    return count


async def upsert_infrastructure(session: AsyncSession, rows: list) -> int:
    count = 0
    for row in rows:
        await session.execute(
            text(
                """
                INSERT INTO infrastructure (tur, geom, kaynak, son_guncelleme)
                VALUES (:tur, ST_SetSRID(ST_GeomFromGeoJSON(:geom_geojson), 4326), :kaynak, :son_guncelleme)
                """
            ),
            row,
        )
        count += 1
    return count


async def log_etl(session: AsyncSession, source: str, records: int, data_hash: str, status: str) -> None:
    await session.execute(
        text(
            """
            INSERT INTO etl_update_log (source_name, records_upserted, data_hash, started_at, finished_at, status)
            VALUES (:source, :records, :hash, NOW(), NOW(), :status)
            """
        ),
        {"source": source, "records": records, "hash": data_hash, "status": status},
    )


async def load_seed_file(session: AsyncSession, path: Path, layer: str) -> int:
    """Tek seed dosyasını yükler; hash değişmediyse atlar."""
    if not path.exists():
        logger.warning("Seed dosyası yok: %s", path)
        return 0

    digest = file_hash(path)
    existing = await session.execute(
        text("SELECT id FROM etl_update_log WHERE source_name = :name AND data_hash = :hash LIMIT 1"),
        {"name": path.name, "hash": digest},
    )
    if existing.first():
        logger.info("Seed atlandı (değişmedi): %s", path.name)
        return 0

    collection = load_geojson(path)
    if layer == "zoning":
        rows = normalize_zoning_features(collection)
        count = await upsert_zoning(session, rows)
    elif layer == "parcels":
        rows = normalize_parcel_features(collection)
        count = await upsert_parcels(session, rows)
    elif layer == "infrastructure":
        rows = normalize_infrastructure_features(collection)
        count = await upsert_infrastructure(session, rows)
    else:
        return 0

    await log_etl(session, path.name, count, digest, "success")
    return count


async def load_all_seeds(session: AsyncSession) -> dict:
    """Tüm pilot seed dosyalarını yükler."""
    results = {}
    for layer, filename in [
        ("zoning", "kadikoy_zoning.geojson"),
        ("parcels", "kadikoy_parcels.geojson"),
        ("infrastructure", "kadikoy_infrastructure.geojson"),
    ]:
        path = SEED_DIR / filename
        results[filename] = await load_seed_file(session, path, layer)
    await session.commit()
    return results
