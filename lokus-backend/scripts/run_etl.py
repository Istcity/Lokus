#!/usr/bin/env python3
"""ETL pipeline — seed yükleme."""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from database import SessionLocal
from etl.wfs_fetcher import run_full_etl


async def main() -> None:
    async with SessionLocal() as session:
        results = await run_full_etl(session)
        print("ETL sonuçları:", results)


if __name__ == "__main__":
    asyncio.run(main())
