#!/usr/bin/env python3
"""Lokus — TurkiyeAPI'den 81 il + 973 ilçe indeksini üretir."""

import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "Lokus" / "Data"
API = "https://api.turkiyeapi.dev/v2/datasets/2025"

# Tahmini ortalama konut m² fiyatları (TL) — ileride kalibrasyon yapılacak
AVG_PRICES = {
    1: 38000, 2: 22000, 3: 28000, 4: 18000, 5: 26000, 6: 52000, 7: 65000,
    8: 24000, 9: 42000, 10: 36000, 11: 30000, 12: 17000, 13: 19000, 14: 32000,
    15: 29000, 16: 48000, 17: 34000, 18: 22000, 19: 25000, 20: 40000, 21: 28000,
    22: 35000, 23: 24000, 24: 21000, 25: 23000, 26: 44000, 27: 36000, 28: 27000,
    29: 20000, 30: 16000, 31: 34000, 32: 31000, 33: 45000, 34: 95000, 35: 72000,
    36: 18000, 37: 24000, 38: 38000, 39: 33000, 40: 23000, 41: 55000, 42: 32000,
    43: 28000, 44: 26000, 45: 41000, 46: 27000, 47: 25000, 48: 68000, 49: 17000,
    50: 35000, 51: 26000, 52: 30000, 53: 32000, 54: 46000, 55: 34000, 56: 20000,
    57: 28000, 58: 24000, 59: 50000, 60: 22000, 61: 42000, 62: 19000, 63: 26000,
    64: 29000, 65: 22000, 66: 20000, 67: 30000, 68: 25000, 69: 18000, 70: 24000,
    71: 26000, 72: 23000, 73: 18000, 74: 31000, 75: 17000, 76: 20000, 77: 48000,
    78: 27000, 79: 24000, 80: 28000, 81: 34000,
}


from typing import Any, Dict, List, Union


def fetch_json(url: str) -> Union[List, Dict]:
    with urllib.request.urlopen(url, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def main() -> None:
    provinces_raw = fetch_json(f"{API}/provinces.json")
    districts_raw = fetch_json(f"{API}/districts.json")

    districts_by_province: dict[int, list] = {}
    for district in districts_raw:
        pid = district["provinceId"]
        districts_by_province.setdefault(pid, []).append({
            "id": district["id"],
            "name": district["name"],
            "population": district.get("population"),
            "neighborhoodCount": district.get("stats", {}).get("neighborhoodCount", 0),
            "villageCount": district.get("stats", {}).get("villageCount", 0),
            "areaKm2": district.get("area", {}).get("value"),
        })

    provinces = []
    for province in sorted(provinces_raw, key=lambda p: p["id"]):
        plate = province["id"]
        provinces.append({
            "plateNumber": plate,
            "name": province["name"],
            "avgHousePrice": AVG_PRICES.get(plate, 30000),
            "population": province.get("population"),
            "isMetropolitan": province.get("isMetropolitan", False),
            "districts": sorted(
                districts_by_province.get(plate, []),
                key=lambda d: d["name"],
            ),
        })

    index = {
        "version": "2025",
        "source": "turkiyeapi.dev",
        "lastUpdated": "2025-06",
        "provinceCount": len(provinces),
        "districtCount": sum(len(p["districts"]) for p in provinces),
        "provinces": provinces,
    }

    out = ROOT / "administrative_index.json"
    out.write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # regional_summary: hafif özet (ODR/geriye uyumluluk)
    summary = {
        "version": "3.0",
        "lastUpdated": "2025-06",
        "provinces": [
            {
                "plateNumber": p["plateNumber"],
                "name": p["name"],
                "avgHousePrice": p["avgHousePrice"],
                "districts": [],
            }
            for p in provinces
        ],
    }
    (ROOT / "regional_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"✓ administrative_index.json — {index['provinceCount']} il, {index['districtCount']} ilçe")
    print(f"✓ Dosya boyutu: {out.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    main()
