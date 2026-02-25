import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/trabajador.dart';
import '../models/registro_recolector.dart';
import '../providers/jornaleros_provider.dart';
import '../providers/registro_provider.dart';
import '../services/pdf_service.dart';

class JornalerosScreen extends StatefulWidget {
  const JornalerosScreen({super.key});

  @override
  State<JornalerosScreen> createState() => _JornalerosScreenState();
}

class _JornalerosScreenState extends State<JornalerosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final provider = context.read<JornalerosProvider>();
    debugPrint('=== REFRESH ===');
    debugPrint('UserID: ${provider.userId}');
    debugPrint('Has user: ${provider.hasUser}');
    debugPrint('Trabajadores antes: ${provider.trabajadores.length}');
    provider.refresh().then((_) {
      debugPrint('Trabajadores después: ${provider.trabajadores.length}');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar PDF',
            onSelected: (value) => _generarPdf(value),
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
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Trabajadores'),
              Tab(icon: Icon(Icons.add_box), text: 'Registrar'),
              Tab(icon: Icon(Icons.list), text: 'Registros'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TrabajadoresTab(),
                _RegistrarKilosTab(),
                _ListaRegistrosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _generarPdf(String tipo) async {
    final provider = context.read<JornalerosProvider>();

    if (tipo == 'semanal') {
      final now = DateTime.now();
      final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
      final finSemana = inicioSemana.add(const Duration(days: 6));

      final registrosSemana = provider.getRegistrosSemana(now);

      if (registrosSemana.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay registros en esta semana')),
          );
        }
        return;
      }

      try {
        await PdfService.generatePagoReport(
          title: 'Reporte de Pago Semanal',
          registros: registrosSemana,
          startDate: inicioSemana,
          endDate: finSemana,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error generando PDF: $e')));
        }
      }
    } else if (tipo == 'individual') {
      if (provider.trabajadores.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay trabajadores registrados')),
          );
        }
        return;
      }

      final nombreSeleccionado = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Seleccionar Trabajador'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.trabajadores.length,
              itemBuilder: (context, index) {
                final trabajador = provider.trabajadores[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(trabajador.nombre),
                  subtitle: trabajador.telefono != null
                      ? Text(trabajador.telefono!)
                      : null,
                  onTap: () => Navigator.pop(ctx, trabajador.nombre),
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

      if (nombreSeleccionado != null) {
        final now = DateTime.now();
        final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
        final finSemana = inicioSemana.add(const Duration(days: 6));

        final registros = provider.getRegistrosPorTrabajador(
          nombreSeleccionado,
          fechaInicio: inicioSemana,
          fechaFin: finSemana,
        );

        if (registros.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No hay registros para $nombreSeleccionado esta semana',
                ),
              ),
            );
          }
          return;
        }

        try {
          await PdfService.generatePagoReport(
            title: 'Reporte de Pago - $nombreSeleccionado',
            registros: registros,
            startDate: inicioSemana,
            endDate: finSemana,
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

class _TrabajadoresTab extends StatelessWidget {
  const _TrabajadoresTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<JornalerosProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showAgregarTrabajadorDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar Trabajador'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            Expanded(
              child: provider.trabajadores.isEmpty
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
                          const SizedBox(height: 8),
                          if (provider.userId == null)
                            const Text(
                              '⚠️ Usuario no autenticado',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            )
                          else
                            Text(
                              'UserID: ${provider.userId?.substring(0, 8)}...',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
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
                              provider.loadTrabajadores();
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
                      itemCount: provider.trabajadores.length,
                      itemBuilder: (context, index) {
                        final trabajador = provider.trabajadores[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(trabajador.nombre[0]),
                          ),
                          title: Text(trabajador.nombre),
                          subtitle: trabajador.telefono != null
                              ? Text(trabajador.telefono!)
                              : const Text('Sin teléfono'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditarTrabajadorDialog(
                                  context,
                                  trabajador,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmarEliminar(
                                  context,
                                  provider,
                                  trabajador,
                                ),
                              ),
                            ],
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

  void _showAgregarTrabajadorDialog(BuildContext context) {
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar Trabajador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
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
              controller: telefonoController,
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
              if (nombreController.text.trim().isNotEmpty) {
                final provider = context.read<JornalerosProvider>();
                final userId = provider.userId;

                if (userId == null) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Usuario no autenticado'),
                    ),
                  );
                  return;
                }

                await provider.addTrabajador(
                  Trabajador(
                    userId: userId,
                    nombre: nombreController.text.trim(),
                    telefono: telefonoController.text.trim().isEmpty
                        ? null
                        : telefonoController.text.trim(),
                  ),
                );

                Navigator.pop(dialogContext);

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
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditarTrabajadorDialog(
    BuildContext context,
    Trabajador trabajador,
  ) {
    final nombreController = TextEditingController(text: trabajador.nombre);
    final telefonoController = TextEditingController(
      text: trabajador.telefono ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Trabajador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefonoController,
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
              if (nombreController.text.trim().isNotEmpty) {
                final provider = context.read<JornalerosProvider>();
                provider.updateTrabajador(
                  trabajador.copyWith(
                    nombre: nombreController.text.trim(),
                    telefono: telefonoController.text.trim().isEmpty
                        ? null
                        : telefonoController.text.trim(),
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

  void _confirmarEliminar(
    BuildContext context,
    JornalerosProvider provider,
    Trabajador trabajador,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Trabajador'),
        content: Text('¿Está seguro de eliminar a ${trabajador.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteTrabajador(trabajador);
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

class _RegistrarKilosTab extends StatefulWidget {
  const _RegistrarKilosTab();

  @override
  State<_RegistrarKilosTab> createState() => _RegistrarKilosTabState();
}

class _RegistrarKilosTabState extends State<_RegistrarKilosTab> {
  final _formKey = GlobalKey<FormState>();
  final _kilosController = TextEditingController();
  final _precioController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _trabajadorSeleccionado;
  String? _fincaSeleccionada;

  @override
  void dispose() {
    _kilosController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jurnaleroProvider = context.watch<JornalerosProvider>();
    final registroProvider = context.watch<RegistroProvider>();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _trabajadorSeleccionado,
            decoration: const InputDecoration(
              labelText: 'Trabajador *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            items: jurnaleroProvider.trabajadores.map((t) {
              return DropdownMenuItem(value: t.nombre, child: Text(t.nombre));
            }).toList(),
            onChanged: (value) =>
                setState(() => _trabajadorSeleccionado = value),
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
            value: _fincaSeleccionada,
            decoration: const InputDecoration(
              labelText: 'Finca *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.landscape),
            ),
            items: registroProvider.fincas.map((f) {
              return DropdownMenuItem(value: f, child: Text(f.toUpperCase()));
            }).toList(),
            onChanged: (value) => setState(() => _fincaSeleccionada = value),
            validator: (value) => value == null ? 'Seleccione una finca' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _kilosController,
            decoration: const InputDecoration(
              labelText: 'Kilos recolectados *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
              hintText: 'Cantidad de kilos',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingrese los kilos';
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Ingrese un valor válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _precioController,
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
              if (value == null || value.isEmpty) return 'Ingrese el precio';
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
          if (jurnaleroProvider.trabajadores.isEmpty ||
              registroProvider.fincas.isEmpty) ...[
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
                    if (jurnaleroProvider.trabajadores.isEmpty)
                      const Text(
                        '• Debe agregar trabajadores en la pestaña "Trabajadores"',
                      ),
                    if (registroProvider.fincas.isEmpty)
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
      final kilos = double.parse(_kilosController.text);
      final precioKilo = double.parse(_precioController.text);
      final total = kilos * precioKilo;

      final jurnaleroProvider = context.read<JornalerosProvider>();
      final trabajador = jurnaleroProvider.trabajadores.firstWhere(
        (t) => t.nombre == _trabajadorSeleccionado,
      );

      final registro = RegistroRecolector(
        userId: '',
        trabajadorId: trabajador.id ?? 0,
        nombreTrabajador: _trabajadorSeleccionado!,
        fecha: _selectedDate,
        kilos: kilos,
        precioKilo: precioKilo,
        total: total,
        fibra: _fincaSeleccionada!,
      );

      jurnaleroProvider.addRegistro(registro);

      _kilosController.clear();
      _precioController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _trabajadorSeleccionado = null;
        _fincaSeleccionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kilos registrados correctamente')),
      );
    }
  }
}

class _ListaRegistrosTab extends StatelessWidget {
  const _ListaRegistrosTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<JornalerosProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.registros.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay registros de kilos',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.registros.length,
          itemBuilder: (context, index) {
            final registro = provider.registros[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: registro.estaPagado
                      ? Colors.green
                      : Colors.orange,
                  child: Icon(
                    registro.estaPagado ? Icons.check : Icons.pending,
                    color: Colors.white,
                  ),
                ),
                title: Text(registro.nombreTrabajador),
                subtitle: Text(
                  '${registro.kilos.toStringAsFixed(1)} kg - ${DateFormat('dd/MM/yyyy').format(registro.fecha)}\n${registro.fibra}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${registro.total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[900],
                        fontSize: 16,
                      ),
                    ),
                    if (!registro.estaPagado)
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        tooltip: 'Marcar como pagado',
                        onPressed: () =>
                            _confirmarPago(context, provider, registro),
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

  void _confirmarPago(
    BuildContext context,
    JornalerosProvider provider,
    RegistroRecolector registro,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Text(
          '¿Marcar como pagado a ${registro.nombreTrabajador}?\n\n'
          'Kilos: ${registro.kilos.toStringAsFixed(1)}\n'
          'Total: \$${registro.total.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.marcarComoPagado(registro);
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
