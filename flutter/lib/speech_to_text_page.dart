import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextPage extends StatefulWidget {
  @override
  _SpeechToTextPageState createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String _recognizedText = "";

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<String> _getFilePath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/audio.wav';
  }

  Future<void> _startRecording() async {
    String path = await _getFilePath();
    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.pcm16WAV,
    );
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecordingAndSend() async {
    String? path = await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (path != null) {
      await _sendToServer(File(path));
    } else {
      setState(() {
        _recognizedText = "Kayıt dosyası bulunamadı!";
      });
    }
  }

  Future<void> _sendToServer(File audioFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.15:5000/stt'), // Sunucu IP'sini buraya yaz!
    );
    request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      setState(() {
        _recognizedText = respStr;
      });
    } else {
      setState(() {
        _recognizedText = "Hata oluştu!";
      });
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isRecording ? _stopRecordingAndSend : _startRecording,
          child: Icon(_isRecording ? Icons.stop : Icons.mic),
        ),
        Text(_recognizedText),
      ],
    );
  }
}