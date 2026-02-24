import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/registro_provider.dart';
import '../services/pdf_service.dart';
import '../services/auth_service.dart';
import '../widgets/registro_list_view.dart';
import '../widgets/kilos_bar_chart.dart';
import '../widgets/home_dashboard.dart';
import 'fincas_screen.dart';
import 'perfil_screen.dart';
import 'jornaleros_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = const [
    'Inicio',
    'Registros',
    'Fincas',
    'Gráfica',
    'Perfil',
  ];

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
        context.read<RegistroProvider>().loadRegistros();
      } else if (index == 2) {
        context.read<RegistroProvider>().loadFincas();
      }
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_selectedIndex == 1) ...[
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Generar Reporte PDF',
              onPressed: () => _showPdfDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
              onPressed: () {
                context.read<RegistroProvider>().syncRecords();
              },
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            tooltip: 'Usuario',
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    const Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeDashboard(),
          RegistroListView(),
          FincasScreen(),
          KilosBarChart(),
          PerfilScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Registros',
            ),
            NavigationDestination(
              icon: Icon(Icons.landscape_outlined),
              selectedIcon: Icon(Icons.landscape),
              label: 'Fincas',
            ),
            NavigationDestination(
              icon: Icon(Icons.insert_chart_outlined),
              selectedIcon: Icon(Icons.insert_chart),
              label: 'Gráfica',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outlined),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generar Reporte PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.calendar_view_week,
                color: Colors.brown,
              ),
              title: const Text('Esta Semana'),
              onTap: () {
                Navigator.pop(ctx);
                final now = DateTime.now();
                _generateReport(
                  now.subtract(const Duration(days: 7)),
                  now,
                  'Reporte Semanal',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.brown),
              title: const Text('Este Mes'),
              onTap: () {
                Navigator.pop(ctx);
                final now = DateTime.now();
                final startOfMonth = DateTime(now.year, now.month, 1);
                _generateReport(
                  startOfMonth,
                  now,
                  'Reporte Mensual (${DateFormat('MMMM', 'es').format(now)})',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.brown),
              title: const Text('Todo el Historial'),
              onTap: () {
                Navigator.pop(ctx);
                _generateReport(
                  DateTime(2020),
                  DateTime.now(),
                  'Reporte Histórico Completo',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(
    DateTime start,
    DateTime end,
    String title,
  ) async {
    final provider = context.read<RegistroProvider>();
    // Filter records locally
    final allRecords = provider.registros;
    final filtered = allRecords.where((reg) {
      final date = reg.fecha;
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    if (filtered.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay registros en este periodo')),
        );
      }
      return;
    }

    try {
      await PdfService.generateReport(
        title: title,
        registros: filtered,
        startDate: start,
        endDate: end,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generando PDF: $e')));
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
