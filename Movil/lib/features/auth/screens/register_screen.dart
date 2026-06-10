import 'package:ecoruta/data/costa_rica_locations.dart';
import 'package:ecoruta/features/profile/models/user_model.dart';
import 'package:ecoruta/features/profile/providers/user_provider.dart';
import 'package:ecoruta/core/routes/app_routes.dart';
import 'package:ecoruta/core/services/auth_service.dart';
import 'package:ecoruta/core/widgets/avatar_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla de registro que crea la cuenta inicial y configura preferencias base.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _favoriteActivities = ['Senderismo', 'Ciclismo', 'Running'];

  final AuthService _authService = AuthService();

  int selectedAvatar = 0;
  bool obscurePassword = true;
  bool isLoading = false;
  String selectedFavoriteActivity = 'Senderismo';
  String? selectedProvince;
  CantonDistrictOption? selectedCantonDistrict;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController weightKgController = TextEditingController();
  final TextEditingController heightCmController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  ProvinceLocationData? get _selectedProvinceData {
    final province = selectedProvince;
    if (province == null) return null;

    for (final item in costaRicaLocations) {
      if (item.name == province) return item;
    }
    return null;
  }

  /// Registra al usuario, recupera su perfil y lo deja listo para navegar.
  Future<void> registerUser() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final weightKgText = weightKgController.text.trim().replaceAll(',', '.');
    final heightCmText = heightCmController.text.trim();
    final birthDateText = birthDateController.text.trim();
    final password = passwordController.text.trim();
    final province = selectedProvince;
    final cantonDistrict = selectedCantonDistrict;
    final weightKg = double.tryParse(weightKgText);
    final heightCm = int.tryParse(heightCmText);
    final birthDate = _tryParseBirthDate(birthDateText);

    if (fullName.isEmpty ||
        email.isEmpty ||
        weightKgText.isEmpty ||
        heightCmText.isEmpty ||
        birthDateText.isEmpty ||
        province == null ||
        cantonDistrict == null ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos')),
      );
      return;
    }

    if (weightKg == null || weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un peso valido en kilogramos')),
      );
      return;
    }

    if (heightCm == null || heightCm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una altura valida en centímetros'),
        ),
      );
      return;
    }

    if (birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha de nacimiento valida'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener mínimo 6 caracteres'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userCredential = await _authService.register(
        fullName: fullName,
        email: email,
        address: cantonDistrict.toStoredAddress(province),
        password: password,
        avatarId: selectedAvatar,
        favoriteActivity: selectedFavoriteActivity,
        weightKg: weightKg,
        heightCm: heightCm,
        birthDate: birthDate,
      );
      await _authService.saveRememberedLogin(rememberMe: true, email: email);

      final uid = userCredential.user!.uid;
      final data = await _authService.getUserData(uid);

      if (data != null) {
        final userModel = UserModel.fromMap(data);

        if (!mounted) return;

        Provider.of<UserProvider>(context, listen: false).setUser(userModel);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.shell, (_) => false);
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar usuario';

      if (e.code == 'email-already-in-use') {
        mensaje = 'Ese correo ya esta registrado';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo no tiene un formato valido';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    weightKgController.dispose();
    heightCmController.dispose();
    birthDateController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF012D1D);
    const orangeColor = Color(0xFFFF7043);
    const surfaceColor = Color(0xFFEDEEEF);
    const labelColor = Color(0xFFB8A39A);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ÚNETE A LA EXPEDICIÓN',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comienza tu aventura',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Nombre completo'),
              _buildStyledField(
                controller: fullNameController,
                hint: 'Tu nombre y apellido',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildLabel('Correo electrónico'),
              _buildStyledField(
                controller: emailController,
                hint: 'ejemplo@ecoruta.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildLabel('Peso (kg)'),
              _buildStyledField(
                controller: weightKgController,
                hint: 'Ej. 68.5',
                icon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('Altura (cm)'),
              _buildStyledField(
                controller: heightCmController,
                hint: 'Ej. 172',
                icon: Icons.height_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildLabel('Fecha de nacimiento'),
              _buildStyledField(
                controller: birthDateController,
                hint: 'AAAA-MM-DD',
                icon: Icons.cake_outlined,
                readOnly: true,
                onTap: _selectBirthDate,
              ),
              const SizedBox(height: 16),
              _buildLabel('Provincia'),
              _buildDropdownField<String>(
                value: selectedProvince,
                hint: 'Selecciona una provincia',
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
                    selectedProvince = value;
                    selectedCantonDistrict = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Cantón-Distrito'),
              _buildDropdownField<CantonDistrictOption>(
                value: selectedCantonDistrict,
                hint: selectedProvince == null
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
                onChanged: selectedProvince == null
                    ? null
                    : (value) {
                        setState(() {
                          selectedCantonDistrict = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              _buildLabel('Contraseña'),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Actividad favorita'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _favoriteActivities.map((activity) {
                  final isSelected = selectedFavoriteActivity == activity;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFavoriteActivity = activity;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : surfaceColor,
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
              const SizedBox(height: 24),
              const Text('Selecciona tu avatar'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(AvatarImage.avatarCount, (index) {
                  final isSelected = selectedAvatar == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.green.shade100
                            : surfaceColor,
                        border: Border.all(
                          color: isSelected
                              ? Colors.green.shade700
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: AvatarImage(
                        avatarId: index,
                        size: 56,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registrarse',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
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

  /// Mantiene una jerarquía visual uniforme entre los campos del formulario.
  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: Colors.black54,
      ),
    );
  }

  /// Reutiliza el mismo estilo de entrada en los datos principales del registro.
  Widget _buildStyledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFEDEEEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate =
        _tryParseBirthDate(birthDateController.text) ??
        DateTime(now.year - 18, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate == null) return;

    birthDateController.text =
        '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
  }

  DateTime? _tryParseBirthDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String hint,
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
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFEDEEEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
