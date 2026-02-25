import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/registro_finca.dart';
import '../models/finca.dart';
import '../providers/registro_provider.dart';

class RegistroForm extends StatefulWidget {
  const RegistroForm({super.key});

  @override
  State<RegistroForm> createState() => _RegistroFormState();
}

class _RegistroFormState extends State<RegistroForm> {
  final _formKey = GlobalKey<FormState>();
  final _fechaController = TextEditingController();
  final _fincaController = TextEditingController();
  final _kilosSecoController = TextEditingController();
  final _precioController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<String> _fincasList = [];
  String? _lastUserId;
  double _totalCalculado = 0;

  @override
  void initState() {
    super.initState();
    _kilosSecoController.addListener(_calcularTotal);
    _precioController.addListener(_calcularTotal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
    });
  }

  void _calcularTotal() {
    final kilos = double.tryParse(_kilosSecoController.text) ?? 0;
    final precio = double.tryParse(_precioController.text) ?? 0;
    setState(() {
      _totalCalculado = kilos * precio;
    });
  }

  void _loadPreferences() {
    final provider = context.read<RegistroProvider>();
    final userId = provider.userId ?? '';
    final uniqueFincas = provider.fincas.toSet().toList()..sort();

    if (_lastUserId != userId) {
      _lastUserId = userId;
      setState(() {
        _fincasList = uniqueFincas;
        _fincaController.clear();
        _fechaController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    } else {
      if (_fincasList.toSet().difference(uniqueFincas.toSet()).isNotEmpty ||
          uniqueFincas.toSet().difference(_fincasList.toSet()).isNotEmpty) {
        setState(() {
          _fincasList = uniqueFincas;
          _fincaController.clear();
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPreferences();
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _fincaController.dispose();
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
        fibra: _fincaController.text.trim(),
        kilosSeco: kilosSeco,
        precioKilo: precioKilo,
        total: total,
      );

      context.read<RegistroProvider>().addRegistro(registro);
      _clearForm();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Venta registrada')));
    }
  }

  void _clearForm() {
    _kilosSecoController.clear();
    _precioController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _fechaController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _totalCalculado = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RegistroProvider>(
      builder: (context, provider, child) {
        final uniqueFincas = provider.fincas.toSet().toList()..sort();
        if (_fincasList.toSet().difference(uniqueFincas.toSet()).isNotEmpty ||
            uniqueFincas.toSet().difference(_fincasList.toSet()).isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _fincasList = uniqueFincas;
              });
            }
          });
        }

        if (uniqueFincas.isEmpty) {
          return _buildNoFincasMessage(context);
        }

        return _buildForm();
      },
    );
  }

  Widget _buildNoFincasMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.landscape, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay fincas registradas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Para registrar cosechas, primero debes agregar una finca',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddFincaDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Finca'),
              style: ElevatedButton.styleFrom(
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

  Widget _buildForm() {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Café Seco - Venta',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _fechaController,
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleccione una fecha';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFincaField(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kilosSecoController,
              decoration: const InputDecoration(
                labelText: 'Kilos de café seco',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale, color: Colors.brown),
                hintText: 'Cantidad de kilos',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese los kilos';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Ingrese un valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio por kilo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Valor por kilo',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el precio';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Ingrese un valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currencyFormat.format(_totalCalculado),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Venta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFincaField() {
    final controllerValue = _fincaController.text;
    final selected =
        controllerValue.isEmpty || !_fincasList.contains(controllerValue)
        ? null
        : controllerValue;
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: const InputDecoration(
        labelText: 'Finca',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.home),
      ),
      isExpanded: true,
      hint: const Text('Seleccionar o agregar finca'),
      items: _fincasList.map((f) {
        return DropdownMenuItem<String>(value: f, child: Text(f.toUpperCase()));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          if (!_fincasList.contains(value)) {
            setState(() {
              _fincasList.add(value);
              _fincasList.sort();
            });
          }
          _fincaController.text = value;
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Seleccione una finca';
        }
        return null;
      },
    );
  }

  void _showAddFincaDialog(BuildContext ctx) {
    final nombreController = TextEditingController();
    final ubicacionController = TextEditingController();
    final tamanoController = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar Finca'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la finca *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: LA ESPERANZA',
                ),
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (vereda/municipio)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Vereda El Porvenir',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tamanoController,
                decoration: const InputDecoration(
                  labelText: 'Tamaño (hectáreas)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 5.5',
                  suffixText: 'ha',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.trim().isNotEmpty) {
                final userId = context.read<RegistroProvider>().userId ?? '';
                final nuevaFinca = Finca(
                  userId: userId,
                  nombre: nombreController.text.trim().toUpperCase(),
                  ubicacion: ubicacionController.text.trim().isEmpty
                      ? null
                      : ubicacionController.text.trim().toUpperCase(),
                  tamanoHectareas: tamanoController.text.trim().isEmpty
                      ? null
                      : double.tryParse(tamanoController.text),
                );
                context.read<RegistroProvider>().addFinca(nuevaFinca);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Finca agregada correctamente')),
                );
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
