import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/client_model.dart';
import '../../services/client_service.dart';
import 'client_card.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _moduleSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF0B261D) : Colors.white;

Color _moduleBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

class ClientListModule extends StatelessWidget {
  const ClientListModule({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClientModel>>(
      stream: context.read<ClientService>().getClients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final clients = snapshot.data ?? [];

        if (clients.isEmpty) {
          return const Center(child: Text('No hay clientes registrados'));
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _moduleSurface(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _moduleBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lista de clientes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 8),

              Text(
                'Clientes registrados en EcoRutaCR.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 22),

              ...clients.map(
                (client) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClientCard(client: client),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
