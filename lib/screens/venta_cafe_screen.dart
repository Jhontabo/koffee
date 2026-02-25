import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/registro_finca.dart';
import '../providers/registro_provider.dart';
import '../services/pdf_service.dart';

class VentaCafeScreen extends StatefulWidget {
  const VentaCafeScreen({super.key});

  @override
  State<VentaCafeScreen> createState() => _VentaCafeScreenState();
}

class _VentaCafeScreenState extends State<VentaCafeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _fechaController = TextEditingController();
  final _kilosSecoController = TextEditingController();
  final _precioController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _lastUserId;
  List<String> _fincasList = [];
  String? _selectedFinca;
  double _totalCalculado = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fechaController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _kilosSecoController.addListener(_calcularTotal);
    _precioController.addListener(_calcularTotal);
  }

  void _calcularTotal() {
    final kilos = double.tryParse(_kilosSecoController.text) ?? 0;
    final precio = double.tryParse(_precioController.text) ?? 0;
    setState(() {
      _totalCalculado = kilos * precio;
    });
  }

  void _loadFincas() {
    final provider = context.read<RegistroProvider>();
    final userId = provider.userId ?? '';
    final uniqueFincas = provider.fincas.toSet().toList()..sort();

    if (_lastUserId != userId) {
      _lastUserId = userId;
      setState(() {
        _fincasList = uniqueFincas;
      });
    } else {
      if (_fincasList.toSet().difference(uniqueFincas.toSet()).isNotEmpty ||
          uniqueFincas.toSet().difference(_fincasList.toSet()).isNotEmpty) {
        setState(() {
          _fincasList = uniqueFincas;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFincas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fechaController.dispose();
    _kilosSecoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _fechaController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final kilosSeco = double.parse(_kilosSecoController.text);
      final precioKilo = double.parse(_precioController.text);
      final total = kilosSeco * precioKilo;

      final registro = RegistroFinca(
        fecha: _selectedDate,
        fibra: _selectedFinca ?? '',
        kilosSeco: kilosSeco,
        precioKilo: precioKilo,
        total: total,
      );

      context.read<RegistroProvider>().addRegistro(registro);
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente')),
      );
      setState(() {
        _tabController.index = 1;
      });
    }
  }

  void _clearForm() {
    _kilosSecoController.clear();
    _precioController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _fechaController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _selectedFinca = null;
      _totalCalculado = 0;
    });
  }

  void _showPdfDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.brown[700]),
            const SizedBox(width: 8),
            const Text('Generar Reporte PDF'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPdfOption(
              ctx,
              icon: Icons.calendar_view_week,
              title: 'Esta Semana',
              subtitle: 'Últimos 7 días',
              color: Colors.blue,
            ),
            _buildPdfOption(
              ctx,
              icon: Icons.calendar_month,
              title: 'Este Mes',
              subtitle: DateFormat('MMMM yyyy', 'es').format(DateTime.now()),
              color: Colors.green,
            ),
            _buildPdfOption(
              ctx,
              icon: Icons.history,
              title: 'Todo el Historial',
              subtitle: 'Desde el inicio',
              color: Colors.orange,
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

  Widget _buildPdfOption(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(ctx);
          final now = DateTime.now();
          if (title == 'Esta Semana') {
            _generateReport(
              now.subtract(const Duration(days: 7)),
              now,
              'Reporte Semanal',
            );
          } else if (title == 'Este Mes') {
            final startOfMonth = DateTime(now.year, now.month, 1);
            _generateReport(startOfMonth, now, 'Reporte Mensual');
          } else {
            _generateReport(DateTime(2020), now, 'Reporte Histórico Completo');
          }
        },
      ),
    );
  }

  Future<void> _generateReport(
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
      if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generando PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventanas de café'),
        backgroundColor: Colors.brown[900],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor:Colors.white,
          unselectedLabelColor:Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'registrar'),
            Tab(icon: Icon(Icons.receipt_long), text: 'listado'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'exportar pdf',
            onPressed: _showPdfDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _fincasList.isEmpty ? _buildNoFincasMessage() : _buildForm(),
          _buildListView(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sell,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nueva Venta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Registra los datos de tu venta',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _fechaController,
              label: 'Fecha de la venta',
              icon: Icons.calendar_today,
              onTap: () => _selectDate(context),
              isReadOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleccione una fecha';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _kilosSecoController,
                    label: 'Kilos Secos',
                    icon: Icons.scale,
                    suffix: 'kg',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese kilos';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _precioController,
                    label: 'Precio/kg',
                    icon: Icons.attach_money,
                    prefix: '\$',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese precio';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Total de la Venta',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(_totalCalculado),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text(
                    'Guardar Venta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefix,
    String? suffix,
    bool isReadOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
        ),
        prefixIcon: Icon(icon),
        prefixText: prefix,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedFinca,
      decoration: InputDecoration(
        labelText: 'Finca',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
        ),
        prefixIcon: const Icon(Icons.landscape),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      isExpanded: true,
      hint: const Text('Seleccionar finca'),
      items: _fincasList.map((f) {
        return DropdownMenuItem<String>(
          value: f,
          child: Text(
            f.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedFinca = value;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Seleccione una finca';
        }
        return null;
      },
    );
  }

  Widget _buildListView() {
    return Consumer<RegistroProvider>(
      builder: (context, provider, child) {
        final registros = provider.registros;

        if (registros.isEmpty) {
          return _buildEmptyState();
        }

        final currencyFormat = NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
        );
        final totalVentas = registros.fold<double>(
          0,
          (sum, r) => sum + r.total,
        );

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.brown[900]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${registros.length} ventas registradas',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(totalVentas),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showPdfDialog,
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.brown[900],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80, top: 8),
                itemCount: registros.length,
                itemBuilder: (context, index) {
                  final reg = registros[index];
                  return _buildVentaCard(reg);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 64,
                color: Colors.green.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay ventas registradas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza registrando tu primera venta\nde café',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _tabController.index = 0;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Registrar Venta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVentaCard(RegistroFinca registro) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Dismissible(
      key: Key(registro.firebaseId ?? registro.hashCode.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        _showDeleteConfirmation(registro);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showVentaDetails(registro),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sell, color: Colors.white, size: 20),
                      Text(
                        '${registro.kilosSeco.toStringAsFixed(0)}kg',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registro.fibra.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(registro.fecha),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.attach_money,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          Text(
                            currencyFormat.format(registro.precioKilo),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(registro.total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (!registro.isSynced)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 10,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Pendiente',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVentaDetails(RegistroFinca registro) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'es');
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sell,
                    color: Colors.green.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles de Venta',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        registro.fibra.toUpperCase(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(registro.total),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailItem(
              icon: Icons.calendar_today,
              label: 'Fecha',
              value: dateFormat.format(registro.fecha),
            ),
            _buildDetailItem(
              icon: Icons.scale,
              label: 'Kilos Secos',
              value: '${registro.kilosSeco.toStringAsFixed(1)} kg',
            ),
            _buildDetailItem(
              icon: Icons.attach_money,
              label: 'Precio por kilo',
              value: currencyFormat.format(registro.precioKilo),
            ),
            _buildDetailItem(
              icon: Icons.check_circle,
              label: 'Estado',
              value: registro.isSynced ? 'Sincronizado' : 'Pendiente',
              valueColor: registro.isSynced ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(registro);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Eliminar Venta',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(RegistroFinca registro) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Eliminar Venta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Está seguro de eliminar esta venta?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.landscape,
                        size: 18,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          registro.fibra.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.scale, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${registro.kilosSeco.toStringAsFixed(1)} kg',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                      const Spacer(),
                      Text(
                        currencyFormat.format(registro.total),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Esta acción no se puede deshacer',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (registro.firebaseId != null) {
                context.read<RegistroProvider>().deleteRegistro(
                  registro.firebaseId!,
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFincasMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.landscape,
                size: 64,
                color: Colors.orange.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay fincas registradas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Para registrar ventas,\nprimero debes agregar una finca',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[900],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
