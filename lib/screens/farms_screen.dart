import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/farm.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsProvider>().loadFarms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4EEE7), Color(0xFFF1E8DF)],
          ),
        ),
        child: Consumer<RecordsProvider>(
          builder: (context, provider, child) {
            final farms = provider.farms;

            if (farms.isEmpty) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(22),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.landscape_outlined,
                        size: 62,
                        color: Colors.brown.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No tienes fincas registradas',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Agrega tu primera finca para empezar',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: farms.length,
              itemBuilder: (context, index) {
                final farm = farms[index];
                return _FarmCard(
                  farm: farm,
                  onEdit: () => _showFarmDialog(context, farm: farm),
                  onDelete: () => _showDeleteDialog(context, farm),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFarmDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Farm'),
        backgroundColor: AppPalette.espresso,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showFarmDialog(BuildContext context, {Farm? farm}) {
    showDialog(
      context: context,
      builder: (ctx) => _FarmFormDialog(
        farm: farm,
        onSave: (newFarm) {
          final provider = context.read<RecordsProvider>();
          if (farm != null && farm.id != null) {
            provider.updateFarm(newFarm.copyWith(id: farm.id));
          } else {
            provider.addFarm(newFarm);
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Farm farm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Farm'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la finca "${farm.name}"?\n\n'
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
              context.read<RecordsProvider>().removeFarm(farm);
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

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FarmCard({
    required this.farm,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppPalette.caramel.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.landscape, color: AppPalette.espresso),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (farm.location != null && farm.location!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              farm.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (farm.hectares != null)
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${farm.hectares} ha',
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

class _FarmFormDialog extends StatefulWidget {
  final Farm? farm;
  final Function(Farm) onSave;

  const _FarmFormDialog({this.farm, required this.onSave});

  @override
  State<_FarmFormDialog> createState() => _FarmFormDialogState();
}

class _FarmFormDialogState extends State<_FarmFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _hectaresController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.farm?.name ?? '');
    _locationController = TextEditingController(
      text: widget.farm?.location ?? '',
    );
    _hectaresController = TextEditingController(
      text: widget.farm?.hectares?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _hectaresController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final userId = context.read<RecordsProvider>().userId ?? '';

      final farm = Farm(
        id: widget.farm?.id,
        userId: userId,
        name: _nameController.text.trim().toUpperCase(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim().toUpperCase(),
        hectares: _hectaresController.text.trim().isEmpty
            ? null
            : double.tryParse(_hectaresController.text),
        createdAt: widget.farm?.createdAt ?? DateTime.now(),
        isSynced: false,
        firebaseId: widget.farm?.firebaseId,
      );

      widget.onSave(farm);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.farm == null ? 'Agregar Finca' : 'Editar Finca'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
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
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (vereda/municipio)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Vereda El Porvenir, Toledo',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hectaresController,
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
                    final hectaresValue = double.tryParse(value);
                    if (hectaresValue == null || hectaresValue <= 0) {
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
          child: Text(widget.farm == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}
