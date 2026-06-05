import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../models/advertisement_model.dart';
import '../../../models/sponsor_model.dart';
import '../../../services/advertisement_service.dart';
import '../../../services/sponsor_service.dart';
import '../shared/sponsor_map_canvas.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _panelSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF0B261D) : Colors.white;

Color _panelBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

Color _sectionSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF132F25) : const Color(0xFFFDFDFD);

Color _sectionBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF214937) : const Color(0xFFEDEEEF);

Color _chipSurface(BuildContext context, bool selected) {
  if (selected) return const Color(0xFFFF7043);
  return _isDarkMode(context)
      ? const Color(0xFF17352A)
      : const Color(0xFFF3F4F5);
}

Color _chipText(BuildContext context, bool selected) {
  if (selected) return Colors.white;
  return _isDarkMode(context)
      ? const Color(0xFFE8F5E9)
      : const Color(0xFF012D1D);
}

class AdvertisementRegistrationModule extends StatefulWidget {
  const AdvertisementRegistrationModule({this.sponsorsStream, super.key});

  final Stream<List<Sponsor>>? sponsorsStream;

  @override
  State<AdvertisementRegistrationModule> createState() =>
      _AdvertisementRegistrationModuleState();
}

class _AdvertisementRegistrationModuleState
    extends State<AdvertisementRegistrationModule> {
  final _formKey = GlobalKey<FormState>();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();

  static const _statuses = ['Activo', 'Inactivo'];
  static const _fallbackCenter = LatLng(9.9281, -84.0907);

  AdvertisementType _type = AdvertisementType.anuncio;
  bool _isSubmitting = false;
  String? _selectedSponsorId;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  LatLng? _selectedPoint;

  @override
  void dispose() {
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Stream<List<Sponsor>> _resolveSponsorsStream(BuildContext context) {
    return widget.sponsorsStream ??
        context.read<SponsorService>().getSponsors();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Sponsor>>(
      stream: _resolveSponsorsStream(context),
      builder: (context, snapshot) {
        final sponsors = snapshot.data ?? const <Sponsor>[];
        final selectedSponsor = _findSelectedSponsor(sponsors);
        final localDateError = _type == AdvertisementType.local
            ? _localDateAvailabilityError(selectedSponsor)
            : null;
        final mapCenter =
            _selectedPoint ??
            _pointFromSponsor(selectedSponsor) ??
            _fallbackCenter;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _panelSurface(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _panelBorder(context)),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _sectionSurface(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _sectionBorder(context)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formulario de publicidad',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona el tipo y completa los datos visibles para preparar la entidad que luego se guardara.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  _TypeSelector(
                    value: _type,
                    onChanged: (value) {
                      setState(() {
                        _type = value;
                        if (value == AdvertisementType.anuncio) {
                          _openingTime = null;
                          _closingTime = null;
                          _selectedPoint = null;
                        } else {
                          _startDate = null;
                          _endDate = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const _InfoBanner(
                      message: 'Cargando patrocinadores disponibles...',
                    )
                  else if (snapshot.hasError)
                    const _InfoBanner(
                      message:
                          'No se pudieron cargar los patrocinadores para el selector.',
                      isError: true,
                    )
                  else if (sponsors.isEmpty)
                    const _InfoBanner(
                      message:
                          'No hay patrocinadores registrados todavia. Registra al menos uno antes de preparar publicidades.',
                      isError: true,
                    ),
                  if (localDateError != null) ...[
                    const SizedBox(height: 12),
                    _InfoBanner(message: localDateError, isError: true),
                  ],
                  const SizedBox(height: 18),
                  _FieldBlock(
                    label: 'PATROCINADOR',
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSponsorId,
                      items: sponsors
                          .map(
                            (sponsor) => DropdownMenuItem(
                              value: sponsor.id ?? sponsor.name,
                              child: Text(sponsor.name),
                            ),
                          )
                          .toList(),
                      onChanged: sponsors.isEmpty
                          ? null
                          : (value) => setState(() {
                              _selectedSponsorId = value;
                              if (_type == AdvertisementType.local) {
                                _selectedPoint = _pointFromSponsor(
                                  _findSelectedSponsor(sponsors),
                                );
                              }
                            }),
                      validator: (_) => _validateSponsor(sponsors),
                      decoration: const InputDecoration(
                        hintText: 'Selecciona un patrocinador',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _TwoColumnFields(
                    leftLabel: 'ESTADO',
                    leftChild: DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      items: _statuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedStatus = value),
                      validator: (value) =>
                          value == null ? 'Selecciona un estado.' : null,
                    ),
                    rightLabel: 'URL DE IMAGEN',
                    rightChild: TextFormField(
                      controller: _imageUrlController,
                      validator: _validateUrlField,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_type == AdvertisementType.anuncio)
                    _TwoColumnFields(
                      leftLabel: 'FECHA DE INICIO',
                      leftChild: _DatePickerField(
                        value: _startDate,
                        hint: 'Selecciona una fecha',
                        onTap: () => _pickDate(
                          initialDate: _startDate,
                          onSelected: (date) =>
                              setState(() => _startDate = date),
                        ),
                        errorText: _dateValidationError.startError,
                      ),
                      rightLabel: 'FECHA DE FIN',
                      rightChild: _DatePickerField(
                        value: _endDate,
                        hint: 'Selecciona una fecha',
                        onTap: () => _pickDate(
                          initialDate: _endDate ?? _startDate,
                          onSelected: (date) => setState(() => _endDate = date),
                        ),
                        errorText: _dateValidationError.endError,
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 420,
                      child: Stack(
                        children: [
                          SponsorMapCanvas(
                            center: mapCenter,
                            mapController: _mapController,
                            selectedPoint: _selectedPoint,
                            zoom: _selectedPoint == null ? 13 : 15,
                            onTap: (point) =>
                                setState(() => _selectedPoint = point),
                            interactionFlags:
                                InteractiveFlag.all &
                                ~InteractiveFlag.scrollWheelZoom,
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
                    const SizedBox(height: 14),
                    _MapHintRow(
                      selectedPoint: _selectedPoint,
                      showError: !_isSubmitting && _selectedPoint == null,
                    ),
                    const SizedBox(height: 18),
                    _TwoColumnFields(
                      leftLabel: 'HORA DE APERTURA',
                      leftChild: _TimePickerField(
                        value: _openingTime,
                        hint: 'Selecciona una hora',
                        onTap: () => _pickTime(
                          initialValue: _openingTime,
                          onSelected: (time) =>
                              setState(() => _openingTime = time),
                        ),
                        errorText: _timeValidationError.openingError,
                      ),
                      rightLabel: 'HORA DE CIERRE',
                      rightChild: _TimePickerField(
                        value: _closingTime,
                        hint: 'Selecciona una hora',
                        onTap: () => _pickTime(
                          initialValue: _closingTime,
                          onSelected: (time) =>
                              setState(() => _closingTime = time),
                        ),
                        errorText: _timeValidationError.closingError,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _FieldBlock(
                    label: 'DESCRIPCION',
                    child: TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 5,
                      validator: _validateDescription,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed:
                          _isSubmitting || sponsors.isEmpty || snapshot.hasError
                          ? null
                          : () => _submit(sponsors),
                      child: Text(
                        _isSubmitting ? 'Validando...' : 'Guardar',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _DateValidationResult get _dateValidationError => _DateValidationResult(
    startError: _type == AdvertisementType.anuncio && _startDate == null
        ? 'Selecciona la fecha de inicio.'
        : null,
    endError: _type != AdvertisementType.anuncio
        ? null
        : (_endDate == null
              ? 'Selecciona la fecha de fin.'
              : (_startDate != null && _endDate!.isBefore(_startDate!)
                    ? 'La fecha final no puede ser anterior al inicio.'
                    : null)),
  );

  _TimeValidationResult get _timeValidationError => _TimeValidationResult(
    openingError: _type == AdvertisementType.local && _openingTime == null
        ? 'Selecciona la hora de apertura.'
        : null,
    closingError: _type != AdvertisementType.local
        ? null
        : (_closingTime == null
              ? 'Selecciona la hora de cierre.'
              : (_openingTime != null &&
                        _minutesOfDay(_closingTime!) <=
                            _minutesOfDay(_openingTime!)
                    ? 'La hora de cierre debe ser posterior a la apertura.'
                    : null)),
  );

  Sponsor? _findSelectedSponsor(List<Sponsor> sponsors) {
    if (_selectedSponsorId == null) return null;
    for (final sponsor in sponsors) {
      final candidateId = sponsor.id ?? sponsor.name;
      if (candidateId == _selectedSponsorId) {
        return sponsor;
      }
    }
    return null;
  }

  LatLng? _pointFromSponsor(Sponsor? sponsor) {
    if (sponsor?.latitude == null || sponsor?.longitude == null) return null;
    return LatLng(sponsor!.latitude!, sponsor.longitude!);
  }

  String? _localDateAvailabilityError(Sponsor? sponsor) {
    if (sponsor == null) return null;
    if (sponsor.startDate.isAfter(sponsor.endDate)) {
      return 'El patrocinador seleccionado no tiene un rango de fechas valido para un local.';
    }
    return null;
  }

  String? _validateSponsor(List<Sponsor> sponsors) {
    if (sponsors.isEmpty) {
      return 'Primero registra un patrocinador.';
    }
    return _selectedSponsorId == null ? 'Selecciona un patrocinador.' : null;
  }

  String? _validateUrlField(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return 'Ingresa la URL de la imagen.';
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Ingresa una URL valida.';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return 'Ingresa una descripcion.';
    if (normalized.length < 12) return 'Describe un poco mas la publicidad.';
    return null;
  }

  Future<void> _submit(List<Sponsor> sponsors) async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final selectedSponsor = _findSelectedSponsor(sponsors);
    final datesValid = _type == AdvertisementType.anuncio
        ? _dateValidationError.startError == null &&
              _dateValidationError.endError == null
        : true;
    final timesValid = _type == AdvertisementType.local
        ? _timeValidationError.openingError == null &&
              _timeValidationError.closingError == null
        : true;
    final pointValid =
        _type == AdvertisementType.anuncio || _selectedPoint != null;
    final localDateError = _type == AdvertisementType.local
        ? _localDateAvailabilityError(selectedSponsor)
        : null;

    setState(() => _isSubmitting = true);
    if (!formValid ||
        !datesValid ||
        !timesValid ||
        !pointValid ||
        localDateError != null ||
        selectedSponsor == null) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      return;
    }

    final draft = AdvertisementDraft(
      type: _type,
      sponsorId: selectedSponsor.id ?? selectedSponsor.name,
      sponsorName: selectedSponsor.name,
      sponsorLogoUrl: selectedSponsor.logoUrl,
      sponsorExternalLink: selectedSponsor.externalLink,
      status: _selectedStatus!,
      imageUrl: _imageUrlController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _type == AdvertisementType.anuncio
          ? _startDate
          : selectedSponsor.startDate,
      endDate: _type == AdvertisementType.anuncio
          ? _endDate
          : selectedSponsor.endDate,
      openingTime: _type == AdvertisementType.local ? _openingTime : null,
      closingTime: _type == AdvertisementType.local ? _closingTime : null,
      latitude: _type == AdvertisementType.local
          ? _selectedPoint!.latitude
          : null,
      longitude: _type == AdvertisementType.local
          ? _selectedPoint!.longitude
          : null,
      totalClicks: 0,
    );

    try {
      final advertisementId = await context
          .read<AdvertisementService>()
          .createAdvertisement(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Publicidad guardada: ${draft.sponsorName} (${advertisementId.substring(0, 8)})',
          ),
        ),
      );
      _resetForm();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'No se pudo guardar la publicidad en Firebase.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocurrio un error inesperado al guardar la publicidad.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _imageUrlController.clear();
    _descriptionController.clear();
    setState(() {
      _isSubmitting = false;
      _type = AdvertisementType.anuncio;
      _selectedSponsorId = null;
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
      _openingTime = null;
      _closingTime = null;
      _selectedPoint = null;
    });
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null) onSelected(selected);
  }

  Future<void> _pickTime({
    required TimeOfDay? initialValue,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: initialValue ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (selected != null) onSelected(selected);
  }

  int _minutesOfDay(TimeOfDay time) => (time.hour * 60) + time.minute;

  void _zoomIn() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom + 1);
  }

  void _zoomOut() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom - 1);
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final AdvertisementType value;
  final ValueChanged<AdvertisementType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AdvertisementType.values
          .map(
            (type) => ChoiceChip(
              label: Text(type.label),
              selected: value == type,
              onSelected: (_) => onChanged(type),
              selectedColor: _chipSurface(context, true),
              backgroundColor: _chipSurface(context, false),
              labelStyle: TextStyle(
                color: _chipText(context, value == type),
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(color: _panelBorder(context)),
            ),
          )
          .toList(),
    );
  }
}

class _MapHintRow extends StatelessWidget {
  const _MapHintRow({required this.selectedPoint, required this.showError});

  final LatLng? selectedPoint;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = selectedPoint == null
        ? 'Selecciona un punto sobre el mapa para asociar el local.'
        : 'Ubicacion seleccionada: ${selectedPoint!.latitude.toStringAsFixed(5)}, ${selectedPoint!.longitude.toStringAsFixed(5)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          showError ? Icons.error_outline : Icons.place_outlined,
          color: showError ? const Color(0xFFE57373) : const Color(0xFFFF7043),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: showError ? const Color(0xFFE57373) : null,
              fontWeight: showError ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, this.isError = false});

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

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _TwoColumnFields extends StatelessWidget {
  const _TwoColumnFields({
    required this.leftLabel,
    required this.leftChild,
    required this.rightLabel,
    required this.rightChild,
  });

  final String leftLabel;
  final Widget leftChild;
  final String rightLabel;
  final Widget rightChild;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldBlock(label: leftLabel, child: leftChild),
              const SizedBox(height: 18),
              _FieldBlock(label: rightLabel, child: rightChild),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FieldBlock(label: leftLabel, child: leftChild),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FieldBlock(label: rightLabel, child: rightChild),
            ),
          ],
        );
      },
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.value,
    required this.hint,
    required this.onTap,
    required this.errorText,
  });

  final DateTime? value;
  final String hint;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? hint
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';
    return _PickerFieldShell(
      label: label,
      errorText: errorText,
      icon: Icons.calendar_month_outlined,
      onTap: onTap,
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.value,
    required this.hint,
    required this.onTap,
    required this.errorText,
  });

  final TimeOfDay? value;
  final String hint;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final label = value == null ? hint : value!.format(context);
    return _PickerFieldShell(
      label: label,
      errorText: errorText,
      icon: Icons.schedule_outlined,
      onTap: onTap,
    );
  }
}

class _PickerFieldShell extends StatelessWidget {
  const _PickerFieldShell({
    required this.label,
    required this.errorText,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? errorText;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF17352A) : const Color(0xFFF3F4F5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: errorText != null
                    ? const Color(0xFFE57373)
                    : (isDark ? const Color(0xFF214937) : Colors.transparent),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDark
                      ? const Color(0xFF9DB4A8)
                      : const Color(0xFF6B7E76),
                ),
                const SizedBox(width: 12),
                Text(label),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(color: Color(0xFFE57373), fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _DateValidationResult {
  const _DateValidationResult({this.startError, this.endError});

  final String? startError;
  final String? endError;
}

class _TimeValidationResult {
  const _TimeValidationResult({this.openingError, this.closingError});

  final String? openingError;
  final String? closingError;
}
