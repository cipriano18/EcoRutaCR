import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../models/advertisement_model.dart';
import '../../../models/sponsor_model.dart';
import '../../../services/advertisement_service.dart';
import '../../../services/sponsor_service.dart';
import '../registration/sponsor_registration_form.dart';
import '../shared/sponsor_map_canvas.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _panelSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF0B261D) : Colors.white;

Color _panelBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

Color _mapPreviewText(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFE8F5E9) : const Color(0xFF012D1D);

class SponsorRegisterPreview extends StatelessWidget {
  const SponsorRegisterPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return SponsorRegistrationForm(
      onSave: (Sponsor sponsor) async {
        try {
          final sponsorId = await context.read<SponsorService>().createSponsor(
            sponsor,
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Patrocinador guardado: ${sponsor.name} (${sponsorId.substring(0, 8)})',
              ),
            ),
          );
        } on FirebaseException catch (error) {
          if (!context.mounted) return;
          final message =
              error.message ??
              'No se pudo guardar el patrocinador en Firebase.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
          );
          rethrow;
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocurrio un error inesperado al guardar.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          rethrow;
        }
      },
    );
  }
}

class SponsorMapModulePreview extends StatelessWidget {
  const SponsorMapModulePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SponsorMapContent();
  }
}

class _SponsorMapContent extends StatefulWidget {
  const _SponsorMapContent();

  @override
  State<_SponsorMapContent> createState() => _SponsorMapContentState();
}

class _SponsorMapContentState extends State<_SponsorMapContent> {
  final _mapController = MapController();
  static const _fallbackCenter = LatLng(9.9281, -84.0907);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdvertisementDraft>>(
      stream: context.read<AdvertisementService>().getAdvertisements(),
      builder: (context, snapshot) {
        final allAds = snapshot.data ?? const <AdvertisementDraft>[];
        final localAds = allAds
            .where(
              (ad) =>
                  ad.type == AdvertisementType.local &&
                  ad.latitude != null &&
                  ad.longitude != null,
            )
            .toList();
        final center = localAds.isNotEmpty
            ? LatLng(localAds.first.latitude!, localAds.first.longitude!)
            : _fallbackCenter;

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
                'Vista real de OpenStreetMap para revisar locales activos, explorar su informacion y acceder a una edicion rapida.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _MapStateBanner(
                  message: 'Cargando puntos de publicidades desde Firebase...',
                )
              else if (snapshot.hasError)
                const _MapStateBanner(
                  message: 'No se pudieron cargar los puntos de publicidades.',
                  isError: true,
                )
              else if (localAds.isEmpty)
                const _MapStateBanner(
                  message:
                      'Todavia no hay publicidades tipo local con coordenadas para mostrar.',
                ),
              if (localAds.isNotEmpty) ...[
                SizedBox(
                  height: 420,
                  child: Stack(
                    children: [
                      SponsorMapCanvas(
                        center: center,
                        mapController: _mapController,
                        zoom: 13,
                        interactionFlags:
                            InteractiveFlag.all &
                            ~InteractiveFlag.scrollWheelZoom,
                        markers: localAds
                            .map(
                              (ad) => SponsorMapMarkerData(
                                point: LatLng(ad.latitude!, ad.longitude!),
                                label: ad.sponsorName,
                              ),
                            )
                            .toList(),
                        markerBuilder: (marker) {
                          final advertisement = localAds.firstWhere(
                            (ad) =>
                                ad.latitude == marker.point.latitude &&
                                ad.longitude == marker.point.longitude &&
                                ad.sponsorName == marker.label,
                          );
                          return _AdvertisementMapMarker(
                            advertisement: advertisement,
                          );
                        },
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        child: _MapZoomControls(
                          onZoomIn: _zoomIn,
                          onZoomOut: _zoomOut,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _LegendPill(
                      color: const Color(0xFFFF7043),
                      label: '${localAds.length} locales cargados',
                    ),
                    const _LegendPill(
                      color: Color(0xFF2C8C5A),
                      label: 'Hover para ver detalle',
                    ),
                    const _LegendPill(
                      color: Color(0xFF4DA1FF),
                      label: 'Editar disponible',
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _zoomIn() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom + 1);
  }

  void _zoomOut() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom - 1);
  }
}

class _AdvertisementMapMarker extends StatefulWidget {
  const _AdvertisementMapMarker({required this.advertisement});

  final AdvertisementDraft advertisement;

  @override
  State<_AdvertisementMapMarker> createState() =>
      _AdvertisementMapMarkerState();
}

class _AdvertisementMapMarkerState extends State<_AdvertisementMapMarker> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isBubbleHovered = false;
  bool _isCardHovered = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.advertisement;
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _updateBubbleHover(true),
        onExit: (_) => _updateBubbleHover(false),
        child: _LogoBubble(logoUrl: ad.sponsorLogoUrl),
      ),
    );
  }

  void _updateBubbleHover(bool hovering) {
    _isBubbleHovered = hovering;
    if (hovering) {
      _showOverlay();
    } else {
      _scheduleOverlayRemovalCheck();
    }
  }

  void _updateCardHover(bool hovering) {
    _isCardHovered = hovering;
    if (hovering) {
      _showOverlay();
    } else {
      _scheduleOverlayRemovalCheck();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: IgnorePointer(
          ignoring: false,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topCenter,
                followerAnchor: Alignment.bottomCenter,
                offset: const Offset(0, -12),
                child: MouseRegion(
                  onEnter: (_) => _updateCardHover(true),
                  onExit: (_) => _updateCardHover(false),
                  child: _AdvertisementHoverCard(
                    advertisement: widget.advertisement,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _scheduleOverlayRemovalCheck() {
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      if (_isBubbleHovered || _isCardHovered) return;
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isCardHovered = false;
    _isBubbleHovered = false;
  }
}

String _resolveRenderableImageUrl(String rawUrl) {
  final normalized = rawUrl.trim();
  final uri = Uri.tryParse(normalized);
  if (uri == null) return normalized;

  if (uri.host.contains('drive.google.com')) {
    final fileId = _extractDriveFileId(uri);
    if (fileId != null && fileId.isNotEmpty) {
      return 'https://drive.google.com/thumbnail?id=$fileId&sz=w1600';
    }
  }

  if (uri.host.contains('lh3.googleusercontent.com') &&
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == 'd') {
    final fileId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    if (fileId != null && fileId.isNotEmpty) {
      return 'https://drive.google.com/thumbnail?id=$fileId&sz=w1600';
    }
  }

  return normalized;
}

String? _extractDriveFileId(Uri uri) {
  final idFromQuery = uri.queryParameters['id'];
  if (idFromQuery != null && idFromQuery.isNotEmpty) {
    return idFromQuery;
  }

  final segments = uri.pathSegments;
  final fileIndex = segments.indexOf('d');
  if (fileIndex != -1 && fileIndex + 1 < segments.length) {
    return segments[fileIndex + 1];
  }

  return null;
}

class _AdvertisementHoverCard extends StatelessWidget {
  const _AdvertisementHoverCard({required this.advertisement});

  final AdvertisementDraft advertisement;

  @override
  Widget build(BuildContext context) {
    final ad = advertisement;

    return Container(
      width: 420,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panelSurface(context).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _panelBorder(context)),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode(context)
                ? const Color(0x40020B08)
                : const Color(0x18012D1D),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _panelBorder(context)),
              color: _isDarkMode(context)
                  ? const Color(0xFF17352A)
                  : const Color(0xFFF3F4F5),
              boxShadow: [
                BoxShadow(
                  color: _isDarkMode(context)
                      ? const Color(0x22020B08)
                      : const Color(0x12012D1D),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ad.imageUrl.trim().isEmpty
                ? const Icon(
                    Icons.image_outlined,
                    size: 34,
                    color: Color(0xFFFF7043),
                  )
                : _NetworkPreviewImage(
                    imageUrl: ad.imageUrl,
                    fit: BoxFit.cover,
                    fallback: const Icon(
                      Icons.broken_image_outlined,
                      size: 34,
                      color: Color(0xFFFF7043),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ad.sponsorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  ad.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Estado: ${ad.status}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clicks: ${ad.totalClicks}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Edicion pendiente para ${ad.sponsorName}.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Editar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBubble extends StatelessWidget {
  const _LogoBubble({required this.logoUrl});

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFF7043), width: 3),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode(context)
                ? const Color(0x40020B08)
                : const Color(0x18012D1D),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: logoUrl.trim().isEmpty
            ? const Icon(Icons.storefront_rounded, color: Color(0xFF012D1D))
            : _NetworkPreviewImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
                fallback: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFF012D1D),
                ),
              ),
      ),
    );
  }
}

class _NetworkPreviewImage extends StatelessWidget {
  const _NetworkPreviewImage({
    required this.imageUrl,
    required this.fit,
    required this.fallback,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _resolveRenderableImageUrl(imageUrl),
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ZoomButton(
          icon: Icons.add_rounded,
          tooltip: 'Acercar mapa',
          onPressed: onZoomIn,
        ),
        const SizedBox(height: 10),
        _ZoomButton(
          icon: Icons.remove_rounded,
          tooltip: 'Alejar mapa',
          onPressed: onZoomOut,
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final iconColor = _isDarkMode(context)
        ? const Color(0xFFE8F5E9)
        : const Color(0xFF012D1D);

    return Material(
      color: _panelSurface(context).withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _panelBorder(context)),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _MapStateBanner extends StatelessWidget {
  const _MapStateBanner({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFE57373) : const Color(0xFF2C8C5A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
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

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.color, required this.label});

  final Color color;
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
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
