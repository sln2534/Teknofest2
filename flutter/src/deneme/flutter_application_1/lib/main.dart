import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
// 'package:collection/collection.dart'; // firstWhereOrNull için bu paketi de eklemek gerekebilir

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Kamera hatası: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSignLanguageMode = true;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Timer? _timer;
  String _currentWord = '';
  String _accumulatedText = '';
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Aşağıdaki IP adresini kendi cihazına göre değiştirdiğini varsayıyorum.
  final String _backendUrl = 'http://192.168.1.111:5000/process_frame';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      print('Kamera bulunamadı.');
      return;
    }

    // Ön kamerayı bulmaya çalış
    CameraDescription? selectedCamera;
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        selectedCamera = camera;
        break; // Ön kamerayı bulduğumuzda döngüyü sonlandır
      }
    }

    // Eğer ön kamera bulunamazsa, varsayılan olarak ilk kamerayı (genellikle arka) kullan
    if (selectedCamera == null) {
      print('Ön kamera bulunamadı, varsayılan olarak ilk kamerayı kullanılıyor.');
      selectedCamera = cameras[0];
    }

    _cameraController = CameraController(
      selectedCamera, // Artık seçilen kamerayı kullanıyoruz
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) {
        return; // Widget hala takılı değilse işlem yapma
      }
      setState(() {
        _isCameraInitialized = true;
      });
      _startImageStreaming();
    } catch (e) {
      print('Kamera başlatılamadı: $e');
    }
  }

  void _startImageStreaming() {
    _timer?.cancel();
    if (_isSignLanguageMode) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _sendFrameToBackend();
      });
    }
  }

  Future<void> _sendFrameToBackend() async {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final XFile image = await _cameraController!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'image': base64Image}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentWord = data['detected_text'] ?? '';
          if (_currentWord.trim().isNotEmpty) {
            _accumulatedText += ' $_currentWord';
          }
        });
        if (data['audio_base64'] != null && _isSignLanguageMode) {
          _playAudio(data['audio_base64']);
        }
      } else {
        setState(() {
          _currentWord = 'Hata: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _currentWord = 'Bağlantı hatası';
      });
    }
  }

  Future<void> _playAudio(String base64String) async {
    try {
      final Uint8List audioBytes = base64Decode(base64String);
      await _audioPlayer.play(BytesSource(audioBytes));
    } catch (e) {
      print('Ses hatası: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF6E21B5),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SES → İŞARET DİLİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Switch(
                        value: _isSignLanguageMode,
                        onChanged: (val) {
                          setState(() {
                            _isSignLanguageMode = val;
                            if (_isSignLanguageMode) {
                              _startImageStreaming();
                            } else {
                              _timer?.cancel();
                            }
                          });
                        },
                      ),
                      const Text('İŞARET DİLİ → SES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Icon(Icons.camera_alt, color: Colors.red),
                      SizedBox(width: 8),
                      Text('KAMERA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black),
                    ),
                    child: _isCameraInitialized
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AspectRatio(
                              aspectRatio: _cameraController!.value.aspectRatio,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 20),
                  const Text('ALGILANAN METİN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black),
                    ),
                    child: SingleChildScrollView(
                      child: Text(_accumulatedText.trim(), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _accumulatedText = '';
                      });
                    },
                    child: const Text('Temizle'),
                  ),
                  const SizedBox(height: 20),
                  const Text('ÇEVRİLEN MP3 DOSYASI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        iconSize: 50,
                        color: Colors.black,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        iconSize: 50,
                        color: Colors.black,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        iconSize: 50,
                        color: Colors.black,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
