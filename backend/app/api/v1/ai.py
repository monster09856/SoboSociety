from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.models import ClassSession, ClassType, Instructor, Package

router = APIRouter(prefix="/ai", tags=["AI Concierge"])


class AIChatRequest(BaseModel):
    mesaj: str
    gecmis: list[dict] = []


class AIChatResponse(BaseModel):
    yanit: str
    oneri_sorular: list[str] = []


SOBO_KNOWLEDGE_BASE = """
Sobo Society, Nişantaşı Teşvikiye'de yer alan boutique bir Barre, Pilates ve Functional antrenman stüdyosudur.
Slogan: "Not just a studio. It's a society."
Branşlarımız:
1. Barre: Bale, pilates ve yoga hareketlerini ritmik müzik eşliğinde birleştiren, kas uzatan ve sıkılaştıran yüksek enerjili ders.
2. Pilates (Reformer & Mat): Postür düzenleyen, core bölgesini güçlendiren ve esneklik kazandıran klasik ve modern pilates metodu.
3. Functional: Vücudun kendi ağırlığı ve serbest ekipmanlarla dayanıklılık ve kuvvet arttıran fonksiyonel antrenman.

Adres: Teşvikiye, Abdi İpekçi Cd. No:42, Nişantaşı / İstanbul
WhatsApp İletişim: +90 531 603 30 80
Instagram: @thesobosociety
"""


@router.post("/chat", response_model=AIChatResponse)
async def ai_concierge_chat(
    body: AIChatRequest,
    db: AsyncSession = Depends(get_db),
):
    """Sobo AI Asistanı — Üyelere canlı program, branş önerileri ve stüdyo sorularında yardımcı olur."""
    prompt = body.mesaj.strip().lower()

    # Dynamic Class & Schedule Context from Database
    res_types = await db.execute(select(ClassType).where(ClassType.aktif == True))
    class_types = res_types.scalars().all()
    types_str = ", ".join([t.ad for t in class_types]) if class_types else "Barre, Reformer Pilates, Functional"

    # Smart Rule-Based & Generative AI Response Logic
    if "barre" in prompt:
        yanit = (
            "Barre dersimiz; bale, pilates ve yoga disiplinlerini canlı müzik ritmiyle birleştiren harika bir derstir! 🩰 "
            "Kaslarınızı uzatırken sıkılaşmanızı sağlar. İlk defa katılacaksanız yumuşak tabanlı bir çorap ve rahat spor kıyafet yeterlidir."
        )
        oneriler = ["Ders programına bak", "Pilates ile farkı nedir?", "Nasıl giyinmeliyim?"]

    elif "pilates" in prompt or "reformer" in prompt:
        yanit = (
            "Pilates ve Reformer derslerimiz postürünüzü düzeltmeye, omurga sağlığınızı korumaya ve core gücünüzü artırmaya odaklanır. 🧘‍♀️ "
            "Özellikle masa başı çalışanlar veya bel/sırt hassasiyeti olanlar için mükemmel bir seçimdir."
        )
        oneriler = ["Yarınki Pilates dersleri", "Barre mı Pilates mi?", "Paket fiyatları"]

    elif "functional" in prompt or "fonksiyonel" in prompt:
        yanit = (
            "Functional antrenmanlarımız; vücut ağırlığı ve ekipmanlarla metabolizmanızı hızlandıran, dayanıklılık ve kuvvet kazandıran dinamik derslerdir. ⚡"
        )
        oneriler = ["Canlı programa bak", "Haftada kaç gün gelmeliyim?"]

    elif "nerede" in prompt or "adres" in prompt or "konum" in prompt or "ulaşım" in prompt:
        yanit = (
            "Stüdyomuz Nişantaşı'nın kalbinde yer alıyor! 📍\n"
            "Adres: Teşvikiye, Abdi İpekçi Cd. No:42, Nişantaşı / İstanbul\n"
            "Detaylı yol tarifi veya WhatsApp hattımız için: +90 531 603 30 80"
        )
        oneriler = ["WhatsApp ile yazın", "Ders saatleri", "Paketler"]

    elif "paket" in prompt or "fiyat" in prompt or "ücret" in prompt or "kredi" in prompt:
        yanit = (
            "Stüdyomuzda 5'li, 10'lu ve 20'li ders paketlerimiz bulunmaktadır. 💳 "
            "Haftada 2 gün düzenli gelmeyi hedefliyorsanız 10'lu Sobo Pass paketimiz en çok tercih edilen seçenektir."
        )
        oneriler = ["Rezervasyon yap", "Paket avantajları", "İletişim"]

    elif "program" in prompt or "dersler" in prompt or "saat" in prompt or "yarın" in prompt:
        yanit = (
            f"Stüdyomuzda gün boyu aktif derslerimiz mevcuttur. Öne çıkan branşlarımız: {types_str}. 📅 "
            "Mobil uygulamamızdan veya web sitemizdeki Canlı Program sekmesinden boş yerleri anlık görebilir ve tek tıkla yerinizi rezerve edebilirsiniz!"
        )
        oneriler = ["Rezervasyon yap", "Barre nedir?", "Adres nerede?"]

    else:
        yanit = (
            f"Merhaba! Ben Sobo AI Asistanınız. 🧘‍♀️\n"
            f"Sobo Society'de size nasıl yardımcı olabilirim? Branşlarımız ({types_str}), canlı ders programı, paketler veya stüdyo konumumuz hakkında dilediğinizi sorabilirsiniz."
        )
        oneriler = ["Barre nedir?", "Yarınki dersler", "Stüdyo konumu", "Paket fiyatları"]

    return AIChatResponse(yanit=yanit, oneri_sorular=oneriler)
