import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/registro_provider.dart';
import '../providers/jornaleros_provider.dart';
import '../screens/jornaleros_screen.dart';
import '../screens/venta_cafe_screen.dart';
import '../services/pdf_service.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final registroProvider = context.watch<RegistroProvider>();
    final jornalerosProvider = context.watch<JornalerosProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.brown[900],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.coffee, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'Bienvenido a Koffee',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickAccess(
            context,
            icon: Icons.people,
            title: 'Jornaleros',
            subtitle: 'Gestionar trabajadores y registrar kilos',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JornalerosScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickAccess(
            context,
            icon: Icons.sell,
            title: 'Registrar Venta',
            subtitle: 'Registrar venta de café seco',
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VentaCafeScreen()),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Resumen',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Fincas',
                  value: '${registroProvider.fincas.length}',
                  icon: Icons.landscape,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Trabajadores',
                  value: '${jornalerosProvider.trabajadores.length}',
                  icon: Icons.people,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Ventas',
                  value: '${registroProvider.registros.length}',
                  icon: Icons.sell,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Pendientes',
                  value:
                      '${jornalerosProvider.registros.where((r) => !r.estaPagado).length}',
                  icon: Icons.pending_actions,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHistorialVentas(context, registroProvider),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showPdfDialog(context, registroProvider),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar Reporte PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[900],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialVentas(
    BuildContext context,
    RegistroProvider provider,
  ) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');
    final registros = provider.registros.take(5).toList();

    if (registros.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No hay ventas registradas',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Últimas Ventas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...registros.map(
            (reg) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(Icons.sell, color: Colors.green[800], size: 20),
              ),
              title: Text(reg.fibra.toUpperCase()),
              subtitle: Text(
                '${reg.kilosSeco.toStringAsFixed(1)} kg - ${dateFormat.format(reg.fecha)}',
              ),
              trailing: Text(
                currencyFormat.format(reg.total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPdfDialog(BuildContext context, RegistroProvider provider) {
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
                  context,
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
                  context,
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
                  context,
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
    BuildContext context,
    DateTime start,
    DateTime end,
    String title,
  ) async {
    final provider = context.read<RegistroProvider>();
    final allRecords = provider.registros;
    final filtered = allRecords.where((reg) {
      final date = reg.fecha;
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    if (filtered.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay ventas en este periodo')),
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generando PDF: $e')));
      }
    }
  }
}
