import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; 
import 'package:intl/date_symbol_data_local.dart';


// --- AYARLAR ---
const String SU_URL = 'https://ntxofpiomcftqqzvugcr.supabase.co';
const String SU_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im50eG9mcGlvbWNmdHFxenZ1Z2NyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMzAxNjIsImV4cCI6MjA4MDYwNjE2Mn0.Ijh3m5RSRVIc11--fGVTsebw-ocu44k6xKzvoCXln-Q';

// GLOBAL KULLANICI BİLGİLERİ (Demo amaçlıdır)
String currentUserRole = ''; 
String currentUserName = '';
int currentUserId = 0;

// ENUMLAR
const List<String> vehicleTypes = ['MINIVAN', 'PANELVAN', 'UZUN_PANELVAN', 'KAMYONET', '6_TEKER', '8_TEKER', '10_TEKER', 'KIRKAYAK', 'TIR'];
const List<String> bodyTypes = ['STANDART', 'KAPALI', 'TENTELI', 'YUKSEK_YAN', 'ACIK', 'FRIGO', 'LOWBED', 'DAMPERLI', 'KONTEYNER'];

// YARDIMCI FONKSİYON: ENUM Kodlarını Türkçeleştirir
String _translate(String code) {
  switch (code) {
    case 'UZUN_PANELVAN': return 'Uzun Panelvan';
    case '6_TEKER': return '6 Teker';
    case '8_TEKER': return '8 Teker';
    case '10_TEKER': return '10 Teker';
    case 'KIRKAYAK': return 'Kırkayak';
    case 'YUKSEK_YAN': return 'Yüksek Yan Kasa';
    case 'ACIK': return 'Açık Kasa';
    case 'LOWBED': return 'Lowbed';
    case 'STANDART': return 'Standart Kasa';
    case 'TENTELI': return 'Tenteli Kasa';
    case 'FRIGO': return 'Frigo Kasa';
    case 'KAPALI': return 'Kapalı Kasa';
    case 'DAMPERLI': return 'Damperli Kasa';
    case 'KONTEYNER': return 'Konteyner';
    default: return code;
  }
}

// YARDIMCI FONKSİYON: Durum Metinlerini Standartlaştırır
String _getStatusText(String status, bool isShipper) {
    switch (status) {
      case 'PUBLISHED':
        return isShipper ? "Yayında (Pazarda)" : "Yol Atanmadı";
      case 'BOOKED':
        return isShipper ? "Şoför Atandı (Yolda)" : "Aktif Sefer";
      case 'COMPLETED':
        return "Teslim Edildi";
      case 'CANCELED':
        return "İptal Edildi";
      default:
        return status;
    }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // HATA ÇÖZÜMÜ: Türkçe yerel ayar verilerini başlat (LocaleDataException hatası çözümü)
  await initializeDateFormatting('tr', null); 
  
  await Supabase.initialize(url: SU_URL, anonKey: SU_KEY);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EALOGI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- 1. GİRİŞ EKRANI ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userC = TextEditingController(text: "firma");
  final TextEditingController _passC = TextEditingController(text: "123");
  bool _isLoading = false;

void _attemptLogin() {
    setState(() => _isLoading = true);
    String user = _userC.text.trim().toLowerCase();
    String pass = _passC.text.trim();

    Future.delayed(const Duration(seconds: 1), () {
      if (pass == "123") { 
        if (user == "firma") _loginSuccess('SHIPPER', 'Global Lojistik A.Ş.', 1);
        else if (user == "sofor") _loginSuccess('CARRIER', 'Ali Kaptan', 2);
        
        // YENİ KULLANICILAR EKLENDİ
        else if (user == "mavikapi") _loginSuccess('SHIPPER', 'Mavi Kapı Taşımacılık A.Ş.', 3);
        else if (user == "ayse") _loginSuccess('CARRIER', 'Ayşe Şoför', 4);
        
        else _showError("Kullanıcı bulunamadı.");
      } else {
        _showError("Hatalı şifre! (Demo: 123)");
      }
    });
}

  void _loginSuccess(String role, String name, int id) {
    currentUserRole = role;
    currentUserName = name;
    currentUserId = id;
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  void _showError(String msg) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(Icons.hub, size: 80, color: Colors.amber),
            const SizedBox(height: 10),
            Text("EALOGI", style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
            const Text("Güvenli Lojistik Ağı", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),
            _loginInput("Kullanıcı Adı / E-posta", Icons.person, false, _userC),
            const SizedBox(height: 15),
            _loginInput("Şifre", Icons.lock, true, _passC),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _attemptLogin,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("GİRİŞ YAP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const Spacer(),
            const Divider(color: Colors.white24),
            const Text("Hızlı Demo Girişleri", style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: () { _userC.text="firma"; _passC.text="123"; _attemptLogin(); }, child: const Text("Şirket", style: TextStyle(color: Colors.blueAccent))),
                const SizedBox(width: 20),
                TextButton(onPressed: () { _userC.text="sofor"; _passC.text="123"; _attemptLogin(); }, child: const Text("Sürücü", style: TextStyle(color: Colors.greenAccent))),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _loginInput(String label, IconData icon, bool isPass, TextEditingController c) {
    return TextField(controller: c, obscureText: isPass, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: label, hintStyle: const TextStyle(color: Colors.white54), prefixIcon: Icon(icon, color: Colors.white54), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  }
}

// --- 2. ANA EKRAN ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  List<Map<String, dynamic>> _loads = []; 
  List<Map<String, dynamic>> _myJobsOrLoads = []; // SHIPPER için kullanılır
  
  // CARRIER için yeni ayrılmış listeler (UI ayrımı ve limit kontrolü için)
  List<Map<String, dynamic>> _activeBookedLoads = []; 
  List<Map<String, dynamic>> _publishedDriverPosts = [];
  
  // Mesaj Kutusu değişkenleri
  List<Map<String, dynamic>> _inboxThreads = [];
  bool _loadingInbox = false;

  bool _loading = true;
  
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedLoad;
  List<LatLng> _routePoints = [];
  LatLng? _myLocation;

  @override
  void initState() { 
    super.initState(); 
    _fetchAll(); 
    _fetchMyJobsOrLoads();
    _fetchInboxThreads(); 
    _locateUser(); 
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    String postTypeFilter = currentUserRole == 'SHIPPER' ? 'DRIVER' : 'LOAD';
    try {
      final query = Supabase.instance.client.from('loads')
          .select()
          .eq('status', 'PUBLISHED')
          .eq('post_type', postTypeFilter) 
          .order('created_at', ascending: false);
      final data = await query;
      if (mounted) setState(() => _loads = List<Map<String, dynamic>>.from(data));
    } catch (e) { 
      debugPrint("İlan Pazarı Hatası: $e"); 
    } finally { 
      if (mounted) setState(() => _loading = false); 
    }
  }
// _MainScreenState sınıfı içinde
void _showDetails(Map<String, dynamic> load) {
    if (mounted) {
      showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45, minChildSize: 0.2, maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(20),
          child: ListView(controller: controller, children: [
            Center(child: Container(width: 40, height: 4, color: Colors.grey[300], margin: const EdgeInsets.only(bottom: 20))),
            Text(load['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Yük Detayları (Çeviri ve Post Tipi)
            Wrap(spacing: 8, children: [
              Chip(label: Text(_translate(load['required_body'] ?? 'Bilinmiyor')), backgroundColor: Colors.blue[50]), 
              if(load['is_stackable'] == true) const Chip(label: Text("İstiflenebilir"), backgroundColor: Colors.orangeAccent), 
              Chip(label: Text(load['load_type'] ?? 'Yük Tanımı Yok'), backgroundColor: Colors.purple[50]) 
            ]),
            const Divider(height: 30),
            
            // Ebatlar
            if (load['quantity'] != null && load['dim_width'] != null && load['dim_width'] > 0) ...[
              const Text("Yük Ebatları & Adet", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_miniBox("${load['quantity']} Adet", Icons.grid_view), _miniBox("${load['dim_width']}x${load['dim_length']}x${load['dim_height']} cm", Icons.aspect_ratio)]),
              const SizedBox(height: 20),
            ],
            
            // Rota Bilgisi (Helperlar kullanılıyor)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.circle, Colors.green, "Nereden", load['pickup_address']), 
                _verticalLine(), 
                _infoRow(Icons.circle, Colors.red, "Nereye", load['delivery_address'] ?? 'Bilinmiyor'),
              ],
            ),
            const SizedBox(height: 20),

            // Kasa/Ağırlık Bilgisi (Helperlar kullanılıyor)
            Row(children: [
              Expanded(child: _boxInfo(load['post_type']=='DRIVER'?"Kapasite":"Ağırlık", "${load['weight_kg']} KG", Icons.scale)), 
              Expanded(child: _boxInfo("Araç", _translate(load['required_vehicle']), Icons.local_shipping)) 
            ]),
            
            const SizedBox(height: 30),
            Text(
              load['post_type'] == 'DRIVER' 
                ? "KM/ ${NumberFormat.compact().format(load['price'])}₺"
                : NumberFormat.currency(locale: 'tr', symbol: '₺').format(load['price']), 
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.green)
            ),
            const SizedBox(height: 10),
            
            // Butonlar
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _openGoogleMaps(load['pickup_lat'], load['pickup_lng'], load['delivery_lat'], load['delivery_lng']), icon: const Icon(Icons.map), label: const Text("YOL TARİFİ"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: () => _openChatDialog(load), icon: const Icon(Icons.chat_bubble_outline), label: const Text("MESAJ"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)))),
            ]),
            const SizedBox(height: 10),
            
            // Rol Bazlı Aksiyon Butonları
            if(currentUserRole == 'SHIPPER' && load['shipper_id'] == currentUserId) 
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: () => _delete(load['id']), 
                icon: const Icon(Icons.delete), 
                label: const Text("İLANI SİL"), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15))
              ))
            else if (currentUserRole == 'CARRIER' && load['post_type'] != 'DRIVER')
               SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _acceptLoad(load), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("YÜKÜ AL (REZERVE ET)")))
          ]),
        )
      )).whenComplete(() => _clearRoute()); 
    }
}
// GÜNCELLENDİ: Şoför için veriyi ayırıyor
Future<void> _fetchMyJobsOrLoads() async {
    if (currentUserId == 0) return;
    final client = Supabase.instance.client;

    try {
        if (currentUserRole == 'SHIPPER') {
            // SHIPPER: Tüm kendi yayınladığı yükleri çeker (PUBLISHED, BOOKED, vb.)
            final shipperLoads = await client.from('loads')
                .select()
                .eq('shipper_id', currentUserId)
                .order('created_at', ascending: false);
            if (mounted) setState(() => _myJobsOrLoads = List<Map<String, dynamic>>.from(shipperLoads));

        } else if (currentUserRole == 'CARRIER') {
            // CARRIER: Verileri iki ayrı listeye ayırıyoruz
            
            // 1. Kendi atanmış LOAD seferlerini çeker (Aktif Sefer Yükleri)
            final bookedJobs = await client.from('loads')
                .select()
                .eq('carrier_id', currentUserId)
                .eq('status', 'BOOKED')
                .order('created_at', ascending: false);
            
            // 2. Kendi yayınladığı DRIVER ilanlarını çeker (Boşum İlanları)
            final publishedPosts = await client.from('loads')
                .select()
                .eq('shipper_id', currentUserId) 
                .eq('post_type', 'DRIVER')
                .eq('status', 'PUBLISHED') // Sadece aktif yayınları çeker
                .order('created_at', ascending: false);

            if (mounted) {
                setState(() {
                    _activeBookedLoads = List<Map<String, dynamic>>.from(bookedJobs);
                    _publishedDriverPosts = List<Map<String, dynamic>>.from(publishedPosts);
                });
            }
        }
    } catch (e) { 
      debugPrint("Sefer/Yük Hatası: $e"); 
    }
}
  
  // Mesaj Kutusu Başlıklarını Çekme Fonksiyonu
  // _MainScreenState sınıfı içinde
Future<void> _fetchInboxThreads() async {
    if (currentUserId == 0) return;
    setState(() => _loadingInbox = true);
    
    try {
        // SQL Mantığı: Kullanıcının shipper_id veya carrier_id olarak yer aldığı TÜM ilanlara ait mesajları çeker
        // Ancak bu, mesajlaşmanın SADECE bu iki role kısıtlı olduğu anlamına gelir.
        
        // Şirketler için: load.shipper_id = currentUserId
        // Şoförler için: load.shipper_id = currentUserId (kendi boş ilanı için) VEYA load.carrier_id = currentUserId (atanmış yük için)

        // Bu karmaşık mantık yerine, sadece kullanıcının gönderdiği veya aldığı mesajların load_id'lerini toplayan bir filtre uygulayalım:
        
        final response = await Supabase.instance.client
            .from('messages')
            .select('load_id, content, created_at, sender_role, loads!inner(id, title, post_type, shipper_id, carrier_id, users!shipper_id(name), users!carrier_id(name))')
            .order('created_at', ascending: false);

        Map<int, Map<String, dynamic>> threadMap = {};
        
        for (var msg in response as List) {
            final loadId = msg['load_id'] as int;
            final loadData = msg['loads'] as Map<String, dynamic>;
            
            // Kullanıcının mesajı görmesi için koşullar:
            // 1. İlanı veren (Shipper) ise
            // 2. Yükü alan (Carrier) ise
            // 3. Mesajı gönderen kişi ise (Eğer ilan henüz birine atanmadıysa ve anonim mesaj attıysa)
            
            bool isRelevant = loadData['shipper_id'] == currentUserId || loadData['carrier_id'] == currentUserId;

            if (isRelevant) {
                if (!threadMap.containsKey(loadId)) {
                    threadMap[loadId] = {
                        'load_id': loadId,
                        'title': loadData['title'],
                        'post_type': loadData['post_type'],
                        'last_message': msg['content'],
                        'last_message_time': msg['created_at'],
                        // Rolleri isimlendirme için tutabiliriz
                        'shipper_id': loadData['shipper_id'],
                        'carrier_id': loadData['carrier_id']
                    };
                }
            }
        }

        if (mounted) {
            setState(() {
                _inboxThreads = threadMap.values.toList();
                _inboxThreads.sort((a, b) => (b['last_message_time'] as String).compareTo(a['last_message_time'] as String));
            });
        }
    } catch (e) {
        debugPrint("Mesaj Kutusu Çekme Hatası: $e");
    } finally {
        if (mounted) setState(() => _loadingInbox = false);
    }
}

  // YENİ: Şoför Boşum İlanlarını Otomatik İptal Etme
  Future<void> _deleteCarrierDriverPosts() async {
      if (currentUserRole != 'CARRIER') return;

      // Şoförün tüm yayınlanmış DRIVER ilanlarını iptal et (Soft Delete: CANCELED olarak işaretle)
      await Supabase.instance.client
          .from('loads')
          .update({'status': 'CANCELED'}) 
          .eq('shipper_id', currentUserId)
          .eq('post_type', 'DRIVER')
          .eq('status', 'PUBLISHED'); // Sadece yayınlanmış olanları iptal et
      
      // UI'ı güncellemek için listeleri tekrar çek
      _fetchMyJobsOrLoads();
      _fetchAll();
  }


  Future<void> _locateUser() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition();
        if(mounted) {
          setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
          _mapController.move(_myLocation!, 10);
        }
      }
    } catch (e) { debugPrint("Konum: $e"); }
  }

  Future<void> _getRealRoute(LatLng start, LatLng end) async {
    if (mounted) setState(() { _routePoints = []; });
    try {
      final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry']['coordinates'] as List;
        if (mounted) setState(() {
          _routePoints = geometry.map((p) => LatLng(p[1], p[0])).toList();
        });
      }
    } catch (e) { 
      debugPrint("Rota çekme hatası: $e");
      if (mounted) setState(() { _routePoints = [start, end]; }); 
    }
  }

  void _zoomToRoute(Map<String, dynamic> load) {
    if (mounted) setState(() => _selectedLoad = load);
    LatLng p1 = LatLng(load['pickup_lat'], load['pickup_lng']);
    LatLng p2 = LatLng(load['delivery_lat'], load['delivery_lng']);
    _mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds(p1, p2), padding: const EdgeInsets.all(80)));
    _getRealRoute(p1, p2);
  }

  void _clearRoute() {
    if(mounted) {
      setState(() {
        _selectedLoad = null;
        _routePoints = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isShipper = currentUserRole == 'SHIPPER';
    List<Widget> screens = [_map(), _list(), _inbox(), _myJobsOrLoadsScreen(), _profile()];
    int currentIdx = _idx; 
    
    List<NavigationDestination> destinations = [
        const NavigationDestination(icon: Icon(Icons.map_outlined), label: "Harita"), 
        const NavigationDestination(icon: Icon(Icons.list_alt), label: "İlanlar"), 
        const NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: "Mesajlar"), 
        NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: isShipper ? "Yüklerim" : "Seferlerim"), 
        const NavigationDestination(icon: Icon(Icons.person_outline), label: "Profil"), 
    ];

    return Scaffold(
      body: IndexedStack(index: currentIdx, children: screens),
      
      floatingActionButton: (isShipper && (currentIdx == 0 || currentIdx == 1 || currentIdx == 3)) || (!isShipper && (currentIdx == 0 || currentIdx == 1))
        ? FloatingActionButton.extended(
            onPressed: _addDialog, 
            label: Text(isShipper ? "YÜK İLANI VER" : "BOŞUM İLANI VER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            icon: Icon(isShipper ? Icons.add_box : Icons.campaign, color: Colors.white),
            backgroundColor: isShipper ? const Color(0xFF0F172A) : Colors.green[700],
          ) 
        : null,
        
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIdx,
        onDestinationSelected: (i) => setState(() {
          _idx = i;
          if (i == 2) _fetchInboxThreads();
        }),
        backgroundColor: Colors.white,
        destinations: destinations,
      ),
    );
  }

  Widget _map() {
    bool isShipper = currentUserRole == 'SHIPPER';
    
    List<Map<String, dynamic>> mapMarkers = List.from(_loads); 
    
    if (isShipper) {
      mapMarkers.addAll(_myJobsOrLoads.where((load) => load['post_type'] == 'LOAD').toList());
    }
    
    if (!isShipper) {
       mapMarkers.addAll(_activeBookedLoads.where((load) => load['post_type'] == 'LOAD').toList()); 
    }

    Map<int, Map<String, dynamic>> uniqueLoads = {};
    for (var load in mapMarkers) {
      if (load['id'] != null) {
        uniqueLoads[load['id']] = load;
      }
    }
    List<Map<String, dynamic>> markersList = uniqueLoads.values.toList();
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(39.0, 35.0), 
            initialZoom: 6.0,
            onTap: (_, __) => _clearRoute(), 
          ),
          children: [
            TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c', 'd']),
            if (_selectedLoad != null && _routePoints.isNotEmpty)
              PolylineLayer(polylines: [Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.blueAccent)]),
            if (_myLocation != null)
              MarkerLayer(markers: [Marker(point: _myLocation!, width: 60, height: 60, child: Container(decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle), child: Center(child: Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))))))]),

            MarkerLayer(markers: markersList.map((load) {
              bool isSelected = _selectedLoad == load;
              bool isDriverPost = load['post_type'] == 'DRIVER';
              Color markerColor = isDriverPost ? Colors.blue[700]! : Colors.orange[800]!;

              return Marker(
                point: LatLng(load['pickup_lat'] ?? 39.0, load['pickup_lng'] ?? 35.0),
                width: isSelected ? 90 : 70, height: isSelected ? 90 : 70,
                child: GestureDetector(
                  onTap: () { _zoomToRoute(load); _showDetails(load); },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 5)]),
                        child: Text(isDriverPost ? "BOŞ" : "${NumberFormat.compact().format(load['price'])}₺", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: markerColor)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [const BoxShadow(color: Colors.black38, blurRadius: 5)]),
                        child: Icon(isDriverPost ? Icons.local_shipping : Icons.inventory_2, color: Colors.white, size: isSelected ? 30 : 20),
                      ),
                    ],
                  ),
                ),
              );
            }).toList()),
          ],
        ),
      ],
    );
  }

  Widget _list() {
    bool isShipper = currentUserRole == 'SHIPPER';
    if(_loading) return const Center(child: CircularProgressIndicator());
    List<Map<String, dynamic>> displayList = _loads; 
    String title = isShipper ? "Boş Araç Pazarı" : "Yük Pazarı";
    if(displayList.isEmpty) return Center(child: Text(isShipper ? "Yayınlanmış boş araç ilanı yok." : "Yayınlanmış yük ilanı yok."));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: displayList.length,
        itemBuilder: (ctx, i) {
          final load = displayList[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(load['title'] ?? 'İlan', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${load['pickup_address']} -> ${load['delivery_address']}"),
              trailing: Text("${NumberFormat.compact().format(load['price'])}₺", style: TextStyle(color: load['post_type'] == 'LOAD' ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
              onTap: () { _zoomToRoute(load); _showDetails(load); },
            ),
          );
        },
      ),
    );
  }

  // Mesaj Kutusu Listesi Widget'ı
  Widget _inbox() {
      if (_loadingInbox) {
          return Scaffold(appBar: AppBar(title: const Text("Mesajlar")), body: const Center(child: CircularProgressIndicator()));
      }
      
      if (_inboxThreads.isEmpty) {
          return Scaffold(appBar: AppBar(title: const Text("Mesajlar")), body: const Center(child: Text("Aktif mesajlaşmanız bulunmuyor.")));
      }

      return Scaffold(
          appBar: AppBar(title: const Text("Mesajlar")),
          body: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _inboxThreads.length,
              itemBuilder: (context, index) {
                  final thread = _inboxThreads[index];
                  
                  bool isDriverPost = thread['post_type'] == 'DRIVER';
                  
                  String timeAgo = DateFormat('dd MMM HH:mm', 'tr').format(DateTime.parse(thread['last_message_time']).toLocal());
                  
                  return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                          leading: Icon(isDriverPost ? Icons.local_shipping : Icons.inventory_2, color: isDriverPost ? Colors.blue : Colors.orange),
                          title: Text(thread['title']),
                          subtitle: Text(thread['last_message'], maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Text(timeAgo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                          ),
                          onTap: () {
                              showModalBottomSheet(
                                context: context, 
                                isScrollControlled: true, 
                                builder: (ctx) => _ChatScreen(
                                  loadTitle: thread['title'], 
                                  price: 0, 
                                  loadId: thread['load_id']
                                )
                              ).whenComplete(() {
                                _fetchInboxThreads(); 
                              });
                          },
                      ),
                  );
              },
          ),
      );
  }

  // GÜNCELLENDİ: Şoför için UI ayrımı yapıldı
  Widget _myJobsOrLoadsScreen() {
    bool isShipper = currentUserRole == 'SHIPPER';
    if (_loading) return const Center(child: CircularProgressIndicator());
    
    if (isShipper) {
        // SHIPPER UI (Şirket)
        if (_myJobsOrLoads.isEmpty) return const Center(child: Text("Henüz yayınlanmış veya atanmış yükünüz yok."));
        return Scaffold(
          appBar: AppBar(title: const Text("Yayınladığım Yükler")),
          body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myJobsOrLoads.length,
              itemBuilder: (context, index) {
                final load = _myJobsOrLoads[index];
                return _loadCard(load, isShipper); 
              },
          ),
        );
    } else {
        // CARRIER UI (Şoför - İkiye ayrılmış görünüm)
        bool hasActiveJobs = _activeBookedLoads.isNotEmpty;
        bool hasPublishedPosts = _publishedDriverPosts.isNotEmpty;

        if (!hasActiveJobs && !hasPublishedPosts) {
          return const Center(child: Text("Aktif seferiniz veya yayınlanmış ilanınız bulunmamaktadır."));
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Seferlerim / İlanlarım")),
          body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                  // --- BÖLÜM 1: AKTİF SEFER YÜKLERİ (BOOKED LOADS) ---
                  Text("Aktif Sefer Yükleri (${_activeBookedLoads.length})", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                  const Divider(),
                  if (_activeBookedLoads.isEmpty) 
                      const Padding(padding: EdgeInsets.only(bottom: 20), child: Text("Henüz size atanmış aktif bir sefer yok.")),
                  ..._activeBookedLoads.map((load) => _loadCard(load, isShipper)).toList(),

                  const SizedBox(height: 30),

                  // --- BÖLÜM 2: YAYINLANMIŞ BOŞUM İLANLARI (DRIVER POSTS) ---
                  Text("Yayınlanmış Boşum İlanları (${_publishedDriverPosts.length}/5)", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
                  const Divider(),
                  if (_publishedDriverPosts.isEmpty) 
                      const Padding(padding: EdgeInsets.only(bottom: 20), child: Text("Yayınlanmış boşum ilanınız bulunmamaktadır.")),
                  ..._publishedDriverPosts.map((load) => _loadCard(load, isShipper)).toList(),
              ],
          ),
        );
    }
  }

  Widget _profile() => Center(child: ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>const LoginScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Çıkış Yap")));

  Future<Map<String, dynamic>?> _pickLocation(BuildContext context) async {
    return await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationPickerScreen()));
  }

  // --- İLAN EKLEME (Limit Kontrolü Eklendi) ---
  void _addDialog() {
    final _formKey = GlobalKey<FormState>();
    final titleC = TextEditingController(); final priceC = TextEditingController(); 
    final wC = TextEditingController(); final vC = TextEditingController();
    final qtyC = TextEditingController(text: '1'); 
    final dimWC = TextEditingController(); final dimLC = TextEditingController(); final dimHC = TextEditingController();
    final loadTypeC = TextEditingController(); 

    Map<String, dynamic>? pickupLoc;
    Map<String, dynamic>? deliveryLoc;
    
    String? vType; String? bType;
    bool isStack = false; bool isDriver = currentUserRole == 'CARRIER';
    
    List<String> _getFilteredBodyTypes(String? vehicle) {
      if (['MINIVAN', 'PANELVAN', 'UZUN_PANELVAN'].contains(vehicle)) return ['STANDART'];
      if (['KAMYONET', '6_TEKER', '8_TEKER', '10_TEKER'].contains(vehicle)) return ['KAPALI', 'TENTELI', 'YUKSEK_YAN', 'ACIK'];
      if (vehicle == 'TIR' || vehicle == 'KIRKAYAK') return ['KAPALI', 'TENTELI', 'FRIGO', 'LOWBED', 'ACIK', 'DAMPERLI', 'KONTEYNER'];
      return [];
    }

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: StatefulBuilder(builder: (context, setState) {
        List<String> filteredBodyTypes = _getFilteredBodyTypes(vType);
        if (bType != null && !filteredBodyTypes.contains(bType)) {
          bType = filteredBodyTypes.cast<String?>().firstWhere((element) => element == 'STANDART', orElse: () => null);
        } else if (bType == null && filteredBodyTypes.contains('STANDART')) {
           bType = 'STANDART';
        }

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.9,
          padding: const EdgeInsets.all(10),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(isDriver ? "Boş Araç Bildir" : "Yeni Yük İlanı", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  IconButton(onPressed: ()=>Navigator.pop(context), icon: const Icon(Icons.close))
                ]),
                const SizedBox(height: 20),
                
                const Text("Rota (Zorunlu)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                _locationSelector("Nereden", pickupLoc, () async { final loc = await _pickLocation(context); if(loc != null && mounted) setState(() => pickupLoc = loc); }),
                const SizedBox(height: 10),
                _locationSelector(isDriver ? "Gideceğim Şehir" : "Nereye", deliveryLoc, () async { final loc = await _pickLocation(context); if(loc != null && mounted) setState(() => deliveryLoc = loc); }),
                if(pickupLoc == null || deliveryLoc == null) const Padding(padding: EdgeInsets.all(8.0), child: Text("Lütfen rota seçiniz *", style: TextStyle(color: Colors.red, fontSize: 12))),

                const SizedBox(height: 20),
                TextFormField(controller: titleC, decoration: InputDecoration(labelText: isDriver ? "Durum *" : "Başlık *", border: const OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(controller: priceC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isDriver ? "KM Başı Ücret *" : "Fiyat (TL) *", border: const OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: wC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isDriver ? "Kapasite (KG) *" : "Ağırlık (KG) *", border: const OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null)),
                ]),
                
                const SizedBox(height: 10),
                
                if(!isDriver) ...[
                  const Text("Ölçüler & Adet (Zorunlu)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Row(children: [
                    Expanded(child: TextFormField(controller: qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Adet *", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null)),
                    const SizedBox(width: 5), Expanded(child: TextFormField(controller: dimWC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "En *", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null)),
                    const SizedBox(width: 5), Expanded(child: TextFormField(controller: dimLC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Boy *", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null)),
                    const SizedBox(width: 5), Expanded(child: TextFormField(controller: dimHC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Yük *", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextFormField(controller: loadTypeC, decoration: const InputDecoration(labelText: "Yük Tanımı (Örn: Palet, Ev Eşyası) *", border: const OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: vC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Hacim m³ (Opsiyonel)", border: const OutlineInputBorder()))),
                  ]),
                ],

                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: vType, 
                    hint: const Text("Araç *"), 
                    items: vehicleTypes.map((e) => DropdownMenuItem(value: e, child: Text(_translate(e)))).toList(), 
                    onChanged: (v) => setState(() {
                      vType = v;
                      bType = _getFilteredBodyTypes(v).cast<String?>().firstWhere((element) => element == 'STANDART', orElse: () => null);
                    }), 
                    decoration: const InputDecoration(border: const OutlineInputBorder()), 
                    validator: (v) => v == null ? "Seçiniz" : null)),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonFormField<String>(
                    value: bType, 
                    hint: const Text("Kasa *"), 
                    items: filteredBodyTypes.map((e) => DropdownMenuItem(value: e, child: Text(_translate(e)))).toList(), 
                    onChanged: filteredBodyTypes.contains('STANDART') ? null : (v) => setState(() => bType = v), 
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      enabled: !filteredBodyTypes.contains('STANDART')
                    ), 
                    validator: (v) => v == null ? "Seçiniz" : null)),
                ]),

                if(!isDriver) CheckboxListTile(title: const Text("İstiflenebilir?"), value: isStack, onChanged: (v)=>setState(()=>isStack=v!), contentPadding: EdgeInsets.zero),

                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () async { 
                  if(_formKey.currentState!.validate() && pickupLoc != null && deliveryLoc != null) {
                    
                    // İLAN SINIRI KONTROLÜ (CARRIER)
                    if (isDriver) {
                        if (_publishedDriverPosts.length >= 5) {
                            if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maksimum 5 adet boşum ilanı yayınlayabilirsiniz."), backgroundColor: Colors.red));
                                return; 
                            }
                        }
                    }
                    
                    if (vType == null || bType == null) {
                       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen Araç ve Kasa seçiniz!"), backgroundColor: Colors.red));
                       return;
                    }
                    if (!isDriver && loadTypeC.text.isEmpty) { 
                       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen Yük Tipini Belirtin!"), backgroundColor: Colors.red));
                       return;
                    }
                    
                    String finalBType = bType ?? filteredBodyTypes.firstWhere((element) => true, orElse: () => 'STANDART');

                    await _saveLoad(titleC.text, double.tryParse(priceC.text)??0, int.tryParse(wC.text)??0, double.tryParse(vC.text)??0, pickupLoc!, deliveryLoc!, vType ?? 'TIR', finalBType, loadTypeC.text, isStack, isDriver ? 'DRIVER' : 'LOAD', qty: int.tryParse(qtyC.text), dw: int.tryParse(dimWC.text), dl: int.tryParse(dimLC.text), dh: int.tryParse(dimHC.text));
                  } else {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen zorunlu alanları ve rotayı doldurun!"), backgroundColor: Colors.red));
                  }
                }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white), child: const Text("YAYINLA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))))
              ]),
            ),
          ),
        );
      }),
    ));
  }

  // HATA DÜZELTİLDİ: _locationSelector doğru olarak yeniden yazıldı
  Widget _locationSelector(String label, Map<String, dynamic>? loc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: loc != null ? Colors.green : Colors.redAccent), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [Icon(Icons.map, color: loc != null ? Colors.green : Colors.red), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)), Text(loc != null ? loc['address'] : "Haritadan Seçmek İçin Dokun *", style: TextStyle(fontWeight: FontWeight.bold, color: loc != null ? Colors.black : Colors.red, fontSize: 16))])), const Icon(Icons.chevron_right)]),
      ),
    );
  }

  Future<void> _saveLoad(String t, double p, int w, double vol, Map<String, dynamic> pLoc, Map<String, dynamic> dLoc, String vt, String bt, String lt, bool stack, String type, {int? qty, int? dw, int? dl, int? dh}) async {
    final int posterId = currentUserId; 
    
    final Map<String, dynamic> loadData = {
      'title': t, 'price': p, 'weight_kg': w, 'volume_m3': vol, 'load_type': lt, 'is_stackable': stack,
      'pickup_address': pLoc['address'], 'delivery_address': dLoc['address'], 'pickup_lat': pLoc['lat'], 'pickup_lng': pLoc['lng'], 'delivery_lat': dLoc['lat'], 'delivery_lng': dLoc['lng'],
      'required_vehicle': vt, 'required_body': bt, 'status': 'PUBLISHED', 
      'shipper_id': posterId,
      'post_type': type,
      'quantity': qty??1, 'dim_width': dw??0, 'dim_length': dl??0, 'dim_height': dh??0
    };
    
    try {
        await Supabase.instance.client.from('loads').insert(loadData);
        _fetchAll(); 
        _fetchMyJobsOrLoads(); 
        _fetchInboxThreads(); 
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İlan Başarıyla Yayınlandı!"), backgroundColor: Colors.green));
        }
    } catch (e) {
        debugPrint("İlan yayınlama hatası: $e");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("İlan yayınlanamadı. Hata: ${e.toString()}"), backgroundColor: Colors.red));
    }
  }

  // TAKSİCİ MANTIĞI ÇAĞRISI BURADA
  Future<void> _acceptLoad(Map<String, dynamic> load) async {
    try {
      await Supabase.instance.client.from('loads')
          .update({'status': 'BOOKED', 'carrier_id': currentUserId})
          .eq('id', load['id']);
          
      // TAKSİCİ MANTIĞI: Yeni iş alındığında boşum ilanlarını sil
      await _deleteCarrierDriverPosts(); 

      _fetchAll(); 
      _fetchMyJobsOrLoads();
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Yük Rezerve Edildi! Boşum ilanları iptal edildi."), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Yük kabul etme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rezerve Hatası: ${e.toString()}"), backgroundColor: Colors.red));
      }
    }
  }
  
  // Silme Butonunun Çağrısı
  // _MainScreenState sınıfı içinde
// _MainScreenState sınıfı içinde
Future<void> _delete(int id) async { 
    bool success = false;
    
    try {
      // 1. Veritabanından silme işlemini gerçekleştir
      await Supabase.instance.client.from('loads').delete().eq('id', id); 
      
      // 2. Silme başarılı oldu
      success = true;

    } catch (e) {
      debugPrint("İlan silme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Silme Hatası: ${e.toString()}"), backgroundColor: Colors.red));
      }
    } finally {
        if (mounted) {
            // 3. UI/Veri Yenileme (Hata olsa da olmasa da yenileme yapılması gerekir)
            await _fetchAll(); 
            await _fetchMyJobsOrLoads();
            await _fetchInboxThreads(); 

            // 4. Detay penceresini kapat
            // Navigator'ı en sona alarak listenin güncellendiğinden emin oluyoruz.
            if (Navigator.of(context).canPop()) {
                 Navigator.pop(context); 
            }
            
            // 5. Başarı bildirimi
            if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ İlan Başarıyla Silindi!"), backgroundColor: Colors.orange));
            }
        }
    }
}

  // _MainScreenState sınıfı içinde
void _openChatDialog(Map<String, dynamic> load) { 
    if (mounted) {
      showModalBottomSheet(
        context: context, 
        isScrollControlled: true, 
        builder: (ctx) => _ChatScreen(loadTitle: load['title'] ?? 'İlan', price: load['price'], loadId: load['id'])
      ).whenComplete(() {
        // Sohbet penceresi kapandığında listeyi yenile
        _fetchInboxThreads(); 
      });
      
      // KRİTİK DÜZELTME: Sohbet açıldığında listeyi hemen yenile
      // Bu, ilk mesaj atılmadan önce bile Mesajlar sekmesinde başlığın görünmesini sağlar.
      // (Asenkron olarak çalıştırıyoruz)
      _fetchInboxThreads(); 
    }
}

  void _openGoogleMaps(double? pLat, double? pLng, double? dLat, double? dLng) async {
    if(pLat == null || dLat == null || pLng == null || dLng == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rota bilgisi eksik. GPS koordinatları bulunamadı."), backgroundColor: Colors.red));
      return;
    }
    final String mapsUrl = "https://www.google.com/maps/dir/?api=1&origin=$pLat,$pLng&destination=$dLat,$dLng&travelmode=driving";
    final Uri uri = Uri.parse(mapsUrl);
    try { 
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication); 
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harita uygulaması açılamadı. Lütfen Google Haritalar'ın yüklü olduğundan emin olun."), backgroundColor: Colors.red));
      }
    } catch (e) { 
      debugPrint("Harita açma hatası: $e"); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Harita Hatası: ${e.toString()}"), backgroundColor: Colors.red));
    }
  }

  // --- HELPER WIDGET'LAR (Hata veren tüm helper'lar doğru tanımlandı) ---
  
  // HATA DÜZELTİLDİ: _loadCard fonksiyonu eklendi
  Widget _loadCard(Map<String, dynamic> jobOrLoad, bool isShipper) {
    final String status = jobOrLoad['status'] as String? ?? 'PUBLISHED';
    final bool isDriverPost = jobOrLoad['post_type'] == 'DRIVER';

    Color cardColor = isDriverPost ? Colors.green.shade50 : (status == 'BOOKED' ? Colors.blue.shade50 : Colors.grey.shade50);
    IconData icon = isDriverPost ? Icons.campaign : (isShipper ? Icons.assignment : Icons.local_shipping);
    String statusText = _getStatusText(status, isShipper);

    return Card(
        color: cardColor,
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(icon, color: isDriverPost ? Colors.green[700] : (isShipper ? Colors.blue : Colors.green)),
          title: Text(jobOrLoad['title']),
          subtitle: Text(statusText),
          trailing: isDriverPost && !isShipper 
             ? ElevatedButton(
                onPressed: () => _delete(jobOrLoad['id']), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size(80, 35)), 
                child: const Text("SİL")
               )
             : isShipper && status != 'BOOKED'
                ? const Icon(Icons.chevron_right)
                : isShipper && status == 'BOOKED'
                    ? const Icon(Icons.check_circle_outline, color: Colors.green) 
                    : ElevatedButton(onPressed: (){}, child: const Text("TESLİM ET")),
          onTap: () => _showDetails(jobOrLoad),
        ),
    );
  }

  Widget _infoRow(IconData i, Color c, String l, String v) => Row(children: [Icon(i, size: 14, color: c), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10)), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]))]);
  Widget _verticalLine() => Container(margin: const EdgeInsets.only(left: 6), height: 20, width: 2, color: Colors.grey[200]);
  Widget _boxInfo(String l, String v, IconData i) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)), child: Column(children: [Icon(i, size: 20, color: Colors.blueGrey), const SizedBox(height: 5), Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis), Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey))]));
  Widget _miniBox(String txt, IconData i) => Row(children: [Icon(i, size: 16, color: Colors.black54), const SizedBox(width: 5), Text(txt, style: const TextStyle(fontWeight: FontWeight.bold))]);

}

// Konum Seçici Ekranı (Aynı Kaldı)
class LocationPickerScreen extends StatefulWidget { const LocationPickerScreen({super.key}); @override State<LocationPickerScreen> createState() => _LocationPickerScreenState(); }
class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _pickerMapController = MapController();
  LatLng _center = const LatLng(41.0082, 28.9784);
  String _address = "Konum seçiliyor...";
  final TextEditingController _searchC = TextEditingController();
  List<dynamic> _searchResults = [];
  Timer? _debounce;

  void _onPositionChanged(MapPosition position, bool hasGesture) { if (position.center != null) _center = position.center!; }
  Future<void> _getAddress() async { if (mounted) setState(() => _address = "Adres alınıyor..."); try { final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${_center.latitude}&lon=${_center.longitude}&zoom=18&addressdetails=1'); final response = await http.get(url, headers: {'User-Agent': 'com.logicore.app'}); if (response.statusCode == 200) { final data = json.decode(response.body); String full = data['display_name'] ?? "Bilinmeyen Konum"; List<String> parts = full.split(','); String short = parts.length > 2 ? "${parts[0]}, ${parts[1]}" : full; if(mounted) setState(() => _address = short); } } catch (e) { debugPrint("Adres hatası: $e"); if(mounted) setState(() => _address = "Konum: ${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}"); } }
  Future<void> _searchPlace(String query) async { if (_debounce?.isActive ?? false) _debounce!.cancel(); _debounce = Timer(const Duration(milliseconds: 800), () async { if(query.length < 3) return; final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5'); final response = await http.get(url, headers: {'User-Agent': 'com.logicore.app'}); if (response.statusCode == 200 && mounted) { setState(() => _searchResults = json.decode(response.body)); } }); }

  @override Widget build(BuildContext context) { return Scaffold(body: Stack(children: [FlutterMap(mapController: _pickerMapController, options: MapOptions(initialCenter: _center, initialZoom: 12.0, onPositionChanged: _onPositionChanged, onMapEvent: (evt) { if (evt is MapEventMoveEnd) _getAddress(); }), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')]), const Center(child: Icon(Icons.location_on, size: 50, color: Colors.red)), SafeArea(child: Column(children: [Container(margin: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(children: [TextField(controller: _searchC, decoration: InputDecoration(hintText: "İl, İlçe veya Yer Ara...", prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: (){ _searchC.clear(); if(mounted) setState(()=>_searchResults=[]); }), border: InputBorder.none, contentPadding: const EdgeInsets.all(15)), onChanged: _searchPlace), if (_searchResults.isNotEmpty) Container(height: 200, color: Colors.white, child: ListView.builder(itemCount: _searchResults.length, itemBuilder: (ctx, i) { final place = _searchResults[i]; return ListTile(title: Text(place['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis), leading: const Icon(Icons.place, color: Colors.grey), onTap: () { final lat = double.parse(place['lat']); final lon = double.parse(place['lon']); _pickerMapController.move(LatLng(lat, lon), 15); if(mounted) setState(() { _center = LatLng(lat, lon); _searchResults = []; _searchC.clear(); }); _getAddress(); FocusScope.of(context).unfocus(); }); }))]))])), Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Seçilen Konum:", style: TextStyle(color: Colors.grey)), Text(_address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 15), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { if(mounted) Navigator.pop(context, {'lat': _center.latitude, 'lng': _center.longitude, 'address': _address}); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), child: const Text("BU KONUMU ONAYLA")))])))],),); }
}

// GÜNCELLENMİŞ CHAT EKRANI (Realtime Entegre)
class _ChatScreen extends StatefulWidget { final String loadTitle; final dynamic price; final int loadId; const _ChatScreen({required this.loadTitle, required this.price, required this.loadId}); @override State<_ChatScreen> createState() => _ChatScreenState(); }
class _ChatScreenState extends State<_ChatScreen> { 
  final TextEditingController _cnt = TextEditingController(); 
  List<Map<String, dynamic>> _msgs = []; 
  late final StreamSubscription<List<Map<String, dynamic>>> _messagesSubscription;

  @override
  void initState() { 
    super.initState(); 
    _loadInitialMessages(); 
    _setupRealtimeListener(); 
  } 

  @override
  void dispose() {
    _messagesSubscription.cancel(); 
    super.dispose();
  }

  Future<void> _loadInitialMessages() async { 
    try {
        final d = await Supabase.instance.client.from('messages')
            .select()
            .eq('load_id', widget.loadId)
            .order('created_at', ascending: true);
        
        if(mounted) {
            setState(() => _msgs = List<Map<String, dynamic>>.from(d));
        }
    } catch (e) {
        debugPrint("İlk mesajlar yüklenirken hata: $e");
    }
  }

  void _setupRealtimeListener() {
    final client = Supabase.instance.client;
    
    _messagesSubscription = client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('load_id', widget.loadId) 
        .order('created_at', ascending: true)
        .listen((data) {
            if(mounted) {
                setState(() {
                    _msgs = List<Map<String, dynamic>>.from(data);
                });
            }
        });
  }

  Future<void> _send() async { 
    if(_cnt.text.isEmpty) return; 

    try {
        await Supabase.instance.client.from('messages').insert({
            'load_id': widget.loadId, 
            'content': _cnt.text, 
            'sender_role': currentUserRole
        });
        
        _cnt.clear(); 
        
    } catch (e) {
        debugPrint("Mesaj gönderme hatası: $e");
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mesaj gönderilemedi: ${e.toString()}"), backgroundColor: Colors.red));
        }
    }
  } 

  @override 
  Widget build(BuildContext context) { 
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), 
      child: Container(
        height: 500, 
        padding: const EdgeInsets.all(20), 
        child: Column(
          children: [
            Text("Pazarlık: ${widget.loadTitle}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
            const Divider(), 
            Expanded(
              child: ListView.builder(
                reverse: true, 
                itemCount: _msgs.length, 
                itemBuilder: (c, i) { 
                    final m = _msgs[_msgs.length - 1 - i]; 
                    bool me = m['sender_role'] == currentUserRole; 
                    
                    return Align(
                        alignment: me ? Alignment.centerRight : Alignment.centerLeft, 
                        child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5), 
                            padding: const EdgeInsets.all(10), 
                            decoration: BoxDecoration(
                                color: me ? Colors.blue[100] : Colors.grey[200], 
                                borderRadius: BorderRadius.circular(10)
                            ), 
                            child: Column(
                                crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                    Text(m['content']),
                                    const SizedBox(height: 4),
                                    Text(
                                        DateFormat('HH:mm').format(DateTime.parse(m['created_at']).toLocal()), 
                                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    ),
                                ],
                            )
                        )
                    ); 
                }
              )
            ), 
            Row(
              children: [
                Expanded(child: TextField(controller: _cnt, decoration: const InputDecoration(hintText: "Mesaj..."))), 
                IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Colors.blue))
              ]
            )
          ]
        )
      )
    ); 
  } 
}