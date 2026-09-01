import logging
import random
import httpx
from app.settings import ayarlar

logger = logging.getLogger("sobo.sms")

async def send_sms_otp(telefon: str, kod: str) -> bool:
    """Telefon numarasına OTP SMS mesajı gönderir.
    
    `ayarlar.sms_provider` değerine göre Netgsm, İletimerkezi veya Mock servis kullanır.
    """
    mesaj = f"Sobo Society giriş doğrulama kodunuz: {kod}. Bu kodu kimseyle paylaşmayınız."
    
    # Telefon numarasını temizle (örn: +905316033080 -> 905316033080)
    clean_tel = telefon.replace("+", "").replace(" ", "").replace("-", "")
    if clean_tel.startswith("0"):
        clean_tel = "9" + clean_tel
    elif not clean_tel.startswith("90") and len(clean_tel) == 10:
        clean_tel = "90" + clean_tel

    logger.info(f"[SMS DISPATCH] Provider: {ayarlar.sms_provider} | Tel: {clean_tel} | OTP: {kod}")

    if ayarlar.sms_provider == "netgsm":
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(
                    "https://api.netgsm.com.tr/sms/send/xml",
                    data=f"""<?xml version="1.0" encoding="UTF-8"?>
                    <mainbody>
                        <header>
                            <company code="{ayarlar.sms_header}" />
                            <usercode>{ayarlar.sms_user}</usercode>
                            <password>{ayarlar.sms_password}</password>
                            <type>1:n</type>
                            <msgheader>{ayarlar.sms_header}</msgheader>
                        </header>
                        <body>
                            <msg><![CDATA[{mesaj}]]></msg>
                            <no>{clean_tel}</no>
                        </body>
                    </mainbody>"""
                )
                logger.info(f"Netgsm SMS gönderildi ({clean_tel}): {resp.status_code}")
                return resp.status_code == 200
        except Exception as e:
            logger.error(f"Netgsm SMS gönderme hatası: {e}")
            return False

    elif ayarlar.sms_provider == "iletimerkezi":
        try:
            payload = {
                "request": {
                    "authentication": {
                        "key": ayarlar.sms_user,
                        "hash": ayarlar.sms_password,
                    },
                    "order": {
                        "sender": ayarlar.sms_header,
                        "message": {
                            "text": mesaj,
                            "receipents": {
                                "number": [clean_tel],
                            },
                        },
                    },
                }
            }
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post("https://api.iletimerkezi.com/v1/send-sms/json", json=payload)
                logger.info(f"İletimerkezi SMS yanıtı ({clean_tel}): status={resp.status_code} body={resp.text}")
                
                # İletimerkezi 200 dönerse başarılıdır
                if resp.status_code == 200 and '"code":200' in resp.text:
                    return True
                
                # API Key panellerinde henüz "API Kullanımına İzin Ver" açılmadıysa 401 döner
                logger.warning(f"İletimerkezi SMS gönderilemedi: {resp.text}")
                return False
        except Exception as e:
            logger.error(f"İletimerkezi SMS gönderme hatası: {e}")
            return False

    # Dev/Mock fallback
    logger.info(f"[MOCK SMS] Telefon: {clean_tel} | Kod: {kod}")
    return True


def generate_otp_code() -> str:
    """Rastgele 6 haneli OTP kodu üretir."""
    if ayarlar.sms_provider == "mock":
        return "123456"
    return str(random.randint(100000, 999999))
