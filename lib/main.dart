import 'package:flutter/material.dart';
import 'home_page.dart';
import 'wishlist_page.dart';
import 'history_page.dart';
import 'notification_helper.dart'; // 1. PERBAIKAN: Import helper notifikasi wajib ada di sini

// Perbaikan Alias: bedakan alias timezone data dengan timezone utama agar tidak bentrok
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  // Pastikan inisialisasi Flutter Binding berjalan duluan
  WidgetsFlutterBinding.ensureInitialized();

  // 2. PERBAIKAN: Menggunakan alias data yang sudah dibedakan
  tz_data.initializeTimeZones();

  // Set default ke Asia/Jakarta (WIB) agar perhitungan jam pengingat aman
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  // Jalankan fungsi inisialisasi plugin notifikasi lokal
  await NotificationHelper.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2C5364),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // GlobalKey untuk kontrol sinkronisasi data antar tab halaman
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  final GlobalKey<WishlistPageState> _wishlistKey =
      GlobalKey<WishlistPageState>();
  final GlobalKey<HistoryPageState> _historyKey = GlobalKey<HistoryPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: _homeKey),
      WishlistPage(key: _wishlistKey),
      HistoryPage(key: _historyKey),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Jalankan perintah refresh data otomatis sesuai tab yang dipilih user
    if (index == 0) {
      _homeKey.currentState?.loadSavings();
    } else if (index == 1) {
      _wishlistKey.currentState?.loadData();
    } else if (index == 2) {
      _historyKey.currentState?.loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(_pages.length, (index) {
          final bool isSelected = index == _selectedIndex;
          return IgnorePointer(
            ignoring: !isSelected,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _pages[index],
            ),
          );
        }),
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF2C5364),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Tabunganku',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.star),
                label: 'Wishlist',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Riwayat',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
