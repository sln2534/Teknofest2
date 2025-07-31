import os

file_path = 'hand_landmarker.task'

if not os.path.exists(file_path):
    print(f"Hata: '{file_path}' dosyası bulunamadı. Lütfen klasörde olduğundan emin olun.")
else:
    try:
        with open(file_path, 'rb') as f:
            data = f.read(100) # İlk 100 byte'ı oku
            print('Dosya başarıyla okundu. İlk 100 byte (ilk 50 gösteriliyor):', data[:50])
    except IOError as e:
        print(f"Dosya okuma/erişim hatası (IOError): {e}")
    except Exception as e:
        print(f"Beklenmedik bir hata oluştu: {e}")