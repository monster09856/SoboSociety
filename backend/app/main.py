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
        content={
            "detail": str(exc) or exc.__class__.__name__,
            "detay": str(exc) or exc.__class__.__name__,
            "hata": exc.__class__.__name__,
        },
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import traceback
    import logging
    logger = logging.getLogger("uvicorn.error")
    logger.error(f"[SERVER EXCEPTION] {request.method} {request.url.path} -> {exc}\n{traceback.format_exc()}")

    err_str = str(exc).strip() if str(exc).strip() else "İşlem sırasında beklenmedik bir sunucu hatası oluştu."
    return JSONResponse(
        status_code=500,
        content={
            "detail": err_str,
            "detay": err_str,
            "hata": exc.__class__.__name__,
        },
    )


app.include_router(api_v1_router)


@app.on_event("startup")
async def startup_event():
    # Başlangıçta silinen workshopların tekrar otomatik eklenmesini engelle
    pass


@app.get("/")
async def root():
    return {"mesaj": "Sobo API Katmanı Çalışıyor"}
