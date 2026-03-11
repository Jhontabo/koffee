import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/coffee_record.dart';
import '../providers/records_provider.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

class CoffeeSalesScreen extends StatefulWidget {
  const CoffeeSalesScreen({super.key});

  @override
  State<CoffeeSalesScreen> createState() => _CoffeeSalesScreenState();
}

class _CoffeeSalesScreenState extends State<CoffeeSalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _dryCoffeeKgController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _lastUserId;
  List<String> _farmsList = [];
  String? _selectedFarm;
  double _calculatedTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _dryCoffeeKgController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final kilograms = double.tryParse(_dryCoffeeKgController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    setState(() {
      _calculatedTotal = kilograms * price;
    });
  }

  void _loadFarms() {
    final provider = context.read<RecordsProvider>();
    final userId = provider.userId ?? '';
    final uniqueFarms = provider.farmNames.toSet().toList()..sort();

    if (_lastUserId != userId) {
      _lastUserId = userId;
      setState(() {
        _farmsList = uniqueFarms;
      });
    } else {
      if (_farmsList.toSet().difference(uniqueFarms.toSet()).isNotEmpty ||
          uniqueFarms.toSet().difference(_farmsList.toSet()).isNotEmpty) {
        setState(() {
          _farmsList = uniqueFarms;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFarms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateController.dispose();
    _dryCoffeeKgController.dispose();
    _priceController.dispose();
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
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final dryCoffeeKg = double.parse(_dryCoffeeKgController.text);
      final pricePerKg = double.parse(_priceController.text);
      final total = dryCoffeeKg * pricePerKg;

      final record = CoffeeRecord(
        date: _selectedDate,
        farmName: _selectedFarm ?? '',
        dryCoffeeKg: dryCoffeeKg,
        pricePerKg: pricePerKg,
        total: total,
      );

      context.read<RecordsProvider>().addRecord(record);
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente')),
      );
      setState(() {
        _tabController.index = 1;
      });
    }
  }

  void _resetForm() {
    _dryCoffeeKgController.clear();
    _priceController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _selectedFarm = null;
      _calculatedTotal = 0;
    });
  }

  void _showReportDialog() {
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
            _buildReportOption(
              ctx,
              icon: Icons.calendar_view_week,
              title: 'Esta Semana',
              subtitle: 'Últimos 7 días',
              color: Colors.blue,
            ),
            _buildReportOption(
              ctx,
              icon: Icons.calendar_month,
              title: 'Este Mes',
              subtitle: DateFormat('MMMM yyyy', 'es').format(DateTime.now()),
              color: Colors.green,
            ),
            _buildReportOption(
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

  Widget _buildReportOption(
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
            color: color.withValues(alpha: 0.1),
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
    final provider = context.read<RecordsProvider>();
    final allRecords = provider.records;
    final filtered = allRecords.where((reg) {
      final date = reg.date;
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
        records: filtered,
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
        title: const Text('Ventas de Café'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.espresso, AppPalette.cocoa],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPalette.caramel,
          indicatorWeight: 2.8,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Registrar'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Listado'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4EEE7), Color(0xFFF1E8DF)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _farmsList.isEmpty ? _buildNoFarmsMessage() : _buildForm(),
            _buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 380;

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
                      color: Colors.white.withValues(alpha: 0.2),
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
              controller: _dateController,
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
            if (isNarrow) ...[
              _buildInputField(
                controller: _dryCoffeeKgController,
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
              const SizedBox(height: 12),
              _buildInputField(
                controller: _priceController,
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
            ] else
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _dryCoffeeKgController,
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
                      controller: _priceController,
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
                    currencyFormat.format(_calculatedTotal),
                    style: TextStyle(
                      fontSize: isNarrow ? 30 : 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveRecord,
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
                    Flexible(
                      child: Text(
                        'Guardar Venta',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
      initialValue: _selectedFarm,
      decoration: InputDecoration(
        labelText: 'Farm',
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
      items: _farmsList.map((f) {
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
          _selectedFarm = value;
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
    return Consumer<RecordsProvider>(
      builder: (context, provider, child) {
        final records = provider.records;

        if (records.isEmpty) {
          return _buildEmptyState();
        }

        final currencyFormat = NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
        );
        final totalSales = records.fold<double>(0, (sum, r) => sum + r.total);

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.brown[900]),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final summary = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${records.length} ventas registradas',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(totalSales),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isNarrow ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );

                  final button = ElevatedButton.icon(
                    onPressed: _showReportDialog,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.brown[900],
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [summary, const SizedBox(height: 10), button],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [summary, button],
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80, top: 8),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final reg = records[index];
                  return _buildSaleCard(reg);
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

  Widget _buildSaleCard(CoffeeRecord record) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Dismissible(
      key: Key(record.firebaseId ?? record.hashCode.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        _showDeleteConfirmation(record);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showSaleDetails(record),
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
                        '${record.dryCoffeeKg.toStringAsFixed(0)}kg',
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
                        record.farmName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(record.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Icon(
                            Icons.attach_money,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          Text(
                            currencyFormat.format(record.pricePerKg),
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
                      currencyFormat.format(record.total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (!record.isSynced)
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

  void _showSaleDetails(CoffeeRecord record) {
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                        record.farmName.toUpperCase(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    currencyFormat.format(record.total),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              value: dateFormat.format(record.date),
            ),
            _buildDetailItem(
              icon: Icons.scale,
              label: 'Kilos Secos',
              value: '${record.dryCoffeeKg.toStringAsFixed(1)} kg',
            ),
            _buildDetailItem(
              icon: Icons.attach_money,
              label: 'Precio por kilo',
              value: currencyFormat.format(record.pricePerKg),
            ),
            _buildDetailItem(
              icon: Icons.check_circle,
              label: 'Estado',
              value: record.isSynced ? 'Sincronizado' : 'Pendiente',
              valueColor: record.isSynced ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(record);
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(CoffeeRecord record) {
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
                          record.farmName.toUpperCase(),
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
                        '${record.dryCoffeeKg.toStringAsFixed(1)} kg',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                      const Spacer(),
                      Text(
                        currencyFormat.format(record.total),
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
              if (record.firebaseId != null) {
                context.read<RecordsProvider>().deleteRecord(
                  record.firebaseId!,
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

  Widget _buildNoFarmsMessage() {
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
