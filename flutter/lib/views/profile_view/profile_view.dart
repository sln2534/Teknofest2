import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool notificationsEnabled = true; // Bildirimler için state

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profil kutucuğu
        Container(
          width: 350,
          height: 85,
          margin: const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8C7AE6), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C7AE6).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEAEAFF),
                child: Icon(Icons.person, size: 32, color: Colors.grey[700]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Kullanıcı',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'kullanici@email.com',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Profil düzenleme işlemi
                },
                icon: Icon(Icons.edit, color: Color(0xFF8C7AE6)),
                splashRadius: 22,
              ),
            ],
          ),
        ),
        // Ayarlar kutusu
        Container(
          width: 350,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8C7AE6), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C7AE6).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "Ayarlar",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF6E21B5),
                  ),
                ),
              ),
              // Çeviri Dili
              _settingsRow(
                icon: Icons.language,
                iconColor: Color(0xFF8C7AE6),
                title: "Çeviri Dili",
                trailing: const Text("Türkçe", style: TextStyle(color: Colors.black)),
                 
              ),
              // İşaret Dili Varyantı
              _settingsRow(
                icon: Icons.pan_tool_alt_rounded,
                iconColor: Color(0xFF8C7AE6),
                title: "İşaret Dili Varyantı",
                trailing: const Text("TİD", style: TextStyle(color: Colors.black)),
              ),
              // Bildirimler
              _settingsRow(
                icon: Icons.confirmation_num_rounded,
                iconColor: Color(0xFF8C7AE6),
                title: "Bildirimler",
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (val) {
                    setState(() {
                      notificationsEnabled = val;
                    });
                  },
                  activeColor: Color(0xFF8C7AE6),           // Açıkken thumb rengi (mor)
                  activeTrackColor: Color(0xFFB39DDB),      // Açıkken arka plan (isteğe bağlı)
                  inactiveThumbColor: Color(0xFF8C7AE6),    // Kapalıyken thumb rengi (mor)
                  inactiveTrackColor: Color(0xFFEAEAFF),    // Kapalıyken arka plan (isteğe bağlı)
                ),
              ),
              // Gizlilik
              _settingsRow(
                icon: Icons.lock,
                iconColor: Color(0xFF8C7AE6),
                title: "Gizlilik",
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
        ),
        // Çıkış Yap butonu
        Container(
          width: 350,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE), // Açık kırmızı arka plan
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton.icon(
            onPressed: () {
              // Çıkış işlemi burada yapılacak
              Navigator.of(context).popUntil((route) => route.isFirst);
              // go_router ile login sayfasına yönlendir
              // context.go('/login');
              // Ancak context.go kullanabilmek için import eklenmeli
              // Bunun yerine aşağıda doğrudan context.go ile yönlendirme yapalım:
              // context.go('/login');
              // En doğru yöntem:
              // context.go('/login');
              // Ama context.go kullanmak için import 'package:go_router/go_router.dart'; ekle
              // Kısa ve net:
              // context.go('/login');
              // Son hali:
              context.go('/login');
            },
            icon: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
            label: const Text(
              "Çıkış Yap",
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.transparent, // Container'ın rengi kullanılacak
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _settingsRow({
  required IconData icon,
  required Color iconColor,
  required String title,
  required Widget trailing,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEAEAFF),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        trailing,
      ],
    ),
  );
  
}
