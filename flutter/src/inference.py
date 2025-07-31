import cv2
from ultralytics import YOLO
from gtts import gTTS
from playsound import playsound  # Eğer playsound sorun çıkarsa pygame öneririm
import time

def speak_text(text):
    tts = gTTS(text=text, lang='tr')
    tts.save("temp.mp3")
    playsound("temp.mp3")

def form_sentence(words):
    # Kelimeleri küçük harfe çevir
    words = [w.lower() for w in words]

    # Basit kural örnekleri
    if 'dur' in words:
        return "Lütfen dur."

    subjects = {'anne', 'baba', 'kardeş', 'arkadaş'}
    verbs = {'içmek', 'özür-dileme', 'yemek', 'dur'}

    subject_word = None
    verb_word = None

    for w in words:
        if w in subjects:
            subject_word = w
        if w in verbs:
            verb_word = w

    if subject_word and verb_word:
        if verb_word == 'içmek':
            verb_word = 'içiyor'
        elif verb_word == 'özür-dileme':
            verb_word = 'özür diliyor'
        elif verb_word == 'yemek':
            verb_word = 'yiyor'

        return f"{subject_word.capitalize()} {verb_word}."

    if 'nerede' in words:
        for w in words:
            if w in {'tuvalet', 'ev', 'telefon'}:
                return f"{w.capitalize()} nerede?"

    if 'nasıl' in words:
        for w in words:
            if w in {'ev', 'yemek', 'kötü', 'iyi'}:
                return f"{w.capitalize()} nasıl?"

    short_phrases = {'evet', 'hayır', 'tamam', 'teşekkürler'}
    for w in words:
        if w in short_phrases:
            return w.capitalize()

    # Kural yoksa kelimeleri birleştir
    return " ".join(words).capitalize()

def main():
    model = YOLO("runs/detect/sign_language_model/weights/last.pt")
    cap = cv2.VideoCapture(0)

    previous_label = ""
    sentence_words = []
    last_detect_time = time.time()

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        results = model(frame)[0]
        boxes = results.boxes
        names = results.names

        current_label = ""

        for box in boxes:
            cls_id = int(box.cls.cpu().numpy())
            label = names[cls_id].lower()
            current_label = label

            x1, y1, x2, y2 = map(int, box.xyxy[0].cpu().numpy())
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX,
                        1, (0, 255, 0), 2)

        if current_label and current_label != previous_label:
            sentence_words.append(current_label)
            previous_label = current_label
            last_detect_time = time.time()

        if time.time() - last_detect_time > 4 and sentence_words:
            sentence = form_sentence(sentence_words)
            print(f"Kurulan cümle: {sentence}")
            speak_text(sentence)
            sentence_words.clear()

        cv2.imshow("El Hareketi Algılama", frame)

        if cv2.waitKey(1) & 0xFF == 27:
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()



