import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/finca.dart';
import '../providers/registro_provider.dart';

class FincasScreen extends StatefulWidget {
  const FincasScreen({super.key});

  @override
  State<FincasScreen> createState() => _FincasScreenState();
}

class _FincasScreenState extends State<FincasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistroProvider>().loadFincas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Fincas'), centerTitle: true),
      body: Consumer<RegistroProvider>(
        builder: (context, provider, child) {
          final fincas = provider.fincasList;

          if (fincas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.landscape, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes fincas registradas',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega tu primera finca',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fincas.length,
            itemBuilder: (context, index) {
              final fibra = fincas[index];
              return _FincaCard(
                fibra: fibra,
                onEdit: () => _showFincaDialog(context, fibra: fibra),
                onDelete: () => _showDeleteDialog(context, fibra),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFincaDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Finca'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showFincaDialog(BuildContext context, {Finca? fibra}) {
    showDialog(
      context: context,
      builder: (ctx) => _FincaFormDialog(
        fibra: fibra,
        onSave: (nuevaFinca) {
          final provider = context.read<RegistroProvider>();
          if (fibra != null && fibra.id != null) {
            provider.updateFinca(nuevaFinca.copyWith(id: fibra.id));
          } else {
            provider.addFinca(nuevaFinca);
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Finca fibra) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Finca'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la finca "${fibra.nombre}"?\n\n'
          'Los registros asociados no se eliminarán, pero deberá seleccionar '
          'otra finca para ellos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<RegistroProvider>().removeFinca(fibra);
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

class _FincaCard extends StatelessWidget {
  final Finca fibra;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FincaCard({
    required this.fibra,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.landscape,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fibra.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (fibra.ubicacion != null && fibra.ubicacion!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fibra.ubicacion!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    if (fibra.tamanoHectareas != null)
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${fibra.tamanoHectareas} ha',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[400],
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FincaFormDialog extends StatefulWidget {
  final Finca? fibra;
  final Function(Finca) onSave;

  const _FincaFormDialog({this.fibra, required this.onSave});

  @override
  State<_FincaFormDialog> createState() => _FincaFormDialogState();
}

class _FincaFormDialogState extends State<_FincaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _ubicacionController;
  late TextEditingController _tamanoController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.fibra?.nombre ?? '');
    _ubicacionController = TextEditingController(
      text: widget.fibra?.ubicacion ?? '',
    );
    _tamanoController = TextEditingController(
      text: widget.fibra?.tamanoHectareas?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    _tamanoController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final userId = context.read<RegistroProvider>().userId ?? '';

      final fibra = Finca(
        id: widget.fibra?.id,
        userId: userId,
        nombre: _nombreController.text.trim().toUpperCase(),
        ubicacion: _ubicacionController.text.trim().isEmpty
            ? null
            : _ubicacionController.text.trim().toUpperCase(),
        tamanoHectareas: _tamanoController.text.trim().isEmpty
            ? null
            : double.tryParse(_tamanoController.text),
        fechaCreacion: widget.fibra?.fechaCreacion ?? DateTime.now(),
        isSynced: false,
        firebaseId: widget.fibra?.firebaseId,
      );

      widget.onSave(fibra);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.fibra == null ? 'Agregar Finca' : 'Editar Finca'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la finca *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: LA ESPERANZA',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (vereda/municipio)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Vereda El Porvenir, Toledo',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tamanoController,
                decoration: const InputDecoration(
                  labelText: 'Tamaño (hectáreas)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 5.5',
                  suffixText: 'ha',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final tamano = double.tryParse(value);
                    if (tamano == null || tamano <= 0) {
                      return 'Ingrese un valor válido';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.fibra == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}
