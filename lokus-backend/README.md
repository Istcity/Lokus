# Lokus Geo Backend

FastAPI + PostGIS coğrafi veri katmanı. iOS uygulaması doğrudan kurumlara değil, bu API'ye bağlanır.

## Hızlı başlangıç (mock mod)

```bash
cd lokus-backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Pilot: http://127.0.0.1:8000/api/query?lat=40.9927&lng=29.0277

## PostGIS + ETL (Faz 2)

```bash
docker compose up -d
python scripts/init_db.py
# .env → USE_MOCK_DATA=false
python scripts/run_etl.py
uvicorn main:app --reload --port 8000
```

Manuel ETL: `POST /admin/etl/run`  
Seed bootstrap: `POST /admin/etl/bootstrap`

## Katmanlar

| Endpoint | Açıklama |
|----------|----------|
| `GET /api/query` | Parsel + imar + altyapı + POI |
| `GET /api/poi` | Overpass POI proxy |
| `GET /api/layers/{layer}/geojson` | Bbox GeoJSON (iOS overlay) |
| `GET /tiles/{layer}/{z}/{x}/{y}.mvt` | Vector tiles (PostGIS) |
| `POST /admin/etl/run` | ETL pipeline |
| `GET /about` | Yasal attribution |

## POI kaynakları

1. **Backend:** OpenStreetMap Overpass API (proxy)
2. **iOS yedek:** Apple MapKit Local Search (POI boşsa)

## Faz durumu

| Faz | Durum |
|-----|--------|
| Faz 1 — API + mock | ✅ |
| Faz 2 — ETL + PostGIS + seed | ✅ pilot Kadıköy |
| Faz 3 — iOS entegrasyon | ✅ |
| Faz 4 — POI Overpass + MapKit | ✅ |
| Faz 5 — Offline cache | ✅ iOS 7 gün TTL |

## Test

```bash
pytest tests/ -q
```

## iOS

`Secrets.plist` → `GEO_BACKEND_URL=http://127.0.0.1:8000`

Simülatör: `127.0.0.1` · Fiziksel cihaz: Mac IP adresi
