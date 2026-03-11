import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/worker.dart';
import '../models/worker_record.dart';
import '../providers/workers_provider.dart';
import '../providers/records_provider.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Cargar datos inmediatamente al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<WorkersProvider>();
    // Si no tiene datos, forzar carga
    if (provider.workers.isEmpty || provider.records.isEmpty) {
      await provider.refresh();
    }
  }

  void _refreshData() {
    final provider = context.read<WorkersProvider>();
    debugPrint('=== REFRESH ===');
    debugPrint('UserID: ${provider.userId}');
    debugPrint('Has user: ${provider.hasUser}');
    debugPrint('Workers antes: ${provider.workers.length}');
    provider.refresh().then((_) {
      debugPrint('Workers después: ${provider.workers.length}');
    });
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
        title: const Text('Jornaleros'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Actualizando...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar PDF',
            onSelected: (value) => _generatePdf(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'semanal',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week, color: Colors.brown),
                    SizedBox(width: 8),
                    Text('Reporte Semanal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'individual',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.brown),
                    SizedBox(width: 8),
                    Text('Por Trabajador'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppPalette.caramel,
            indicatorWeight: 2.8,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Trabajadores'),
              Tab(icon: Icon(Icons.add_box), text: 'Registrar'),
              Tab(icon: Icon(Icons.list), text: 'Registros'),
            ],
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF4EEE7), Color(0xFFF1E8DF)],
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _WorkersTab(),
                  _RegisterKilogramsTab(),
                  _RecordsListTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generatePdf(String reportType) async {
    final provider = context.read<WorkersProvider>();

    if (reportType == 'semanal') {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weeklyRecords = provider.getWeeklyRecords(now);

      if (weeklyRecords.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay registros en esta semana')),
          );
        }
        return;
      }

      try {
        await PdfService.generateWorkerPaymentReport(
          title: 'Reporte de Pago Semanal',
          records: weeklyRecords,
          startDate: weekStart,
          endDate: weekEnd,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error generando PDF: $e')));
        }
      }
    } else if (reportType == 'individual') {
      if (provider.workers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay trabajadores registrados')),
          );
        }
        return;
      }

      final selectedWorkerName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Seleccionar Trabajador'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.workers.length,
              itemBuilder: (context, index) {
                final worker = provider.workers[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(worker.name),
                  subtitle: worker.phone != null ? Text(worker.phone!) : null,
                  onTap: () => Navigator.pop(ctx, worker.name),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (selectedWorkerName != null) {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));

        final records = provider.getRecordsByWorker(
          selectedWorkerName,
          startDate: weekStart,
          endDate: weekEnd,
        );

        if (records.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No hay registros para $selectedWorkerName esta semana',
                ),
              ),
            );
          }
          return;
        }

        try {
          await PdfService.generateWorkerPaymentReport(
            title: 'Reporte de Pago - $selectedWorkerName',
            records: records,
            startDate: weekStart,
            endDate: weekEnd,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error generando PDF: $e')));
          }
        }
      }
    }
  }
}

class _WorkersTab extends StatelessWidget {
  const _WorkersTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkersProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ElevatedButton.icon(
                onPressed: () => _showAddWorkerDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar Trabajador'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            Expanded(
              child: provider.workers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay trabajadores registrados',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          if (provider.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Error: ${provider.error}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              provider.loadWorkers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Recargando...')),
                              );
                            },
                            child: const Text('Recargar'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                      itemCount: provider.workers.length,
                      itemBuilder: (context, index) {
                        final worker = provider.workers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppPalette.caramel.withValues(
                                alpha: 0.25,
                              ),
                              child: Text(
                                worker.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppPalette.espresso,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(worker.name),
                            subtitle: worker.phone != null
                                ? Text(worker.phone!)
                                : const Text('Sin teléfono'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _showEditWorkerDialog(context, worker),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, provider, worker),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showAddWorkerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar Trabajador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
                hintText: 'Ej: Juan Pérez',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Ej: 3001234567',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final provider = context.read<WorkersProvider>();
                final userId = provider.userId;

                if (userId == null) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: usuario no autenticado'),
                    ),
                  );
                  return;
                }

                await provider.addWorker(
                  Worker(
                    userId: userId,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                  ),
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!context.mounted) return;

                if (provider.error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(provider.error!)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trabajador agregado')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditWorkerDialog(BuildContext context, Worker worker) {
    final nameController = TextEditingController(text: worker.name);
    final phoneController = TextEditingController(text: worker.phone ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Trabajador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final provider = context.read<WorkersProvider>();
                provider.updateWorker(
                  worker.copyWith(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trabajador actualizado')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WorkersProvider provider,
    Worker worker,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Trabajador'),
        content: Text('¿Está seguro de eliminar a ${worker.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteWorker(worker);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trabajador eliminado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _RegisterKilogramsTab extends StatefulWidget {
  const _RegisterKilogramsTab();

  @override
  State<_RegisterKilogramsTab> createState() => _RegisterKilogramsTabState();
}

class _RegisterKilogramsTabState extends State<_RegisterKilogramsTab> {
  final _formKey = GlobalKey<FormState>();
  final _kilogramsController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedWorker;
  String? _selectedFarm;

  @override
  void dispose() {
    _kilogramsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workersProvider = context.watch<WorkersProvider>();
    final recordsProvider = context.watch<RecordsProvider>();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedWorker,
            decoration: const InputDecoration(
              labelText: 'Trabajador *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            items: workersProvider.workers.map((t) {
              return DropdownMenuItem(value: t.name, child: Text(t.name));
            }).toList(),
            onChanged: (value) => setState(() => _selectedWorker = value),
            validator: (value) =>
                value == null ? 'Seleccione un trabajador' : null,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedFarm,
            decoration: const InputDecoration(
              labelText: 'Farm *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.landscape),
            ),
            items: recordsProvider.farmNames.map((f) {
              return DropdownMenuItem(value: f, child: Text(f.toUpperCase()));
            }).toList(),
            onChanged: (value) => setState(() => _selectedFarm = value),
            validator: (value) => value == null ? 'Seleccione una finca' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _kilogramsController,
            decoration: const InputDecoration(
              labelText: 'Kilos recolectados *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
              hintText: 'Cantidad de kilogramos',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese los kilogramos';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Ingrese un valor válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Precio por kilo *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
              hintText: 'Valor a pagar por kilo',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el precio';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Ingrese un valor válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.save),
            label: const Text('Guardar Registro'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.brown[900],
              foregroundColor: Colors.white,
            ),
          ),
          if (workersProvider.workers.isEmpty ||
              recordsProvider.farmNames.isEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Información',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (workersProvider.workers.isEmpty)
                      const Text(
                        '• Debe agregar trabajadores en la pestaña "Workers"',
                      ),
                    if (recordsProvider.farmNames.isEmpty)
                      const Text(
                        '• Debe tener fincas registradas en la app principal',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final kilograms = double.parse(_kilogramsController.text);
      final pricePerKg = double.parse(_priceController.text);
      final total = kilograms * pricePerKg;

      final workersProvider = context.read<WorkersProvider>();
      final worker = workersProvider.workers.firstWhere(
        (t) => t.name == _selectedWorker,
      );

      final record = WorkerRecord(
        userId: '',
        workerId: worker.firebaseId ?? '',
        workerName: _selectedWorker!,
        date: _selectedDate,
        kilograms: kilograms,
        pricePerKg: pricePerKg,
        total: total,
        farmName: _selectedFarm!,
      );

      workersProvider.addRecord(record);

      _kilogramsController.clear();
      _priceController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedWorker = null;
        _selectedFarm = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kilos registrados correctamente')),
      );
    }
  }
}

class _RecordsListTab extends StatelessWidget {
  const _RecordsListTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkersProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay registros de kilogramos',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
          itemCount: provider.records.length,
          itemBuilder: (context, index) {
            final record = provider.records[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: record.isPaid ? Colors.green : Colors.orange,
                  child: Icon(
                    record.isPaid ? Icons.check : Icons.pending,
                    color: Colors.white,
                  ),
                ),
                title: Text(record.workerName),
                subtitle: Text(
                  '${record.kilograms.toStringAsFixed(1)} kg - ${DateFormat('dd/MM/yyyy').format(record.date)}\n${record.farmName}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${record.total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[900],
                        fontSize: 16,
                      ),
                    ),
                    if (!record.isPaid)
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        tooltip: 'Marcar como pagado',
                        onPressed: () =>
                            _confirmPayment(context, provider, record),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmPayment(
    BuildContext context,
    WorkersProvider provider,
    WorkerRecord record,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Text(
          '¿Marcar como pagado a ${record.workerName}?\n\n'
          'Kilos: ${record.kilograms.toStringAsFixed(1)}\n'
          'Total: \$${record.total.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.markAsPaid(record);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pago marcado como realizado')),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
