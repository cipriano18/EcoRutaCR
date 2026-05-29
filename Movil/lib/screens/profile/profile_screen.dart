import 'package:ecoruta/models/user_model.dart';
import 'package:ecoruta/providers/user_provider.dart';
import 'package:ecoruta/screens/home/home_screen.dart';
import 'package:ecoruta/screens/profile/avatar_picker_screen.dart';
import 'package:ecoruta/screens/profile/change_password_screen.dart';
import 'package:ecoruta/screens/profile/delete_account_screen.dart';
import 'package:ecoruta/screens/profile/edit_account_screen.dart';
import 'package:ecoruta/screens/profile/user_rank_screen.dart';
import 'package:ecoruta/services/auth_service.dart';
import 'package:ecoruta/widgets/avatar_image.dart';
import 'package:ecoruta/widgets/confirm_dialog.dart';
import 'package:ecoruta/widgets/streak_status_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla principal del perfil con resumen, progreso y acciones.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const primary = Color(0xFF012D1D);
  static const primaryContainer = Color(0xFF1B4332);
  static const surface = Color(0xFFF8F9FA);
  static const surfaceLow = Color(0xFFF3F4F5);
  static const surfaceContainer = Color(0xFFEDEEEF);
  static const secondary = Color(0xFF2C694E);
  static const error = Color(0xFFBA1A1A);

  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> _openAvatarPicker(int avatarId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AvatarPickerScreen(initialAvatarId: avatarId),
      ),
    );
  }

  /// Carga el perfil actual desde Firebase para refrescar la vista.
  Future<void> loadProfile() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final userProfile = await AuthService().getCurrentUserProfile();

    if (userProfile != null) {
      provider.setUser(userProfile);
    }

    if (mounted) {
      setState(() {
        isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final fullName = user?.fullName ?? 'Usuario';
    final favoriteActivity = user?.favoriteActivity?.trim().isNotEmpty == true
        ? user!.favoriteActivity!
        : 'Ninguna';
    final completedRoutes = user?.completedRoutes ?? 0;
    final totalKilometers = user?.kmCounter ?? 0;
    final streakWeeks = user?.streakWeeks ?? 0;
    final healthInference = user?.healthInference;
    final currentRank = getUserRank(totalKilometers);
    final currentRankPalette = getUserRankPalette(totalKilometers);
    final avatarId = user?.avatarId ?? 0;
    final safeAvatarId = AvatarImage.isValidAvatarId(avatarId) ? avatarId : 0;

    if (isLoadingProfile) {
      return const Scaffold(
        backgroundColor: surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          children: [
            _profileHeader(
              fullName: fullName,
              avatarId: safeAvatarId,
              currentRankTitle: currentRank.title,
              currentRankPalette: currentRankPalette,
              totalKilometers: totalKilometers,
              streakWeeks: streakWeeks,
            ),
            const SizedBox(height: 36),
            _statsGrid(
              favoriteActivity: favoriteActivity,
              completedRoutes: completedRoutes,
              totalKilometers: totalKilometers,
            ),
            const SizedBox(height: 16),
            _healthInsightsCard(user: user, healthInference: healthInference),
            const SizedBox(height: 16),
            StreakStatusCard(streakWeeks: streakWeeks),
            const SizedBox(height: 34),
            _settingsButton(),
            const SizedBox(height: 14),
            _changePasswordButton(),
            const SizedBox(height: 14),
            _deleteAccountButton(),
            const SizedBox(height: 14),
            _logoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader({
    required String fullName,
    required int avatarId,
    required String currentRankTitle,
    required UserRankPalette currentRankPalette,
    required num totalKilometers,
    required int streakWeeks,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: surfaceContainer,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: AvatarImage(
                  avatarId: avatarId,
                  size: 128,
                  backgroundColor: surfaceContainer,
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: GestureDetector(
                onTap: () => _openAvatarPicker(avatarId),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          fullName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserRankScreen(kmCounter: totalKilometers),
                  ),
                );
              },
              child: _profileBadge(
                icon: Icons.military_tech_rounded,
                label: currentRankTitle,
                iconColor: currentRankPalette.iconColor,
                textColor: currentRankPalette.textColor,
                backgroundColor: currentRankPalette.backgroundColor,
              ),
            ),
            _profileBadge(
              icon: Icons.local_fire_department_rounded,
              label: streakWeeks == 1 ? '1 semana' : '$streakWeeks semanas',
              iconColor: getStreakPalette(streakWeeks).iconColor,
              textColor: getStreakPalette(streakWeeks).textColor,
              backgroundColor: getStreakPalette(streakWeeks).backgroundColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _profileBadge({
    required IconData icon,
    required String label,
    Color iconColor = secondary,
    Color textColor = secondary,
    Color backgroundColor = surfaceLow,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid({
    required String favoriteActivity,
    required int completedRoutes,
    required num totalKilometers,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: primaryContainer,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL KILOMETROS',
                    style: TextStyle(
                      color: Color(0xFF86AF99),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatKmCounter(totalKilometers),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 7),
                        child: Text(
                          'KM',
                          style: TextStyle(
                            color: Color(0xFF86AF99),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.10),
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.timeline, color: Colors.white, size: 34),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _smallStatCard(
                icon: Icons.route,
                value: completedRoutes.toString(),
                label: 'Rutas completadas',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _smallStatCard(
                icon: Icons.favorite,
                value: favoriteActivity,
                label: 'Actividad favorita',
                smallerValue: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _smallStatCard({
    required IconData icon,
    required String value,
    required String label,
    bool smallerValue = false,
  }) {
    return Container(
      height: 146,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: secondary, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: smallerValue ? 18 : 38,
                  fontWeight: FontWeight.w900,
                  color: primary,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                  letterSpacing: 1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthInsightsCard({
    required UserModel? user,
    required dynamic healthInference,
  }) {
    final bmi = healthInference?.bmi;
    final bmiCategory = healthInference?.bmiCategory;
    final activityLevel = healthInference?.activityLevel;
    final summary = _buildHealthSummary(
      user: user,
      bmiCategory: bmiCategory,
      activityLevel: activityLevel,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INSIGHTS DE SALUD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Indicadores orientativos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Estos datos sirven como referencia general y no sustituyen evaluacion medica.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _smallStatCard(
                  icon: Icons.monitor_weight_outlined,
                  value: bmi == null ? '--' : bmi.toStringAsFixed(1),
                  label: 'IMC',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _smallStatCard(
                  icon: Icons.fitness_center_rounded,
                  value: _labelForActivityLevel(activityLevel),
                  label: 'Actividad',
                  smallerValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summary.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _labelForActivityLevel(String? value) {
    switch (value) {
      case 'high':
        return 'Alta';
      case 'good':
        return 'Buena';
      case 'moderate':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return 'Pendiente';
    }
  }

  _HealthSummary _buildHealthSummary({
    required UserModel? user,
    required String? bmiCategory,
    required String? activityLevel,
  }) {
    if (user == null) {
      return const _HealthSummary(
        title: 'Faltan datos para una lectura completa',
        message:
            'Todavia no tenemos suficiente informacion de tu perfil para darte una lectura clara de salud.',
      );
    }

    final hasBodyMetrics = user.weightKg != null && user.heightCm != null;
    final hasWeeklySignals = user.routesPerWeekAvg != null ||
        user.kmPerWeekAvg != null ||
        user.minutesPerWeekAvg != null ||
        user.activityConsistencyScore != null;

    if (!hasBodyMetrics || !hasWeeklySignals) {
      return const _HealthSummary(
        title: 'Faltan datos para una lectura completa',
        message:
            'Completa tu peso, altura y registra mas actividad para darte una lectura mas clara y personalizada.',
      );
    }

    final consistencyScore = user.activityConsistencyScore;
    final hasLowConsistency = consistencyScore != null && consistencyScore < 45;
    final hasStrongConsistency =
        consistencyScore != null && consistencyScore >= 70;
    final isNormalBmi = bmiCategory == 'normal';
    final isRiskBmi = bmiCategory == 'overweight' || bmiCategory == 'obesity';
    final isUnderweight = bmiCategory == 'underweight';

    if ((activityLevel == 'high' || activityLevel == 'good') &&
        isNormalBmi &&
        !hasLowConsistency) {
      return const _HealthSummary(
        title: 'Buen equilibrio general',
        message:
            'Tu actividad reciente y tus indicadores corporales muestran una base positiva y bastante estable.',
      );
    }

    if (activityLevel == 'moderate' ||
        ((activityLevel == 'good' || activityLevel == 'high') &&
            !hasStrongConsistency)) {
      return const _HealthSummary(
        title: 'Actividad en progreso',
        message:
            'Vas construyendo una buena base, pero todavia hace falta mas constancia semanal para consolidar el ritmo.',
      );
    }

    if (activityLevel == 'low' || hasLowConsistency) {
      return const _HealthSummary(
        title: 'Conviene retomar constancia',
        message:
            'Tu actividad reciente es baja o irregular. Recuperar una rutina semanal te dara una lectura mas solida y favorable.',
      );
    }

    if (isRiskBmi && activityLevel != 'high' && activityLevel != 'good') {
      return const _HealthSummary(
        title: 'Actividad en progreso',
        message:
            'Tu perfil muestra margen de mejora en condicion general. Mantener actividad frecuente puede ayudarte a estabilizar estos indicadores.',
      );
    }

    if (isUnderweight) {
      return const _HealthSummary(
        title: 'Lectura para seguir de cerca',
        message:
            'Tus indicadores corporales merecen seguimiento. Mantener actividad y revisar tus habitos puede darte una lectura mas equilibrada.',
      );
    }

    return const _HealthSummary(
      title: 'Lectura general disponible',
      message:
          'Ya contamos con una base de datos util. Seguir registrando actividad nos ayudara a afinar mejor esta lectura.',
    );
  }

  String _formatKmCounter(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  Widget _settingsButton() {
    return _profileActionTile(
      icon: Icons.settings,
      title: 'Ajustes de Cuenta',
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const EditAccountScreen()));
      },
    );
  }

  Widget _changePasswordButton() {
    return _profileActionTile(
      icon: Icons.lock_reset_rounded,
      title: 'Cambiar contraseña',
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
      },
    );
  }

  Widget _logoutButton(BuildContext context) {
    return _profileActionTile(
      icon: Icons.logout_rounded,
      title: 'Cerrar sesion',
      iconColor: error,
      titleColor: error,
      onTap: () async {
        final shouldLogout = await ConfirmDialog.mostrar(
          context,
          titulo: 'Cerrar sesion',
          mensaje:
              'Estas seguro de que quieres cerrar tu sesion actual en EcoRuta?',
          textoConfirmar: 'Cerrar sesion',
        );

        if (!shouldLogout) return;

        await AuthService().logout();

        if (!context.mounted) return;

        Provider.of<UserProvider>(context, listen: false).clear();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      },
    );
  }

  Widget _deleteAccountButton() {
    return _profileActionTile(
      icon: Icons.delete_outline_rounded,
      title: 'Eliminar cuenta',
      iconColor: error,
      titleColor: error,
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DeleteAccountScreen()));
      },
    );
  }

  Widget _profileActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = primary,
    Color titleColor = primary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w900, color: titleColor),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _HealthSummary {
  const _HealthSummary({required this.title, required this.message});

  final String title;
  final String message;
}
