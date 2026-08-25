import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          final user = AuthService.instance.currentUser;
          final email = user?.email ?? 'caficultor@koffee.app';
          final records = provider.records;
          final farms = provider.farms;

          final totalSales = records.fold<double>(0, (sum, r) => sum + r.total);
          final totalDryKg = records.fold<double>(
            0,
            (sum, r) => sum + r.dryCoffeeKg,
          );
          final avgPrice = totalDryKg > 0 ? (totalSales / totalDryKg) : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(email, provider.role),
                  const SizedBox(height: 18),
                  _buildSummarySection(
                    context,
                    currencyFormat,
                    records.length,
                    farms.length,
                    totalDryKg,
                    totalSales,
                    avgPrice,
                  ),
                  const SizedBox(height: 18),
                  _buildInfoCard(context, email),
                  const SizedBox(height: 18),
                  _buildActionsSection(context, provider),
                  const SizedBox(height: 18),
                  _buildAppInfo(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String email, String role) {
    final username = email.split('@').first.toUpperCase();
    final initial = username.isNotEmpty ? username.substring(0, 1) : 'C';

    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.caramel,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppPalette.espresso,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFECD9C8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppPalette.leaf,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        role.toUpperCase() == 'ADMIN' ? 'ADMINISTRADOR' : 'CAFICULTOR REGISTRADO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
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

  Widget _buildSummarySection(
    BuildContext context,
    NumberFormat currency,
    int totalSales,
    int farmCount,
    double totalDryKg,
    double totalIncome,
    double avgPrice,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.insights_rounded, color: AppPalette.cocoa, size: 18),
            SizedBox(width: 8),
            Text(
              'Resumen Histórico',
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
            _buildStatCard(
              icon: Icons.monetization_on_rounded,
              label: 'Ingresos Totales',
              value: currency.format(totalIncome),
              color: AppPalette.leaf,
            ),
            _buildStatCard(
              icon: Icons.scale_rounded,
              label: 'Café Seco Total',
              value: '${totalDryKg.toStringAsFixed(1)} kg',
              color: AppPalette.caramelDark,
            ),
            _buildStatCard(
              icon: Icons.receipt_long_rounded,
              label: 'Ventas Realizadas',
              value: '$totalSales',
              color: AppPalette.espresso,
            ),
            _buildStatCard(
              icon: Icons.landscape_rounded,
              label: 'Fincas Activas',
              value: '$farmCount',
              color: const Color(0xFF43655A),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String email) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la Cuenta',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Correo',
            value: email,
          ),
          const Divider(height: 20, color: AppPalette.cardBorder),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha Actual',
            value: DateFormat('d MMMM yyyy', 'es').format(DateTime.now()),
          ),
          const Divider(height: 20, color: AppPalette.cardBorder),
          _buildInfoRow(
            icon: Icons.cloud_done_outlined,
            label: 'Sincronización Cloud',
            value: 'Activa con Firebase',
            valueColor: AppPalette.leaf,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppPalette.cocoa),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppPalette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, RecordsProvider provider) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppPalette.cardBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_reset_rounded, color: Colors.blue, size: 20),
            ),
            title: const Text(
              'Cambiar Contraseña',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: const Text(
              'Enviar correo para restablecer contraseña',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppPalette.textMuted),
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1, color: AppPalette.cardBorder),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPalette.caramel.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppPalette.caramelDark, size: 20),
            ),
            title: const Text(
              'Descargar Reporte Completo',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: const Text(
              'Generar PDF con todo el historial de ventas',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppPalette.textMuted),
            onTap: () async {
              if (provider.records.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay ventas registradas para exportar')),
                );
                return;
              }
              await PdfService.generateReport(
                title: 'Reporte Histórico Completo de Ventas',
                records: provider.records,
                startDate: DateTime(2020),
                endDate: DateTime.now(),
              );
            },
          ),
          const Divider(height: 1, color: AppPalette.cardBorder),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 20),
            ),
            title: Text(
              'Cerrar Sesión',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: const Text(
              'Salir de tu cuenta en este dispositivo',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppPalette.textMuted),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppPalette.espresso.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee_rounded, color: AppPalette.espresso, size: 16),
          ),
          const SizedBox(width: 8),
          const Text(
            'Koffee • Registro Cafetero v1.0.0',
            style: TextStyle(
              color: AppPalette.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final emailController = TextEditingController(
      text: AuthService.instance.currentUser?.email ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppPalette.cocoa),
            SizedBox(width: 10),
            Text('Cambiar Contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se enviará un enlace a tu correo electrónico para restablecer de forma segura tu contraseña.',
              style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              enabled: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Correo de recuperación enviado con éxito'),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Enviar Correo'),
          ),
        ],
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
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cerrar Sesión',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
