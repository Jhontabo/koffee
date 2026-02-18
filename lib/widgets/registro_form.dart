import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/registro_finca.dart';
import '../providers/registro_provider.dart';
import '../services/preferences_service.dart';

class RegistroForm extends StatefulWidget {
  const RegistroForm({super.key});

  @override
  State<RegistroForm> createState() => _RegistroFormState();
}

class _RegistroFormState extends State<RegistroForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyRojo = GlobalKey<FormState>();
  final _formKeySeco = GlobalKey<FormState>();

  final _fechaRojoController = TextEditingController();
  final _fincaRojoController = TextEditingController();
  final _kilosRojoController = TextEditingController();

  final _fechaSecoController = TextEditingController();
  final _fincaSecoController = TextEditingController();
  final _kilosSecoController = TextEditingController();
  final _valorUnitarioController = TextEditingController();

  DateTime _selectedDateRojo = DateTime.now();
  DateTime _selectedDateSeco = DateTime.now();
  List<String> _fincasList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final fincas = PreferencesService.instance.getFincas();
    setState(() {
      _fincasList = fincas;
      _fechaRojoController.text =
          DateFormat('yyyy-MM-dd').format(_selectedDateRojo);
      _fechaSecoController.text =
          DateFormat('yyyy-MM-dd').format(_selectedDateSeco);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fechaRojoController.dispose();
    _fincaRojoController.dispose();
    _kilosRojoController.dispose();
    _fechaSecoController.dispose();
    _fincaSecoController.dispose();
    _kilosSecoController.dispose();
    _valorUnitarioController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRojo(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateRojo,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRojo = picked;
        _fechaRojoController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectDateSeco(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateSeco,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateSeco = picked;
        _fechaSecoController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submitRojo() {
    if (_formKeyRojo.currentState!.validate()) {
      final kilosRojo = double.parse(_kilosRojoController.text);

      final registro = RegistroFinca(
        fecha: _selectedDateRojo,
        finca: _fincaRojoController.text.trim(),
        kilosRojo: kilosRojo,
        kilosSeco: 0,
        valorUnitario: 0,
        total: 0,
      );

      PreferencesService.instance.addFinca(_fincaRojoController.text.trim());

      context.read<RegistroProvider>().addRegistro(registro);
      _clearFormRojo();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kilos rojos registrados')),
      );
    }
  }

  void _submitSeco() {
    if (_formKeySeco.currentState!.validate()) {
      final kilosSeco = double.parse(_kilosSecoController.text);
      final valorUnitario = double.parse(_valorUnitarioController.text);
      final total = kilosSeco * valorUnitario;

      final registro = RegistroFinca(
        fecha: _selectedDateSeco,
        finca: _fincaSecoController.text.trim(),
        kilosRojo: 0,
        kilosSeco: kilosSeco,
        valorUnitario: valorUnitario,
        total: total,
      );

      PreferencesService.instance.addFinca(_fincaSecoController.text.trim());

      context.read<RegistroProvider>().addRegistro(registro);
      _clearFormSeco();
      _loadPreferences();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kilos secos registrados')),
      );
    }
  }

  void _clearFormRojo() {
    _kilosRojoController.clear();
    setState(() {
      _selectedDateRojo = DateTime.now();
      _fechaRojoController.text =
          DateFormat('yyyy-MM-dd').format(_selectedDateRojo);
    });
  }

  void _clearFormSeco() {
    _fincaSecoController.clear();
    _kilosSecoController.clear();
    setState(() {
      _selectedDateSeco = DateTime.now();
      _fechaSecoController.text =
          DateFormat('yyyy-MM-dd').format(_selectedDateSeco);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'ROJO'),
            Tab(text: 'SECO'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRojoForm(),
              _buildSecoForm(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRojoForm() {
    return Form(
      key: _formKeyRojo,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Café Rojo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fechaRojoController,
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDateRojo(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleccione una fecha';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _fincasList;
                }
                return _fincasList.where((finca) => finca
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _fincaRojoController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                _fincaRojoController.text = controller.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Finca',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.home),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddFincaDialog(isRojo: true),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el nombre de la finca';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _fincaRojoController.text = value;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kilosRojoController,
              decoration: const InputDecoration(
                labelText: 'Kilos Rojos',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale, color: Colors.red),
                hintText: 'Cantidad de kilos de café rojo',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitRojo,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Rojo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecoForm() {
    return Form(
      key: _formKeySeco,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Café Seco',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fechaSecoController,
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDateSeco(context),
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
                labelText: 'Kilos Secos',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
                hintText: 'Cantidad de kilos de café seco',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
              controller: _valorUnitarioController,
              decoration: const InputDecoration(
                labelText: 'Valor por Kilo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Precio por kilo (min 1000 COP)',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el valor por kilo';
                }
                final valor = double.tryParse(value);
                if (valor == null || valor < 1000) {
                  return 'El valor mínimo es 1000 COP';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitSeco,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Seco'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFincaField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _fincasList;
        }
        return _fincasList.where((finca) =>
            finca.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        _fincaSecoController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        _fincaSecoController.text = controller.text;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Finca',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.home),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddFincaDialog(),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingrese el nombre de la finca';
            }
            return null;
          },
          onChanged: (value) {
            _fincaSecoController.text = value;
          },
        );
      },
    );
  }

  void _showAddFincaDialog({bool isRojo = false}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Finca'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre de la finca',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                PreferencesService.instance.addFinca(controller.text.trim());
                setState(() {
                  _fincasList = PreferencesService.instance.getFincas();
                  if (isRojo) {
                    _fincaRojoController.text = controller.text.trim();
                  } else {
                    _fincaSecoController.text = controller.text.trim();
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
