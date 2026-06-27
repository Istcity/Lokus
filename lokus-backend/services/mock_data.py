"""Mock coğrafi veri — Kadıköy pilot."""

from datetime import date, datetime, timezone

from schemas.geo import (
    DataSource,
    InfrastructureData,
    LocationQueryResponse,
    ParcelInfo,
    POIData,
    POIItem,
    ZoningResponse,
)

KADIKOY_CENTER = (40.9927, 29.0277)
KADIKOY_RADIUS_DEG = 0.015


def _in_kadikoy_pilot(lat: float, lng: float) -> bool:
    clat, clng = KADIKOY_CENTER
    return abs(lat - clat) <= KADIKOY_RADIUS_DEG and abs(lng - clng) <= KADIKOY_RADIUS_DEG


def _is_sea(lat: float, lng: float) -> bool:
    return lat < 40.85 and lng > 29.0


def mock_query(lat: float, lng: float, radius_m: int = 500) -> LocationQueryResponse:
    """
    Pilot mock yanıt.
    - Kadıköy merkez: tam veri
    - Deniz: parsel null
    - Diğer: düşük güven tahmini
    """
    now = datetime.now(timezone.utc)
    sources = [
        DataSource(
            katman="imar",
            kaynak="İBB Açık Veri Portalı (mock)",
            guncelleme_tarihi=date(2025, 6, 1),
            lisans="CC BY 4.0",
        ),
        DataSource(
            katman="parsel",
            kaynak="TKGM WFS (mock)",
            guncelleme_tarihi=date(2025, 5, 15),
            lisans="Kamu Verisi",
        ),
    ]

    if _is_sea(lat, lng):
        return LocationQueryResponse(
            parcel=None,
            zoning=ZoningResponse(
                plan_notu="Deniz alanı — imar planı uygulanmaz",
                yapilasma_turu="Deniz",
                confidence_level="high",
                son_guncelleme=now,
            ),
            infrastructure=InfrastructureData(),
            poi=POIData(),
            data_sources=sources,
        )

    if _in_kadikoy_pilot(lat, lng):
        return LocationQueryResponse(
            parcel=ParcelInfo(
                ada="1234",
                parsel="5",
                yuzolcum=450.0,
                malik_ozet="Özet bilgi — resmi tapu kaydı için TKGM",
                il="İstanbul",
                ilce="Kadıköy",
                mahalle="Caferağa",
                confidence_level="high",
            ),
            zoning=ZoningResponse(
                plan_notu="Konut alanı — E:5.00, TAKS:0.40, KAKS:2.00",
                taks=0.40,
                kaks=2.00,
                yapilasma_turu="Konut",
                max_kat="5 Kat",
                son_guncelleme=now,
                confidence_level="high",
            ),
            infrastructure=InfrastructureData(
                yol=True,
                su=True,
                elektrik=True,
                dogalgaz=True,
                fiber=True,
                toplu_tasima=True,
            ),
            poi=POIData(
                okullar=[
                    POIItem(name="Caferağa İlkokulu", category="okul", distance_m=320, lat=40.9935, lng=29.0265)
                ],
                hastaneler=[
                    POIItem(name="Kadıköy Devlet Hastanesi", category="hastane", distance_m=890, lat=40.9890, lng=29.0310)
                ],
                marketler=[
                    POIItem(name="Mahalle Marketi", category="market", distance_m=180, lat=40.9920, lng=29.0280)
                ],
                parklar=[
                    POIItem(name="Moda Parkı", category="park", distance_m=650, lat=40.9840, lng=29.0250)
                ],
                duraklar=[
                    POIItem(name="Moda İskele Durağı", category="durak", distance_m=420, lat=40.9870, lng=29.0240)
                ],
            ),
            data_sources=sources,
        )

    return LocationQueryResponse(
        parcel=ParcelInfo(
            ada=None,
            parsel=None,
            confidence_level="low",
            il="Türkiye",
        ),
        zoning=ZoningResponse(
            plan_notu="Bu bölge için henüz resmi katman yüklenmedi. Tahmini model.",
            taks=0.30,
            kaks=1.20,
            yapilasma_turu="Konut",
            max_kat="5 Kat",
            son_guncelleme=now,
            confidence_level="low",
        ),
        infrastructure=InfrastructureData(yol=True, su=True, elektrik=True),
        poi=POIData(),
        data_sources=[
            DataSource(
                katman="tahmin",
                kaynak="Lokus Bölgesel Model",
                guncelleme_tarihi=date.today(),
                lisans="Tahmini",
            )
        ],
    )
