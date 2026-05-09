import 'package:ecoruta/data/costa_rica_locations.dart';
import 'package:ecoruta/providers/user_provider.dart';
import 'package:ecoruta/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla para editar los campos básicos del perfil del usuario.
class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  static const _primary = Color(0xFF012D1D);
  static const _surface = Color(0xFFEDEEEF);
  static const _favoriteActivities = ['Senderismo', 'Ciclismo', 'Running'];

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;
  String _selectedActivity = 'Senderismo';
  String? _selectedProvince;
  CantonDistrictOption? _selectedCantonDistrict;

  ProvinceLocationData? get _selectedProvinceData {
    final province = _selectedProvince;
    if (province == null) return null;

    for (final item in costaRicaLocations) {
      if (item.name == province) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _fullNameController.text = user?.fullName ?? '';
    _emailController.text = user?.email ?? '';
    _selectedActivity = _favoriteActivities.contains(user?.favoriteActivity)
        ? user!.favoriteActivity!
        : 'Senderismo';
    _hydrateAddressSelection(user?.address ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _hydrateAddressSelection(String address) {
    final parts = address
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (parts.length < 3) return;

    final province = parts[0];
    final canton = parts[1];
    final district = parts[2];

    ProvinceLocationData? provinceData;
    for (final item in costaRicaLocations) {
      if (item.name == province) {
        provinceData = item;
        break;
      }
    }
    if (provinceData == null) return;

    CantonDistrictOption? selectedOption;
    for (final option in provinceData.cantonDistricts) {
      if (option.canton == canton && option.district == district) {
        selectedOption = option;
        break;
      }
    }

    _selectedProvince = provinceData.name;
    _selectedCantonDistrict = selectedOption;
  }

  /// Guarda los cambios del perfil y sincroniza el estado local.
  Future<void> _saveProfile() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final user = provider.user;

    if (user == null) return;

    final fullName = _fullNameController.text.trim();
    final province = _selectedProvince;
    final cantonDistrict = _selectedCantonDistrict;

    if (fullName.isEmpty || province == null || cantonDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos requeridos')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await AuthService().updateProfile(
        fullName: fullName,
        address: cantonDistrict.toStoredAddress(province),
        favoriteActivity: _selectedActivity,
      );

      provider.setUser(
        user.copyWith(
          fullName: fullName,
          address: cantonDistrict.toStoredAddress(province),
          favoriteActivity: _selectedActivity,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la cuenta: $e')),
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
    Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _primary,
        title: const Text(
          'Editar cuenta',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actualiza tus datos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aqui puedes cambiar tu nombre, ubicacion y actividad favorita. El correo y el avatar se administran por separado.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Nombre completo'),
              _buildStyledField(
                controller: _fullNameController,
                hintText: 'Tu nombre y apellido',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildLabel('Correo electronico'),
              _buildDisabledField(),
              const SizedBox(height: 16),
              _buildLabel('Provincia'),
              _buildDropdownField<String>(
                value: _selectedProvince,
                hintText: 'Selecciona una provincia',
                icon: Icons.map_outlined,
                items: costaRicaLocations
                    .map(
                      (province) => DropdownMenuItem<String>(
                        value: province.name,
                        child: Text(province.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedProvince = value;
                    _selectedCantonDistrict = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Canton-Distrito'),
              _buildDropdownField<CantonDistrictOption>(
                value: _selectedCantonDistrict,
                hintText: _selectedProvince == null
                    ? 'Selecciona primero una provincia'
                    : 'Selecciona canton y distrito',
                icon: Icons.location_on_outlined,
                items: (_selectedProvinceData?.cantonDistricts ?? const [])
                    .map(
                      (option) => DropdownMenuItem<CantonDistrictOption>(
                        value: option,
                        child: Text(
                          option.displayLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _selectedProvince == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCantonDistrict = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              _buildLabel('Actividad favorita'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _favoriteActivities.map((activity) {
                  final isSelected = _selectedActivity == activity;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedActivity = activity;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _primary : _surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        activity,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
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
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
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

  /// Presenta la etiqueta descriptiva de cada grupo del formulario.
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: Colors.black54,
        ),
      ),
    );
  }

  /// Construye campos editables con el estilo visual del módulo de perfil.
  Widget _buildStyledField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String hintText,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Muestra el correo como referencia sin permitir su edición directa.
  Widget _buildDisabledField() {
    return TextField(
      enabled: false,
      controller: _emailController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: const Color(0xFFE6E8EA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
