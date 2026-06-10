import 'package:ecoruta/features/routes/models/stored_route.dart';
import 'package:flutter/material.dart';

/// Resultado intermedio del formulario para guardar rutas.
class SaveRouteFormResult {
  const SaveRouteFormResult({
    required this.title,
    required this.description,
    required this.visibility,
  });

  final String title;
  final String description;
  final StoredRouteVisibility visibility;
}

/// Hoja modal que recopila título, descripción y visibilidad de una ruta.
class SaveRouteSheet extends StatefulWidget {
  const SaveRouteSheet({
    super.key,
    required this.initialTitle,
    required this.startLabel,
    required this.endLabel,
    this.initialDescription = '',
    this.titleText = 'Guardar ruta',
    this.submitButtonText = 'Guardar en Mis rutas',
  });

  final String initialTitle;
  final String startLabel;
  final String endLabel;
  final String initialDescription;
  final String titleText;
  final String submitButtonText;

  @override
  State<SaveRouteSheet> createState() => _SaveRouteSheetState();
}

class _SaveRouteSheetState extends State<SaveRouteSheet> {
  static const _primaryColor = Color(0xFF012D1D);
  static const _surfaceLow = Color(0xFFF3F4F5);
  static const _surfaceBorder = Color(0xFFDCE2DE);
  static const _tertiaryFixed = Color(0xFFFFB59F);
  static const _tertiaryText = Color(0xFF721D00);

  late final TextEditingController _titleController;
  final TextEditingController _descriptionController = TextEditingController();
  StoredRouteVisibility _visibility = StoredRouteVisibility.private;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController.text = widget.initialDescription;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.titleText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceLow,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _surfaceBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _tertiaryFixed.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.startLabel} -> ${widget.endLabel}',
                          style: const TextStyle(
                            color: Color(0xFF414844),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _FieldLabel(text: 'Titulo de la ruta *'),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    hintText: 'Ej. Ruta verde por Escazú',
                    prefixIcon: Icons.edit_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'descripción'),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    hintText: 'Agrega una nota corta sobre esta ruta',
                    prefixIcon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 20),
                const _FieldLabel(text: 'Visibilidad'),
                const SizedBox(height: 10),
                Theme(
                  data: Theme.of(context).copyWith(
                    segmentedButtonTheme: SegmentedButtonThemeData(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return _primaryColor;
                          }
                          return _surfaceLow;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return _primaryColor;
                        }),
                        side: const WidgetStatePropertyAll(
                          BorderSide(color: _surfaceBorder),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        ),
                        textStyle: const WidgetStatePropertyAll(
                          TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  child: SegmentedButton<StoredRouteVisibility>(
                    segments: const [
                      ButtonSegment(
                        value: StoredRouteVisibility.private,
                        icon: Icon(Icons.lock_outline_rounded),
                        label: Text('Privada'),
                      ),
                      ButtonSegment(
                        value: StoredRouteVisibility.public,
                        icon: Icon(Icons.public_rounded),
                        label: Text('Pública'),
                      ),
                    ],
                    selected: {_visibility},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() => _visibility = selection.first);
                    },
                  ),
                ),
                if (_visibility == StoredRouteVisibility.public) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFD4C7)),
                    ),
                    child: const Text(
                      'Si la haces pública, quedara visible para otros usuarios y no podrás editarla después.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: _tertiaryText,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(widget.submitButtonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      filled: true,
      fillColor: _surfaceLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _primaryColor, width: 1.8),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega un titulo para la ruta.')),
      );
      return;
    }

    if (title == widget.initialTitle.trim()) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Usar nombre por defecto'),
            content: Text(
              'La ruta se guardara con el nombre "$title". ¿Deseas mantenerlo o cambiarlo antes de guardar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cambiar nombre'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Guardar asi'),
              ),
            ],
          );
        },
      );

      if (shouldSave != true) {
        return;
      }
    }

    if (!mounted) return;

    Navigator.of(context).pop(
      SaveRouteFormResult(
        title: title,
        description: _descriptionController.text.trim(),
        visibility: _visibility,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFFFF825C),
        letterSpacing: 1.8,
      ),
    );
  }
}
