import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/farm.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsProvider>().loadFarms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          final allFarms = provider.farms;
          final filteredFarms = allFarms.where((farm) {
            final query = _searchQuery.toLowerCase();
            final nameMatch = farm.name.toLowerCase().contains(query);
            final locMatch = farm.location?.toLowerCase().contains(query) ?? false;
            return nameMatch || locMatch;
          }).toList();

          final totalHectares = allFarms.fold<double>(
            0,
            (sum, f) => sum + (f.hectares ?? 0),
          );

          return ResponsiveCenter(
            child: Column(
              children: [
                // Top Search & Stats Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppPalette.cardBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C2E1C14),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o ubicación...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppPalette.cocoa,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
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
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildSummaryChip(
                            icon: Icons.terrain_rounded,
                            label: '${allFarms.length} ${allFarms.length == 1 ? "finca" : "fincas"}',
                            color: AppPalette.espresso,
                          ),
                          const SizedBox(width: 8),
                          if (totalHectares > 0)
                            _buildSummaryChip(
                              icon: Icons.square_foot_rounded,
                              label: '${totalHectares.toStringAsFixed(1)} ha registradas',
                              color: AppPalette.leaf,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Farm List or Empty State
                Expanded(
                  child: allFarms.isEmpty
                      ? _buildEmptyState(context)
                      : filteredFarms.isEmpty
                          ? _buildNoSearchResults()
                          : RefreshIndicator(
                              color: AppPalette.caramel,
                              backgroundColor: Colors.white,
                              onRefresh: () => provider.loadFarms(),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                itemCount: filteredFarms.length,
                                itemBuilder: (context, index) {
                                  final farm = filteredFarms[index];
                                  return _FarmCard(
                                    farm: farm,
                                    recordsProvider: provider,
                                    onEdit: () => _showFarmBottomSheet(context, farm: farm),
                                    onDelete: () => _showDeleteDialog(context, farm),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFarmBottomSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva Finca',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        backgroundColor: AppPalette.espresso,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                'No tienes fincas registradas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Registra tus fincas para asociar ventas y monitorear la producción de cada terreno.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showFarmBottomSheet(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar Primera Finca'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppPalette.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            'No se encontraron fincas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppPalette.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Intenta con otro término de búsqueda.',
            style: TextStyle(fontSize: 13, color: AppPalette.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showFarmBottomSheet(BuildContext context, {Farm? farm}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FarmFormBottomSheet(
        farm: farm,
        onSave: (newFarm) {
          final provider = context.read<RecordsProvider>();
          if (farm != null && farm.firebaseId != null) {
            provider.updateFarm(newFarm.copyWith(firebaseId: farm.firebaseId));
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
                Icons.delete_outline_rounded,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Eliminar Finca',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la finca "${farm.name}"?\n\n'
          'Los registros de ventas previos se mantendrán en el historial.',
          style: const TextStyle(color: AppPalette.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<RecordsProvider>().removeFarm(farm);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Finca "${farm.name}" eliminada')),
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
}

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final RecordsProvider recordsProvider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FarmCard({
    required this.farm,
    required this.recordsProvider,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final farmKg = recordsProvider.kilogramsByFarm[farm.name] ?? 0.0;
    final farmSalesCount = recordsProvider.records
        .where((r) => r.farmName.toUpperCase() == farm.name.toUpperCase())
        .length;

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final farmTotalMoney = recordsProvider.records
        .where((r) => r.farmName.toUpperCase() == farm.name.toUpperCase())
        .fold<double>(0, (sum, r) => sum + r.total);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2E1C14),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          farm.name.isNotEmpty ? farm.name.substring(0, 1) : 'F',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farm.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (farm.location != null && farm.location!.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppPalette.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    farm.location!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppPalette.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (farm.hectares != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.square_foot_rounded,
                                  size: 14,
                                  color: AppPalette.leaf,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${farm.hectares} hectáreas',
                                  style: const TextStyle(
                                    color: AppPalette.leaf,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppPalette.textMuted),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: AppPalette.cocoa),
                              SizedBox(width: 8),
                              Text('Editar Finca'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPalette.crema,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppPalette.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.scale_rounded, size: 15, color: AppPalette.caramelDark),
                          const SizedBox(width: 6),
                          Text(
                            '${farmKg.toStringAsFixed(1)} kg café',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$farmSalesCount ventas (${currencyFormat.format(farmTotalMoney)})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.leaf,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FarmFormBottomSheet extends StatefulWidget {
  final Farm? farm;
  final Function(Farm) onSave;

  const _FarmFormBottomSheet({this.farm, required this.onSave});

  @override
  State<_FarmFormBottomSheet> createState() => _FarmFormBottomSheetState();
}

class _FarmFormBottomSheetState extends State<_FarmFormBottomSheet> {
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
    final isEditing = widget.farm != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppPalette.caramel.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_location_alt_rounded : Icons.add_business_rounded,
                        color: AppPalette.espresso,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Editar Finca' : 'Registrar Nueva Finca',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la finca *',
                    hintText: 'Ej: LA ESPERANZA, EL ROBLE',
                    prefixIcon: Icon(Icons.landscape_rounded),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el nombre de la finca';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación / Vereda / Municipio',
                    hintText: 'Ej: Vereda El Porvenir, Pitalito',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _hectaresController,
                  decoration: const InputDecoration(
                    labelText: 'Tamaño del lote (Hectáreas)',
                    hintText: 'Ej: 4.5',
                    prefixIcon: Icon(Icons.straighten_rounded),
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
                      final val = double.tryParse(value);
                      if (val == null || val <= 0) {
                        return 'Ingrese un número válido mayor a 0';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
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
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(isEditing ? 'Guardar Cambios' : 'Registrar Finca'),
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
}
