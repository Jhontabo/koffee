import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/registro_finca.dart';
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
  final _kilosController = TextEditingController();
  final _valorUnitarioController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _fechaController.dispose();
    _fincaController.dispose();
    _kilosController.dispose();
    _valorUnitarioController.dispose();
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final kilos = double.parse(_kilosController.text);
      final valorUnitario = double.parse(_valorUnitarioController.text);
      final total = kilos * valorUnitario;

      final registro = RegistroFinca(
        fecha: _selectedDate,
        finca: _fincaController.text.trim(),
        kilosSeco: kilos,
        valorUnitario: valorUnitario,
        total: total,
      );

      context.read<RegistroProvider>().addRegistro(registro);
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro guardado')),
      );
    }
  }

  void _clearForm() {
    _fincaController.clear();
    _kilosController.clear();
    _valorUnitarioController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _fechaController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            TextFormField(
              controller: _fincaController,
              decoration: const InputDecoration(
                labelText: 'Finca',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese el nombre de la finca';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kilosController,
              decoration: const InputDecoration(
                labelText: 'Kilos Secos',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese los kilos';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Ingrese un valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorUnitarioController,
              decoration: const InputDecoration(
                labelText: 'Valor Unitario',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el valor unitario';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Ingrese un valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Registro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
