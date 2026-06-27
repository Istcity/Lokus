"""TCMB fiyat referans testleri."""

import os

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_tcmb_status_without_key(monkeypatch):
    monkeypatch.delenv("TCMB_EVDS_API_KEY", raising=False)
    from config import settings

    settings.tcmb_evds_api_key = ""
    r = client.get("/api/prices/tcmb/status")
    assert r.status_code == 200
    assert r.json()["configured"] is False


def test_tcmb_province_istanbul():
    key = os.environ.get("TCMB_EVDS_API_KEY", "")
    if not key:
        return
    from config import settings

    settings.tcmb_evds_api_key = key
    r = client.get("/api/prices/tcmb/province/34")
    assert r.status_code == 200
    data = r.json()
    assert data["plateNumber"] == 34
    assert data["housePricePerM2"] > 50_000
