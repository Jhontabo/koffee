import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/home_dashboard.dart';
import 'farms_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = const ['Panel Principal', 'Mis Fincas', 'Mi Perfil'];

  void navigateToTab(int index) {
    if (index >= 0 && index < _titles.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      if (index == 1) {
        context.read<RecordsProvider>().loadFarms();
      }
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final userEmail = user?.email ?? '';
    final username = userEmail.isNotEmpty ? userEmail.split('@').first : 'Caficultor';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x301E1109),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.coffee_rounded,
                color: AppPalette.caramel,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              tooltip: 'Menú de Usuario',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              offset: const Offset(0, 48),
              onSelected: (value) {
                if (value == 'profile') {
                  navigateToTab(2);
                } else if (value == 'logout') {
                  _showLogoutDialog(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppPalette.espresso,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Divider(height: 16),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        color: AppPalette.espresso,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Ver Perfil',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.background,
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: const [HomeDashboard(), FarmsScreen(), ProfileScreen()],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppPalette.cardBorder,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x182E1C14),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: NavigationBar(
              height: 64,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.terrain_outlined),
                  selectedIcon: Icon(Icons.terrain_rounded),
                  label: 'Fincas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cerrar Sesión',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir de tu cuenta de Koffee?',
          style: TextStyle(color: AppPalette.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
