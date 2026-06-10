import 'package:flutter/material.dart';

const _kPrimaryColor = Color(0xFF012D1D);
const _kOrangeColor = Color(0xFFFF7043);

enum StartRouteAction { live, savedRoutes }

/// Hoja inferior que permite elegir cómo iniciar una actividad en el mapa.
class StartRouteSheet extends StatelessWidget {
  const StartRouteSheet({super.key, required this.onActionSelected});

  /// Notifica la opción elegida por el usuario.
  final ValueChanged<StartRouteAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Iniciar registro',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _kPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige si quieres comenzar una ruta en vivo o ir al módulo donde ya administras tus rutas guardadas.',
                style: TextStyle(
                  color: Color(0xFF414844),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _StartOptionCard(
                icon: Icons.fiber_manual_record_rounded,
                accentColor: _kOrangeColor,
                title: 'Empezar a registrar',
                subtitle:
                    'Activa el seguimiento para ir trazando la ruta mientras avanzas.',
                onTap: () => onActionSelected(StartRouteAction.live),
              ),
              const SizedBox(height: 12),
              _StartOptionCard(
                icon: Icons.route_rounded,
                accentColor: _kPrimaryColor,
                title: 'Ver rutas guardadas',
                subtitle:
                    'Te llevamos a tus rutas guardadas para que inicies la aventura.',
                onTap: () => onActionSelected(StartRouteAction.savedRoutes),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta táctil para una opción de inicio de ruta.
class _StartOptionCard extends StatelessWidget {
  const _StartOptionCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDCE2DE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF414844),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: _kPrimaryColor),
          ],
        ),
      ),
    );
  }
}
