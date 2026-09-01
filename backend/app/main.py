from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1.router import api_v1_router
from app.services.hatalar import (
    GecersizOTP,
    GecersizToken,
    KayitBulunamadi,
    SoboHata,
    ZatenIptal,
    ZatenRezerve,
    ZatenSirada,
)

app = FastAPI(
    title="Sobo API",
    description="Sobo Pilates & Fitness HTTP API Katmanı",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(SoboHata)
async def sobo_hata_handler(request: Request, exc: SoboHata):
    status_code = 400
    if isinstance(exc, KayitBulunamadi):
        status_code = 404
    elif isinstance(exc, (ZatenRezerve, ZatenIptal, ZatenSirada)):
        status_code = 409
    elif isinstance(exc, GecersizToken):
        status_code = 401
    elif isinstance(exc, GecersizOTP):
        status_code = 400

    return JSONResponse(
        status_code=status_code,
        content={"detay": str(exc) or exc.__class__.__name__, "hata": exc.__class__.__name__},
    )


app.include_router(api_v1_router)


@app.get("/")
async def root():
    return {"mesaj": "Sobo API Katmanı Çalışıyor"}
