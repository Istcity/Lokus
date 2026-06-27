"""PostGIS ST_AsMVT vector tile üretimi."""

from __future__ import annotations

import logging
from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

LAYER_TABLE = {
    "zoning": ("zoning_plans", "zoning"),
    "parcels": ("parcels", "parcels"),
    "infrastructure": ("infrastructure", "infra"),
}


async def fetch_mvt_tile(
    session: AsyncSession,
    layer: str,
    z: int,
    x: int,
    y: int,
) -> Optional[bytes]:
    """Tek MVT karosu üretir."""
    if layer not in LAYER_TABLE:
        return None

    table, layer_name = LAYER_TABLE[layer]

    sql = text(
        f"""
        WITH bounds AS (
            SELECT ST_TileEnvelope(:z, :x, :y) AS geom
        ),
        mvtgeom AS (
            SELECT ST_AsMVTGeom(
                ST_Transform(t.geom, 3857),
                bounds.geom,
                4096, 256, true
            ) AS geom,
            to_jsonb(t.*) - 'geom' AS properties
            FROM {table} t, bounds
            WHERE ST_Intersects(t.geom, ST_Transform(bounds.geom, 4326))
        )
        SELECT ST_AsMVT(mvtgeom.*, :layer_name) AS tile
        FROM mvtgeom
        """
    )

    try:
        result = await session.execute(sql, {"z": z, "x": x, "y": y, "layer_name": layer_name})
        row = result.scalar()
        return bytes(row) if row else b""
    except Exception as exc:
        logger.warning("MVT üretim hatası %s/%s/%s/%s: %s", layer, z, x, y, exc)
        return b""
