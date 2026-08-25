import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/coffee_record.dart';
import '../providers/records_provider.dart';
import '../screens/coffee_sales_screen.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import 'kilograms_bar_chart.dart';
import 'responsive.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '¡Buenos días!';
    } else if (hour >= 12 && hour < 19) {
      return '¡Buenas tardes!';
    } else {
      return '¡Buenas noches!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsProvider = context.watch<RecordsProvider>();
    final user = AuthService.instance.currentUser;
    final userEmail = user?.email ?? '';
    final username = userEmail.isNotEmpty ? userEmail.split('@').first : 'Caficultor';

    return RefreshIndicator(
      color: AppPalette.caramel,
      backgroundColor: Colors.white,
      onRefresh: () => recordsProvider.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _animateIn(0, _buildHeroHeader(context, username, recordsProvider)),
              const SizedBox(height: 16),
              _animateIn(1, _buildQuickActions(context, recordsProvider)),
              const SizedBox(height: 20),
              _animateIn(2, _buildStatsGrid(context, recordsProvider)),
              const SizedBox(height: 20),
              _animateIn(3, const KilogramsBarChart()),
              const SizedBox(height: 20),
              _animateIn(4, _buildRecentSales(context, recordsProvider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animateIn(int step, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (step * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    String username,
    RecordsProvider provider,
  ) {
    final totalSales = provider.records.fold<double>(0, (sum, r) => sum + r.total);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x321E1109),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 30,
                  color: AppPalette.caramel,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()} ${username.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
                      style: const TextStyle(
                        color: Color(0xFFE4D5C9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Acumulado',
                      style: TextStyle(
                        color: Color(0xFFDCC8B9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(totalSales),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppPalette.leaf,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.records.length} ventas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildQuickActions(BuildContext context, RecordsProvider provider) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _HeroActionCard(
            icon: Icons.add_shopping_cart_rounded,
            title: 'Nueva Venta',
            subtitle: 'Registrar café seco',
            gradient: AppGradients.leaf,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoffeeSalesScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _HeroActionCard(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Reporte PDF',
            subtitle: 'Exportar datos',
            gradient: AppGradients.caramel,
            onTap: () => _showPdfBottomSheet(context, provider),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    RecordsProvider recordsProvider,
  ) {
    final records = recordsProvider.records;
    final totalSales = records.fold<double>(0, (sum, r) => sum + r.total);
    final totalDryKg = records.fold<double>(0, (sum, r) => sum + r.dryCoffeeKg);
    final avgPrice = totalDryKg > 0 ? (totalSales / totalDryKg) : 0.0;

    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.dashboard_customize_rounded, size: 18, color: AppPalette.cocoa),
            SizedBox(width: 8),
            Text(
              'Métricas Clave',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AutoGrid(
          minTileWidth: 150,
          maxColumns: 2,
          spacing: 12,
          children: [
            _StatCard(
              title: 'Ingresos Totales',
              value: currencyFormat.format(totalSales),
              icon: Icons.monetization_on_rounded,
              color: AppPalette.leaf,
              badge: 'Total ventas',
            ),
            _StatCard(
              title: 'Café Seco Total',
              value: '${totalDryKg.toStringAsFixed(1)} kg',
              icon: Icons.scale_rounded,
              color: AppPalette.caramelDark,
              badge: 'Producción',
            ),
            _StatCard(
              title: 'Fincas Activas',
              value: '${recordsProvider.farms.length}',
              icon: Icons.landscape_rounded,
              color: AppPalette.espresso,
              badge: 'Predios',
            ),
            _StatCard(
              title: 'Promedio por Kilo',
              value: currencyFormat.format(avgPrice),
              icon: Icons.price_check_rounded,
              color: const Color(0xFF43655A),
              badge: 'COP / Kg',
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

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: AppPalette.cocoa),
                    SizedBox(width: 8),
                    Text(
                      'Últimas Ventas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (records.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CoffeeSalesScreen(),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Ver todas'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppPalette.cardBorder),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppPalette.crema,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        size: 38,
                        color: AppPalette.caramel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay ventas registradas aún',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Comienza registrando tu primera venta de café.',
                      style: TextStyle(color: AppPalette.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CoffeeSalesScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Registrar Venta'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 68,
                endIndent: 16,
                color: AppPalette.cardBorder,
              ),
              itemBuilder: (context, index) {
                final record = records[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  onTap: () => _showSaleBottomSheet(context, record),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppPalette.leafLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: AppPalette.leaf,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    record.farmName.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${record.dryCoffeeKg.toStringAsFixed(1)} kg • ${dateFormat.format(record.date)}',
                    style: const TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    currencyFormat.format(record.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppPalette.leaf,
                      fontSize: 15,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _showSaleBottomSheet(BuildContext context, CoffeeRecord record) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'es');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.leafLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_rounded,
                      color: AppPalette.leaf,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle de Venta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        Text(
                          record.farmName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppPalette.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(record.total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.leaf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppPalette.cardBorder),
              const SizedBox(height: 12),
              _buildModalRow('Fecha de Venta', dateFormat.format(record.date), Icons.calendar_today_rounded),
              _buildModalRow('Café Seco', '${record.dryCoffeeKg.toStringAsFixed(2)} kg', Icons.scale_rounded),
              _buildModalRow('Precio por Kilo', currencyFormat.format(record.pricePerKg), Icons.sell_rounded),
              _buildModalRow(
                'Estado',
                record.isSynced ? 'Sincronizado' : 'Pendiente',
                Icons.cloud_done_rounded,
                valueColor: record.isSynced ? AppPalette.leaf : AppPalette.caramelDark,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppPalette.cocoa),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppPalette.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: valueColor ?? AppPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPdfBottomSheet(BuildContext context, RecordsProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: AppPalette.cocoa, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Exportar Reporte PDF',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona el periodo para generar tu reporte de ventas.',
                style: TextStyle(color: AppPalette.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _buildReportTile(
                icon: Icons.calendar_view_week_rounded,
                title: 'Esta Semana',
                subtitle: 'Últimos 7 días de ventas',
                onTap: () {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  _generateReport(
                    context,
                    now.subtract(const Duration(days: 7)),
                    now,
                    'Reporte Semanal de Ventas',
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildReportTile(
                icon: Icons.calendar_month_rounded,
                title: 'Este Mes',
                subtitle: DateFormat('MMMM yyyy', 'es').format(DateTime.now()).toUpperCase(),
                onTap: () {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  _generateReport(
                    context,
                    startOfMonth,
                    now,
                    'Reporte Mensual (${DateFormat('MMMM yyyy', 'es').format(now)})',
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildReportTile(
                icon: Icons.history_rounded,
                title: 'Historial Completo',
                subtitle: 'Todas las ventas registradas',
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
        ),
      ),
    );
  }

  Widget _buildReportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppPalette.crema,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppPalette.espresso, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppPalette.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppPalette.textMuted),
          ],
        ),
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
          const SnackBar(content: Text('No hay ventas en este periodo seleccionado')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generando PDF: $e')),
        );
      }
    }
  }
}

class _HeroActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _HeroActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x202E1C14),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
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
  final String badge;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
