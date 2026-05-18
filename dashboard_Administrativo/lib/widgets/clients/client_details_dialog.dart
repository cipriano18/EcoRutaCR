import 'package:flutter/material.dart';

import '../../models/client_model.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _dialogTileSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF132F25) : Colors.white;

Color _dialogTileLabel(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF9DB4A8) : const Color(0xFF6B7B75);

Color _dialogTileValue(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFE8F5E9) : const Color(0xFF012D1D);

class ClientDetailsDialog extends StatelessWidget {
  const ClientDetailsDialog({super.key, required this.client});

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _isDarkMode(context)
          ? const Color(0xFF0B261D)
          : const Color(0xFFF4F7F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        'Detalle del cliente',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: _dialogTileValue(context),
        ),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: _isDarkMode(context)
                    ? const Color(0xFF17352A)
                    : const Color(0xFFC1ECD4),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 38,
                  color: _dialogTileValue(context),
                ),
              ),
              const SizedBox(height: 18),
              _InfoTile(label: 'Nombre', value: _orFallback(client.name)),
              const SizedBox(height: 12),
              _InfoTile(label: 'Correo', value: _orFallback(client.email)),
              const SizedBox(height: 12),
              _InfoTile(label: 'Dirección', value: _orFallback(client.address)),
              const SizedBox(height: 12),
              _InfoTile(
                label: 'Actividad favorita',
                value: _orFallback(client.favoriteActivity),
              ),
              const SizedBox(height: 12),
              _InfoTile(
                label: 'Rutas completadas',
                value: '${client.completedRoutes}',
              ),
              const SizedBox(height: 12),
              _InfoTile(
                label: 'Kilómetros acumulados',
                value: client.kilometers.toStringAsFixed(1),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  static String _orFallback(String value) {
    if (value.trim().isEmpty) {
      return 'No disponible';
    }
    return value;
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _dialogTileSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isDarkMode(context)
              ? const Color(0xFF1B4332)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _dialogTileLabel(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _dialogTileValue(context),
            ),
          ),
        ],
      ),
    );
  }
}
