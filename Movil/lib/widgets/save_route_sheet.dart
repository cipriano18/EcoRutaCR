import 'package:ecoruta/models/stored_route.dart';
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

/// Hoja modal que recopila titulo, descripcion y visibilidad de una ruta.
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.titleText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF012D1D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.startLabel} -> ${widget.endLabel}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titulo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripcion (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Visibilidad',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SegmentedButton<StoredRouteVisibility>(
                segments: const [
                  ButtonSegment(
                    value: StoredRouteVisibility.private,
                    icon: Icon(Icons.lock_outline),
                    label: Text('Privada'),
                  ),
                  ButtonSegment(
                    value: StoredRouteVisibility.public,
                    icon: Icon(Icons.public),
                    label: Text('Publica'),
                  ),
                ],
                selected: {_visibility},
                onSelectionChanged: (selection) {
                  setState(() => _visibility = selection.first);
                },
              ),
              if (_visibility == StoredRouteVisibility.public) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD4C7)),
                  ),
                  child: const Text(
                    'Si cambias la ruta a publica, no podras editarla despues y sera visible para los demas usuarios.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF721D00),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF012D1D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(widget.submitButtonText),
                ),
              ),
            ],
          ),
        ),
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
