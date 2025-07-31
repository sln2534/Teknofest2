from roboflow import Roboflow
from ultralytics import YOLO
import os
import shutil
import torch

def main():
    print("GPU kullanılabilir mi?", torch.cuda.is_available()) 
    if torch.cuda.is_available():
        print("Kullanılan GPU:", torch.cuda.get_device_name(0))
    else:
        print("GPU bulunamadı, CPU ile eğitim yapılacak.")
    
    # Veri setini indir (zaten indirdiyse tekrar indirmez)
    rf = Roboflow(api_key="dLhQbx0JymZSxmq7ZekF")
    project = rf.workspace("proje-qtjgs").project("turk-isaret-dili")
    version = project.version(2)
    dataset = version.download("yolov8")
    print(f"Veri seti indirildi: {dataset.location}")
    
    # YOLOv8 modelini yükle
    model = YOLO("yolov8n.pt")

    # Eğitim işlemi (try-except ile hata ayıklama dahil)
    try:
        results = model.train(
            data=os.path.join(dataset.location, "data.yaml"),
            epochs=30,
            imgsz=640,
            batch=8,
            name="sign_language_model"
        )
        print("✅ Eğitim tamamlandı.")
        print("📁 Eğitim çıktısı klasörü:", results.save_dir)
    except Exception as e:
        print("❌ Eğitim sırasında hata oluştu:", e)
        return

    # Eğitim dosyasını yedekle
    last_weights = os.path.join("runs", "train", "sign_language_model", "weights", "last.pt")
    backup_folder = "backup"
    backup_path = os.path.join(backup_folder, "last_backup.pt")
    
    os.makedirs(backup_folder, exist_ok=True)

    if os.path.exists(last_weights):
        shutil.copy(last_weights, backup_path)
        print(f"💾 Model yedeklendi: {backup_path}")
    else:
        print("⚠️ UYARI: last.pt dosyası bulunamadı, yedekleme yapılmadı.")

if __name__ == '__main__':
    main()
