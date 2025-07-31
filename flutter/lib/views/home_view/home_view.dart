
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trans_bridge/app/router.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:trans_bridge/main.dart'; // Global 'cameras' değişkenine erişim için
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Mod kontrolü: true ise İşaret -> Konuşma, false ise Konuşma -> İşaret
  bool _isSignLanguageMode = true;

  // İşaret -> Konuşma modu için kamera değişkenleri
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Timer? _timer;
  String _detectedText = ''; // Algılanan işaret dili metni
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _backendUrl = 'http://192.168.1.111:5000/process_frame'; // Kendi IP adresinize göre güncelleyin!

  // Konuşma -> İşaret modu için değişkenler
  String _spokenText = ''; // Algılanan konuşma metni
  String _avatarSignText = 'Avatar burada işaret dilini gösterecek...'; // Avatarın göstereceği işaret dili metni

  // Ses kaydı için değişkenler
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // Kamera her zaman başlatılır
    _initRecorder();     // Ses kaydediciyi başlat
  }

  // Kamera başlatma ve akışını yönetme
  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      if (mounted) {
        setState(() {
          _detectedText = 'Kamera bulunamadı veya başlatılamadı.';
        });
      }
      return;
    }

    _cameraController = CameraController(
      cameras[0], // İlk kamerayı kullan
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
      // Sadece işaret dili modundaysa akışı başlat
      if (_isSignLanguageMode) {
        _startImageStreaming();
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _detectedText = 'Kamera başlatılamadı: ${e.code}';
        });
      }
    }
  }

  // Ses kaydediciyi başlat
Future<void> _initRecorder() async {
  final status = await Permission.microphone.request();

  if (status.isGranted) {
    await Future.delayed(Duration(milliseconds: 500)); // Cihazdan cihaza değişir
    try {
      await _recorder.openRecorder();
      print("🎙️ Mikrofon başarıyla açıldı!");
    } catch (e) {
      print("⚠️ Recorder açılırken hata: $e");
      setState(() {
        _spokenText = "Recorder başlatılamadı!";
      });
    }
  } else {
    print("❌ Mikrofon izni verilmedi!");
    setState(() {
      _spokenText = "Mikrofon izni gerekli!";
    });
  }
}

  // İşaret dili akışını başlatma
  void _startImageStreaming() {
    _timer?.cancel();
    if (_isSignLanguageMode) {
      _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        _sendFrameToBackend();
      });
    }
  }

  // Kareleri backend'e gönderme
  Future<void> _sendFrameToBackend() async {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized || _cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'image': base64Image}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _detectedText = data['detected_text'] ?? 'Algılanan metin yok.';
        });
        if (data['audio_base64'] != null && _isSignLanguageMode) {
          _playAudio(data['audio_base64']);
        }
      } else {
        setState(() {
          _detectedText = 'API Hatası: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detectedText = 'Bağlantı hatası: ${e.toString()}';
      });
    }
  }

  // Sesi oynatma
  Future<void> _playAudio(String base64String) async {
    try {
      final Uint8List audioBytes = base64Decode(base64String);
      await _audioPlayer.play(BytesSource(audioBytes));
    } catch (e) {
      print('Ses oynatma hatası: $e');
    }
  }

  // Ses kaydı için dosya yolu
  Future<String> _getFilePath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/audio.wav';
  }

  // Ses kaydını başlat
  Future<void> _startRecording() async {
    String path = await _getFilePath();
    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.pcm16WAV, // <-- Farklı codec dene
      sampleRate: 16000,
      numChannels: 1,
      audioSource: AudioSource.microphone,
    );
    setState(() {
      _isRecording = true;
      _spokenText = "Dinleniyor...";
    });
  }

  // Ses kaydını durdur ve sunucuya gönder
  Future<void> _stopRecordingAndSend() async {
    String? path = await _recorder.stopRecorder();
    print('Kayıt durduruldu. Dosya yolu: $path');
    setState(() {
      _isRecording = false;
    });
    if (path != null) {
      File audioFile = File(path);
      print('Dosya var mı? ${audioFile.existsSync()}'); // EKLE
      print('Dosya boyutu: ${audioFile.lengthSync()} bytes'); // EKLE


      await _sendToServer(audioFile);
    } else {
      setState(() {
        _spokenText = "Kayıt dosyası bulunamadı!";
      });
    }
  }

  // Sunucuya ses dosyasını gönder
  Future<void> _sendToServer(File audioFile) async {
    print('Sunucuya gönderiliyor...'); // <-- EKLE
    try { // <-- EKLE
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.15:5000/stt'),
      );
      request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
      print('Dosya eklendi, istek gönderiliyor...'); // <-- EKLE
      var response = await request.send();
      print('Sunucu cevabı: ${response.statusCode}'); // <-- EKLE
      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        print('Sunucu metni: $respStr'); // <-- EKLE
        setState(() {
          try {
            final decoded = jsonDecode(respStr);
            _spokenText = decoded['text'] ?? '';
          } catch (_) {
            _spokenText = respStr;
          }
        });
      } else {
        print('Hata: ${response.statusCode}'); // <-- EKLE
        setState(() {
          _spokenText = "Hata oluştu!";
        });
      }
    } catch (e) { // <-- EKLE
      print('Bağlantı hatası: $e'); // <-- EKLE
      setState(() {
        _spokenText = "Bağlantı hatası: $e";
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _audioPlayer.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF6E21B5), // Mor arka plan
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Mod değiştirme switch'i
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SES → İŞARET DİLİ',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                  child: Switch(
                    value: _isSignLanguageMode,
                    onChanged: (val) {
                      setState(() {
                        _isSignLanguageMode = val;
                        if (_isSignLanguageMode) {
                          _startImageStreaming();
                          _spokenText = '';
                          _avatarSignText = 'Avatar burada işaret dilini gösterecek...';
                          _isRecording = false;
                        } else {
                          _timer?.cancel();
                          _detectedText = '';
                          _audioPlayer.stop();
                        }
                      });
                    },
                    activeColor: const Color(0xFF6E21B5),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'İŞARET DİLİ → SES',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              child: Center(
                child: Container(
                  width: 365,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232B36),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isSignLanguageMode
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, color: Colors.red),
                          SizedBox(width: 8),
                          Text('KAMERA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black),
                        ),
                        child: _isCameraInitialized && _cameraController!.value.isInitialized
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                            : const Center(child: CircularProgressIndicator(color: Color(0xFF6E21B5))),
                      ),
                      const SizedBox(height: 20),
                      const Text('ALGILANAN METİN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black),
                        ),
                        child: SingleChildScrollView(
                          child: Text(_detectedText, style: const TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            iconSize: 40,
                            color: Colors.black,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop),
                            iconSize: 40,
                            color: Colors.black,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                            onPressed: () {
                              _audioPlayer.stop();
                            },
                          ),
                        ],
                      ),
                    ],
                  )
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mikrofon butonu
                      IconButton(
                        icon: Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          size: 80,
                          color: _isRecording ? Colors.red : Colors.white,
                        ),
                        onPressed: _isRecording ? _stopRecordingAndSend : _startRecording,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'KONUŞULAN METİN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black),
                        ),
                        child: SingleChildScrollView(
                          child: Text(_spokenText, style: const TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'AVATAR İŞARET DİLİ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black),
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Text(
                              _avatarSignText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6E21B5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                onPressed: () {
                  context.go(AppRoutes.livesupport);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF6E21B5)),
                    SizedBox(width: 8),
                    Text(
                      'Chat Bot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6E21B5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
