"""Fiyat referans uçları — ilçe çapası + TCMB EVDS."""

from fastapi import APIRouter, HTTPException

from services import tcmb_evds

router = APIRouter(prefix="/api/prices", tags=["prices"])

_PILOT_ANCHORS = {
    1421: {"districtName": "Kadıköy", "housePricePerM2": 159500, "landPricePerM2": 92500},
}


@router.get("/tcmb/status")
async def tcmb_status() -> dict:
    return {
        "configured": tcmb_evds.is_configured(),
        "source": "TCMB EVDS3 (ücretsiz)",
        "endpoint": "https://evds3.tcmb.gov.tr",
    }


@router.get("/tcmb/province/{plate_number}")
async def tcmb_province_price(plate_number: int) -> dict:
    if not tcmb_evds.is_configured():
        raise HTTPException(status_code=503, detail="TCMB EVDS API anahtarı yapılandırılmamış")
    result = await tcmb_evds.get_province_unit_price(plate_number)
    if not result:
        raise HTTPException(status_code=404, detail="Bu il için TCMB birim fiyatı bulunamadı")
    kfe = await tcmb_evds.get_national_kfe()
    if kfe:
        result["kfe"] = kfe
    result["disclaimer"] = "TCMB ortanca m² fiyatı — il geneli; mahalle/ilçe farkını yansıtmaz."
    return result


@router.get("/district/{district_id}")
async def district_price(district_id: int) -> dict:
    anchor = _PILOT_ANCHORS.get(district_id)
    if not anchor:
        raise HTTPException(status_code=404, detail="İlçe çapası bulunamadı")
    return {
        "districtId": district_id,
        "source": "Lokus Endeks",
        **anchor,
        "disclaimer": "Tahmini referans — resmi ekspertiz yerine geçmez.",
    }
