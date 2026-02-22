import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/registro_finca.dart';
import '../providers/registro_provider.dart';

class RegistroListView extends StatefulWidget {
  const RegistroListView({super.key});

  @override
  State<RegistroListView> createState() => _RegistroListViewState();
}

class _RegistroListViewState extends State<RegistroListView> {
  String _groupBy = 'day'; // 'day', 'month'

  @override
  Widget build(BuildContext context) {
    return Consumer<RegistroProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.registros.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay registros aún'),
              ],
            ),
          );
        }

        // Group records
        final grouped = _groupRegistros(provider.registros);

        return Column(
          children: [
            // Filter Tabs
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'day',
                    label: Text('Día'),
                    icon: Icon(Icons.calendar_view_day),
                  ),
                  ButtonSegment(
                    value: 'month',
                    label: Text('Mes'),
                    icon: Icon(Icons.calendar_view_month),
                  ),
                ],
                selected: {_groupBy},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _groupBy = newSelection.first;
                  });
                },
              ),
            ),
            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: grouped.length,
                itemBuilder: (context, index) {
                  final group = grouped[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(group.key),
                      ...group.items.map((r) => _RegistroCard(registro: r)),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<_GroupedData> _groupRegistros(List<RegistroFinca> registros) {
    if (registros.isEmpty) return [];

    final groups = <String, List<RegistroFinca>>{};

    for (var reg in registros) {
      String key;
      if (_groupBy == 'day') {
        key = DateFormat('EEEE d MMMM, y', 'es').format(reg.fecha);
      } else {
        key = DateFormat('MMMM y', 'es').format(reg.fecha);
      }

      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(reg);
    }

    return groups.entries.map((e) => _GroupedData(e.key, e.value)).toList();
  }

  Widget _buildHeader(String title) {
    // Capitalize first letter
    final capitalized = title[0].toUpperCase() + title.substring(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            capitalized,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const Expanded(child: Divider(indent: 10)),
        ],
      ),
    );
  }
}

class _GroupedData {
  final String key;
  final List<RegistroFinca> items;
  _GroupedData(this.key, this.items);
}

class _RegistroCard extends StatelessWidget {
  final RegistroFinca registro;

  const _RegistroCard({required this.registro});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    final isRojo = registro.kilosRojo > 0;
    final isSeco = registro.kilosSeco > 0;

    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    if (isRojo && !isSeco) {
      typeColor = Colors.red.shade700;
      typeIcon = Icons.circle;
      typeLabel = "Café Rojo";
    } else if (isSeco && !isRojo) {
      typeColor = Colors.brown.shade600;
      typeIcon = Icons.grain;
      typeLabel = "Café Seco";
    } else {
      typeColor = Colors.purple;
      typeIcon = Icons.merge_type;
      typeLabel = "Mixto";
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSummaryDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          registro.finca,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isSeco)
                          Text(
                            currencyFormat.format(registro.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRojo
                              ? '${registro.kilosRojo} kg'
                              : '${registro.kilosSeco} kg',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const Spacer(),
                        if (!registro.isSynced)
                          const Icon(
                            Icons.cloud_off,
                            size: 16,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showEditDialog(context),
                    tooltip: 'Editar',
                    color: Colors.blue,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _showDeleteConfirmation(context),
                    tooltip: 'Eliminar',
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSummaryDialog(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Detalles del Registro'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Finca', registro.finca.toUpperCase()),
              _detailRow('Fecha', dateFormat.format(registro.fecha)),
              if (registro.kilosRojo > 0)
                _detailRow('Kilos Rojo', '${registro.kilosRojo} kg'),
              if (registro.kilosSeco > 0) ...[
                _detailRow('Kilos Seco', '${registro.kilosSeco} kg'),
                _detailRow(
                  'Valor Unitario',
                  currencyFormat.format(registro.valorUnitario),
                ),
                _detailRow('Total', currencyFormat.format(registro.total)),
              ],
              _detailRow('Sincronizado', registro.isSynced ? 'Sí' : 'No'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditRegistroSheet(registro: registro),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Eliminación'),
          ],
        ),
        content: Text(
          '¿Está seguro de eliminar el registro de "${registro.finca}" del ${DateFormat('dd/MM/yyyy', 'es').format(registro.fecha)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (registro.firebaseId != null) {
                final tipo = registro.isRojo ? 'rojo' : 'seco';
                context.read<RegistroProvider>().deleteRegistro(
                  registro.firebaseId!,
                  tipo,
                );
              }
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _EditRegistroSheet extends StatefulWidget {
  final RegistroFinca registro;

  const _EditRegistroSheet({required this.registro});

  @override
  State<_EditRegistroSheet> createState() => _EditRegistroSheetState();
}

class _EditRegistroSheetState extends State<_EditRegistroSheet> {
  late TextEditingController _fincaController;
  late TextEditingController _kilosRojoController;
  late TextEditingController _kilosSecoController;
  late TextEditingController _valorUnitarioController;
  late DateTime _selectedDate;
  final _formKey = GlobalKey<FormState>();

  // Tipo de registro
  late bool isRojo;
  late bool isSeco;
  late bool isMixto;

  @override
  void initState() {
    super.initState();

    // Usar getters del modelo
    isRojo = widget.registro.isRojo;
    isSeco = widget.registro.isSeco;
    isMixto = widget.registro.isMixto;

    _fincaController = TextEditingController(text: widget.registro.finca);
    _kilosRojoController = TextEditingController(
      text: widget.registro.kilosRojo > 0
          ? widget.registro.kilosRojo.toString()
          : '0',
    );
    _kilosSecoController = TextEditingController(
      text: widget.registro.kilosSeco > 0
          ? widget.registro.kilosSeco.toString()
          : '0',
    );
    _valorUnitarioController = TextEditingController(
      text:
          (widget.registro.valorUnitario != null &&
              widget.registro.valorUnitario! > 0)
          ? widget.registro.valorUnitario.toString()
          : '0',
    );
    _selectedDate = widget.registro.fecha;
  }

  @override
  void dispose() {
    _fincaController.dispose();
    _kilosRojoController.dispose();
    _kilosSecoController.dispose();
    _valorUnitarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    isRojo
                        ? 'Editar Café Rojo'
                        : isMixto
                        ? 'Editar Registro Mixto'
                        : 'Editar Café Seco',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fincaController,
                decoration: const InputDecoration(
                  labelText: 'Finca',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese la finca';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd', 'es').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Mostrar campo de kilos rojos si es rojo o mixto
              if (isRojo || isMixto)
                TextFormField(
                  controller: _kilosRojoController,
                  decoration: const InputDecoration(
                    labelText: 'Kilos Rojos',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.circle, color: Colors.red),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese los kilos';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
              // Mostrar campo de kilos secos si es seco o mixto
              if (isSeco || isMixto) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _kilosSecoController,
                  decoration: const InputDecoration(
                    labelText: 'Kilos Secos',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wb_sunny),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese los kilos';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorUnitarioController,
                  decoration: const InputDecoration(
                    labelText: 'Valor Unitario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el valor';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saveChanges,
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final isRojo = widget.registro.kilosRojo > 0;

      double kilosRojo = 0;
      double kilosSeco = 0;
      double valorUnitario = 0;
      double total = 0;

      // Calcular kilos según el tipo
      if (isRojo) {
        kilosRojo = double.tryParse(_kilosRojoController.text) ?? 0;
      } else if (isSeco) {
        kilosSeco = double.tryParse(_kilosSecoController.text) ?? 0;
        valorUnitario = double.tryParse(_valorUnitarioController.text) ?? 0;
        total = kilosSeco * valorUnitario;
      } else if (isMixto) {
        kilosRojo = double.tryParse(_kilosRojoController.text) ?? 0;
        kilosSeco = double.tryParse(_kilosSecoController.text) ?? 0;
        valorUnitario = double.tryParse(_valorUnitarioController.text) ?? 0;
        total = kilosSeco * valorUnitario;
      }

      final updatedRegistro = widget.registro.copyWith(
        fecha: _selectedDate,
        finca: _fincaController.text.trim(),
        kilosRojo: kilosRojo,
        kilosSeco: kilosSeco,
        valorUnitario: valorUnitario,
        total: total,
        isSynced: false,
      );

      context.read<RegistroProvider>().updateRegistro(updatedRegistro);
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro actualizado')));
    }
  }
}
