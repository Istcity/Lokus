"""Geo query API testleri."""

import pytest
from httpx import ASGITransport, AsyncClient

from main import app


@pytest.mark.asyncio
async def test_kadikoy_returns_parcel_and_zoning():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/query", params={"lat": 40.9927, "lng": 29.0277})
    assert response.status_code == 200
    data = response.json()
    assert data["parcel"]["ada"] == "1234"
    assert data["zoning"]["taks"] == 0.40
    assert len(data["data_sources"]) >= 1


@pytest.mark.asyncio
async def test_sea_returns_null_parcel():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/query", params={"lat": 40.80, "lng": 29.10})
    assert response.status_code == 200
    assert response.json()["parcel"] is None


@pytest.mark.asyncio
async def test_invalid_lat_returns_422():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/query", params={"lat": 999, "lng": 29.0})
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_health():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
