
LOGIUBER, lojistik sektöründeki verimsizliği ve "boş dönüş" sorununu çözen; yük veren firmalar ile taşıyıcıları akıllı harita üzerinde buluşturan, uçtan uca dijital bir lojistik pazar yeridir.

🌟 Temel Özellikler

🏢 Şirket Paneli (Yük Veren)

Detaylı İlan Verme: Araç tipi, kasa tipi, tonaj, hacim ve detaylı ölçü (En/Boy/Yükseklik) girerek nokta atışı ilan oluşturma.

Google Maps Entegrasyonu: Harita üzerinden pinleme yöntemiyle hassas adres seçimi.

Zorunlu Alan Kontrolü: Hatalı veri girişini engelleyen katı validasyon kuralları.

Canlı Takip: Yüklerin ve boş araçların harita üzerinde anlık takibi.

Gizlilik: Sadece kendi yüklerini ve boş araçları görür (Rakip firma yükleri gizlenir).


🚚 Sürücü Paneli (Taşıyıcı)

"Boşum" İlanı: Dönüş yükü bulmak için konum, araç tipi ve KM başı ücret bilgisiyle ilan açabilme.

Akıllı Eşleşme: Sadece kendisine uygun yükleri haritada ve listede görür.

Hızlı Rezervasyon: "Hemen Al" butonu ile yükü rezerve etme ve diğerlerinden gizleme.

Rota Planlama: Yüke tıklayınca OSRM altyapısı ile gerçek yol rotasını (Polyline) görme.

Navigasyon: Tek tuşla Google Maps'e bağlanarak yükleme veya boşaltma noktasına rota alma.


💬 İletişim ve Etkileşim

Canlı Pazarlık: İlan üzerinden direkt olarak mesajlaşma (Chat) başlatma.

Çift Yönlü Akış: Şirket sürücüye, sürücü şirkete teklif verebilir.


🛠️ Kullanılan Teknolojiler

Frontend: Flutter (Dart) - Hibrit Mimari (iOS/Android/Web)

Backend & Database: Supabase (PostgreSQL)

Harita Altyapısı: flutter_map (OpenStreetMap) + CartoDB Voyager Teması

Routing (Rota Çizimi): OSRM (Open Source Routing Machine) API

Konum Servisleri: geolocator, latlong2

Adres Çözümleme: Nominatim API (Reverse Geocoding)

🗺️ Yol Haritası (Roadmap)
[x] Temel Harita ve İlan Fonksiyonları

[x] Rol Bazlı Giriş ve Yetkilendirme

[x] Canlı Mesajlaşma

[ ] Fotoğraf ve Evrak Yükleme (POD) (Geliştiriliyor)

[ ] Cüzdan ve Bakiye Yönetimi (Planlandı)

[ ] Push Bildirimleri (Planlandı)

