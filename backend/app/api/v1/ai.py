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
Sobo Society, Afyonkarahisar Uydukent'te yer alan boutique bir Barre, Pilates ve Functional antrenman stüdyosudur.
Slogan: "Not just a studio. It's a society."
Marka Teması: Pantone 17-1230 TCX (Mocha Mousse #A47864)

Branşlarımız & Ders Tipleri:
1. Barre: Bale, pilates ve yoga hareketlerini ritmik müzik eşliğinde birleştiren, kas uzatan ve sıkılaştıran yüksek enerjili ders.
2. Pilates & Reformer: Postür düzenleyen, core bölgesini güçlendiren ve esneklik kazandıran klasik/modern pilates ve kişiye özel reformer cihazı.
3. Functional: Vücudun kendi ağırlığı ve serbest ekipmanlarla dayanıklılık ve kuvvet arttıran fonksiyonel antrenman.
4. Yoga: Nefes, esneklik ve zihinsel denge odaklı seanslar.

Resmi İptal & Ders Kuralları:
- İptal Süresi: Ders iptalleri dersten en geç 12 saat öncesine kadar yapıldığında ders hakkı iadesi ile tamamlanır. 12 saatten az kala yapılan iptallerde ders yapılmış sayılır.
- Paket Kullanım Süreleri: 4 derslik paket 30 Gün / 4 Hafta, 8 derslik paket 45 Gün / 6 Hafta, 12 derslik paket 60 Gün / 8 Hafta geçerlidir.
- Özel Paketler: İhtiyaca göre kişiye/üyeye özel ders hakkı, süresi ve paket adı tanımlanabilmektedir.
- Vücut Ölçüleri & Form Takibi: Üyelerimiz /hesabim sayfasından Bel, Kalça, Sağ/Sol İç Bacak, Sağ/Sol Bacak, Sağ/Sol Kol, Boy, Kilo ve Sağlık/Sakatlık notlarını girebilir. Eğitmenlerimiz gelişimlerini yakından takip eder.

Adres: Cumhuriyet Mah. 16. Sk. No:3 D:13 Metropol Plaza 1. Kat (İstek Koleji Arkası, Uydukent), Afyonkarahisar
WhatsApp İletişim: +90 531 603 30 80
Email: sobosociety@gmail.com
Instagram: @thesobosociety
"""


@router.post("/chat", response_model=AIChatResponse)
async def ai_concierge_chat(
    body: AIChatRequest,
    db: AsyncSession = Depends(get_db),
    current_member: Member | None = Depends(get_optional_current_member),
):
    """Sobo AI 2.0 Concierge — Canlı veritabanı bağlamı, ders paketleri, üye ders hakları ve kişiselleştirilmiş yanıtlar sunar."""
    prompt = body.mesaj.strip().lower()
    now = datetime.now()

    # Dynamic Class & Schedule Context from Database
    res_types = await db.execute(select(ClassType).where(ClassType.aktif == True))
    class_types = res_types.scalars().all()
    types_str = ", ".join([t.ad for t in class_types]) if class_types else "Barre, Reformer Pilates, Functional, Yoga"

    # --- INTENT 1: DERS PAKETLERİ & FİYAT SORGULARI ---
    if any(k in prompt for k in ["paket", "paketler", "fiyat", "ücret", "ucret", "ne kadar", "kaç tl", "üye", "üyelik", "satın al"]):
        if current_member:
            res_pkg = await db.execute(select(Package).where(Package.aktif == True).order_by(Package.fiyat_kurus.asc()))
            db_pkgs = res_pkg.scalars().all()

            if db_pkgs:
                pkg_lines = []
                for p in db_pkgs:
                    sure_str = f"{p.gecerlilik_gun // 7} Hafta" if p.gecerlilik_gun % 7 == 0 else f"{p.gecerlilik_gun} Gün"
                    pkg_lines.append(f"• **{p.ad}**: {p.ders_adedi} Ders ({sure_str} Kullanım)")
                
                pkgs_text = "\n".join(pkg_lines)
                yanit = (
                    f"Sayın {current_member.ad}, Sobo Society güncel ders paketlerimiz: 💳\n\n"
                    f"{pkgs_text}\n\n"
                    f"✨ Paket fiyatlandırmaları ve kişiye özel üyelik seçenekleri hakkında detaylı bilgi almak için WhatsApp hattımız üzerinden stüdyo yöneticimiz Eda Hanım ile doğrudan iletişime geçebilirsiniz."
                )
            else:
                yanit = (
                    f"Sayın {current_member.ad}, Sobo Society güncel ders paketlerimiz: 💳\n\n"
                    "• **Barre Class 4 Ders**: 30 Gün / 4 Hafta Kullanım\n"
                    "• **Barre Class 8 Ders (Popüler ⭐)**: 45 Gün / 6 Hafta Kullanım\n"
                    "• **Barre Class 12 Ders**: 60 Gün / 8 Hafta Kullanım\n"
                    "• **Bireysel Class Paketleri**: Kişiye özel birebir eğitmen eşliğinde 8 ve 12 derslik seanslar.\n\n"
                    "✨ Fiyatlandırma ve satın alım detayları için WhatsApp üzerinden stüdyo yöneticimizle iletişime geçebilirsiniz."
                )
            oneriler = ["WhatsApp ile Fiyat Al", "Ders programı", "12 Saat İptal Kuralı"]
            aksiyon = AIActionButton(
                etiket="WhatsApp İle Fiyat Bilgisi Al",
                url="https://wa.me/905316033080?text=Merhaba!%20Sobo%20Society%20ders%20paketleri%20ve%20güncel%20fiyatlar%20hakkında%20bilgi%20almak%20istiyorum.",
                tip="external"
            )
        else:
            # Üye değilse / giriş yapmamışsa -> Fiyat gösterilmez, WhatsApp'a yönlendirilir!
            yanit = (
                "Sobo Society'de 4'lü, 8'li ve 12'li Grup (Barre, Yoga, Functional) ve Kişiye Özel Bireysel Class paketlerimiz mevcuttur. 💳\n\n"
                "Güncel paket fiyatları ve stüdyo üyelik bilgisi stüdyo yöneticimiz tarafından doğrudan WhatsApp üzerinden iletilmektedir.\n\n"
                "Paket fiyatlarını öğrenmek ve stüdyomuzu ziyaret etmek için WhatsApp hattımızdan bize dilediğiniz zaman yazabilirsiniz!"
            )
            oneriler = ["WhatsApp Fiyat Bilgisi", "Ders Programı", "Stüdyo Nerede?"]
            aksiyon = AIActionButton(
                etiket="WhatsApp İle Fiyat Bilgisi Al",
                url="https://wa.me/905316033080?text=Merhaba!%20Sobo%20Society%20ders%20paketleri%20ve%20güncel%20fiyatlar%20hakkında%20bilgi%20almak%20istiyorum.",
                tip="external"
            )

    # --- INTENT 2: KALAN DERS HAKKI & BAKİYE SORGULARI ---
    elif any(k in prompt for k in ["kalan ders", "kaç ders", "bakiye", "ders hakkım", "haklarım"]):
        if current_member:
            kalan_ders = await bakiye(db, current_member.id)
            stmt_pkg = (
                select(MemberPackage, Package)
                .join(Package, MemberPackage.package_id == Package.id)
                .where(MemberPackage.member_id == current_member.id)
            )
            pkg_res = await db.execute(stmt_pkg)
            packages = pkg_res.all()

            if kalan_ders > 0:
                pkg_info = ""
                if packages:
                    pkg_list = [f"• {p[1].ad} (Başlangıç: {p[0].baslangic.strftime('%d.%m.%Y')})" for p in packages]
                    pkg_info = "\nTanımlı Paketleriniz:\n" + "\n".join(pkg_list)

                yanit = (
                    f"Merhaba {current_member.ad}! 🧘‍♀️\n\n"
                    f"Hesabınızda şu an toplam **{kalan_ders} adet ders hakkınız** bulunmaktadır.{pkg_info}\n\n"
                    f"Hemen bir seans rezerve etmek ister misiniz?"
                )
                oneriler = ["Ders programına bak", "İptal kuralı nedir?", "Vücut ölçülerim"]
                aksiyon = AIActionButton(etiket="Ders Rezerve Et", rota="/booking", tip="navigate")
            else:
                yanit = (
                    f"Merhaba {current_member.ad}! 💳\n\n"
                    f"Hesabınızda şu an aktif kullanılabilir ders hakkınız bulunmamaktadır. "
                    f"4'lü, 8'li veya 12'li paketlerimizden dilediğinizi seçerek derslere katılabilirsiniz!"
                )
                oneriler = ["Paket fiyatları", "Barre nedir?", "İletişime geç"]
                aksiyon = AIActionButton(etiket="Paket Satın Al / İletişim", url="https://wa.me/905316033080", tip="external")
        else:
            yanit = (
                "Sobo Society'de 4'lü, 8'li ve 12'li grup ve bireysel ders paketlerimiz mevcuttur. 💳\n"
                "Kendi hesabınızdaki kalan ders haklarınızı ve paket durumunuzu görmek için lütfen giriş yapın."
            )
            oneriler = ["Giriş yap", "Paket fiyatları", "Ders programı"]
            aksiyon = AIActionButton(etiket="Giriş Yap", rota="/login", tip="navigate")

    # --- INTENT 3: İPTAL KURALI & YAKLAŞAN DERSLER ---
    elif any(k in prompt for k in ["iptal", "iade", "değişim", "kaç saat", "seansım", "randevum", "dersim var mı", "yaklaşan"]):
        if current_member:
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
                        durum_notu = f"✅ (Derse {kalan_saat:.1f} saat var - İptal ederseniz ders hakkınız anında iade edilir)"
                    else:
                        durum_notu = f"⚠️ (Derse {kalan_saat:.1f} saat kaldı - 12 saat kuralı gereği iptal edilirse ders hakkı düşer)"
                    
                    lines.append(f"• **{s.class_type.ad}** ({tarih_str}) - Eğitmen: {s.instructor.ad}\n  {durum_notu}")

                yanit = (
                    f"Merhaba {current_member.ad}! Yaklaşan ders rezervasyonlarınız:\n\n"
                    + "\n\n".join(lines) + "\n\n"
                    f"⏱️ **İptal Kuralımız:** Derslerinizi en geç **12 saat öncesine kadar** iptal ettiğinizde ders hakkınız eksiksiz olarak hesabınıza iade edilir."
                )
                oneriler = ["Kalan ders haklarım", "Başka ders ekle", "Hesabım"]
                aksiyon = AIActionButton(etiket="Rezervasyonlarım", rota="/hesabim", tip="navigate")
            else:
                yanit = (
                    f"Sayın {current_member.ad}, şu anda tanımlı yaklaşan bir ders rezervasyonunuz bulunmamaktadır.\n\n"
                    f"⏱️ **İptal Kuralımız:** Ders saatinize **en geç 12 saat kalana kadar** yapılan iptallerde ders hakkınız anında iade edilir. "
                    f"12 saatten az süre kaldığında yapılan iptallerde ise kontenjan koruması gereği ders hakkı kullanılır."
                )
                oneriler = ["Ders rezerve et", "Kalan derslerim", "Ders saatleri"]
                aksiyon = AIActionButton(etiket="Ders Rezerve Et", rota="/booking", tip="navigate")
        else:
            yanit = (
                "Ders iptal ve değişiklik kuralımız son derece nettir! ⏱️\n"
                "Ders saatinize **en geç 12 saat kalana kadar** rezervasyonunuzu tek tıkla iptal edebilirsiniz. "
                "12 saat öncesine kadar yapılan iptallerde ders hakkınız anında hesabınıza iade edilir. "
                "12 saatten az süre kaldığında yapılan iptallerde ise kontenjan koruması gereği ders hakkı düşmektedir."
            )
            oneriler = ["Ders programına bak", "Giriş Yap", "İletişim"]
            aksiyon = AIActionButton(etiket="Ders Programı", rota="/booking", tip="navigate")

    # --- INTENT 4: VÜCUT ÖLÇÜLERİ & FORM TAKİBİ ---
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
            oneriler = ["Ölçülerimi güncelle", "Ders rezerve et", "Kalan ders haklarım"]
            aksiyon = AIActionButton(etiket="Profil / Ölçülerim", rota="/hesabim", tip="navigate")
        else:
            yanit = (
                "Sobo Society'de eğitmenlerimiz gelişiminizi adım adım takip eder! 📐\n"
                "Giriş yapıp Hesabım sayfasından Bel, Kalça, Sağ/Sol Bacak, Kol, Boy, Kilo ve Sağlık/Sakatlık notlarınızı doldurabilirsiniz."
            )
            oneriler = ["Giriş Yap", "Barre nedir?", "Pilates nedir?"]
            aksiyon = AIActionButton(etiket="Giriş Yap", rota="/login", tip="navigate")

    # --- INTENT 5: CANLI DERS PROGRAMI & BOŞ SEANS ARAMA ---
    elif any(k in prompt for k in ["program", "dersler", "saat", "yarın", "bugün", "seans", "boş yer", "kontenjan"]):
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
        oneriler = ["Ders Rezerve Et", "Paket Fiyatları", "Adres"]
        aksiyon = AIActionButton(etiket="Canlı Programa Git", rota="/booking", tip="navigate")

    # --- INTENT 6: BRANŞ TANITIMLARI (BARRE / PILATES / FUNCTIONAL) ---
    elif "barre" in prompt:
        yanit = (
            "Barre dersimiz; bale, pilates ve yoga disiplinlerini ritmik müzik eşliğinde birleştiren, "
            "kasları uzatarak derinlemesine sıkılaşma sağlayan yüksek enerjili imza dersimizdir! 🩰\n"
            "İlk defa katılacaksanız yumuşak tabanlı bir çorap ve rahat spor kıyafet yeterlidir."
        )
        oneriler = ["Barre seansları", "Paket Fiyatları", "Rezervasyon yap"]
        aksiyon = AIActionButton(etiket="Barre Seanslarını Gör", rota="/booking", tip="navigate")

    elif "pilates" in prompt or "reformer" in prompt:
        yanit = (
            "Pilates ve Reformer seanslarımız; postürünüzü düzeltmeye, omurga sağlığınızı korumaya "
            "ve core (karın/sırt) bölgesi gücünüzü artırmaya odaklanır. 🧘‍♀️\n"
            "Masa başı çalışanlar, bel/sırt hassasiyeti olanlar ve vücudunu hizalamak isteyenler için mükemmel bir seçimdir."
        )
        oneriler = ["Pilates seansları", "Paket Fiyatları", "Barre nedir?"]
        aksiyon = AIActionButton(etiket="Pilates Seanslarını Gör", rota="/booking", tip="navigate")

    elif "functional" in prompt or "fonksiyonel" in prompt:
        yanit = (
            "Functional antrenmanlarımız; vücut ağırlığı ve ekipmanlarla metabolizmanızı hızlandıran, "
            "dayanıklılık, kondisyon ve kuvvet kazandıran dinamik seanslardır. ⚡"
        )
        oneriler = ["Functional seansları", "Paket Fiyatları", "İletişim"]
        aksiyon = AIActionButton(etiket="Functional Seansları", rota="/booking", tip="navigate")

    # --- INTENT 7: ADRES / İLETİŞİM / KONUM ---
    elif any(k in prompt for k in ["nerede", "adres", "konum", "ulaşım", "harita", "iletişim", "telefon", "whatsapp", "instagram"]):
        yanit = (
            "Sobo Society Stüdyomuz Afyonkarahisar Uydukent'te Metropol Plaza'da yer almaktadır! 📍\n\n"
            "• **Adres:** Cumhuriyet Mah. 16. Sk. No:3 D:13 Metropol Plaza 1. Kat (İstek Koleji Arkası, Uydukent) Afyonkarahisar\n"
            "• **WhatsApp İletişim:** +90 531 603 30 80\n"
            "• **E-posta:** sobosociety@gmail.com\n"
            "• **Instagram:** @thesobosociety\n\n"
            "Dilerseniz WhatsApp butonuna tıklayarak bize anında yazabilir ve canlı konum isteyebilirsiniz!"
        )
        oneriler = ["WhatsApp ile yazın", "Ders programı", "Paket Fiyatları"]
        aksiyon = AIActionButton(etiket="WhatsApp İletişim", url="https://wa.me/905316033080", tip="external")

    # --- INTENT 8: VARSAYILAN HOŞ GELDİN / GENEL YANIT ---
    else:
        if current_member:
            kalan_ders = await bakiye(db, current_member.id)
            yanit = (
                f"Merhaba {current_member.ad}! Ben Sobo AI Asistanınız. 🧘‍♀️\n\n"
                f"Hesabınızda şu an **{kalan_ders} adet ders hakkınız** bulunmaktadır.\n"
                f"Ders paketleri ve fiyatlarımız, rezervasyonlarınız, 12 saatlik iadeli iptal kuralımız, vücut ölçü takibiniz veya ders programımız hakkında dilediğinizi sorabilirsiniz!"
            )
            oneriler = ["Paket fiyatları", "Yaklaşan derslerim var mı?", "Ders programı", "Ölçülerim"]
            aksiyon = AIActionButton(etiket="Ders Programı", rota="/booking", tip="navigate")
        else:
            yanit = (
                f"Merhaba! Ben Sobo AI Asistanınız. 🧘‍♀️\n\n"
                f"Sobo Society'de size nasıl yardımcı olabilirim? Branşlarımız ({types_str}), "
                f"güncel ders paketlerimizin fiyatları, 12 saatlik iadeli ders iptal kuralımız veya stüdyo konumumuz hakkında dilediğinizi sorabilirsiniz."
            )
            oneriler = ["Paket fiyatları", "12 Saat İptal Kuralı", "Barre nedir?", "Ders Programı"]
            aksiyon = AIActionButton(etiket="Ders Programını Gör", rota="/booking", tip="navigate")

    return AIChatResponse(
        yanit=yanit,
        oneri_sorular=oneriler,
        aksiyon_butonu=aksiyon,
    )
