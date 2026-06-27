#!/usr/bin/env python3
"""Lokus — 81 il regional_summary ve province ODR JSON üretici."""

import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "Lokus" / "Data"
PROVINCES_DIR = ROOT / "Provinces"

PROVINCES = [
    (1, "Adana", 38000),
    (2, "Adıyaman", 22000),
    (3, "Afyonkarahisar", 28000),
    (4, "Ağrı", 18000),
    (5, "Amasya", 26000),
    (6, "Ankara", 52000),
    (7, "Antalya", 65000),
    (8, "Artvin", 24000),
    (9, "Aydın", 42000),
    (10, "Balıkesir", 36000),
    (11, "Bilecik", 30000),
    (12, "Bingöl", 17000),
    (13, "Bitlis", 19000),
    (14, "Bolu", 32000),
    (15, "Burdur", 29000),
    (16, "Bursa", 48000),
    (17, "Çanakkale", 34000),
    (18, "Çankırı", 22000),
    (19, "Çorum", 25000),
    (20, "Denizli", 40000),
    (21, "Diyarbakır", 28000),
    (22, "Edirne", 35000),
    (23, "Elazığ", 24000),
    (24, "Erzincan", 21000),
    (25, "Erzurum", 23000),
    (26, "Eskişehir", 44000),
    (27, "Gaziantep", 36000),
    (28, "Giresun", 27000),
    (29, "Gümüşhane", 20000),
    (30, "Hakkari", 16000),
    (31, "Hatay", 34000),
    (32, "Isparta", 31000),
    (33, "Mersin", 45000),
    (34, "İstanbul", 95000),
    (35, "İzmir", 72000),
    (36, "Kars", 18000),
    (37, "Kastamonu", 24000),
    (38, "Kayseri", 38000),
    (39, "Kırklareli", 33000),
    (40, "Kırşehir", 23000),
    (41, "Kocaeli", 55000),
    (42, "Konya", 32000),
    (43, "Kütahya", 28000),
    (44, "Malatya", 26000),
    (45, "Manisa", 41000),
    (46, "Kahramanmaraş", 27000),
    (47, "Mardin", 25000),
    (48, "Muğla", 68000),
    (49, "Muş", 17000),
    (50, "Nevşehir", 35000),
    (51, "Niğde", 26000),
    (52, "Ordu", 30000),
    (53, "Rize", 32000),
    (54, "Sakarya", 46000),
    (55, "Samsun", 34000),
    (56, "Siirt", 20000),
    (57, "Sinop", 28000),
    (58, "Sivas", 24000),
    (59, "Tekirdağ", 50000),
    (60, "Tokat", 22000),
    (61, "Trabzon", 42000),
    (62, "Tunceli", 19000),
    (63, "Şanlıurfa", 26000),
    (64, "Uşak", 29000),
    (65, "Van", 22000),
    (66, "Yozgat", 20000),
    (67, "Zonguldak", 30000),
    (68, "Aksaray", 25000),
    (69, "Bayburt", 18000),
    (70, "Karaman", 24000),
    (71, "Kırıkkale", 26000),
    (72, "Batman", 23000),
    (73, "Şırnak", 18000),
    (74, "Bartın", 31000),
    (75, "Ardahan", 17000),
    (76, "Iğdır", 20000),
    (77, "Yalova", 48000),
    (78, "Karabük", 27000),
    (79, "Kilis", 24000),
    (80, "Osmaniye", 28000),
    (81, "Düzce", 34000),
]

DISTRICTS_BY_PROVINCE = {
    6: ["Çankaya", "Keçiören", "Yenimahalle"],
    34: ["Beşiktaş", "Kadıköy", "Üsküdar"],
    35: ["Konak", "Karşıyaka", "Bornova"],
    16: ["Nilüfer", "Osmangazi", "Yıldırım"],
    7: ["Muratpaşa", "Konyaaltı", "Kepez"],
    41: ["İzmit", "Gebze", "Gölcük"],
    33: ["Yenişehir", "Mezitli", "Toroslar"],
    48: ["Bodrum", "Fethiye", "Menteşe"],
    27: ["Şahinbey", "Şehitkamil", "Oğuzeli"],
    42: ["Selçuklu", "Meram", "Karatay"],
    38: ["Melikgazi", "Kocasinan", "Talas"],
    55: ["Atakum", "İlkadım", "Canik"],
    61: ["Ortahisar", "Akçaabat", "Yomra"],
}

ZONING_STATUSES = ["Konut", "Konut", "Konut", "Tarım", "Ticari"]
INFRA_PATTERNS = [
    (True, True, True, True, True),
    (True, True, True, True, False),
    (True, True, False, True, True),
    (True, True, True, False, False),
]

random.seed(42)


def make_village(name: str, base_price: float, index: int) -> dict:
    factor = 0.85 + (index * 0.12)
    house = round(base_price * factor * random.uniform(0.9, 1.15), -2)
    land = round(house * random.uniform(0.45, 0.75), -2)
    status = ZONING_STATUSES[index % len(ZONING_STATUSES)]
    infra = INFRA_PATTERNS[index % len(INFRA_PATTERNS)]
    taks = round(random.uniform(0.22, 0.42), 2)
    kaks = round(random.uniform(0.75, 1.60), 2)
    floors = f"{max(2, int(kaks * 3))} Kat"

    return {
        "name": name,
        "housePricePerM2": house,
        "landPricePerM2": land,
        "zoning": {
            "taks": taks,
            "kaks": kaks,
            "maxFloors": floors,
            "status": status,
        },
        "infrastructure": {
            "electricity": infra[0],
            "water": infra[1],
            "naturalGas": infra[2],
            "road": infra[3],
            "internet": infra[4],
        },
        "notes": f"{name} bölgesi için tahmini bölgesel fiyat ve imar verisi",
    }


def districts_for_province(plate: int, name: str, avg_price: float) -> list:
    if plate in DISTRICTS_BY_PROVINCE:
        district_names = DISTRICTS_BY_PROVINCE[plate]
    else:
        district_names = [
            f"{name} Merkez",
            f"{name} Kuzey",
            f"{name} Güney",
        ]

    districts = []
    for d_index, district_name in enumerate(district_names):
        villages = [
            make_village(f"{district_name} Mahallesi", avg_price, d_index * 2),
            make_village(f"{district_name} Köyü", avg_price * 0.75, d_index * 2 + 1),
        ]
        districts.append({"name": district_name, "villages": villages})
    return districts


def build_full_province(plate: int, name: str, avg_price: float) -> dict:
    return {
        "plateNumber": plate,
        "name": name,
        "avgHousePrice": avg_price,
        "districts": districts_for_province(plate, name, avg_price),
    }


def main() -> None:
    PROVINCES_DIR.mkdir(parents=True, exist_ok=True)

    summary_provinces = []
    for plate, name, avg_price in PROVINCES:
        full = build_full_province(plate, name, avg_price)
        file_name = f"province_{plate:02d}.json"
        (PROVINCES_DIR / file_name).write_text(
            json.dumps(full, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        summary_provinces.append({
            "plateNumber": plate,
            "name": name,
            "avgHousePrice": avg_price,
            "districts": [],
        })

    summary = {
        "version": "2.0",
        "lastUpdated": "2025-06",
        "provinces": summary_provinces,
    }
    (ROOT / "regional_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"✓ {len(PROVINCES)} il özeti → regional_summary.json")
    print(f"✓ {len(PROVINCES)} ODR dosyası → Data/Provinces/")


if __name__ == "__main__":
    main()
