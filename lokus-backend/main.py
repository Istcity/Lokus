"""Lokus Geo Backend — FastAPI giriş noktası."""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from config import settings
from routers import admin, geo_query, layers, poi, tiles

GEO_ATTRIBUTION = (
    "Parsel ve imar verileri TKGM, ilgili belediyeler ve Çevre Bakanlığı "
    "açık veri kaynaklarından derlenmektedir. Bilgilerin güncelliği ve doğruluğu "
    "için resmi kaynaklara başvurunuz."
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    if settings.enable_etl_scheduler and not settings.use_mock_data:
        from etl.scheduler import start_scheduler
        start_scheduler()
    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Lokus coğrafi veri katmanı API — tüm kurum sorguları bu backend üzerinden.",
    lifespan=lifespan,
)

app.state.limiter = geo_query.limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

origins = [o.strip() for o in settings.cors_origins.split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if origins != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(geo_query.router)
app.include_router(layers.router)
app.include_router(tiles.router)
app.include_router(poi.router)
app.include_router(admin.router)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "mock": settings.use_mock_data}


@app.get("/about")
async def about() -> dict:
    return {"attribution": GEO_ATTRIBUTION, "version": settings.app_version}


@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError) -> JSONResponse:
    return JSONResponse(status_code=422, content={"detail": str(exc)})
