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
Marka Teması: Pantone 17-1230 TCX (Mocha Mousse #A47864)

Branşlarımız & Ders Tipleri:
1. Barre: Bale, pilates ve yoga hareketlerini ritmik müzik eşliğinde birleştiren, kas uzatan ve sıkılaştıran yüksek enerjili ders.
2. Pilates & Reformer: Postür düzenleyen, core bölgesini güçlendiren ve esneklik kazandıran klasik/modern pilates ve kişiye özel reformer cihazı.
3. Functional: Vücudun kendi ağırlığı ve serbest ekipmanlarla dayanıklılık ve kuvvet arttıran fonksiyonel antrenman.
4. Yoga: Nefes, esneklik ve zihinsel denge odaklı seanslar.

Resmi İptal & Ders Kuralları:
- İptal Süresi: Ders iptalleri dersten en geç 12 saat öncesine kadar yapıldığında bakiye iadesi ile tamamlanır. 12 saatten az kala yapılan iptallerde ders yapılmış sayılır.
- Paket Kullanım Süreleri: 4 derslik paket 4 hafta, 8 derslik paket 6 hafta, 12 derslik paket 8 hafta geçerlidir.
- Özel Paketler: İhtiyaca göre kişiye/üyeye özel ders kredisi, süresi ve paket adı tanımlanabilmektedir.
- Vücut Ölçüleri & Form Takibi: Üyelerimiz /hesabim sayfasından Bel, Kalça, Sağ/Sol İç Bacak, Sağ/Sol Bacak, Sağ/Sol Kol, Boy, Kilo ve Sağlık/Sakatlık notlarını girebilir. Eğitmenlerimiz gelişimlerini yakından takip eder.

Adres: Teşvikiye, Abdi İpekçi Cd. No:42, Nişantaşı / İstanbul
WhatsApp İletişim: +90 531 603 30 80
Instagram: @thesobosociety
"""


@router.post("/chat", response_model=AIChatResponse)
async def ai_concierge_chat(
    body: AIChatRequest,
    db: AsyncSession = Depends(get_db),
):
    """Sobo AI Asistanı — Üyelere canlı program, iptal kuralları (12 saat), vücut ölçü takibi ve paketlerde yardımcı olur."""
    prompt = body.mesaj.strip().lower()

    # Dynamic Class & Schedule Context from Database
    res_types = await db.execute(select(ClassType).where(ClassType.aktif == True))
    class_types = res_types.scalars().all()
    types_str = ", ".join([t.ad for t in class_types]) if class_types else "Barre, Reformer Pilates, Functional, Yoga"

    # Smart Rule-Based & Generative AI Response Logic
    if "iptal" in prompt or "iade" in prompt or "değişim" in prompt or "değişiklik" in prompt or "kaç saat" in prompt:
        yanit = (
            "Ders iptal ve değişiklik kuralımız son derece şeffaftır! ⏱️\n"
            "Ders saatinize **en geç 12 saat kalana kadar** rezervasyonunuzu tek tıkla iptal edebilirsiniz. "
            "12 saat öncesine kadar yapılan iptallerde ders krediniz anında hesabınıza iade edilir. "
            "12 saatten az süre kaldığında yapılan iptallerde ise kontenjan koruması gereği ders hakkı düşmektedir."
        )
        oneriler = ["Ders programına bak", "Profilimdeki dersler", "İletişim"]

    elif "ölçü" in prompt or "beden" in prompt or "kilo" in prompt or "boy" in prompt or "bel" in prompt or "kalça" in prompt or "bacak" in prompt:
        yanit = (
            "Sobo Society'de eğitmenlerimiz gelişiminizi adım adım takip eder! 📐\n"
            "Hesabım (/hesabim) sayfasından Bel, Kalça, Sağ/Sol İç Bacak, Sağ/Sol Bacak, Sağ/Sol Kol, Boy, Kilo ve Sağlık/Sakatlık notlarınızı kolayca doldurabilirsiniz. "
            "Eğitmenlerimiz ders esnasında ve sonrasında bu bilgilerinize göre size özel hareket modifikasyonu uygular."
        )
        oneriler = ["Hesabıma git", "Paketler", "Barre nedir?"]

    elif "barre" in prompt:
        yanit = (
            "Barre dersimiz; bale, pilates ve yoga disiplinlerini ritmik müzik eşliğinde birleştiren harika bir derstir! 🩰 "
            "Kaslarınızı uzatırken sıkılaşmanızı sağlar. İlk defa katılacaksanız yumuşak tabanlı bir çorap ve rahat spor kıyafet yeterlidir."
        )
        oneriler = ["Ders programına bak", "Pilates ile farkı nedir?", "İptal kuralı nedir?"]

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
            "Detaylı yol tarifi veya WhatsApp hattımız için: +90 531 603 30 80\n"
            "Instagram: @thesobosociety"
        )
        oneriler = ["WhatsApp ile yazın", "Ders saatleri", "Paketler"]

    elif "paket" in prompt or "fiyat" in prompt or "ücret" in prompt or "kredi" in prompt:
        yanit = (
            "Stüdyomuzda 4'lü (4 Hafta), 8'li (6 Hafta), 12'li (8 Hafta) ve 20'li grup paketlerimizin yanı sıra kişiye/üyeye özel tanımlanan özel ders paketlerimiz bulunmaktadır. 💳\n"
            "Ayrıca tüm ders iptallerinizde 12 saat öncesine kadar krediniz eksiksiz korunur!"
        )
        oneriler = ["Rezervasyon yap", "İptal kuralı (12 Saat)", "İletişim"]

    elif "program" in prompt or "dersler" in prompt or "saat" in prompt or "yarın" in prompt:
        yanit = (
            f"Stüdyomuzda gün boyu aktif derslerimiz mevcuttur. Öne çıkan branşlarımız: {types_str}. 📅\n"
            "Web sitemizdeki Canlı Program sekmesinden boş yerleri anlık görebilir ve tek tıkla yerinizi rezerve edebilirsiniz!"
        )
        oneriler = ["Rezervasyon yap", "12 Saat İptal Kuralı", "Adres nerede?"]

    else:
        yanit = (
            f"Merhaba! Ben Sobo AI Asistanınız. 🧘‍♀️\n"
            f"Sobo Society'de size nasıl yardımcı olabilirim? Branşlarımız ({types_str}), 12 saatlik iadeli ders iptal kuralı, vücut ölçü takibi, özel paketler veya stüdyo konumumuz hakkında dilediğinizi sorabilirsiniz."
        )
        oneriler = ["12 Saat İptal Kuralı", "Ölçülerimi Nereye Girebilirim?", "Barre nedir?", "Stüdyo konumu"]

    return AIChatResponse(yanit=yanit, oneri_sorular=oneriler)
