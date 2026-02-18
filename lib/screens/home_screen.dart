import 'package:flutter/material.dart';
import '../widgets/registro_form.dart';
import '../widgets/registro_list_view.dart';
import '../widgets/kilos_bar_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Agrícola'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle), text: 'Nuevo'),
            Tab(icon: Icon(Icons.list), text: 'Registros'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Gráfica'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RegistroForm(),
          RegistroListView(),
          KilosBarChart(),
        ],
      ),
    );
  }
}
