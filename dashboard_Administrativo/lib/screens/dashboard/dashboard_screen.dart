import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_session_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../services/admin_auth_service.dart';
import '../../widgets/admin/admin_list_module.dart';
import '../../widgets/admin/current_admin_profile_dialog.dart';
import '../../widgets/clients/client_list_module.dart';
import '../../widgets/sponsors/ads/advertisement_registration_module.dart';
import '../../widgets/sponsors/dashboard/sponsor_management_panels.dart';
import 'home/dashboard_home_section.dart';
import 'public_routes/public_routes_management_section.dart';
import 'reports/dashboard_reports_section.dart';
import 'statistics/dashboard_statistics_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _sidebarWidth = 300;
  static const String homeSectionId = 'home';
  static const String statisticsSectionId = 'statistics';
  static const String reportsSectionId = 'reports';
  static const String publicRoutesManagementSectionId =
      'public-routes-management';
  static const String sponsorsSectionId = 'sponsors';
  static const String clientsSectionId = 'clients';
  static const String adminsSectionId = 'admins';

  static const String reportUsersSubsectionId = 'report-users';
  static const String reportSponsorsSubsectionId = 'report-sponsors';
  static const String reportAdsSubsectionId = 'report-ads';
  static const String reportRoutesSubsectionId = 'report-routes';

  static const String sponsorRegisterSubsectionId = 'sponsor-register';
  static const String sponsorAdsSubsectionId = 'sponsor-ads';
  static const String sponsorMapSubsectionId = 'sponsor-map';

  late final List<_AdminSection> _sections = [
    const _AdminSection(
      id: homeSectionId,
      title: 'Inicio',
      icon: Icons.space_dashboard_outlined,
      summary:
          'Vista principal del panel con indicadores generales, estado operativo y actividad reciente.',
    ),
    const _AdminSection(
      id: statisticsSectionId,
      title: 'Estadisticas',
      icon: Icons.bar_chart_rounded,
      summary:
          'Vista analitica con graficos administrativos y comparativos operativos del sistema.',
    ),
    const _AdminSection(
      id: reportsSectionId,
      title: 'Reportes',
      icon: Icons.assessment_outlined,
      summary:
          'Modulo visual para seguimiento institucional, tablas administrativas y reportes simulados del ecosistema.',
      subsections: [
        _AdminSubsection(
          id: reportUsersSubsectionId,
          title: 'Reporte de usuarios',
          description:
              'Seguimiento de usuarios registrados, activos, crecimiento y ultimos movimientos.',
          icon: Icons.people_alt_outlined,
        ),
        _AdminSubsection(
          id: reportSponsorsSubsectionId,
          title: 'Reporte de patrocinadores',
          description:
              'Vista comercial de patrocinadores activos, categorias y campanas vigentes.',
          icon: Icons.handshake_outlined,
        ),
        _AdminSubsection(
          id: reportAdsSubsectionId,
          title: 'Reporte de publicidades',
          description:
              'Control visual de publicidades activas, pausadas, vencidas y su rendimiento.',
          icon: Icons.ads_click_outlined,
        ),
        _AdminSubsection(
          id: reportRoutesSubsectionId,
          title: 'Reporte de rutas publicas',
          description:
              'Seguimiento institucional de rutas, zonas mas utilizadas y actividad geografica.',
          icon: Icons.route_outlined,
        ),
      ],
    ),
    const _AdminSection(
      id: publicRoutesManagementSectionId,
      title: 'Manejo de rutas publicas',
      icon: Icons.alt_route_rounded,
      summary:
          'Administracion visual de rutas publicas creadas desde la app movil con filtros, edicion simple y eliminacion controlada.',
    ),
    const _AdminSection(
      id: sponsorsSectionId,
      title: 'Manejo de patrocinadores',
      icon: Icons.handshake_outlined,
      summary:
          'Registra aliados, administra publicidades y prepara los puntos donde apareceran sus anuncios.',
      subsections: [
        _AdminSubsection(
          id: sponsorRegisterSubsectionId,
          title: 'Registrar patrocinadores',
          description:
              'Formulario base para alta de patrocinadores y datos de contacto.',
          icon: Icons.person_add_alt_1_outlined,
        ),
        _AdminSubsection(
          id: sponsorAdsSubsectionId,
          title: 'Registrar publicidades',
          description:
              'Gestion de materiales visuales, copys y anuncios activos por patrocinador.',
          icon: Icons.campaign_outlined,
        ),
        _AdminSubsection(
          id: sponsorMapSubsectionId,
          title: 'Puntos en mapa',
          description:
              'Modulo previsto para ubicar anuncios sobre OpenStreetMap.',
          icon: Icons.map_outlined,
        ),
      ],
    ),
    const _AdminSection(
      id: clientsSectionId,
      title: 'Manejo de clientes',
      icon: Icons.groups_2_outlined,
      summary:
          'Consulta, ordena y administra la base de clientes conectada al proyecto principal.',
    ),
    const _AdminSection(
      id: adminsSectionId,
      title: 'Manejo de administradores',
      icon: Icons.admin_panel_settings_outlined,
      summary:
          'Controla accesos internos, roles administrativos y seguimiento del equipo.',
    ),
  ];

  String _selectedSectionId = homeSectionId;
  String _selectedSubsectionId = sponsorRegisterSubsectionId;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AdminSessionProvider>();
    final admin = session.admin;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _DashboardHeader(
              onLogout: () async {
                await context.read<AdminAuthService>().logout();
              },
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 980;

                  if (isCompact) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SidebarCard(
                            sections: _sections,
                            selectedSectionId: _selectedSectionId,
                            selectedSubsectionId: _selectedSubsectionId,
                            adminName: admin?.name ?? 'Administrador',
                            adminRole: admin?.role ?? 'admin',
                            adminEmail: admin?.email ?? '-',
                            onSectionTap: _selectSection,
                            onSubsectionTap: _selectSubsection,
                          ),
                          const SizedBox(height: 20),
                          _DashboardContent(
                            section: _selectedSection,
                            subsection: _selectedSubsection,
                          ),
                        ],
                      ),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
                        child: SizedBox(
                          width: _sidebarWidth,
                          child: _SidebarCard(
                            fillHeight: true,
                            sections: _sections,
                            selectedSectionId: _selectedSectionId,
                            selectedSubsectionId: _selectedSubsectionId,
                            adminName: admin?.name ?? 'Administrador',
                            adminRole: admin?.role ?? 'admin',
                            adminEmail: admin?.email ?? '-',
                            onSectionTap: _selectSection,
                            onSubsectionTap: _selectSubsection,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 20, 24, 28),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: _resolveContentMaxWidth(
                                  constraints.maxWidth,
                                ),
                              ),
                              child: _DashboardContent(
                                section: _selectedSection,
                                subsection: _selectedSubsection,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _AdminSection get _selectedSection {
    return _sections.firstWhere((section) => section.id == _selectedSectionId);
  }

  _AdminSubsection? get _selectedSubsection {
    final section = _selectedSection;
    if (section.subsections.isEmpty) {
      return null;
    }

    return section.subsections.firstWhere(
      (subsection) => subsection.id == _selectedSubsectionId,
      orElse: () => section.subsections.first,
    );
  }

  void _selectSection(String sectionId) {
    final section = _sections.firstWhere((item) => item.id == sectionId);
    setState(() {
      _selectedSectionId = sectionId;
      if (section.subsections.isNotEmpty) {
        _selectedSubsectionId = section.subsections.first.id;
      }
    });
  }

  void _selectSubsection(String sectionId, String subsectionId) {
    setState(() {
      _selectedSectionId = sectionId;
      _selectedSubsectionId = subsectionId;
    });
  }

  double _resolveContentMaxWidth(double viewportWidth) {
    final availableWidth = viewportWidth - _sidebarWidth - 88;

    if (viewportWidth >= 1900) {
      return availableWidth.clamp(0, 1420).toDouble();
    }

    if (viewportWidth >= 1600) {
      return availableWidth.clamp(0, 1320).toDouble();
    }

    if (viewportWidth >= 1300) {
      return availableWidth.clamp(0, 1180).toDouble();
    }

    return availableWidth.clamp(0, 1040).toDouble();
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PANEL ADMINISTRATIVO',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF4EAC7F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'EcoRutaCR',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const Spacer(),
          const _ThemeModeToggle(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              await onLogout();
            },
            tooltip: 'Cerrar sesion',
            icon: Icon(
              Icons.logout_rounded,
              color: isDark ? const Color(0xFFE8F3EE) : const Color(0xFF012D1D),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeToggle extends StatelessWidget {
  const _ThemeModeToggle();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeModeProvider>();
    final isDark = themeMode.isDarkMode;

    return Tooltip(
      message: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      child: GestureDetector(
        onTap: () => context.read<ThemeModeProvider>().toggleTheme(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 68,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF050606) : const Color(0xFF0B0B0B),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? const Color(0xFF274137) : const Color(0xFF0B0B0B),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.dark_mode_outlined,
                  size: 18,
                  color: isDark ? Colors.white : const Color(0xFFE8E8E8),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                alignment: isDark
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarCard extends StatelessWidget {
  const _SidebarCard({
    this.fillHeight = false,
    required this.sections,
    required this.selectedSectionId,
    required this.selectedSubsectionId,
    required this.adminName,
    required this.adminRole,
    required this.adminEmail,
    required this.onSectionTap,
    required this.onSubsectionTap,
  });

  final bool fillHeight;
  final List<_AdminSection> sections;
  final String selectedSectionId;
  final String selectedSubsectionId;
  final String adminName;
  final String adminRole;
  final String adminEmail;
  final ValueChanged<String> onSectionTap;
  final void Function(String sectionId, String subsectionId) onSubsectionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: fillHeight ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF012D1D),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Navegacion del panel',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (fillHeight)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections
                      .map(
                        (section) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SidebarSectionTile(
                            section: section,
                            isSelected: section.id == selectedSectionId,
                            selectedSubsectionId: selectedSubsectionId,
                            onSectionTap: () => onSectionTap(section.id),
                            onSubsectionTap: (subsectionId) =>
                                onSubsectionTap(section.id, subsectionId),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            )
          else
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SidebarSectionTile(
                  section: section,
                  isSelected: section.id == selectedSectionId,
                  selectedSubsectionId: selectedSubsectionId,
                  onSectionTap: () => onSectionTap(section.id),
                  onSubsectionTap: (subsectionId) =>
                      onSubsectionTap(section.id, subsectionId),
                ),
              ),
            ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => CurrentAdminProfileDialog(
                  initialName: adminName,
                  initialEmail: adminEmail,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFC1ECD4),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adminRole.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: const Color(0xFFA5D0B9)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adminEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFFC1ECD4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionTile extends StatelessWidget {
  const _SidebarSectionTile({
    required this.section,
    required this.isSelected,
    required this.selectedSubsectionId,
    required this.onSectionTap,
    required this.onSubsectionTap,
  });

  final _AdminSection section;
  final bool isSelected;
  final String selectedSubsectionId;
  final VoidCallback onSectionTap;
  final ValueChanged<String> onSubsectionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1B4332) : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onSectionTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      section.icon,
                      color: isSelected
                          ? const Color(0xFFFF7043)
                          : const Color(0xFFC1ECD4),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected && section.subsections.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...section.subsections.map(
                (subsection) => Padding(
                  padding: const EdgeInsets.only(left: 18, top: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSubsectionTap(subsection.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: subsection.id == selectedSubsectionId
                            ? const Color(0xFFFF7043)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(subsection.icon, size: 18, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              subsection.title,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.section, required this.subsection});

  final _AdminSection section;
  final _AdminSubsection? subsection;

  @override
  Widget build(BuildContext context) {
    final displayTitle = _resolveDisplayTitle();
    final displayDescription = _resolveDisplayDescription();

    if (section.id == _DashboardScreenState.homeSectionId) {
      return const DashboardHomeSection();
    }

    if (section.id == _DashboardScreenState.statisticsSectionId) {
      return const DashboardStatisticsSection();
    }

    if (section.id == _DashboardScreenState.reportsSectionId) {
      return _ReportsModule(subsection: subsection);
    }

    if (section.id == _DashboardScreenState.publicRoutesManagementSectionId) {
      return const PublicRoutesManagementSection();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 10),
          Text(
            displayDescription,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _buildSectionBody(context),
        ],
      ),
    );
  }

  String _resolveDisplayTitle() {
    if (section.id == _DashboardScreenState.sponsorsSectionId &&
        subsection?.id == _DashboardScreenState.sponsorRegisterSubsectionId) {
      return 'Registro de patrocinador';
    }

    if (section.id == _DashboardScreenState.sponsorsSectionId &&
        subsection?.id == _DashboardScreenState.sponsorAdsSubsectionId) {
      return 'Mapa y configuracion de publicidades';
    }

    return section.title;
  }

  String _resolveDisplayDescription() {
    if (section.id == _DashboardScreenState.sponsorsSectionId &&
        subsection?.id == _DashboardScreenState.sponsorRegisterSubsectionId) {
      return 'Completa los datos principales.';
    }

    return subsection?.description ?? section.summary;
  }

  Widget _buildSectionBody(BuildContext context) {
    if (section.id == _DashboardScreenState.sponsorsSectionId) {
      return _SponsorsModule(subsection: subsection);
    }

    if (section.id == _DashboardScreenState.clientsSectionId) {
      return const ClientListModule();
    }

    if (section.id == _DashboardScreenState.adminsSectionId) {
      return const AdminListModule();
    }

    return const SponsorModulePlaceholder(
      title: 'Modulo no disponible',
      description: 'Esta seccion todavia no tiene contenido asignado.',
      accentColor: Color(0xFFFF7043),
      bullets: ['Contenido pendiente'],
    );
  }
}

class _ReportsModule extends StatelessWidget {
  const _ReportsModule({required this.subsection});

  final _AdminSubsection? subsection;

  @override
  Widget build(BuildContext context) {
    final currentId = subsection?.id;

    if (currentId == _DashboardScreenState.reportSponsorsSubsectionId) {
      return const DashboardReportsSection(
        reportType: DashboardReportType.sponsors,
      );
    }

    if (currentId == _DashboardScreenState.reportAdsSubsectionId) {
      return const DashboardReportsSection(reportType: DashboardReportType.ads);
    }

    if (currentId == _DashboardScreenState.reportRoutesSubsectionId) {
      return const DashboardReportsSection(
        reportType: DashboardReportType.publicRoutes,
      );
    }

    return const DashboardReportsSection(reportType: DashboardReportType.users);
  }
}

class _SponsorsModule extends StatelessWidget {
  const _SponsorsModule({required this.subsection});

  final _AdminSubsection? subsection;

  @override
  Widget build(BuildContext context) {
    final currentId = subsection?.id;

    if (currentId == _DashboardScreenState.sponsorAdsSubsectionId) {
      return const AdvertisementRegistrationModule();
    }

    if (currentId == _DashboardScreenState.sponsorMapSubsectionId) {
      return const SponsorMapModulePreview();
    }

    return const SponsorRegisterPreview();
  }
}

class _AdminSection {
  const _AdminSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.summary,
    this.subsections = const [],
  });

  final String id;
  final String title;
  final IconData icon;
  final String summary;
  final List<_AdminSubsection> subsections;
}

class _AdminSubsection {
  const _AdminSubsection({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
}
