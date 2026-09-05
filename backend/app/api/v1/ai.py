from datetime import datetime, timedelta
from typing import Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_db, get_optional_current_member
from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType,
    Instructor, Member, MemberPackage, Package, SessionDurumu,
)
from app.services.kredi import bakiye

router = APIRouter(prefix="/ai", tags=["AI Concierge"])


class AIActionButton(BaseModel):
    etiket: str
    rota: str | None = None
    url: str | None = None
    tip: Literal["navigate", "external"] = "navigate"


class AIChatRequest(BaseModel):
    mesaj: str
    gecmis: list[dict] = []


class AIChatResponse(BaseModel):
    yanit: str
    oneri_sorular: list[str] = []
    aksiyon_butonu: AIActionButton | None = None


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
    current_member: Member | None = Depends(get_optional_current_member),
):
    """Sobo AI 2.0 Concierge — Canlı veritabanı bağlamı, üye bakiyesi, yaklaşan dersler ve kişiselleştirilmiş yanıtlar sunar."""
    prompt = body.mesaj.strip().lower()
    now = datetime.now()

    member_name = f"Sayın {current_member.ad}" if current_member else "Değerli Misafirimiz"

    # Dynamic Class & Schedule Context from Database
    res_types = await db.execute(select(ClassType).where(ClassType.aktif == True))
    class_types = res_types.scalars().all()
    types_str = ", ".join([t.ad for t in class_types]) if class_types else "Barre, Reformer Pilates, Functional, Yoga"

    # --- INTENT 1: KREDİ & BAKİYE & PAKET SORGULARI ---
    if any(k in prompt for k in ["kredi", "kaç ders", "bakiye", "paketim", "kalan ders", "haklarım"]):
        if current_member:
            kalan_kredi = await bakiye(db, current_member.id)
            
            # Üyenin paketlerini çek
            stmt_pkg = (
                select(MemberPackage, Package)
                .join(Package, MemberPackage.package_id == Package.id)
                .where(MemberPackage.member_id == current_member.id)
            )
            pkg_res = await db.execute(stmt_pkg)
            packages = pkg_res.all()

            if kalan_kredi > 0:
                pkg_info = ""
                if packages:
                    pkg_list = [f"• {p[1].ad} (Başlangıç: {p[0].baslangic.strftime('%d.%m.%Y')})" for p in packages]
                    pkg_info = "\nTanımlı Paketleriniz:\n" + "\n".join(pkg_list)

                yanit = (
                    f"Merhaba {current_member.ad}! 🧘‍♀️\n\n"
                    f"Hesabınızda şu an toplam **{kalan_kredi} ders krediniz** bulunmaktadır.{pkg_info}\n\n"
                    f"Hemen bir seans rezerve etmek ister misiniz?"
                )
                oneriler = ["Ders programına bak", "İptal kuralı nedir?", "Vücut ölçülerim"]
                aksiyon = AIActionButton(etiket="Ders Rezerve Et", rota="/booking", tip="navigate")
            else:
                yanit = (
                    f"Merhaba {current_member.ad}! 💳\n\n"
                    f"Hesabınızda şu an aktif ders krediniz bulunmamaktadır. "
                    f"4'lü, 8'li, 12'li veya kişiye özel paketlerimizden dilediğinizi seçerek hemen seanslara katılabilirsiniz!"
                )
                oneriler = ["Paket fiyatları", "Barre nedir?", "İletişime geç"]
                aksiyon = AIActionButton(etiket="Paket Satın Al / İletişim", rota="/booking", tip="navigate")
        else:
            yanit = (
                "Sobo Society'de 4'lü (4 Hafta), 8'li (6 Hafta) ve 12'li (8 Hafta) grup ve reformer paketlerimiz mevcuttur. 💳\n"
                "Kendi hesabınızdaki kalan kredilerinizi ve paket durumunuzu görmek için lütfen giriş yapın."
            )
            oneriler = ["Giriş yap", "Ders programı", "İptal kuralı nedir?"]
            aksiyon = AIActionButton(etiket="Giriş Yap", rota="/login", tip="navigate")

    # --- INTENT 2: İPTAL KURALI & YAKLAŞAN DERSLER ---
    elif any(k in prompt for k in ["iptal", "iade", "değişim", "kaç saat", "seansım", "randevum", "dersim var mı", "yaklaşan"]):
        if current_member:
            # Üyenin yaklaşan rezervasyonlarını çek
            stmt_b = (
                select(Booking, ClassSession)
                .join(ClassSession, Booking.session_id == ClassSession.id)
                .options(
                    selectinload(ClassSession.class_type),
                    selectinload(ClassSession.instructor),
                )
                .where(
                    Booking.member_id == current_member.id,
                    Booking.durum == BookingDurumu.BOOKED,
                    ClassSession.baslangic >= now,
                )
                .order_by(ClassSession.baslangic.asc())
            )
            res_b = await db.execute(stmt_b)
            upcoming = res_b.all()

            if upcoming:
                lines = []
                for b, s in upcoming:
                    kalan_saat = (s.baslangic - now).total_seconds() / 3600.0
                    tarih_str = s.baslangic.strftime("%d.%m.%Y %H:%M")
                    if kalan_saat >= 12:
                        durum_notu = f"✅ (Derse {kalan_saat:.1f} saat var - İptal ederseniz krediniz anında iade edilir)"
                    else:
                        durum_notu = f"⚠️ (Derse {kalan_saat:.1f} saat kaldı - 12 saat kuralı gereği iptal edilirse kredi düşer)"
                    
                    lines.append(f"• **{s.class_type.ad}** ({tarih_str}) - Eğitmen: {s.instructor.ad}\n  {durum_notu}")

                yanit = (
                    f"Merhaba {current_member.ad}! Yaklaşan ders rezervasyonlarınız:\n\n"
                    + "\n\n".join(lines) + "\n\n"
                    f"⏱️ **İptal Kuralımız:** Derslerinizi en geç **12 saat öncesine kadar** iptal ettiğinizde krediniz eksiksiz olarak hesabınıza iade edilir."
                )
                oneriler = ["Kalan kredilerim", "Başka ders ekle", "Hesabım"]
                aksiyon = AIActionButton(etiket="Rezervasyonlarım", rota="/hesabim", tip="navigate")
            else:
                yanit = (
                    f"Sayın {current_member.ad}, şu anda tanımlı yaklaşan bir ders rezervasyonunuz bulunmamaktadır.\n\n"
                    f"⏱️ **İptal Kuralımız:** Ders saatinize **en geç 12 saat kalana kadar** yapılan iptallerde krediniz anında iade edilir. "
                    f"12 saatten az süre kaldığında yapılan iptallerde ise kontenjan koruması gereği kredi düşmektedir."
                )
                oneriler = ["Ders rezerve et", "Kalan kredim", "Ders saatleri"]
                aksiyon = AIActionButton(etiket="Ders Rezerve Et", rota="/booking", tip="navigate")
        else:
            yanit = (
                "Ders iptal ve değişiklik kuralımız son derece nettir! ⏱️\n"
                "Ders saatinize **en geç 12 saat kalana kadar** rezervasyonunuzu tek tıkla iptal edebilirsiniz. "
                "12 saat öncesine kadar yapılan iptallerde ders krediniz anında hesabınıza iade edilir. "
                "12 saatten az süre kaldığında yapılan iptallerde ise kontenjan koruması gereği ders hakkı düşmektedir."
            )
            oneriler = ["Ders programına bak", "Giriş Yap", "İletişim"]
            aksiyon = AIActionButton(etiket="Ders Programı", rota="/booking", tip="navigate")

    # --- INTENT 3: VÜCUT ÖLÇÜLERİ & FORM TAKİBİ ---
    elif any(k in prompt for k in ["ölçü", "beden", "kilo", "boy", "bel", "kalça", "bacak", "kol", "sakatlık", "sağlık", "form"]):
        if current_member:
            olculer = []
            if current_member.bel: olculer.append(f"• Bel: {current_member.bel}")
            if current_member.kalca: olculer.append(f"• Kalça: {current_member.kalca}")
            if current_member.kilo: olculer.append(f"• Kilo: {current_member.kilo}")
            if current_member.boy: olculer.append(f"• Boy: {current_member.boy}")
            if current_member.sag_bacak or current_member.sol_bacak:
                olculer.append(f"• Sağ/Sol Bacak: {current_member.sag_bacak or '-'} / {current_member.sol_bacak or '-'}")
            if current_member.sag_kol or current_member.sol_kol:
                olculer.append(f"• Sağ/Sol Kol: {current_member.sag_kol or '-'} / {current_member.sol_kol or '-'}")
            if current_member.saglik_notu:
                olculer.append(f"• Sağlık / Sakatlık Notu: {current_member.saglik_notu}")

            if olculer:
                olcu_str = "\n".join(olculer)
                yanit = (
                    f"Sayın {current_member.ad}, hesabınızda kayıtlı vücut ölçüleriniz ve form bilgileriniz: 📐\n\n"
                    f"{olcu_str}\n\n"
                    f"Eğitmenlerimiz her ders öncesinde ve esnasında bu gelişiminizi ve notlarınızı takip ederek hareketleri size özel modifiye etmektedir."
                )
            else:
                yanit = (
                    f"Sayın {current_member.ad}, henüz profilinize bel, kalça, kilo veya sağlık notu girmediniz. 📐\n\n"
                    f"Hesabım sayfasından ölçülerinizi doldurduğunuzda eğitmenlerimiz gelişiminizi ve ders sırasındaki özel hareket modifikasyonlarınızı yakından takip edecektir!"
                )
            oneriler = ["Ölçülerimi güncelle", "Ders rezerve et", "Kalan kredim"]
            aksiyon = AIActionButton(etiket="Profil / Ölçülerim", rota="/hesabim", tip="navigate")
        else:
            yanit = (
                "Sobo Society'de eğitmenlerimiz gelişiminizi adım adım takip eder! 📐\n"
                "Giriş yapıp Hesabım sayfasından Bel, Kalça, Sağ/Sol Bacak, Kol, Boy, Kilo ve Sağlık/Sakatlık notlarınızı doldurabilirsiniz."
            )
            oneriler = ["Giriş Yap", "Barre nedir?", "Pilates nedir?"]
            aksiyon = AIActionButton(etiket="Giriş Yap", rota="/login", tip="navigate")

    # --- INTENT 4: CANLI DERS PROGRAMI & BOŞ SEANS ARAMA ---
    elif any(k in prompt for k in ["program", "dersler", "saat", "yarın", "bugün", "seans", "boş yer", "kontenjan"]):
        # Aranan özel branş var mı?
        branch_filter = None
        if "barre" in prompt: branch_filter = "barre"
        elif "pilates" in prompt or "reformer" in prompt: branch_filter = "pilates"
        elif "functional" in prompt or "fonksiyonel" in prompt: branch_filter = "functional"
        elif "yoga" in prompt: branch_filter = "yoga"

        stmt_s = (
            select(ClassSession)
            .options(
                selectinload(ClassSession.class_type),
                selectinload(ClassSession.instructor),
            )
            .where(
                ClassSession.durum == SessionDurumu.AKTIF,
                ClassSession.baslangic >= now,
            )
            .order_by(ClassSession.baslangic.asc())
            .limit(20)
        )
        res_s = await db.execute(stmt_s)
        sessions = res_s.scalars().all()

        matching_sessions = []
        for s in sessions:
            if branch_filter and branch_filter not in s.class_type.ad.lower():
                continue
            matching_sessions.append(s)
            if len(matching_sessions) >= 5:
                break

        if matching_sessions:
            lines = []
            for s in matching_sessions:
                tarih_str = s.baslangic.strftime("%d.%m.%Y %H:%M")
                kalan_kontenjan = max(0, s.kontenjan - s.dolu_sayi)
                lines.append(
                    f"• **{s.class_type.ad}** ({tarih_str})\n"
                    f"  Eğitmen: {s.instructor.ad} | Kalan Yer: {kalan_kontenjan}/{s.kontenjan}"
                )
            
            yanit = (
                f"Sobo Society yakındaki canlı ders seanslarımız: 📅\n\n"
                + "\n\n".join(lines) + "\n\n"
                f"Tek tıkla rezervasyonunuzu yapıp yerinizi ayırtabilirsiniz!"
            )
        else:
            yanit = (
                f"Stüdyomuzda gün boyu aktif ders seanslarımız mevcuttur. Branşlarımız: {types_str}. 📅\n"
                f"Canlı Program sayfamızdan tüm ders saatlerini ve boş kontenjanları anlık olarak inceleyebilirsiniz!"
            )
        oneriler = ["Ders Rezerve Et", "İptal kuralı", "Adres"]
        aksiyon = AIActionButton(etiket="Canlı Programa Git", rota="/booking", tip="navigate")

    # --- INTENT 5: BRANŞ TANITIMLARI (BARRE / PILATES / FUNCTIONAL) ---
    elif "barre" in prompt:
        yanit = (
            "Barre dersimiz; bale, pilates ve yoga disiplinlerini ritmik müzik eşliğinde birleştiren, "
            "kasları uzatarak derinlemesine sıkılaşma sağlayan yüksek enerjili imza dersimizdir! 🩰\n"
            "İlk defa katılacaksanız yumuşak tabanlı bir çorap ve rahat spor kıyafet yeterlidir."
        )
        oneriler = ["Barre seansları", "Pilates ile farkı nedir?", "Rezervasyon yap"]
        aksiyon = AIActionButton(etiket="Barre Seanslarını Gör", rota="/booking", tip="navigate")

    elif "pilates" in prompt or "reformer" in prompt:
        yanit = (
            "Pilates ve Reformer seanslarımız; postürünüzü düzeltmeye, omurga sağlığınızı korumaya "
            "ve core (karın/sırt) bölgesi gücünüzü artırmaya odaklanır. 🧘‍♀️\n"
            "Masa başı çalışanlar, bel/sırt hassasiyeti olanlar ve vücudunu hizalamak isteyenler için mükemmel bir seçimdir."
        )
        oneriler = ["Pilates seansları", "Paketler", "Barre nedir?"]
        aksiyon = AIActionButton(etiket="Pilates Seanslarını Gör", rota="/booking", tip="navigate")

    elif "functional" in prompt or "fonksiyonel" in prompt:
        yanit = (
            "Functional antrenmanlarımız; vücut ağırlığı ve ekipmanlarla metabolizmanızı hızlandıran, "
            "dayanıklılık, kondisyon ve kuvvet kazandıran dinamik seanslardır. ⚡"
        )
        oneriler = ["Functional seansları", "Ders programı", "İletişim"]
        aksiyon = AIActionButton(etiket="Functional Seansları", rota="/booking", tip="navigate")

    # --- INTENT 6: ADRES / İLETİŞİM / KONUM ---
    elif any(k in prompt for k in ["nerede", "adres", "konum", "ulaşım", "harita", "iletişim", "telefon", "whatsapp", "instagram"]):
        yanit = (
            "Stüdyomuz Nişantaşı'nın tam kalbinde yer alıyor! 📍\n\n"
            "• **Adres:** Teşvikiye, Abdi İpekçi Cd. No:42, Nişantaşı / İstanbul\n"
            "• **WhatsApp İletişim:** +90 531 603 30 80\n"
            "• **Instagram:** @thesobosociety\n\n"
            "Dilerseniz WhatsApp üzerinden bize tek tıkla mesaj atabilirsiniz!"
        )
        oneriler = ["WhatsApp ile yazın", "Ders programı", "Paketler"]
        aksiyon = AIActionButton(etiket="WhatsApp İletişim", url="https://wa.me/905316033080", tip="external")

    # --- INTENT 7: VARSAYILAN HOŞ GELDİN YANITI ---
    else:
        if current_member:
            kalan_kredi = await bakiye(db, current_member.id)
            yanit = (
                f"Merhaba {current_member.ad}! Ben Sobo AI Asistanınız. 🧘‍♀️\n\n"
                f"Hesabınızda şu an **{kalan_kredi} ders krediniz** bulunmaktadır. "
                f"Rezervasyonlarınız, 12 saatlik iadeli iptal kuralımız, vücut ölçü takibiniz veya ders programımız hakkında dilediğinizi sorabilirsiniz!"
            )
            oneriler = ["Kalan kredim nedir?", "Yaklaşan derslerim var mı?", "Ders programı", "Ölçülerim"]
            aksiyon = AIActionButton(etiket="Ders Rezerve Et", rota="/booking", tip="navigate")
        else:
            yanit = (
                f"Merhaba! Ben Sobo AI Asistanınız. 🧘‍♀️\n\n"
                f"Sobo Society'de size nasıl yardımcı olabilirim? Branşlarımız ({types_str}), "
                f"12 saatlik iadeli ders iptal kuralımız, paket detayları veya stüdyo konumumuz hakkında dilediğinizi sorabilirsiniz."
            )
            oneriler = ["12 Saat İptal Kuralı", "Barre nedir?", "Ders Programı", "Stüdyo Adresi"]
            aksiyon = AIActionButton(etiket="Ders Programını Gör", rota="/booking", tip="navigate")

    return AIChatResponse(
        yanit=yanit,
        oneri_sorular=oneriler,
        aksiyon_butonu=aksiyon,
    )
