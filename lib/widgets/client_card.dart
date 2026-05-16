import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_model.dart';
import '../services/client_service.dart';
import 'admin_action_button.dart';
import 'update_client_dialog.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.client,
  });

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE7E8E9),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFC1ECD4),
            child: Icon(
              Icons.person_outline,
              color: Color(0xFF012D1D),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: const Color(0xFF012D1D),
                        fontWeight: FontWeight.w800,
                      ),
                ),

                const SizedBox(height: 4),

                Text(
                  client.email,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),

                const SizedBox(height: 4),

                Text(
                  client.favoriteActivity,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                        color: const Color(0xFF4EAC7F),
                      ),
                ),
              ],
            ),
          ),

          AdminActionButton(
            icon: Icons.edit_outlined,
            color: const Color(0xFF8D5B5B),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => UpdateClientDialog(
                  client: client,
                ),
              );
            },
          ),

          const SizedBox(width: 10),

          AdminActionButton(
            icon: Icons.delete_outline,
            color: Colors.redAccent,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: const Text('Eliminar cliente'),
                    content: Text(
                      '¿Deseas eliminar a ${client.name}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Cancelar'),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await context
                    .read<ClientService>()
                    .deleteClient(client.uid);
              }
            },
          ),
        ],
      ),
    );
  }
}