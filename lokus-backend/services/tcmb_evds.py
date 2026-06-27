"""TCMB EVDS3 — Konut birim fiyatları (ücretsiz resmi kaynak)."""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Any

import httpx

from config import settings

EVDS3_BASE = "https://evds3.tcmb.gov.tr/igmevdsms-dis/"
UNIT_PRICE_GROUP = "bie_birimfiyat"
KFE_GROUP = "bie_kfe"

# Plaka → EVDS alan soneki (TP_BIRIMFIYAT_*)
PLATE_TO_FIELD_SUFFIX: dict[int, str] = {
    1: "ADANA", 2: "ADIYAMAN", 3: "AFYON", 4: "AGRI", 5: "AMASYA", 6: "ANK",
    7: "ANTALYA", 8: "ARTVIN", 9: "AYDIN", 10: "BALIKESIR", 11: "BILECIK",
    12: "BINGOL", 13: "BITLIS", 14: "BOLU", 15: "BURDUR", 16: "BURSA",
    17: "CANAKKALE", 18: "CANKIRI", 19: "CORUM", 20: "DENIZLI", 21: "DIYARBAKIR",
    22: "EDIRNE", 23: "ELAZIG", 24: "ERZINCAN", 25: "ERZURUM", 26: "ESKISEHIR",
    27: "ANTEP", 28: "GIRESUN", 29: "GUMUSHANE", 30: "HAKKARI", 31: "HATAY",
    32: "ISPARTA", 33: "MERSIN", 34: "IST", 35: "IZM", 36: "KARS", 37: "KASTAMONU",
    38: "KAYSERI", 39: "KIRKLARELI", 40: "KIRSEHIR", 41: "KOCAELI", 42: "KONYA",
    43: "KUTAHYA", 44: "MALATYA", 45: "MANISA", 46: "MARAS", 47: "MARDIN",
    48: "MUGLA", 49: "MUS", 50: "NEVSEHIR", 51: "NIGDE", 52: "ORDU", 53: "RIZE",
    54: "SAKARYA", 55: "SAMSUN", 56: "SIIRT", 57: "SINOP", 58: "SIVAS",
    59: "TEKIRDAG", 60: "TOKAT", 61: "TRABZON", 62: "TUNCELI", 63: "URFA",
    64: "USAK", 65: "VAN", 66: "YOZGAT", 67: "ZONGULDAK", 68: "AKSARAY",
    69: "BAYBURT", 70: "KARAMAN", 71: "KIRIKKALE", 72: "BATMAN", 73: "SIRNAK",
    74: "BARTIN", 75: "ARDAHAN", 76: "IGDIR", 77: "YALOVA", 78: "KARABUK",
    79: "KILIS", 80: "OSMANIYE", 81: "DUZCE",
}

PLATE_TO_NAME: dict[int, str] = {
    1: "Adana", 2: "Adıyaman", 3: "Afyonkarahisar", 4: "Ağrı", 5: "Amasya",
    6: "Ankara", 7: "Antalya", 8: "Artvin", 9: "Aydın", 10: "Balıkesir",
    11: "Bilecik", 12: "Bingöl", 13: "Bitlis", 14: "Bolu", 15: "Burdur",
    16: "Bursa", 17: "Çanakkale", 18: "Çankırı", 19: "Çorum", 20: "Denizli",
    21: "Diyarbakır", 22: "Edirne", 23: "Elazığ", 24: "Erzincan", 25: "Erzurum",
    26: "Eskişehir", 27: "Gaziantep", 28: "Giresun", 29: "Gümüşhane", 30: "Hakkâri",
    31: "Hatay", 32: "Isparta", 33: "Mersin", 34: "İstanbul", 35: "İzmir",
    36: "Kars", 37: "Kastamonu", 38: "Kayseri", 39: "Kırklareli", 40: "Kırşehir",
    41: "Kocaeli", 42: "Konya", 43: "Kütahya", 44: "Malatya", 45: "Manisa",
    46: "Kahramanmaraş", 47: "Mardin", 48: "Muğla", 49: "Muş", 50: "Nevşehir",
    51: "Niğde", 52: "Ordu", 53: "Rize", 54: "Sakarya", 55: "Samsun", 56: "Siirt",
    57: "Sinop", 58: "Sivas", 59: "Tekirdağ", 60: "Tokat", 61: "Trabzon",
    62: "Tunceli", 63: "Şanlıurfa", 64: "Uşak", 65: "Van", 66: "Yozgat",
    67: "Zonguldak", 68: "Aksaray", 69: "Bayburt", 70: "Karaman", 71: "Kırıkkale",
    72: "Batman", 73: "Şırnak", 74: "Bartın", 75: "Ardahan", 76: "Iğdır",
    77: "Yalova", 78: "Karabük", 79: "Kilis", 80: "Osmaniye", 81: "Düzce",
}

_cache: dict[str, Any] = {}
_cache_expiry: datetime | None = None
_cache_lock = asyncio.Lock()
CACHE_HOURS = 24


def is_configured() -> bool:
    return bool(settings.tcmb_evds_api_key)


def _field_for_plate(plate: int) -> str | None:
    suffix = PLATE_TO_FIELD_SUFFIX.get(plate)
    if not suffix:
        return None
    return f"TP_BIRIMFIYAT_{suffix}"


async def _fetch_datagroup(group: str, months_back: int = 24) -> list[dict[str, Any]]:
    if not settings.tcmb_evds_api_key:
        return []

    end = datetime.now(timezone.utc)
    start = end - timedelta(days=months_back * 31)
    url = (
        f"{EVDS3_BASE}datagroup={group}"
        f"&startDate={start.strftime('%d-%m-%Y')}"
        f"&endDate={end.strftime('%d-%m-%Y')}"
        f"&type=json"
    )
    headers = {"key": settings.tcmb_evds_api_key}

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.get(url, headers=headers)
        response.raise_for_status()
        payload = response.json()

    items = payload.get("items") if isinstance(payload, dict) else None
    return items if isinstance(items, list) else []


async def _load_unit_prices() -> list[dict[str, Any]]:
    global _cache_expiry
    async with _cache_lock:
        now = datetime.now(timezone.utc)
        if _cache.get("unit_prices") and _cache_expiry and now < _cache_expiry:
            return _cache["unit_prices"]

        rows = await _fetch_datagroup(UNIT_PRICE_GROUP)
        _cache["unit_prices"] = rows
        _cache_expiry = now + timedelta(hours=CACHE_HOURS)
        return rows


def _latest_value(rows: list[dict[str, Any]], field: str) -> tuple[float | None, str | None]:
    for row in reversed(rows):
        raw = row.get(field)
        period = row.get("Tarih")
        if raw is None:
            continue
        try:
            value = float(raw)
            if value > 0:
                return value, str(period) if period else None
        except (TypeError, ValueError):
            continue
    return None, None


async def get_province_unit_price(plate: int) -> dict[str, Any] | None:
    field = _field_for_plate(plate)
    if not field:
        return None

    rows = await _load_unit_prices()
    if not rows:
        return None

    value, period = _latest_value(rows, field)
    if value is None:
        return None

    return {
        "plateNumber": plate,
        "provinceName": PLATE_TO_NAME.get(plate, str(plate)),
        "housePricePerM2": round(value),
        "period": period,
        "source": "TCMB EVDS — Konut Birim Fiyatları (ortanca m²)",
        "isOfficial": True,
        "field": field,
    }


async def get_national_kfe() -> dict[str, Any] | None:
    rows = await _fetch_datagroup(KFE_GROUP, months_back=6)
    if not rows:
        return None
    value, period = _latest_value(rows, "TP_KFE_TR")
    if value is None:
        return None
    return {
        "indexValue": value,
        "baseYear": 2023,
        "period": period,
        "source": "TCMB EVDS — Konut Fiyat Endeksi (Türkiye)",
    }
