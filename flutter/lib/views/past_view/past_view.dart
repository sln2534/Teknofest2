import 'package:flutter/material.dart';

class PastView extends StatelessWidget {
  const PastView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Container(
            width: 360,
            height: 500,
            margin: const EdgeInsets.only(top: 32), // Üste boşluk eklemek için
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF8C7AE6), // Yeni mor çerçeve rengi
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve "Tümünü Gör"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Bugün",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Tümünü Gör",
                      style: TextStyle(
                        color: Color(0xFF6E21B5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Geçmiş kartları
                _PastCard(
                  text: "Merhaba, nasılsınız?",
                  time: "14:32",
                  label: "İşaret → Konuşma",
                  labelColor: Color(0xFF6E21B5),
                ),
                _PastCard(
                  text: "Yardıma ihtiyacım var.",
                  time: "14:28",
                  label: "Konuşma → İşaret",
                  labelColor: Color(0xFFB39DDB),
                ),
                _PastCard(
                  text: "Teşekkür ederim.",
                  time: "13:45",
                  label: "İşaret → Konuşma",
                  labelColor: Color(0xFF6E21B5),
                ),
              ],
            ),
          ),
          // İstersen alta başka widget'lar ekleyebilirsin
        ],
      ),
    );
  }
}

class _PastCard extends StatefulWidget {
  final String text;
  final String time;
  final String label;
  final Color labelColor;

  const _PastCard({
    required this.text,
    required this.time,
    required this.label,
    required this.labelColor,
    Key? key,
  }) : super(key: key);

  @override
  State<_PastCard> createState() => _PastCardState();
}

class _PastCardState extends State<_PastCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEAEAFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: metin ve saat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                widget.time,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Alt satır: etiket ve ok
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.labelColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.labelColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                splashRadius: 18,
              ),
            ],
          ),
          // Açılır alan
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Detaylı bilgi veya ek açıklama buraya gelebilir.",
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
