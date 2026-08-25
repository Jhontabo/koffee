import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/coffee_record.dart';
import '../providers/records_provider.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import 'farms_screen.dart';

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
  final _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedFarm;
  double _calculatedTotal = 0;
  String _searchQuery = '';
  String? _filterFarm;

  final List<double> _suggestedPrices = [10000, 12000, 14000, 16000, 18000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _dryCoffeeKgController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final kilograms = double.tryParse(_dryCoffeeKgController.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    setState(() {
      _calculatedTotal = kilograms * price;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateController.dispose();
    _dryCoffeeKgController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppPalette.espresso,
              onPrimary: Colors.white,
              onSurface: AppPalette.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _setQuickDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dateController.text = DateFormat('dd/MM/yyyy').format(date);
    });
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      if (_selectedFarm == null || _selectedFarm!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una finca')),
        );
        return;
      }

      final dryCoffeeKg = double.parse(_dryCoffeeKgController.text.replaceAll(',', '.'));
      final pricePerKg = double.parse(_priceController.text.replaceAll(',', '.'));
      final total = dryCoffeeKg * pricePerKg;

      final record = CoffeeRecord(
        date: _selectedDate,
        farmName: _selectedFarm!,
        dryCoffeeKg: dryCoffeeKg,
        pricePerKg: pricePerKg,
        total: total,
      );

      context.read<RecordsProvider>().addRecord(record);
      _resetForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppPalette.leaf,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('¡Venta guardada exitosamente!'),
            ],
          ),
        ),
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
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      _selectedFarm = null;
      _calculatedTotal = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
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
        title: const Text(
          'Ventas de Café',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
            ),
            tooltip: 'Exportar Reporte PDF',
            onPressed: () => _showReportBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppPalette.caramel,
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppPalette.espresso,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
              tabs: const [
                Tab(
                  icon: Icon(Icons.add_circle_outline_rounded, size: 18),
                  text: 'Registrar Venta',
                ),
                Tab(
                  icon: Icon(Icons.receipt_long_rounded, size: 18),
                  text: 'Historial',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.background,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFormTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: FORMULARIO DE REGISTRO
  // ==========================================
  Widget _buildFormTab() {
    final farms = context.watch<RecordsProvider>().farms;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    if (farms.isEmpty) {
      return _buildNoFarmsMessage();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: ResponsiveCenter(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Receipt Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppPalette.cardBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C2E1C14),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppPalette.leafLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calculate_rounded,
                                color: AppPalette.leaf,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Cálculo en Vivo',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedFarm != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppPalette.crema,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedFarm!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.espresso,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currencyFormat.format(_calculatedTotal),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.leaf,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _calculatedTotal > 0
                          ? 'Total a recibir por la venta'
                          : 'Ingresa kilos y precio para calcular',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Farm Selector Card
              Container(
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
                      '1. Selecciona la Finca',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFarm,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Finca productora *',
                        prefixIcon: Icon(Icons.landscape_rounded),
                        hintText: 'Elige la finca',
                      ),
                      items: farms.map((f) {
                        return DropdownMenuItem<String>(
                          value: f.name,
                          child: Row(
                            children: [
                              Text(
                                f.name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.textPrimary,
                                ),
                              ),
                              if (f.location != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '(${f.location})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppPalette.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedFarm = val;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Selecciona una finca';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Date Selection Card
              Container(
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
                      '2. Fecha de la Venta',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildDateChip('Hoy', DateTime.now()),
                        const SizedBox(width: 8),
                        _buildDateChip(
                          'Ayer',
                          DateTime.now().subtract(const Duration(days: 1)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.crema,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppPalette.cardBorder),
                            ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 16,
                                    color: AppPalette.espresso,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _dateController.text,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppPalette.espresso,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quantities and Price Card
              Container(
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
                      '3. Kilos y Precio',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _dryCoffeeKgController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Café Seco Vendido *',
                        hintText: 'Ej: 125.5',
                        prefixIcon: Icon(Icons.scale_rounded),
                        suffixText: 'kg',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa los kilos de café';
                        }
                        final val = double.tryParse(value.replaceAll(',', '.'));
                        if (val == null || val <= 0) {
                          return 'Ingresa una cantidad válida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Precio por Kilo *',
                        hintText: 'Ej: 14500',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el precio por kilo';
                        }
                        final val = double.tryParse(value.replaceAll(',', '.'));
                        if (val == null || val <= 0) {
                          return 'Ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Quick Price Chips
                    const Text(
                      'Precios comunes por kilo:',
                      style: TextStyle(fontSize: 11, color: AppPalette.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _suggestedPrices.map((p) {
                        return InkWell(
                          onTap: () {
                            _priceController.text = p.toStringAsFixed(0);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.crema,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppPalette.cardBorder),
                            ),
                            child: Text(
                              currencyFormat.format(p),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.cocoa,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _saveRecord,
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'Guardar Venta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.espresso,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, DateTime date) {
    final isSelected = DateUtils.isSameDay(_selectedDate, date);
    return InkWell(
      onTap: () => _setQuickDate(date),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.espresso : AppPalette.crema,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppPalette.espresso : AppPalette.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppPalette.textPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: HISTORIAL DE VENTAS
  // ==========================================
  Widget _buildHistoryTab() {
    return Consumer<RecordsProvider>(
      builder: (context, provider, child) {
        final allRecords = provider.records;

        if (allRecords.isEmpty) {
          return _buildEmptyHistoryState();
        }

        final filteredRecords = allRecords.where((record) {
          final matchesSearch = _searchQuery.isEmpty ||
              record.farmName.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesFarm = _filterFarm == null ||
              record.farmName.toUpperCase() == _filterFarm!.toUpperCase();
          return matchesSearch && matchesFarm;
        }).toList();

        final totalSales = allRecords.fold<double>(0, (sum, r) => sum + r.total);
        final totalKg = allRecords.fold<double>(0, (sum, r) => sum + r.dryCoffeeKg);
        final avgPrice = totalKg > 0 ? (totalSales / totalKg) : 0.0;

        final currencyFormat = NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
        );

        final farmNames = provider.farmNames;

        return ResponsiveCenter(
          child: Column(
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x202E1C14),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${allRecords.length} ventas registradas',
                          style: const TextStyle(
                            color: Color(0xFFDCC8B9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(totalSales),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${totalKg.toStringAsFixed(1)} kg • Prom: ${currencyFormat.format(avgPrice)}/kg',
                          style: const TextStyle(
                            color: Color(0xFFE4D5C9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showReportBottomSheet(context),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('Reporte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.caramel,
                        foregroundColor: AppPalette.espresso,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppPalette.cardBorder),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar por finca...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppPalette.cocoa,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (farmNames.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppPalette.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _filterFarm,
                            hint: const Text('Finca', style: TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.filter_list_rounded, size: 18),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Todas', style: TextStyle(fontSize: 12)),
                              ),
                              ...farmNames.map(
                                (name) => DropdownMenuItem<String?>(
                                  value: name,
                                  child: Text(
                                    name.toUpperCase(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _filterFarm = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // List of sales
              Expanded(
                child: filteredRecords.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron ventas para esta búsqueda',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppPalette.caramel,
                        backgroundColor: Colors.white,
                        onRefresh: () => provider.loadRecords(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            return _buildSaleCard(record);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
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
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        _showDeleteConfirmation(record);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x082E1C14),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showSaleDetailsModal(record),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppPalette.leafLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.scale_rounded,
                          color: AppPalette.leaf,
                          size: 18,
                        ),
                        Text(
                          '${record.dryCoffeeKg.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                            color: AppPalette.leafDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.farmName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppPalette.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(record.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppPalette.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${currencyFormat.format(record.pricePerKg)}/kg',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppPalette.textSecondary,
                                fontWeight: FontWeight.w500,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppPalette.leaf,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: record.isSynced
                              ? AppPalette.leafLight
                              : AppPalette.caramelLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              record.isSynced
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_off_rounded,
                              size: 10,
                              color: record.isSynced
                                  ? AppPalette.leaf
                                  : AppPalette.caramelDark,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              record.isSynced ? 'Guardado' : 'Pendiente',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: record.isSynced
                                  ? AppPalette.leaf
                                  : AppPalette.caramelDark,
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
      ),
    );
  }

  void _showSaleDetailsModal(CoffeeRecord record) {
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalles de Venta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        Text(
                          record.farmName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(record.total),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.leaf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppPalette.cardBorder),
              const SizedBox(height: 12),
              _buildDetailItem(
                icon: Icons.calendar_today_rounded,
                label: 'Fecha',
                value: dateFormat.format(record.date),
              ),
              _buildDetailItem(
                icon: Icons.scale_rounded,
                label: 'Café Seco Vendido',
                value: '${record.dryCoffeeKg.toStringAsFixed(2)} kg',
              ),
              _buildDetailItem(
                icon: Icons.attach_money_rounded,
                label: 'Precio por kilo',
                value: currencyFormat.format(record.pricePerKg),
              ),
              _buildDetailItem(
                icon: Icons.cloud_done_rounded,
                label: 'Estado de Sincronización',
                value: record.isSynced ? 'Sincronizado' : 'Pendiente',
                valueColor: record.isSynced ? AppPalette.leaf : AppPalette.caramelDark,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDeleteConfirmation(record);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      label: const Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await PdfService.generateReport(
                          title: 'Comprobante de Venta - ${record.farmName}',
                          records: [record],
                          startDate: record.date,
                          endDate: record.date,
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Exportar PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.espresso,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
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
          Icon(icon, size: 18, color: AppPalette.cocoa),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppPalette.textPrimary,
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
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Eliminar Venta',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que deseas eliminar este registro de venta?',
              style: TextStyle(color: AppPalette.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.crema,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.farmName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                      Text(
                        '${record.dryCoffeeKg.toStringAsFixed(1)} kg café seco',
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormat.format(record.total),
                    style: const TextStyle(
                      color: AppPalette.leaf,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Venta eliminada del registro')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showReportBottomSheet(BuildContext context) {
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
                    'Generar Reporte PDF',
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
                'Descarga o comparte tus ventas en formato PDF profesional.',
                style: TextStyle(color: AppPalette.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _buildReportOptionTile(
                icon: Icons.calendar_view_week_rounded,
                title: 'Esta Semana',
                subtitle: 'Últimos 7 días',
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
              const SizedBox(height: 10),
              _buildReportOptionTile(
                icon: Icons.calendar_month_rounded,
                title: 'Este Mes',
                subtitle: DateFormat('MMMM yyyy', 'es').format(DateTime.now()).toUpperCase(),
                onTap: () {
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  _generateReport(
                    startOfMonth,
                    now,
                    'Reporte Mensual (${DateFormat('MMMM yyyy', 'es').format(now)})',
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildReportOptionTile(
                icon: Icons.history_rounded,
                title: 'Todo el Historial',
                subtitle: 'Desde el primer registro',
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
        ),
      ),
    );
  }

  Widget _buildReportOptionTile({
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
                    style: const TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 12,
                    ),
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

  Widget _buildNoFarmsMessage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPalette.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppPalette.crema,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.landscape_rounded,
                  size: 54,
                  color: AppPalette.caramel,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No hay fincas registradas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Para registrar ventas, primero debes agregar al menos una finca a tu cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FarmsScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ir a Crear Finca'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppPalette.crema,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 54,
                color: AppPalette.caramel,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay ventas registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Comienza registrando tu primera venta de café.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _tabController.index = 0;
                });
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar Venta'),
            ),
          ],
        ),
      ),
    );
  }
}
