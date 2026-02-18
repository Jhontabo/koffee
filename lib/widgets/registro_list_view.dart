import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/registro_finca.dart';
import '../providers/registro_provider.dart';

class RegistroListView extends StatelessWidget {
  const RegistroListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RegistroProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.registros.isEmpty) {
          return const Center(
            child: Text('No hay registros aún'),
          );
        }

        return ListView.builder(
          itemCount: provider.registros.length,
          itemBuilder: (context, index) {
            final registro = provider.registros[index];
            return _RegistroCard(registro: registro);
          },
        );
      },
    );
  }
}

class _RegistroCard extends StatelessWidget {
  final RegistroFinca registro;

  const _RegistroCard({required this.registro});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              registro.isSynced ? Colors.green : Colors.orange,
          child: Icon(
            registro.isSynced ? Icons.cloud_done : Icons.cloud_off,
            color: Colors.white,
          ),
        ),
        title: Text(
          registro.finca,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha: ${dateFormat.format(registro.fecha)}'),
            Text('Kilos: ${registro.kilosSeco.toStringAsFixed(2)}'),
            Text('Valor: ${currencyFormat.format(registro.valorUnitario)}'),
            Text(
              'Total: ${currencyFormat.format(registro.total)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteDialog(context),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: const Text('¿Está seguro de eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<RegistroProvider>().deleteRegistro(registro.id!);
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
