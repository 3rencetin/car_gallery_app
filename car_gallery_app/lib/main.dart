import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/db_service.dart';
import 'models/car.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Araba Galerisi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A3365),
          primary: const Color(0xFF1A3365),
          secondary: const Color(0xFFE63946),
          surface: Colors.white,
          background: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A3365),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black26,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3365),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Logo animasyonu için controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Büyüme animasyonu
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Veritabanı servisini başlat
    final dbService = DatabaseService();
    await Future.delayed(const Duration(seconds: 2)); // Splash ekran süresi

    // Örnek veri yok ise, örnek verileri ekle
    try {
      final cars = await dbService.getCars();
      if (cars.isEmpty) {
        await _addSampleCars(dbService);
      }
    } catch (e) {
      // Hata durumunda da devam et, olası hata mesajları uygulama açıldığında gösterilebilir
      print('Örnek veri eklenirken hata: $e');
    }

    // Ana ekrana yönlendir
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  Future<void> _addSampleCars(DatabaseService dbService) async {
    final sampleCars = [
      Car(
        brand: 'Mercedes',
        model: 'C200',
        year: 2021,
        color: 'Siyah',
        price: 1450000,
        imageUrl:
            'https://octane.rent/wp-content/uploads/2024/06/mercedes-benz-c-class-black-1.jpg',
      ),
      Car(
        brand: 'BMW',
        model: '320i',
        year: 2022,
        color: 'Beyaz',
        price: 1680000,
        imageUrl:
            'https://carrental.yavin.ro/storage/app/uploads/public/61e/7ff/e03/61e7ffe034ed0458574264.jpg',
      ),
      Car(
        brand: 'Audi',
        model: 'A4',
        year: 2020,
        color: 'Gri',
        price: 1350000,
        imageUrl:
            'https://arabam-blog.mncdn.com/wp-content/uploads/2021/07/yeni-audi-a4.jpg',
      ),
      Car(
        brand: 'Volkswagen',
        model: 'Passat',
        year: 2019,
        color: 'Lacivert',
        price: 1150000,
        imageUrl:
            'https://www.vw.com.tr/content/dam/onehub_pkw/importers/tr/passat/image/Compare-Passats/Passats.jpg',
      ),
      Car(
        brand: 'Toyota',
        model: 'Corolla',
        year: 2021,
        color: 'Kırmızı',
        price: 850000,
        imageUrl:
            'https://cdn.motor1.com/images/mgl/MkJNWx/s3/toyota-corolla-2022-brasil.jpg',
      ),
    ];

    for (var car in sampleCars) {
      await dbService.insertCar(car);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3365),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_car,
                  size: 80,
                  color: Color(0xFF1A3365),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'PREMIUM',
                style: TextStyle(
                  color: Color(0xFFE63946),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'ARABA GALERİSİ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
