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
  String _groupBy = 'day';

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

        final grouped = _groupRegistros(provider.registros);

        return Column(
          children: [
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
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');

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
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.circle, color: Colors.red.shade700),
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
                        Text(
                          '${registro.kilosRojo} kg',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
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
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Café Rojo',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(registro.fecha),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
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
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _showDeleteConfirmation(context),
                tooltip: 'Eliminar',
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSummaryDialog(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Detalles'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Finca', registro.finca.toUpperCase()),
              _detailRow('Fecha', dateFormat.format(registro.fecha)),
              _detailRow('Kilos', '${registro.kilosRojo} kg'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Eliminar Registro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro de eliminar este registro?',
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          registro.finca.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.scale, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${registro.kilosRojo} kg',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Esta acción no se puede deshacer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
              if (registro.firebaseId != null) {
                context.read<RegistroProvider>().deleteRegistro(
                  registro.firebaseId!,
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
