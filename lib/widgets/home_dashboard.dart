import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/records_provider.dart';
import '../providers/workers_provider.dart';
import '../screens/coffee_sales_screen.dart';
import '../screens/workers_screen.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final recordsProvider = context.watch<RecordsProvider>();
    final workersProvider = context.watch<WorkersProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _animateIn(0, _buildHeroHeader(context)),
          const SizedBox(height: 16),
          _animateIn(1, _buildQuickActions(context)),
          const SizedBox(height: 20),
          _animateIn(
            2,
            _buildStatsGrid(context, recordsProvider, workersProvider),
          ),
          const SizedBox(height: 20),
          _animateIn(3, _buildRecentSales(context, recordsProvider)),
          const SizedBox(height: 16),
          _animateIn(
            4,
            ElevatedButton.icon(
              onPressed: () => _showPdfDialog(context, recordsProvider),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Exportar Reporte PDF'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animateIn(int step, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (step * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.espresso, AppPalette.cocoa],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35100000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.coffee, size: 34, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido a Koffee',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                  style: const TextStyle(
                    color: Color(0xFFEEDFD0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 390;
        final cards = [
          _ActionCard(
            icon: Icons.people_alt_outlined,
            title: 'Jornaleros',
            subtitle: 'Gestionar trabajadores y registrar kilogramos',
            color: const Color(0xFFE67E22),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkersScreen()),
            ),
          ),
          _ActionCard(
            icon: Icons.sell_outlined,
            title: 'Registrar Venta',
            subtitle: 'Registrar venta de café seco',
            color: AppPalette.leaf,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoffeeSalesScreen()),
            ),
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [cards[0], const SizedBox(height: 12), cards[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    RecordsProvider recordsProvider,
    WorkersProvider workersProvider,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 390;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: isNarrow ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isNarrow ? 2.5 : 1.32,
          children: [
            _StatCard(
              title: 'Fincas',
              value: '${recordsProvider.farmNames.length}',
              icon: Icons.landscape_outlined,
              color: const Color(0xFF2E7D32),
            ),
            _StatCard(
              title: 'Workers',
              value: '${workersProvider.workers.length}',
              icon: Icons.groups_2_outlined,
              color: const Color(0xFFE67E22),
            ),
            _StatCard(
              title: 'Ventas',
              value: '${recordsProvider.records.length}',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF33691E),
            ),
            _StatCard(
              title: 'Pendientes',
              value:
                  '${workersProvider.records.where((r) => !r.isPaid).length}',
              icon: Icons.pending_actions_outlined,
              color: const Color(0xFFAD8B00),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSales(BuildContext context, RecordsProvider provider) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');
    final records = provider.records.take(5).toList();

    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 42, color: Colors.brown.shade200),
            const SizedBox(height: 8),
            Text(
              'No hay ventas registradas',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              'Últimas Ventas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          ...records.map(
            (record) => ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppPalette.leaf.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppPalette.leaf,
                  size: 18,
                ),
              ),
              title: Text(
                record.farmName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${record.dryCoffeeKg.toStringAsFixed(1)} kg - ${dateFormat.format(record.date)}',
              ),
              trailing: Text(
                currencyFormat.format(record.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppPalette.leaf,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _showPdfDialog(BuildContext context, RecordsProvider provider) {
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
                color: AppPalette.cocoa,
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
              leading: const Icon(
                Icons.calendar_month,
                color: AppPalette.cocoa,
              ),
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
              leading: const Icon(Icons.history, color: AppPalette.cocoa),
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
    final provider = context.read<RecordsProvider>();
    final allRecords = provider.records;
    final filtered = allRecords.where((record) {
      final date = record.date;
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
        records: filtered,
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              height: 1,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }
}
