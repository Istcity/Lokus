"""Admin — ETL ve bakım endpoint'leri."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from database import SessionLocal
from etl.wfs_fetcher import run_full_etl, run_seed_bootstrap

router = APIRouter(prefix="/admin", tags=["admin"])


async def get_db_session() -> AsyncSession:
    async with SessionLocal() as session:
        yield session


@router.post("/etl/run", summary="ETL pipeline'ını manuel çalıştır")
async def run_etl(session: AsyncSession = Depends(get_db_session)):
    if settings.use_mock_data:
        raise HTTPException(
            status_code=400,
            detail="USE_MOCK_DATA=true iken ETL çalıştırılamaz. .env içinde false yapın.",
        )
    try:
        results = await run_full_etl(session)
        return {"status": "ok", "results": results}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.post("/etl/bootstrap", summary="Pilot seed verisini PostGIS'e yükle")
async def bootstrap_seeds(session: AsyncSession = Depends(get_db_session)):
    try:
        results = await run_seed_bootstrap(session)
        return {"status": "ok", "loaded": results}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
