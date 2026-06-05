import 'package:flutter/material.dart';

import '../../../models/sponsor_model.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _formSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF0B261D) : Colors.white;

Color _formBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

Color _sectionSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF132F25) : const Color(0xFFFDFDFD);

Color _sectionBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF214937) : const Color(0xFFEDEEEF);

Color _dateFieldSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF17352A) : const Color(0xFFF3F4F5);

Color _dateFieldText(BuildContext context, bool hasValue) {
  if (_isDarkMode(context)) {
    return hasValue ? const Color(0xFFE8F5E9) : const Color(0xFF9DB4A8);
  }
  return hasValue ? const Color(0xFF012D1D) : const Color(0xFF6B7E76);
}

class SponsorRegistrationForm extends StatefulWidget {
  const SponsorRegistrationForm({required this.onSave, super.key});

  final Future<void> Function(Sponsor sponsor) onSave;

  @override
  State<SponsorRegistrationForm> createState() =>
      _SponsorRegistrationFormState();
}

class _SponsorRegistrationFormState extends State<SponsorRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _externalLinkController = TextEditingController();
  final _priorityController = TextEditingController();

  bool _isSaving = false;
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedPaymentType;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  static const _types = [
    'Empresa',
    'Negocio local',
    'ONG',
    'Institucion',
    'Otro',
  ];
  static const _statuses = ['Activo', 'Inactivo', 'Expirado'];
  static const _paymentTypes = ['Mensual', 'Anual', 'Unico'];
  static const _categories = [
    'Restaurante',
    'Hotel',
    'Tour',
    'Tienda',
    'Transporte',
    'Experiencia',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _logoUrlController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _externalLinkController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _formSurface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _formBorder(context)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionCard(
                title: 'Datos basicos',
                subtitle:
                    'Informacion principal del patrocinador y datos de contacto.',
                child: _FormColumn(
                  children: [
                    _FieldBlock(
                      label: 'NOMBRE',
                      child: TextFormField(
                        controller: _nameController,
                        validator: (value) =>
                            _requiredText(value, 'Ingresa el nombre.'),
                      ),
                    ),
                    _TwoColumnFields(
                      leftLabel: 'LOGO URL',
                      leftChild: TextFormField(
                        controller: _logoUrlController,
                        validator: _validateUrlField,
                      ),
                      rightLabel: 'TIPO',
                      rightChild: DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        items: _types
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedType = value),
                        validator: (value) =>
                            value == null ? 'Selecciona un tipo.' : null,
                      ),
                    ),
                    _TwoColumnFields(
                      leftLabel: 'CORREO DE CONTACTO',
                      leftChild: TextFormField(
                        controller: _emailController,
                        validator: _validateEmail,
                      ),
                      rightLabel: 'TELEFONO',
                      rightChild: TextFormField(
                        controller: _phoneController,
                        validator: (value) =>
                            _requiredText(value, 'Ingresa el telefono.'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Datos comerciales',
                subtitle:
                    'Vigencia del acuerdo, estado actual y condiciones de pago.',
                child: _FormColumn(
                  children: [
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
                        errorText: _validateStartDate(),
                      ),
                      rightLabel: 'FECHA DE FINALIZACION',
                      rightChild: _DatePickerField(
                        value: _endDate,
                        hint: 'Selecciona una fecha',
                        onTap: () => _pickDate(
                          initialDate: _endDate ?? _startDate,
                          onSelected: (date) => setState(() => _endDate = date),
                        ),
                        errorText: _validateEndDate(),
                      ),
                    ),
                    _TwoColumnFields(
                      leftLabel: 'ESTADO',
                      leftChild: DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        items: _statuses
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedStatus = value),
                        validator: (value) =>
                            value == null ? 'Selecciona un estado.' : null,
                      ),
                      rightLabel: 'TIPO DE PAGO',
                      rightChild: DropdownButtonFormField<String>(
                        initialValue: _selectedPaymentType,
                        items: _paymentTypes
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedPaymentType = value),
                        validator: (value) => value == null
                            ? 'Selecciona un tipo de pago.'
                            : null,
                      ),
                    ),
                    _FieldBlock(
                      label: 'MONTO APORTADO',
                      helper: 'Opcional',
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateAmount,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Datos para la app',
                subtitle:
                    'Informacion que luego se podra reflejar dentro de EcoRutaCR.',
                child: _FormColumn(
                  children: [
                    _FieldBlock(
                      label: 'CATEGORIA',
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        items: _categories
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value),
                        validator: (value) =>
                            value == null ? 'Selecciona una categoria.' : null,
                      ),
                    ),
                    _FieldBlock(
                      label: 'DESCRIPCION',
                      child: TextFormField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 5,
                        validator: _validateDescription,
                      ),
                    ),
                    _FieldBlock(
                      label: 'LINK EXTERNO',
                      helper: 'Opcional: web, Instagram o Maps',
                      child: TextFormField(
                        controller: _externalLinkController,
                        validator: _validateOptionalLink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveSponsor,
                  child: Text(
                    _isSaving ? 'Guardando...' : 'Guardar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSponsor() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final dateValid = _validateDates();
    if (!formValid || !dateValid) {
      setState(() {});
      return;
    }
    setState(() => _isSaving = true);
    final sponsor = Sponsor(
      name: _nameController.text.trim(),
      logoUrl: _logoUrlController.text.trim(),
      type: _selectedType!,
      contactEmail: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      status: _selectedStatus!,
      amountContributed: _amountController.text.trim().isEmpty
          ? null
          : double.tryParse(_amountController.text.trim()),
      paymentType: _selectedPaymentType!,
      isPhysicalBusiness: false,
      latitude: null,
      longitude: null,
      category: _selectedCategory!,
      description: _descriptionController.text.trim(),
      externalLink: _externalLinkController.text.trim().isEmpty
          ? null
          : _externalLinkController.text.trim(),
      priority: _priorityController.text.trim().isEmpty
          ? null
          : int.tryParse(_priorityController.text.trim()),
    );

    try {
      await widget.onSave(sponsor);
      if (!mounted) return;
      _resetForm();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _logoUrlController.clear();
    _emailController.clear();
    _phoneController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _externalLinkController.clear();
    _priorityController.clear();
    setState(() {
      _selectedType = null;
      _selectedStatus = null;
      _selectedPaymentType = null;
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
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

  bool _validateDates() =>
      _validateStartDate() == null && _validateEndDate() == null;

  String? _requiredText(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;
  String? _validateUrlField(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return 'Ingresa el logoUrl.';
    final uri = Uri.tryParse(normalized);
    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
      return 'Ingresa una URL valida.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return 'Ingresa el correo.';
    if (!normalized.contains('@')) return 'Ingresa un correo valido.';
    return null;
  }

  String? _validateAmount(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized) == null
        ? 'Ingresa un monto valido.'
        : null;
  }

  String? _validateStartDate() =>
      _startDate == null ? 'Selecciona la fecha de inicio.' : null;

  String? _validateEndDate() {
    if (_endDate == null) return 'Selecciona la fecha de finalizacion.';
    if (_startDate != null && _endDate!.isBefore(_startDate!)) {
      return 'La fecha final no puede ser anterior al inicio.';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return 'Ingresa una descripcion.';
    if (normalized.length < 20) return 'Describe un poco mas al patrocinador.';
    return null;
  }

  String? _validateOptionalLink(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return null;
    final uri = Uri.tryParse(normalized);
    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
      return 'Ingresa un link valido.';
    }
    return null;
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < children.length; i++) ...[
        children[i],
        if (i < children.length - 1) const SizedBox(height: 18),
      ],
    ],
  );
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child, this.helper});
  final String label;
  final String? helper;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      if (helper != null) ...[
        const SizedBox(height: 4),
        Text(helper!, style: Theme.of(context).textTheme.bodyMedium),
      ],
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
              color: _dateFieldSurface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: errorText != null
                    ? const Color(0xFFE57373)
                    : (_isDarkMode(context)
                          ? const Color(0xFF214937)
                          : Colors.transparent),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: _isDarkMode(context)
                      ? const Color(0xFF9DB4A8)
                      : const Color(0xFF6B7E76),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: _dateFieldText(context, value != null),
                    fontWeight: value == null
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _sectionSurface(context),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _sectionBorder(context)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}
