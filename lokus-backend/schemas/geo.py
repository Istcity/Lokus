"""API yanıt şemaları."""

from datetime import date, datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, Field

ConfidenceLevel = Literal["high", "medium", "low"]


class ParcelInfo(BaseModel):
    ada: Optional[str] = None
    parsel: Optional[str] = None
    yuzolcum: Optional[float] = None
    malik_ozet: Optional[str] = None
    il: Optional[str] = None
    ilce: Optional[str] = None
    mahalle: Optional[str] = None
    confidence_level: ConfidenceLevel = "medium"


class ZoningResponse(BaseModel):
    plan_notu: Optional[str] = None
    taks: Optional[float] = None
    kaks: Optional[float] = None
    yapilasma_turu: Optional[str] = None
    max_kat: Optional[str] = None
    son_guncelleme: Optional[datetime] = None
    confidence_level: ConfidenceLevel = "medium"


class InfrastructureData(BaseModel):
    yol: bool = False
    su: bool = False
    elektrik: bool = False
    dogalgaz: bool = False
    fiber: bool = False
    toplu_tasima: bool = False


class POIItem(BaseModel):
    name: str
    category: str
    distance_m: int
    lat: float
    lng: float


class POIData(BaseModel):
    okullar: List[POIItem] = Field(default_factory=list)
    hastaneler: List[POIItem] = Field(default_factory=list)
    marketler: List[POIItem] = Field(default_factory=list)
    parklar: List[POIItem] = Field(default_factory=list)
    duraklar: List[POIItem] = Field(default_factory=list)


class DataSource(BaseModel):
    katman: str
    kaynak: str
    guncelleme_tarihi: date
    lisans: Optional[str] = None


class LocationQueryResponse(BaseModel):
    parcel: Optional[ParcelInfo] = None
    zoning: Optional[ZoningResponse] = None
    infrastructure: InfrastructureData
    poi: POIData
    data_sources: List[DataSource]
    cached: bool = False
