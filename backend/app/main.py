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


app.include_router(api_v1_router)


@app.on_event("startup")
async def startup_event():
    try:
        from app.db.session import OturumFabrikasi
        from app.models.program import StudioEvent
        from sqlalchemy import select, func
        from datetime import datetime, timedelta, timezone

        async with OturumFabrikasi() as db:
            res = await db.execute(select(func.count(StudioEvent.id)))
            cnt = res.scalar_one() or 0
            if cnt == 0:
                now = datetime.now(timezone.utc)
                events = [
                    StudioEvent(
                        baslik="Belgrad Ormanı Doğa Yürüyüşü & Kahve Buluşması",
                        turu="YURUYUS",
                        tarih_saat=now + timedelta(days=4, hours=9),
                        aciklama="Temiz havada yürüyüş, nefes egzersizleri ve ardından tüm Sobo topluluğu ile kahve sohbeti.",
                        kontenjan=20,
                        dolu_sayi=0,
                        ucret="Ücretsiz / Topluluk Etkinliği",
                        aktif=True,
                    ),
                    StudioEvent(
                        baslik="Ses Çanağı & Derin Meditasyon (Sound Bath)",
                        turu="SOUNDBATH",
                        tarih_saat=now + timedelta(days=5, hours=18),
                        aciklama="Tibet ses çanaklarının şifalı frekansları eşliğinde derin zihinsel ve bedensel dinlenme seansı.",
                        kontenjan=12,
                        dolu_sayi=0,
                        ucret="Üyelere Özel / Seans",
                        aktif=True,
                    ),
                    StudioEvent(
                        baslik="Postür Düzeltme & Omurga Sağlığı Atölyesi",
                        turu="WORKSHOP",
                        tarih_saat=now + timedelta(days=6, hours=14),
                        aciklama="Günlük hayattaki duruş bozukluklarını düzeltmeye ve bel-boyun ağrılarını hafifletmeye yönelik uygulamalı atölye.",
                        kontenjan=10,
                        dolu_sayi=0,
                        ucret="Üyelere Özel / Seans",
                        aktif=True,
                    ),
                ]
                db.add_all(events)
                await db.commit()
    except Exception as e:
        print(f"[STARTUP SEED ERROR] {e}")


@app.get("/")
async def root():
    return {"mesaj": "Sobo API Katmanı Çalışıyor"}
