#!/usr/bin/env python3
"""PostGIS şemasını oluşturur."""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from config import settings

SCHEMA = (Path(__file__).resolve().parent.parent / "migrations" / "001_initial_schema.sql").read_text()


async def main() -> None:
    engine = create_async_engine(settings.database_url, echo=True)
    async with engine.begin() as conn:
        for statement in SCHEMA.split(";"):
            stmt = statement.strip()
            if stmt:
                await conn.execute(text(stmt))
    await engine.dispose()
    print("PostGIS şema oluşturuldu.")


if __name__ == "__main__":
    asyncio.run(main())
