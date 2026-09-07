import 'package:flutter/material.dart';
import '../../models/member_models.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../theme/sobo_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PackagesView extends StatefulWidget {
  const PackagesView({super.key});

  @override
  State<PackagesView> createState() => _PackagesViewState();
}

class _PackagesViewState extends State<PackagesView> {
  List<PackageDTO> _packages = <PackageDTO>[];
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    final String? token = await StorageService.getToken();
    _isLoggedIn = token != null && token.isNotEmpty;

    try {
      final dynamic res = await ApiClient.get('/packages');
      final List<PackageDTO> list = <PackageDTO>[];
      if (res is List) {
        for (final dynamic item in res) {
          list.add(PackageDTO.fromJson(item));
        }
      }
      if (mounted) {
        setState(() {
          _packages = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchWhatsApp(String text) async {
    final String encoded = Uri.encodeComponent(text);
    final Uri waUri = Uri.parse("whatsapp://send?phone=905316033080&text=$encoded");
    final Uri webUri = Uri.parse("https://wa.me/905316033080?text=$encoded");

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoboTheme.ivory,
      appBar: AppBar(
        backgroundColor: SoboTheme.ivory,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'DERS PAKETLERİ & ÜYELİK',
          style: SoboTheme.fontSerif(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            color: SoboTheme.espresso,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SoboTheme.espresso))
          : RefreshIndicator(
              onRefresh: _loadPackages,
              color: SoboTheme.espresso,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Banner Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SoboTheme.sandLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: SoboTheme.line),
                      boxShadow: [
                        BoxShadow(
                          color: SoboTheme.espresso.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.card_membership_rounded, color: SoboTheme.mocha, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'ÜYELİK PAKETLERİ 💳',
                              style: SoboTheme.fontSerif(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: SoboTheme.espresso,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sobo Class Paket Seçenekleri',
                          style: SoboTheme.fontSerif(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: SoboTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLoggedIn
                              ? 'Hedefinize en uygun ders paketini seçin. Satın Al butonuna basarak WhatsApp üzerinden kayıt yaptırabilirsiniz.'
                              : '🔒 Paket fiyatlarımız Sobo Society üyelerine özel sunulmaktadır. WhatsApp butonuna tıklayarak fiyat bilgisi alabilir ve anında üye olabilirsiniz.',
                          style: SoboTheme.fontSans(
                            fontSize: 12,
                            color: SoboTheme.secondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'PAKET SEÇENEKLERİ',
                    style: SoboTheme.fontSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: SoboTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Packages List
                  if (_packages.isNotEmpty)
                    ..._packages.map((pkg) {
                      final bool is12Ders = pkg.dersAdedi == 12 || pkg.ad.contains('12');
                      final bool isBireysel = pkg.ad.toLowerCase().contains('bireysel') || pkg.ad.toLowerCase().contains('özel');
                      final String priceStr = _isLoggedIn
                          ? '₺${pkg.fiyatTl.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} TL'
                          : 'Üyelere Özel';

                      final String formattedVal = pkg.gecerlilikGun % 7 == 0
                          ? '${pkg.gecerlilikGun ~/ 7} Hafta Kullanım'
                          : '${pkg.gecerlilikGun} Gün Kullanım';

                      return _buildPackageCard(
                        title: pkg.ad,
                        isPopular: is12Ders,
                        badge: is12Ders ? 'POPÜLER SEÇİM ⭐ • $formattedVal' : formattedVal,
                        price: priceStr,
                        details: '${pkg.dersAdedi} Adet Class Seansı • ${isBireysel ? 'Kişiye Özel Birebir Eğitmen' : 'Butik Sınıf (Maks 5 Kişi)'} • 12 Saat Öncesine Kadar İade',
                      );
                    })
                  else ...[
                    _buildPackageCard(
                      title: 'Barre Class 4 Ders',
                      isPopular: false,
                      badge: '4 Hafta (30 Gün) Kullanım',
                      price: _isLoggedIn ? '₺3.200 TL' : 'Üyelere Özel',
                      details: '4 Adet Barre Class Dersi • Butik Sınıf (Maks 5 Kişi) • 12 Saat Önceden İade',
                    ),
                    _buildPackageCard(
                      title: 'Sobo Class 8 Ders',
                      isPopular: false,
                      badge: '6 Hafta (45 Gün) Kullanım',
                      price: _isLoggedIn ? '₺5.800 TL' : 'Üyelere Özel',
                      details: '8 Adet Barre Class Dersi • Butik Sınıf (Maks 5 Kişi) • Mobil İle Kolay Takip',
                    ),
                    _buildPackageCard(
                      title: 'Sobo Class 12 Ders',
                      isPopular: true,
                      badge: 'POPÜLER SEÇİM ⭐ • 8 Hafta Kullanım',
                      price: _isLoggedIn ? '₺8.400 TL' : 'Üyelere Özel',
                      details: '12 Adet Barre Class Dersi • Butik Sınıf (Maks 5 Kişi) • Öncelikli Bekleme Sırası',
                    ),
                    _buildPackageCard(
                      title: 'Reformer Pilates - Bireysel Standart',
                      isPopular: false,
                      badge: '8 Hafta (60 Gün) Kullanım',
                      price: _isLoggedIn ? '₺9.500 TL' : 'Üyelere Özel',
                      details: '12 Bireysel Reformer Seansı • Özel Reformer Cihazı • Postür Analizi',
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPackageCard({
    required String title,
    required bool isPopular,
    required String badge,
    required String price,
    required String details,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPopular ? SoboTheme.sandLight : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPopular ? SoboTheme.espresso : SoboTheme.line,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: SoboTheme.espresso.withOpacity(isPopular ? 0.08 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: SoboTheme.fontSerif(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: SoboTheme.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPopular ? SoboTheme.espresso : SoboTheme.sand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  price,
                  style: SoboTheme.fontSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? Colors.white : SoboTheme.espresso,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPopular ? SoboTheme.espresso.withOpacity(0.12) : SoboTheme.sage.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: SoboTheme.fontSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPopular ? SoboTheme.espresso : SoboTheme.sage,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            details,
            style: SoboTheme.fontSans(
              fontSize: 12,
              color: SoboTheme.secondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _launchWhatsApp(
              _isLoggedIn
                  ? "Merhaba! Sobo Society'den '$title ($price)' paketini satın almak istiyorum. Yardımcı olabilir misiniz?"
                  : "Merhaba! Sobo Society'nin '$title' paketi ve güncel fiyatlar hakkında bilgi almak istiyorum.",
            ),
            icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
            label: Text(
              _isLoggedIn ? 'WHATSAPP İLE SATIN AL' : 'WHATSAPP İLE FİYAT BİLGİSİ AL',
              style: SoboTheme.fontSans(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: SoboTheme.espresso,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
