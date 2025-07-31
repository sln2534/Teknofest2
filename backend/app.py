from flask import Flask, request, jsonify # send_file artık gerekli değil
import os
import whisper
import requests # AI yanıtı almak için gerekli

# from TTS.api import TTS # <-- Bu satır çıkarıldı

app = Flask(__name__)

# 🔹 Load Whisper Model (Speech-to-Text)
try:
    stt_model = whisper.load_model("base") # "base" modelini yükler
    print("✅ Whisper STT modeli başarıyla yüklendi.")
except Exception as e:
    print(f"ERROR: Whisper modeli yüklenirken hata oluştu: {e}")
    print("Lütfen internet bağlantınızı kontrol edin veya 'base' modeli için yeterli diskiniz olduğundan emin olun.")
    exit()

# 🔹 Hugging Face AI Model Setup - BU KISIM KALIYOR
HF_TOKEN = os.getenv("HF_TOKEN")  # API key env se le raha hai (Hugging Face Spaces ke Secrets me add karna)
MODEL_ID = "mistralai/Mixtral-8x7B-Instruct-v0.1"
API_URL = f"https://api-inference.huggingface.co/models/{MODEL_ID}"
HEADERS = {"Authorization": f"Bearer {HF_TOKEN}"}

# 🔹 Load TTS Model (Text-to-Speech) - BU KISIM TAMAMEN ÇIKARILDI
# tts_model = TTS("tts_models/en/ljspeech/tacotron2-DDC") # <-- Bu satır çıkarıldı

@app.route("/process_audio", methods=["POST"]) # Endpoint'i orijinal adında bıraktım
def process_audio():
    """Ses -> STT -> AI Yanıtı -> Metin Olarak Geri Dön."""
    # file yerine audio kullanılıyorsa mobil uygulamada, bu satırı değiştirin:
    if "audio" not in request.files: # Mobil uygulamanızın "audio" anahtarıyla dosya gönderdiğini varsaydım.
        return jsonify({"error": "Ses dosyası sağlanmadı (beklenen anahtar 'audio')."}), 400

    audio_file = request.files["audio"]
    audio_path = "temp_input.wav" # Geçici dosya adı

    try:
        audio_file.save(audio_path)
        print(f"DEBUG: Ses dosyası '{audio_path}' kaydedildi. Boyut: {os.path.getsize(audio_path)} bytes") # Boyutu logla
        # ✅ Step 1: Convert Speech to Text (Whisper)
        result = stt_model.transcribe(audio_path)
        transcribed_text = result["text"]
        print(f"DEBUG: Çevrilen metin: '{transcribed_text}'") # Çevrilen metni logla
        # Boş veya çok kısa ses kontrolü
        if not transcribed_text.strip():
            print(f"WARNING: Gelen ses dosyası boş veya çok kısa. Çevrilen metin: '{transcribed_text}'")
            return jsonify({"error": "Ses girdisi boş veya çok kısa. Lütfen daha uzun konuşun."}), 400

        # ✅ Step 2: Get AI Response from Hugging Face - BU KISIM KALIYOR
        ai_response = generate_response(transcribed_text)
        print(f"DEBUG: AI yanıtı: '{ai_response}'") # AI yanıtını logla
        # ✅ Step 3: Convert AI Response to Speech (TTS) - BU KISIM ÇIKARILDI
        # output_audio_path = "output.wav"
        # tts_model.tts_to_file(text=ai_response, file_path=output_audio_path)
        # return send_file(output_audio_path, mimetype="audio/wav") # <-- Bu satır da çıkarıldı

        # ✅ Sonucu metin olarak gönder - YENİ DÖNÜŞ KISMI
        return jsonify({"text": ai_response}) # AI yanıtını doğrudan JSON metni olarak gönder

    except Exception as e:
        import traceback
        print(f"ERROR: İşlem sırasında genel bir hata oluştu: {e}")
        print(traceback.format_exc())
        return jsonify({"error": "Dahili sunucu hatası. İşlem tamamlanamadı."}), 500
    finally:
       if os.path.exists(audio_path):
           os.remove(audio_path)

def generate_response(text):
    """Call Hugging Face AI Model for response - BU FONKSİYON KALIYOR"""
    payload = {"inputs": text, "parameters": {"max_new_tokens": 150, "temperature": 0.7}}
    response = requests.post(API_URL, headers=HEADERS, json=payload)

    try:
        response.raise_for_status() # HTTP 4xx/5xx hatalarını yakala
        response_json = response.json()
        if isinstance(response_json, list) and "generated_text" in response_json[0]:
            return response_json[0]["generated_text"]
        else:
            # Hugging Face API'den gelen hata mesajlarını da döndürmek iyi olabilir
            print(f"WARNING: AI API'den beklenmeyen yanıt: {response_json}")
            return "Üzgünüm, isteğinizi işleyemedim."
        
    except requests.exceptions.RequestException as e:
        print(f"ERROR: Hugging Face API isteği sırasında hata: {e}")
        return f"AI bağlantı/API hatası: {str(e)}"    
    except Exception as e:
        print(f"ERROR: AI yanıtını ayrıştırırken hata oluştu: {e}")
        return f"AI yanıt hatası: {str(e)}"

if __name__== "main_":
    # Flask uygulamasını 5000 portunda çalıştıralım, orijinal 7860 değil.
    app.run(host="0.0.0.0", port=5000,debug=True) # debug=True, geliştirme sırasında hata ayıklamayı kolaylaştırır
    print("Flask uygulaması 0.0.0.0:5000 adresinde çalışıyor...")