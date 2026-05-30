import 'package:flutter/material.dart';

const _kPrimaryColor = Color(0xFF012D1D);

enum RouteActivityOption { hiking, cycling, running }

enum RouteVisibilityOption { private, public }

class FinishRouteDraft {
  const FinishRouteDraft({
    required this.title,
    required this.activity,
    required this.visibility,
  });

  final String title;
  final RouteActivityOption activity;
  final RouteVisibilityOption visibility;
}

class FinishRouteSheetResult {
  const FinishRouteSheetResult.save(this.draft) : discarded = false;

  const FinishRouteSheetResult.discard() : draft = null, discarded = true;

  final FinishRouteDraft? draft;
  final bool discarded;
}

class FinishRouteSheet extends StatefulWidget {
  const FinishRouteSheet({
    super.key,
    required this.initialTitle,
    required this.initialActivity,
    required this.initialVisibility,
    required this.onSave,
    required this.onDiscard,
  });

  final String initialTitle;
  final RouteActivityOption initialActivity;
  final RouteVisibilityOption initialVisibility;
  final ValueChanged<FinishRouteDraft> onSave;
  final VoidCallback onDiscard;

  @override
  State<FinishRouteSheet> createState() => _FinishRouteSheetState();
}

class _FinishRouteSheetState extends State<FinishRouteSheet> {
  late final TextEditingController _titleController;
  late RouteActivityOption _selectedActivity;
  late RouteVisibilityOption _selectedVisibility;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _selectedActivity = widget.initialActivity;
    _selectedVisibility = widget.initialVisibility;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terminar registro',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _kPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Completa estos datos para guardar la ruta en Mis rutas o descartarla.',
                style: TextStyle(
                  color: Color(0xFF414844),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              const _SheetLabel('Nombre de la ruta'),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: _sheetInputDecoration(
                  hint: 'Escribe un nombre para tu ruta',
                  icon: Icons.edit_rounded,
                ),
              ),
              const SizedBox(height: 18),
              const _SheetLabel('Tipo de actividad'),
              const SizedBox(height: 10),
              _SegmentedChoice<RouteActivityOption>(
                value: _selectedActivity,
                options: const [
                  _SegmentOption(
                    value: RouteActivityOption.hiking,
                    label: 'Senderismo',
                  ),
                  _SegmentOption(
                    value: RouteActivityOption.cycling,
                    label: 'Ciclismo',
                  ),
                  _SegmentOption(
                    value: RouteActivityOption.running,
                    label: 'Running',
                  ),
                ],
                onChanged: (value) => setState(() => _selectedActivity = value),
              ),
              const SizedBox(height: 18),
              const _SheetLabel('Visibilidad'),
              const SizedBox(height: 10),
              _SegmentedChoice<RouteVisibilityOption>(
                value: _selectedVisibility,
                options: const [
                  _SegmentOption(
                    value: RouteVisibilityOption.private,
                    label: 'Privada',
                  ),
                  _SegmentOption(
                    value: RouteVisibilityOption.public,
                    label: 'Publica',
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedVisibility = value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onDiscard,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBA1A1A),
                    side: const BorderSide(color: Color(0xFFFFC9C1)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    backgroundColor: const Color(0xFFFFF3EE),
                  ),
                  child: const Text('Descartar ruta'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text('Terminar Registro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega un titulo para la ruta.')),
      );
      return;
    }

    widget.onSave(
      FinishRouteDraft(
        title: title,
        activity: _selectedActivity,
        visibility: _selectedVisibility,
      ),
    );
  }
}

InputDecoration _sheetInputDecoration({
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF3F4F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Color(0xFFDCE2DE)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Color(0xFFDCE2DE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: _kPrimaryColor, width: 1.8),
    ),
  );
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

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

class _SegmentOption<T> {
  const _SegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _SegmentedChoice<T> extends StatelessWidget {
  const _SegmentedChoice({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<_SegmentOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: options
            .map((option) {
              final selected = option.value == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(option.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF414844),
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
