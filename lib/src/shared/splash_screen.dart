import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pamsimas_app/src/core/services/auth_service.dart';
import 'package:pamsimas_app/src/pages/login/login_screen.dart';
import 'package:pamsimas_app/src/shared/main_navigation.dart';

class SplashScreenPage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  static const Color bgColor = Color(0xFFFAF9F6);
  // Warna biru tua untuk teks judul
  static const Color darkBlueText = Color(0xFF0D47A1);
  // Warna biru sedang untuk teks slogan
  static const Color mediumBlueText = Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 1. Cek status login
    final bool isLoggedIn = await AuthService.instance.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      try {
        // 2. Pre-load data krusial secara paralel
        await Future.wait([
          Future.delayed(const Duration(seconds: 2)), // Minimal splash time
          AuthService.instance.getAccessToken(),      // Refresh token & local info
          AuthService.instance.getCurrentUserFromServer(), // Fetch full profile from API
        ]);

        if (!mounted) return;
        // 3. Pindah ke MainNavigation setelah data SIAP
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } catch (e) {
        print('[SplashScreen] Error loading data: $e');
        if (!mounted) return;
        _showErrorAndRetry();
      }
    } else {
      // Jika tidak login, langsung ke Login setelah delay minimal
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showErrorAndRetry() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gagal memuat data. Periksa koneksi internet.'),
        action: SnackBarAction(
          label: 'Coba Lagi',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _checkAuthAndNavigate();
          },
        ),
        duration: const Duration(days: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Daun-daun hiasan di sudut menggunakan Positioned
          Positioned(
            top: 20,
            right: 20,
            child: SvgPicture.asset(
              'assets/images/leaves_top_right.svg',
              width: 100,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: SvgPicture.asset(
              'assets/images/leaves_bottom_left.svg',
              width: 100,
            ),
          ),

          // Konten Utama dengan Responsivitas
          OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
                return _buildPortraitLayout();
              } else {
                return _buildLandscapeLayout();
              }
            },
          ),
        ],
      ),
    );
  }

  // Tata letak untuk mode Potret
  Widget _buildPortraitLayout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Melingkar PAMSIMAS
          Image.asset(
            'assets/images/pamsimas_logo.png',
            width: 250,
            height: 250,
          ),

          const SizedBox(height: 30), // Jarak logo ke teks judul
          // Judul "DESA LUWUNGBATA"
          const Text(
            'DESA LUWUNGBATA',
            style: TextStyle(
              color: darkBlueText,
              fontWeight: FontWeight.bold,
              fontSize: 32,
              letterSpacing: 1.5,
              fontFamily: 'Roboto', // Gunakan font yang bersih
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10), // Jarak judul ke sub-judul
          // Sub-judul "KECAMATAN TANJUNG - KABUPATEN BREBES"
          const Text(
            'KECAMATAN TANJUNG - KABUPATEN BREBES',
            style: TextStyle(
              color: darkBlueText,
              fontSize: 18,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30), // Jarak ke slogan
          // Slogan (Potret: Menggunakan huruf kapital)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '"MEMBANGUN DESA MELALUI AIR MINUM DAN SANITASI"',
              style: TextStyle(
                color: mediumBlueText,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Tata letak untuk mode Lanskap
  Widget _buildLandscapeLayout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Melingkar PAMSIMAS
          Image.asset(
            'assets/images/pamsimas_logo.png',
            width: 180,
            height: 180,
          ),

          const SizedBox(height: 20), // Jarak logo ke teks judul
          // Judul "DESA LUWUNGBATA"
          const Text(
            'DESA LUWUNGBATA',
            style: TextStyle(
              color: darkBlueText,
              fontWeight: FontWeight.bold,
              fontSize: 28, // Sedikit lebih kecil
              letterSpacing: 1.5,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 5), // Jarak judul ke sub-judul
          // Sub-judul "KECAMATAN BREBES"
          const Text(
            'KECAMATAN TANJUNG',
            style: TextStyle(
              color: darkBlueText,
              fontSize: 16, // Sedikit lebih kecil
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20), // Jarak ke slogan
          // Slogan (Lanskap: Menggunakan huruf kecil)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '"Membangun Desa Melalui Air Minum dan Sanitasi"',
              style: TextStyle(
                color: mediumBlueText,
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
