import 'package:ecoruta/data/costa_rica_locations.dart';
import 'package:ecoruta/models/user_model.dart';
import 'package:ecoruta/providers/user_provider.dart';
import 'package:ecoruta/routes/app_routes.dart';
import 'package:ecoruta/services/auth_service.dart';
import 'package:ecoruta/widgets/avatar_image.dart';
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
    final password = passwordController.text.trim();
    final province = selectedProvince;
    final cantonDistrict = selectedCantonDistrict;

    if (fullName.isEmpty ||
        email.isEmpty ||
        province == null ||
        cantonDistrict == null ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos')),
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

      Navigator.pushReplacementNamed(context, AppRoutes.shell);
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar usuario';

      if (e.code == 'email-already-in-use') {
        mensaje = 'Ese correo ya esta registrado';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo no tiene un formato valido';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy debil';
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
                'UNETE A LA EXPEDICION',
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
              _buildLabel('Correo electronico'),
              _buildStyledField(
                controller: emailController,
                hint: 'ejemplo@ecoruta.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
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
              _buildLabel('Canton-Distrito'),
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
