import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/registro_provider.dart';
import '../widgets/registro_form.dart';
import '../widgets/registro_list_view.dart';
import '../widgets/kilos_bar_chart.dart';

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
    'Gráfica',
  ];

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      if (index == 1) {
        context.read<RegistroProvider>().loadRegistros();
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
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<RegistroProvider>().syncRecords();
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          RegistroForm(),
          RegistroListView(),
          KilosBarChart(),
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
              icon: Icon(Icons.insert_chart_outlined),
              selectedIcon: Icon(Icons.insert_chart),
              label: 'Gráfica',
            ),
          ],
        ),
      ),
    );
  }
}
