"""Aylık ETL zamanlayıcı."""

from __future__ import annotations

import logging

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from sqlalchemy.ext.asyncio import AsyncSession

from database import SessionLocal
from etl.wfs_fetcher import run_full_etl

logger = logging.getLogger(__name__)
scheduler = AsyncIOScheduler()


async def _monthly_job() -> None:
    async with SessionLocal() as session:
        try:
            results = await run_full_etl(session)
            logger.info("Aylık ETL tamamlandı: %s", results)
        except Exception as exc:
            logger.error("Aylık ETL hatası: %s", exc)


@scheduler.scheduled_job("cron", day=1, hour=3)
async def monthly_update() -> None:
    await _monthly_job()


def start_scheduler() -> None:
    if not scheduler.running:
        scheduler.start()
        logger.info("ETL scheduler başlatıldı (her ayın 1'i 03:00)")
