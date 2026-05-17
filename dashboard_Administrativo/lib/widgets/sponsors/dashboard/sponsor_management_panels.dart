import 'package:flutter/material.dart';

import '../../../models/sponsor_model.dart';
import '../../../screens/dashboard/shared/dashboard_mock_ui.dart';
import '../registration/sponsor_registration_form.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _panelSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF0B261D) : Colors.white;

Color _panelBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

Color _mapStageSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF132F25) : const Color(0xFFE5F3EA);

Color _mapStageBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF214937) : const Color(0xFFC1ECD4);

Color _mapPreviewText(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFE8F5E9) : const Color(0xFF012D1D);

class SponsorRegisterPreview extends StatelessWidget {
  const SponsorRegisterPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return SponsorRegistrationForm(
      onSave: (Sponsor sponsor) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patrocinador listo: ${sponsor.name}')),
        );
      },
    );
  }
}

class SponsorMapModulePreview extends StatelessWidget {
  const SponsorMapModulePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelSurface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _panelBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Puntos de anuncios sobre mapa',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Aqui montaremos OpenStreetMap para elegir visualmente los puntos donde apareceran anuncios y activaciones.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 420,
            child: Container(
              decoration: BoxDecoration(
                color: _mapStageSurface(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _mapStageBorder(context)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _MapGridPainter(context)),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 56,
                          color: _isDarkMode(context)
                              ? dashboardSupportGreen
                              : const Color(0xFF2C694E),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Preview de area para OpenStreetMap',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _mapPreviewText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    left: 60,
                    top: 90,
                    child: _MapPin(label: 'Anuncio A'),
                  ),
                  const Positioned(
                    right: 110,
                    top: 170,
                    child: _MapPin(label: 'Anuncio B'),
                  ),
                  const Positioned(
                    left: 180,
                    bottom: 76,
                    child: _MapPin(label: 'Anuncio C'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SponsorModulePlaceholder extends StatelessWidget {
  const SponsorModulePlaceholder({
    required this.title,
    required this.description,
    required this.accentColor,
    required this.bullets,
    super.key,
  });

  final String title;
  final String description;
  final Color accentColor;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelSurface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _panelBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accentColor.withValues(alpha: 0.20)),
            ),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: accentColor),
            ),
          ),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 18),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _panelSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _panelBorder(context)),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode(context)
                ? const Color(0x40020B08)
                : const Color(0x14012D1D),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: Color(0xFFFF7043),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _mapPreviewText(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter(this.context);

  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _isDarkMode(context)
          ? const Color(0xFF214937)
          : const Color(0xFFB7D9C4)
      ..strokeWidth = 1;

    const step = 48.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
