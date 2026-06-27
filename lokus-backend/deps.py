"""Opsiyonel DB oturumu — mock modda PostGIS gerekmez."""

from collections.abc import AsyncGenerator
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from database import SessionLocal


async def get_optional_db() -> AsyncGenerator[Optional[AsyncSession], None]:
    if settings.use_mock_data:
        yield None
        return
    async with SessionLocal() as session:
        yield session
