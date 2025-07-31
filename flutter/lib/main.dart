import 'package:flutter/material.dart';
import 'package:trans_bridge/app/Theme.dart';
import 'package:trans_bridge/app/router.dart';
import 'package:camera/camera.dart'; // Kamera paketini ekle
import 'package:trans_bridge/speech_to_text_page.dart';  //burayı şilan ekledi

// Kamerayı global olarak tanımla ve başlatma işlevini buraya taşı
late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Kamera hatası: $e');
    // Kameranın bulunamaması durumunda uygulamayı başlatmaya devam et
    // veya kullanıcıya bir hata mesajı göster.
    cameras = []; // Kameranın bulunamadığını belirtmek için boş liste
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router, // go_router konfigürasyonu
      debugShowCheckedModeBanner: false, // Bu satır debug banner'ı kaldırır
      theme: AppTheme.lightTheme, // Mevcut temanız
    );
  }
}

