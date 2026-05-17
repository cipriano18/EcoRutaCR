import 'package:ecoruta/providers/user_provider.dart';
import 'package:ecoruta/services/auth_service.dart';
import 'package:ecoruta/widgets/avatar_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla para elegir un avatar desbloqueado por progreso del usuario.
class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({super.key, required this.initialAvatarId});

  final int initialAvatarId;

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  static const _primary = Color(0xFF012D1D);
  static const _surface = Color(0xFFF8F9FA);
  static const _surfaceAlt = Color(0xFFF2F4F5);
  static const _locked = Color(0xFF6B7280);
  static const _sections = ['Deportistas', 'Mascotas', 'Iconos de rango'];

  late int _selectedAvatarId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.initialAvatarId;
  }

  /// Persiste el avatar seleccionado y actualiza el provider global.
  Future<void> _saveAvatar() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final user = provider.user;

    if (user == null) return;
    if (!AvatarImage.isUnlockedForKm(_selectedAvatarId, user.kmCounter)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aun no has desbloqueado este icono')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await AuthService().updateAvatar(_selectedAvatarId);
      provider.setUser(user.copyWith(avatarId: _selectedAvatarId));

      if (!mounted) return;
      Navigator.of(context).pop(_selectedAvatarId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el avatar')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final totalKilometers = user?.kmCounter ?? 0;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _primary,
        title: const Text(
          'Cambiar avatar',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Elige tu nuevo icono',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige tu icono por seccion. Los chonetes se desbloquean segun tus kilometros acumulados.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _sections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    final sectionOptions = AvatarImage.options
                        .where((option) => option.category == section)
                        .toList();

                    return _buildSection(
                      title: section,
                      options: sectionOptions,
                      totalKilometers: totalKilometers,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAvatar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<AvatarOption> options,
    required num totalKilometers,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _primary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = _selectedAvatarId == option.id;
              final isUnlocked = AvatarImage.isUnlockedForKm(
                option.id,
                totalKilometers,
              );

              return _buildCircularOption(
                option: option,
                isSelected: isSelected,
                isUnlocked: isUnlocked,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircularOption({
    required AvatarOption option,
    required bool isSelected,
    required bool isUnlocked,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isUnlocked) return;
        setState(() {
          _selectedAvatarId = option.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 96,
        height: 96,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? const Color(0xFFCFEFDC)
              : isUnlocked
              ? Colors.transparent
              : _surfaceAlt,
          border: Border.all(
            color: isSelected ? _primary : const Color(0xFFD8DDE1),
            width: isSelected ? 2.4 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: isUnlocked ? 1 : 0.45,
                child: AvatarImage(
                  avatarId: option.id,
                  size: 88,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            if (!isUnlocked)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD5D9DD)),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: _locked,
                    size: 14,
                  ),
                ),
              ),
            if (isSelected)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: _primary,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
