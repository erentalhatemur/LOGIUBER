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

// --- AYARLAR ---
const String SU_URL = 'https://wpzsppbxeofwxcxurnxf.supabase.co';
const String SU_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwenNwcGJ4ZW9md3hjeHVybnhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3NTAxOTksImV4cCI6MjA3OTMyNjE5OX0.-D9W_XrUKKGnQMg0D0vbBgsFABEddgNgnHxvV7IfQ-k';

// GLOBAL
String currentUserRole = ''; 
String currentUserName = '';
int currentUserId = 0;

// --- YENİ ARAÇ VE KASA HİYERARŞİSİ (FAZ 3) ---
const List<String> vehicleList = [
  'Minivan', 'Panelvan', 'Uzun Panelvan', // Grup 1
  'Kamyonet', '6 Teker', '8 Teker', '10 Teker', 'Kırkayak', // Grup 2
  'TIR' // Grup 3
];

// Dinamik Kasa Listesi Getirici
List<String> getBodyTypesForVehicle(String? vehicle) {
  if (vehicle == null) return [];
  if (['Minivan', 'Panelvan', 'Uzun Panelvan'].contains(vehicle)) {
    return []; // Kasa tipi yok
  } else if (['Kamyonet', '6 Teker', '8 Teker', '10 Teker', 'Kırkayak'].contains(vehicle)) {
    return ['Kapalı', 'Tenteli', 'Yüksek Yan', 'Açık'];
  } else if (vehicle == 'TIR') {
    return ['Kapalı', 'Tenteli', 'Lowbed', 'Açık'];
  }
  return [];
}

const List<String> loadTypes = ['PALET', 'KOLI', 'CUVAL', 'DOKME', 'MAKINE', 'GENEL'];

// 81 İLİN KOORDİNATLARI
final Map<String, LatLng> cityCoords = {
  'Adana': const LatLng(37.0000, 35.3213), 'Ankara': const LatLng(39.9208, 32.8541), 'İstanbul': const LatLng(41.0082, 28.9784),
  'İzmir': const LatLng(38.4237, 27.1428), 'Bursa': const LatLng(40.1885, 29.0610), 'Antalya': const LatLng(36.8969, 30.7133),
  // ... (Diğer iller harita seçiciden geldiği için burası kısa tutulabilir)
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  final TextEditingController _userC = TextEditingController();
  final TextEditingController _passC = TextEditingController();
  bool _isLoading = false;

  void _attemptLogin() {
    setState(() => _isLoading = true);
    String user = _userC.text.trim().toLowerCase();
    String pass = _passC.text.trim();

    Future.delayed(const Duration(seconds: 1), () {
      if (pass == "123") { 
        if (user == "firma") _loginSuccess('SHIPPER', 'Global Lojistik A.Ş.', 1);
        else if (user == "sofor") _loginSuccess('CARRIER', 'Ali Kaptan', 2);
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  void _showError(String msg) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
  List<Map<String, dynamic>> _myJobs = [];
  bool _loading = true;
  
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedLoad;
  List<LatLng> _routePoints = [];
  LatLng? _myLocation;

  @override
  void initState() { super.initState(); _fetch(); _locateUser(); }

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

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client.from('loads').select().eq('status', 'PUBLISHED').order('created_at', ascending: false);
      
      // --- FAZ 3.5: GÖRÜNÜRLÜK MANTIĞI (FİLTRELEME) ---
      List<Map<String, dynamic>> rawData = List<Map<String, dynamic>>.from(data);
      List<Map<String, dynamic>> filteredData = [];

      if (currentUserRole == 'SHIPPER') {
        // Şirket: Kendi yüklerini VE Boş Sürücüleri görür
        filteredData = rawData.where((item) {
          bool isMyLoad = item['post_type'] == 'LOAD' && item['shipper_id'] == currentUserId;
          bool isDriverAd = item['post_type'] == 'DRIVER';
          return isMyLoad || isDriverAd;
        }).toList();
      } else {
        // Sürücü: Sadece Yükleri görür (Diğer sürücüleri görmez)
        filteredData = rawData.where((item) => item['post_type'] == 'LOAD').toList();
      }

      setState(() => _loads = filteredData);
      await _fetchMyJobs();

    } catch (e) { debugPrint("$e"); } finally { setState(() => _loading = false); }
  }

  Future<void> _fetchMyJobs() async {
    try {
      // Seferlerim (Sürücü) veya Yüklerim (Şirket - Rezerve Olanlar vs)
      // Şimdilik basit tutuyoruz, sürücüye atananlar:
      if (currentUserRole == 'CARRIER') {
         final data = await Supabase.instance.client.from('loads').select().eq('carrier_id', currentUserId).eq('status', 'BOOKED');
         setState(() => _myJobs = List<Map<String, dynamic>>.from(data));
      } else {
         // Şirket "Yüklerim" (Örnek: Yayındakiler dışındakiler)
         // Şimdilik boş bırakıyoruz, talep olursa eklenir.
      }
    } catch (e) { debugPrint("Sefer hatası: $e"); }
  }

  Future<void> _getRealRoute(LatLng start, LatLng end) async {
    setState(() { _routePoints = []; });
    try {
      final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _routePoints = geometry.map((p) => LatLng(p[1], p[0])).toList();
        });
      }
    } catch (e) { setState(() { _routePoints = [start, end]; }); }
  }

  void _zoomToRoute(Map<String, dynamic> load) {
    setState(() => _selectedLoad = load);
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
    return Scaffold(
      body: IndexedStack(index: _idx, children: [
        _map(), 
        _list(), 
        _inbox(), 
        _myJobsScreen(),
        _profile()
      ]),
      
      floatingActionButton: (_idx < 2) 
        ? FloatingActionButton.extended(
            onPressed: _addDialog, 
            label: Text(isShipper ? "YÜK İLANI VER" : "BOŞUM İLANI VER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            icon: Icon(isShipper ? Icons.add_box : Icons.campaign, color: Colors.white),
            backgroundColor: isShipper ? const Color(0xFF0F172A) : Colors.green[700],
          ) 
        : null,
        
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        backgroundColor: Colors.white,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.map_outlined), label: "Harita"),
          const NavigationDestination(icon: Icon(Icons.list_alt), label: "Pazar"),
          const NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: "Mesajlar"),
          NavigationDestination(icon: Icon(isShipper ? Icons.inventory : Icons.local_shipping_outlined), label: isShipper ? "Yüklerim" : "Seferlerim"),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }

  Widget _map() {
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

            MarkerLayer(markers: _loads.map((load) {
              bool isDriverPost = load['post_type'] == 'DRIVER';
              bool isSelected = _selectedLoad == load;
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
                        child: Text(isDriverPost ? "BOŞ" : "${NumberFormat.compact().format(load['price'])}₺", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDriverPost ? Colors.green : Colors.orange[800])),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: isDriverPost ? Colors.green : Colors.orange[800], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [const BoxShadow(color: Colors.black38, blurRadius: 5)]),
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
    if(_loading) return const Center(child: CircularProgressIndicator());
    if(_loads.isEmpty) return const Center(child: Text("Liste boş."));
    return Scaffold(
      appBar: AppBar(title: const Text("Pazar Yeri")),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _loads.length,
        itemBuilder: (ctx, i) {
          final load = _loads[i];
          bool isDriverPost = load['post_type'] == 'DRIVER';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: isDriverPost ? Colors.green[100] : Colors.amber[100], child: Icon(isDriverPost ? Icons.local_shipping : Icons.inventory_2, color: Colors.black)),
              title: Text(load['title'] ?? 'İlan', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${load['pickup_address']} -> ${load['delivery_address']}"),
              trailing: Text("${NumberFormat.compact().format(load['price'])}₺", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              onTap: () { _zoomToRoute(load); _showDetails(load); },
            ),
          );
        },
      ),
    );
  }

  Widget _inbox() => Scaffold(appBar: AppBar(title: const Text("Mesajlar")), body: const Center(child: Text("Mesaj kutusu yakında.")));

  // --- SEFERLERİM / YÜKLERİM EKRANI ---
  Widget _myJobsScreen() {
    if (currentUserRole == 'SHIPPER') return const Center(child: Text("Yüklerim ekranı yapım aşamasında."));
    if (_myJobs.isEmpty) return const Center(child: Text("Aktif sefer yok."));
    return Scaffold(
      appBar: AppBar(title: const Text("Seferlerim")),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _myJobs.length,
        itemBuilder: (ctx, i) {
          final job = _myJobs[i];
          return Card(
            color: Colors.green[50],
            child: ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.green),
              title: Text(job['title']),
              subtitle: const Text("YOLDA"),
              trailing: ElevatedButton(onPressed: (){}, child: const Text("TESLİM ET")),
            ),
          );
        },
      ),
    );
  }

  Widget _profile() => Center(child: ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>const LoginScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Çıkış Yap")));

  Future<Map<String, dynamic>?> _pickLocation(BuildContext context) async {
    return await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationPickerScreen()));
  }

  // --- İLAN EKLEME (YENİ HİYERARŞİ EKLENDİ) ---
  void _addDialog() {
    final _formKey = GlobalKey<FormState>();
    final titleC = TextEditingController(); final priceC = TextEditingController(); 
    final wC = TextEditingController(); final vC = TextEditingController();
    final qtyC = TextEditingController(text: '1'); 
    final dimWC = TextEditingController(); final dimLC = TextEditingController(); final dimHC = TextEditingController();
    
    Map<String, dynamic>? pickupLoc;
    Map<String, dynamic>? deliveryLoc;
    
    String? vType; String? bType; String? lType; 
    bool isStack = false; bool isDriver = currentUserRole == 'CARRIER';

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: StatefulBuilder(builder: (context, setState) {
        // Seçilen araca göre kasa tiplerini filtrele
        List<String> availableBodyTypes = getBodyTypesForVehicle(vType);

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
                _locationSelector("Nereden", pickupLoc, () async { final loc = await _pickLocation(context); if(loc != null) setState(() => pickupLoc = loc); }),
                const SizedBox(height: 10),
                _locationSelector("Nereye", deliveryLoc, () async { final loc = await _pickLocation(context); if(loc != null) setState(() => deliveryLoc = loc); }),
                if(pickupLoc == null || deliveryLoc == null) const Padding(padding: EdgeInsets.all(8.0), child: Text("Lütfen rota seçiniz *", style: TextStyle(color: Colors.red, fontSize: 12))),

                const SizedBox(height: 20),
                TextFormField(controller: titleC, decoration: const InputDecoration(labelText: "Başlık *", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Fiyat (TL) *", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: wC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Ağırlık (KG) *", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Zorunlu" : null)),
                ]),
                
                const SizedBox(height: 10),
                // SADECE ŞİRKET İÇİN DETAYLI ÖLÇÜLER ZORUNLU
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
                    Expanded(child: DropdownButtonFormField(value: lType, hint: const Text("Yük Tipi *"), items: loadTypes.map((e)=>DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v)=>setState(()=>lType=v), decoration: const InputDecoration(border: OutlineInputBorder()), validator: (v) => v == null ? "Seçiniz" : null)),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: vC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Hacim m³ (Opsiyonel)", border: OutlineInputBorder()))),
                  ]),
                ],

                const SizedBox(height: 10),
                // ARAÇ VE KASA SEÇİMİ (DİNAMİK)
                Row(children: [
                  Expanded(child: DropdownButtonFormField(value: vType, hint: const Text("Araç *"), items: vehicleList.map((e)=>DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) { 
                    setState(() { vType = v; bType = null; }); // Araç değişince kasayı sıfırla
                  }, decoration: const InputDecoration(border: OutlineInputBorder()), validator: (v) => v == null ? "Seçiniz" : null)),
                  
                  const SizedBox(width: 10),
                  
                  // Kasa Tipi (Sadece araç seçildiyse ve kasa tipi varsa göster)
                  Expanded(child: IgnorePointer(
                    ignoring: availableBodyTypes.isEmpty,
                    child: DropdownButtonFormField(
                      value: bType, 
                      hint: Text(availableBodyTypes.isEmpty ? "Standart" : "Kasa *"), 
                      items: availableBodyTypes.map((e)=>DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), 
                      onChanged: (v)=>setState(()=>bType=v), 
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: availableBodyTypes.isEmpty, 
                        fillColor: availableBodyTypes.isEmpty ? Colors.grey[200] : null
                      ),
                      validator: (v) => (availableBodyTypes.isNotEmpty && v == null) ? "Seçiniz" : null // Sadece seçenek varsa zorunlu
                    ),
                  )),
                ]),
                
                if(!isDriver) CheckboxListTile(title: const Text("İstiflenebilir?"), value: isStack, onChanged: (v)=>setState(()=>isStack=v!), contentPadding: EdgeInsets.zero),

                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: (){ 
                  if(_formKey.currentState!.validate() && pickupLoc != null && deliveryLoc != null) {
                    // Kasa tipi zorunluluğu kontrolü (eğer liste boş değilse)
                    if (availableBodyTypes.isNotEmpty && bType == null) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen Kasa Tipi Seçin!"), backgroundColor: Colors.red));
                       return;
                    }
                    
                    // Kaydet
                    _saveLoad(titleC.text, double.tryParse(priceC.text)??0, int.tryParse(wC.text)??0, double.tryParse(vC.text)??0, pickupLoc!, deliveryLoc!, vType!, bType ?? 'STANDART', lType ?? 'GENEL', isStack, isDriver ? 'DRIVER' : 'LOAD', qty: int.tryParse(qtyC.text), dw: int.tryParse(dimWC.text), dl: int.tryParse(dimLC.text), dh: int.tryParse(dimHC.text));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen zorunlu alanları doldurun!"), backgroundColor: Colors.red));
                  }
                }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white), child: const Text("YAYINLA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))))
              ]),
            ),
          ),
        );
      }),
    ));
  }

  Widget _locationSelector(String label, Map<String, dynamic>? loc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: loc != null ? Colors.green : Colors.redAccent), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [Icon(Icons.map, color: loc != null ? Colors.green : Colors.red), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(loc != null ? loc['address'] : "Haritadan Seçmek İçin Dokun *", style: TextStyle(fontWeight: FontWeight.bold, color: loc != null ? Colors.black : Colors.red, fontSize: 16))])), const Icon(Icons.chevron_right)]),
      ),
    );
  }

  Future<void> _saveLoad(String t, double p, int w, double vol, Map<String, dynamic> pLoc, Map<String, dynamic> dLoc, String vt, String bt, String lt, bool stack, String type, {int? qty, int? dw, int? dl, int? dh}) async {
    await Supabase.instance.client.from('loads').insert({
      'title': t, 'price': p, 'weight_kg': w, 'volume_m3': vol, 'load_type': lt, 'is_stackable': stack,
      'pickup_address': pLoc['address'], 'delivery_address': dLoc['address'], 'pickup_lat': pLoc['lat'], 'pickup_lng': pLoc['lng'], 'delivery_lat': dLoc['lat'], 'delivery_lng': dLoc['lng'],
      'required_vehicle': vt, 'required_body': bt, 'status': 'PUBLISHED', 'shipper_id': 1, 'description': vt, 'post_type': type,
      'quantity': qty??1, 'dim_width': dw??0, 'dim_length': dl??0, 'dim_height': dh??0
    });
    _fetch(); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İlan Başarıyla Yayınlandı!")));
  }

  // --- DETAY PENCERESİ ---
  void _showDetails(Map<String, dynamic> load) {
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
          Wrap(spacing: 8, children: [Chip(label: Text(load['required_body'] ?? ''), backgroundColor: Colors.blue[50]), if(load['is_stackable'] == true) const Chip(label: Text("İstiflenebilir"), backgroundColor: Colors.orangeAccent), Chip(label: Text("${load['load_type']}"), backgroundColor: Colors.purple[50])]),
          const Divider(height: 30),
          if (load['quantity'] != null && load['dim_width'] != null && load['dim_width'] > 0) ...[
            const Text("Yük Ebatları & Adet", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_miniBox("${load['quantity']} Adet", Icons.grid_view), _miniBox("${load['dim_width']}x${load['dim_length']}x${load['dim_height']} cm", Icons.aspect_ratio)]),
            const SizedBox(height: 20),
          ],
          _infoRow(Icons.circle, Colors.green, "Nereden", load['pickup_address']), _verticalLine(), _infoRow(Icons.circle, Colors.red, "Nereye", load['delivery_address'] ?? 'Bilinmiyor'),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: _boxInfo(load['post_type']=='DRIVER'?"Kapasite":"Ağırlık", "${load['weight_kg']} KG", Icons.scale)), const SizedBox(width: 10), Expanded(child: _boxInfo("Araç", "${load['required_vehicle']}", Icons.local_shipping))]),
          const SizedBox(height: 30),
          Text("${NumberFormat.compact().format(load['price'])}₺", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.green)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _openGoogleMaps(load['pickup_lat'], load['pickup_lng'], load['delivery_lat'], load['delivery_lng']), icon: const Icon(Icons.map), label: const Text("YOL TARİFİ"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: () => _openChatDialog(load), icon: const Icon(Icons.chat_bubble_outline), label: const Text("MESAJ"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)))),
          ]),
          const SizedBox(height: 10),
          if(currentUserRole == 'SHIPPER') 
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _delete(load['id']), icon: const Icon(Icons.delete), label: const Text("İLANI SİL"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15))))
          else if (currentUserRole == 'CARRIER' && load['post_type'] != 'DRIVER')
             SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _acceptLoad(load), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("YÜKÜ AL (REZERVE ET)")))
        ]),
      )
    )).whenComplete(() => _clearRoute()); 
  }

  void _openGoogleMaps(double? pLat, double? pLng, double? dLat, double? dLng) async {
    if(pLat == null || dLat == null) return;
    final uri = Uri.parse("https://www.google.com/maps/dir/?api=1&origin=$pLat,$pLng&destination=$dLat,$dLng&travelmode=driving");
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (e) { debugPrint("Harita hatası: $e"); }
  }

  Future<void> _acceptLoad(Map<String, dynamic> load) async {
    await Supabase.instance.client.from('loads').update({'status': 'BOOKED', 'carrier_id': currentUserId}).eq('id', load['id']);
    _fetch(); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Yük Rezerve Edildi!"), backgroundColor: Colors.green));
  }

  void _openChatDialog(Map<String, dynamic> load) { showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => _ChatScreen(loadTitle: load['title'] ?? 'İlan', price: load['price'], loadId: load['id'])); }
  Future<void> _delete(int id) async { await Supabase.instance.client.from('loads').delete().eq('id', id); setState(() => _selectedLoad = null); _fetch(); Navigator.pop(context); }
  Widget _infoRow(IconData i, Color c, String l, String v) => Row(children: [Icon(i, size: 14, color: c), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10)), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]))]);
  Widget _verticalLine() => Container(margin: const EdgeInsets.only(left: 6), height: 20, width: 2, color: Colors.grey[200]);
  Widget _boxInfo(String l, String v, IconData i) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)), child: Column(children: [Icon(i, size: 20, color: Colors.blueGrey), const SizedBox(height: 5), Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey))]));
  Widget _miniBox(String txt, IconData i) => Row(children: [Icon(i, size: 16, color: Colors.black54), const SizedBox(width: 5), Text(txt, style: const TextStyle(fontWeight: FontWeight.bold))]);
}

class LocationPickerScreen extends StatefulWidget { const LocationPickerScreen({super.key}); @override State<LocationPickerScreen> createState() => _LocationPickerScreenState(); }
class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _pickerMapController = MapController();
  LatLng _center = const LatLng(41.0082, 28.9784);
  String _address = "Konum seçiliyor...";
  final TextEditingController _searchC = TextEditingController();
  List<dynamic> _searchResults = [];
  Timer? _debounce;

  void _onPositionChanged(MapPosition position, bool hasGesture) { if (position.center != null) _center = position.center!; }
  Future<void> _getAddress() async { setState(() => _address = "Adres alınıyor..."); try { final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${_center.latitude}&lon=${_center.longitude}&zoom=18&addressdetails=1'); final response = await http.get(url, headers: {'User-Agent': 'com.logicore.app'}); if (response.statusCode == 200) { final data = json.decode(response.body); String full = data['display_name'] ?? "Bilinmeyen Konum"; List<String> parts = full.split(','); String short = parts.length > 2 ? "${parts[0]}, ${parts[1]}" : full; if(mounted) setState(() => _address = short); } } catch (e) { if(mounted) setState(() => _address = "Konum: ${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}"); } }
  Future<void> _searchPlace(String query) async { if (_debounce?.isActive ?? false) _debounce!.cancel(); _debounce = Timer(const Duration(milliseconds: 800), () async { if(query.length < 3) return; final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5'); final response = await http.get(url, headers: {'User-Agent': 'com.logicore.app'}); if (response.statusCode == 200) { setState(() => _searchResults = json.decode(response.body)); } }); }

  @override Widget build(BuildContext context) { return Scaffold(body: Stack(children: [FlutterMap(mapController: _pickerMapController, options: MapOptions(initialCenter: _center, initialZoom: 12.0, onPositionChanged: _onPositionChanged, onMapEvent: (evt) { if (evt is MapEventMoveEnd) _getAddress(); }), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')]), const Center(child: Icon(Icons.location_on, size: 50, color: Colors.red)), SafeArea(child: Column(children: [Container(margin: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(children: [TextField(controller: _searchC, decoration: InputDecoration(hintText: "İl, İlçe veya Yer Ara...", prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: (){ _searchC.clear(); setState(()=>_searchResults=[]); }), border: InputBorder.none, contentPadding: const EdgeInsets.all(15)), onChanged: _searchPlace), if (_searchResults.isNotEmpty) Container(height: 200, color: Colors.white, child: ListView.builder(itemCount: _searchResults.length, itemBuilder: (ctx, i) { final place = _searchResults[i]; return ListTile(title: Text(place['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis), leading: const Icon(Icons.place, color: Colors.grey), onTap: () { final lat = double.parse(place['lat']); final lon = double.parse(place['lon']); _pickerMapController.move(LatLng(lat, lon), 15); setState(() { _center = LatLng(lat, lon); _searchResults = []; _searchC.clear(); }); _getAddress(); FocusScope.of(context).unfocus(); }); }))]))])), Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Seçilen Konum:", style: TextStyle(color: Colors.grey)), Text(_address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 15), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { Navigator.pop(context, {'lat': _center.latitude, 'lng': _center.longitude, 'address': _address}); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), child: const Text("BU KONUMU ONAYLA")))])))],),); }
}

class _ChatScreen extends StatefulWidget { final String loadTitle; final dynamic price; final int loadId; const _ChatScreen({required this.loadTitle, required this.price, required this.loadId}); @override State<_ChatScreen> createState() => _ChatScreenState(); }
class _ChatScreenState extends State<_ChatScreen> { final TextEditingController _cnt = TextEditingController(); List<Map<String, dynamic>> _msgs = []; @override void initState() { super.initState(); _load(); } Future<void> _load() async { final d = await Supabase.instance.client.from('messages').select().eq('load_id', widget.loadId).order('created_at', ascending: true); if(mounted) setState(() => _msgs = List<Map<String, dynamic>>.from(d)); } Future<void> _send() async { if(_cnt.text.isEmpty) return; await Supabase.instance.client.from('messages').insert({'load_id': widget.loadId, 'content': _cnt.text, 'sender_role': currentUserRole}); _cnt.clear(); _load(); } @override Widget build(BuildContext context) { return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(height: 500, padding: const EdgeInsets.all(20), child: Column(children: [Text("Pazarlık: ${widget.loadTitle}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const Divider(), Expanded(child: ListView.builder(itemCount: _msgs.length, itemBuilder: (c, i) { final m = _msgs[i]; bool me = m['sender_role'] == currentUserRole; return Align(alignment: me ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: me ? Colors.blue[100] : Colors.grey[200], borderRadius: BorderRadius.circular(10)), child: Text(m['content']))); })), Row(children: [Expanded(child: TextField(controller: _cnt, decoration: const InputDecoration(hintText: "Mesaj..."))), IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Colors.blue))])]))); } }