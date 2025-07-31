import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppView({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: navigationShell.currentIndex == 0
          ? _appBarWidget()
          : navigationShell.currentIndex == 1
              ? _pastAppBarWidget()
              : navigationShell.currentIndex == 2
                  ? _liveSupportAppBarWidget()
                  : navigationShell.currentIndex == 3
                      ? _profileAppBarWidget()
                      : null,
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(color: Theme.of(context).colorScheme.primary);
            }
            return TextStyle(color: Theme.of(context).colorScheme.tertiary);
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          indicatorColor: Colors.transparent,
          onDestinationSelected: navigationShell.goBranch,
          destinations: [
            _menuItem(
              context,
              index: 0,
              currentIndex: navigationShell.currentIndex,
              icon: Icons.home,
              label: 'Ana Sayfa',
            ),
            _menuItem(
              context,
              index: 1,
              currentIndex: navigationShell.currentIndex,
              icon: Icons.access_time,
              label: 'Geçmiş',
            ),
            _menuItem(
              context,
              index: 2,
              currentIndex: navigationShell.currentIndex,
              icon: Icons.support_agent,
              label: 'Canlı Destek',
            ),
            _menuItem(
              context,
              index: 3,
              currentIndex: navigationShell.currentIndex,
              icon: Icons.account_circle,
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required String label,
    required IconData icon,
  }) {
    return NavigationDestination(
      icon: Icon(
        icon,
        color: currentIndex == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.tertiary,
      ),
      label: label,
    );
  }

  AppBar _appBarWidget() {
    return AppBar(
      backgroundColor: const Color(0xFF6E21B5),
      title: const Text(
        'İşaret Dili Çevirmen',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings, color: Colors.white))],
    );
  }

  AppBar _pastAppBarWidget() {
    return AppBar(
      backgroundColor: const Color(0xFF6E21B5),
      title: const Text(
        'Geçmiş Çeviriler',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Geçmişi silme işlemi buraya eklenebilir
          },
          icon: const Icon(Icons.delete, color: Colors.white),
        ),
      ],
    );
  }

  AppBar _liveSupportAppBarWidget() {
    return AppBar(
      backgroundColor: const Color(0xFF6E21B5),
      title: const Text(
        'Canlı Destek',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
      ),
    );
  }

  AppBar _profileAppBarWidget() {
    return AppBar(
      backgroundColor: const Color(0xFF6E21B5),
      title: const Text(
        'Profil',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Ayarlar sayfasına yönlendirme veya başka bir işlem ekleyebilirsiniz
          },
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }
}
