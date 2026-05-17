import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../admin/admin_action_button.dart';
import 'client_details_dialog.dart';
import 'update_client_dialog.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _cardSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF132F25) : Colors.white;

Color _cardBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

Color _cardTitleColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFE8F5E9) : const Color(0xFF012D1D);

Color _activityColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF75DAA8) : const Color(0xFF4EAC7F);

class ClientCard extends StatelessWidget {
  const ClientCard({super.key, required this.client});

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _isDarkMode(context)
                ? const Color(0xFF17352A)
                : const Color(0xFFC1ECD4),
            child: Icon(
              Icons.person_outline,
              color: _isDarkMode(context)
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFF012D1D),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _cardTitleColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  client.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 4),

                Text(
                  client.favoriteActivity,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _activityColor(context),
                  ),
                ),
              ],
            ),
          ),

          AdminActionButton(
            icon: Icons.visibility_outlined,
            color: _isDarkMode(context)
                ? const Color(0xFF75DAA8)
                : const Color(0xFF2C694E),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ClientDetailsDialog(client: client),
              );
            },
          ),

          const SizedBox(width: 10),

          AdminActionButton(
            icon: Icons.edit_outlined,
            color: const Color(0xFF8D5B5B),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => UpdateClientDialog(client: client),
              );
            },
          ),

          const SizedBox(width: 10),

          AdminActionButton(
            icon: Icons.delete_outline,
            color: Colors.redAccent,
            onPressed: () async {
              final clientService = context.read<ClientService>();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: const Text('Eliminar cliente'),
                    content: Text('¿Deseas eliminar a ${client.name}?'),
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
                await clientService.deleteClient(client.uid);
              }
            },
          ),
        ],
      ),
    );
  }
}
