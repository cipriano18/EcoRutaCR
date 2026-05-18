import 'package:flutter/material.dart';

import '../../shared/dashboard_mock_ui.dart';
import '../models/report_models.dart';

final dashboardReportConfigs = {
  DashboardReportType.users: DashboardReportConfig(
    title: 'Reporte de usuarios',
    shortLabel: 'Usuarios',
    description:
        'Seguimiento visual de usuarios registrados, usuarios activos, crecimiento mensual y altas recientes dentro de EcoRutaCR.',
    icon: Icons.people_alt_outlined,
    metrics: const [
      DashboardReportMetric(
        title: 'Total de registros',
        value: '2,450',
        changeLabel: '+132 este mes',
        icon: Icons.people_alt_outlined,
        accentColor: dashboardBrandGreen,
      ),
      DashboardReportMetric(
        title: 'Usuarios activos',
        value: '1,984',
        changeLabel: '81% actividad',
        icon: Icons.person_search_outlined,
        accentColor: dashboardSoftGreen,
      ),
      DashboardReportMetric(
        title: 'Crecimiento mensual',
        value: '12.6%',
        changeLabel: 'Tendencia positiva',
        icon: Icons.trending_up_rounded,
        accentColor: dashboardAccentOrange,
      ),
      DashboardReportMetric(
        title: 'Últimos registros',
        value: '48',
        changeLabel: 'Últimos 7 días',
        icon: Icons.schedule_outlined,
        accentColor: dashboardSupportGreen,
      ),
    ],
    filters: [
      DashboardReportFilter(label: 'Todos', matches: matchAll),
      DashboardReportFilter(label: 'Activos', matches: matchesActivo),
      DashboardReportFilter(label: 'Pendientes', matches: matchesPendiente),
      DashboardReportFilter(label: 'Recientes', matches: matchesRecent),
    ],
    primaryColumnLabel: 'Usuario',
    secondaryColumnLabel: 'Correo',
    detailColumnLabel: 'Actividad',
    activityColumnLabel: 'Último acceso',
    showStatusColumn: false,
    rows: const [
      DashboardReportRow(
        primary: 'Andrea Solis',
        secondary: 'andrea@ecoruta.app',
        detail: 'Ruta Norte',
        status: 'Activo',
        activity: 'Hace 8 min',
        actionLabel: 'Ver perfil',
      ),
      DashboardReportRow(
        primary: 'Jorge Mora',
        secondary: 'jorge@ecoruta.app',
        detail: 'Registro pendiente',
        status: 'Pendiente',
        activity: 'Hace 1 h',
        actionLabel: 'Revisar',
      ),
      DashboardReportRow(
        primary: 'Karla Ruiz',
        secondary: 'karla@ecoruta.app',
        detail: 'Zona Central',
        status: 'Activo',
        activity: 'Hace 3 h',
        actionLabel: 'Ver perfil',
      ),
      DashboardReportRow(
        primary: 'Mario Chacón',
        secondary: 'mario@ecoruta.app',
        detail: 'Alta reciente',
        status: 'Activo',
        activity: 'Hace 5 h',
        actionLabel: 'Ver perfil',
      ),
      DashboardReportRow(
        primary: 'Laura Araya',
        secondary: 'laura@ecoruta.app',
        detail: 'Validación documental',
        status: 'Pendiente',
        activity: 'Hace 1 dia',
        actionLabel: 'Revisar',
      ),
      DashboardReportRow(
        primary: 'Sofia Cordero',
        secondary: 'sofia@ecoruta.app',
        detail: 'Uso recurrente',
        status: 'Activo',
        activity: 'Hace 2 días',
        actionLabel: 'Ver perfil',
      ),
    ],
    asideTitle: 'Lecturas de usuarios',
    asideSubtitle:
        'Indicadores complementarios sobre recurrencia, adopción y comportamiento reciente.',
    timeline: const [
      DashboardActivityItem(
        title: 'Nuevo usuario validado',
        detail:
            'Se completo el alta de una cuenta desde la ruta pública norte.',
        timeLabel: 'Hace 9 min',
        icon: Icons.person_add_alt_1_outlined,
        accentColor: dashboardSoftGreen,
      ),
      DashboardActivityItem(
        title: 'Pico de actividad',
        detail: 'La franja de 9:00 AM reporto el mayor acceso del dia.',
        timeLabel: 'Hace 48 min',
        icon: Icons.query_stats_outlined,
        accentColor: dashboardBrandGreen,
      ),
    ],
    highlights: const [
      ('Region más activa', 'San Jose Centro', dashboardSoftGreen),
      ('Perfil más común', 'Usuario recurrente', dashboardBrandGreen),
      ('Canal de ingreso', 'Registro web', dashboardAccentOrange),
    ],
  ),
  DashboardReportType.sponsors: DashboardReportConfig(
    title: 'Reporte de patrocinadores',
    shortLabel: 'Patrocinadores',
    description:
        'Resumen ejecutivo de patrocinadores activos, categorías, campañas vigentes y relaciones comerciales recientes.',
    icon: Icons.handshake_outlined,
    metrics: const [
      DashboardReportMetric(
        title: 'Patrocinadores activos',
        value: '128',
        changeLabel: '94% operativos',
        icon: Icons.handshake_outlined,
        accentColor: dashboardSoftGreen,
      ),
      DashboardReportMetric(
        title: 'Categorías',
        value: '14',
        changeLabel: 'Comercio y movilidad',
        icon: Icons.category_outlined,
        accentColor: dashboardBrandGreen,
      ),
      DashboardReportMetric(
        title: 'Campañas activas',
        value: '74',
        changeLabel: '+9 esta semana',
        icon: Icons.campaign_outlined,
        accentColor: dashboardAccentOrange,
      ),
      DashboardReportMetric(
        title: 'Patrocinadores recientes',
        value: '11',
        changeLabel: 'Últimos 30 días',
        icon: Icons.new_releases_outlined,
        accentColor: dashboardSupportGreen,
      ),
    ],
    filters: [
      DashboardReportFilter(label: 'Todos', matches: matchAll),
      DashboardReportFilter(label: 'Activos', matches: matchesActivo),
      DashboardReportFilter(
        label: 'Categoría',
        matches: matchesMovilidadOrRetail,
      ),
      DashboardReportFilter(label: 'Recientes', matches: matchesRecent),
    ],
    primaryColumnLabel: 'Patrocinador',
    secondaryColumnLabel: 'Categoría',
    detailColumnLabel: 'Campañas',
    activityColumnLabel: 'Actividad',
    showStatusColumn: true,
    rows: const [
      DashboardReportRow(
        primary: 'Verde Urbano',
        secondary: 'Movilidad sostenible',
        detail: '8 campañas',
        status: 'Activo',
        activity: 'Hace 20 min',
        actionLabel: 'Ver ficha',
      ),
      DashboardReportRow(
        primary: 'Cafe Ruta Viva',
        secondary: 'Alimentos',
        detail: '3 campañas',
        status: 'Revision',
        activity: 'Hace 2 h',
        actionLabel: 'Aprobar',
      ),
      DashboardReportRow(
        primary: 'BioMarket CR',
        secondary: 'Retail',
        detail: '5 campañas',
        status: 'Activo',
        activity: 'Hace 5 h',
        actionLabel: 'Ver ficha',
      ),
      DashboardReportRow(
        primary: 'Eco Wheels',
        secondary: 'Movilidad sostenible',
        detail: '6 campañas',
        status: 'Activo',
        activity: 'Hace 1 día',
        actionLabel: 'Ver ficha',
      ),
      DashboardReportRow(
        primary: 'Ciudad Verde',
        secondary: 'Servicios urbanos',
        detail: '2 campañas',
        status: 'Pendiente',
        activity: 'Hace 2 días',
        actionLabel: 'Revisar',
      ),
    ],
    asideTitle: 'Pulso comercial',
    asideSubtitle:
        'Lecturas institucionales sobre categorías dominantes y dinámica de patrocinio.',
    timeline: const [
      DashboardActivityItem(
        title: 'Campaña renovada',
        detail: 'Verde Urbano amplio su cobertura a 4 zonas nuevas.',
        timeLabel: 'Hace 18 min',
        icon: Icons.campaign_outlined,
        accentColor: dashboardAccentOrange,
      ),
      DashboardActivityItem(
        title: 'Nueva categoría detectada',
        detail: 'Se abrió una línea de patrocinio para servicios urbanos.',
        timeLabel: 'Hace 1 h',
        icon: Icons.category_outlined,
        accentColor: dashboardSoftGreen,
      ),
    ],
    highlights: const [
      ('Categoría líder', 'Movilidad sostenible', dashboardSoftGreen),
      ('Patrocinador destacado', 'Verde Urbano', dashboardBrandGreen),
      ('Cobertura promedio', '5.8 zonas', dashboardAccentOrange),
    ],
  ),
  DashboardReportType.ads: DashboardReportConfig(
    title: 'Reporte de publicidades',
    shortLabel: 'Publicidades',
    description:
        'Seguimiento visual de anuncios activos, pausados, vencidos y sus indicadores simulados de rendimiento.',
    icon: Icons.ads_click_outlined,
    metrics: const [
      DashboardReportMetric(
        title: 'Publicidades activas',
        value: '74',
        changeLabel: '61 en linea',
        icon: Icons.campaign_outlined,
        accentColor: dashboardBrandGreen,
      ),
      DashboardReportMetric(
        title: 'Pausadas',
        value: '12',
        changeLabel: 'Requieren revision',
        icon: Icons.pause_circle_outline_rounded,
        accentColor: dashboardSoftGreen,
      ),
      DashboardReportMetric(
        title: 'Vencidas',
        value: '9',
        changeLabel: 'Pendiente renovación',
        icon: Icons.event_busy_outlined,
        accentColor: dashboardAccentOrange,
      ),
      DashboardReportMetric(
        title: 'Visualizaciones',
        value: '86.2K',
        changeLabel: 'CTR mock 6.1%',
        icon: Icons.visibility_outlined,
        accentColor: dashboardSupportGreen,
      ),
    ],
    filters: [
      DashboardReportFilter(label: 'Todas', matches: matchAll),
      DashboardReportFilter(label: 'Activas', matches: matchesActiva),
      DashboardReportFilter(label: 'Pausadas', matches: matchesPausada),
      DashboardReportFilter(label: 'Vencidas', matches: matchesVencida),
    ],
    primaryColumnLabel: 'Publicidad',
    secondaryColumnLabel: 'Patrocinador',
    detailColumnLabel: 'Impacto',
    activityColumnLabel: 'Actividad',
    showStatusColumn: true,
    rows: const [
      DashboardReportRow(
        primary: 'Campana Ruta Central',
        secondary: 'Verde Urbano',
        detail: '18.4K vistas',
        status: 'Activa',
        activity: 'Hace 14 min',
        actionLabel: 'Analizar',
      ),
      DashboardReportRow(
        primary: 'Temporada costera',
        secondary: 'Cafe Ruta Viva',
        detail: '9.2K vistas',
        status: 'Pausada',
        activity: 'Hace 2 h',
        actionLabel: 'Reactivar',
      ),
      DashboardReportRow(
        primary: 'Movilidad segura',
        secondary: 'Eco Wheels',
        detail: '11.8K vistas',
        status: 'Activa',
        activity: 'Hace 6 h',
        actionLabel: 'Analizar',
      ),
      DashboardReportRow(
        primary: 'Ciudad Verde 360',
        secondary: 'Ciudad Verde',
        detail: '7.1K vistas',
        status: 'Vencida',
        activity: 'Hace 1 dia',
        actionLabel: 'Renovar',
      ),
      DashboardReportRow(
        primary: 'Bosque Circular',
        secondary: 'BioMarket CR',
        detail: '14.6K vistas',
        status: 'Activa',
        activity: 'Hace 2 días',
        actionLabel: 'Analizar',
      ),
    ],
    asideTitle: 'Lecturas de impacto',
    asideSubtitle:
        'Indicadores simulados de alcance, rendimiento y oportunidades de ajuste publicitario.',
    timeline: const [
      DashboardActivityItem(
        title: 'Anuncio reactivado',
        detail:
            'La campaña costera volvió a publicarse con nuevo material visual.',
        timeLabel: 'Hace 22 min',
        icon: Icons.autorenew_rounded,
        accentColor: dashboardSoftGreen,
      ),
      DashboardActivityItem(
        title: 'Pico de visualización',
        detail:
            'Ruta Central concentro el mayor volumen de impresiones del dia.',
        timeLabel: 'Hace 1 h',
        icon: Icons.visibility_outlined,
        accentColor: dashboardBrandGreen,
      ),
    ],
    highlights: const [
      ('Anuncio líder', 'Campana Ruta Central', dashboardSoftGreen),
      ('Mejor CTR', '6.1%', dashboardBrandGreen),
      ('Ajuste sugerido', 'Segmentación horaria', dashboardAccentOrange),
    ],
  ),
  DashboardReportType.publicRoutes: DashboardReportConfig(
    title: 'Reporte de rutas públicas',
    shortLabel: 'Rutas públicas',
    description:
        'Vista institucional de rutas registradas, rutas activas y actividad reciente visible dentro de EcoRutaCR.',
    icon: Icons.route_outlined,
    metrics: const [
      DashboardReportMetric(
        title: 'Rutas registradas',
        value: '56',
        changeLabel: '+4 nuevas',
        icon: Icons.route_outlined,
        accentColor: dashboardBrandGreen,
      ),
      DashboardReportMetric(
        title: 'Ciclismo',
        value: '18',
        changeLabel: 'Rutas visibles',
        icon: Icons.directions_bike_outlined,
        accentColor: dashboardSoftGreen,
      ),
      DashboardReportMetric(
        title: 'Senderismo',
        value: '24',
        changeLabel: 'Rutas visibles',
        icon: Icons.hiking_outlined,
        accentColor: dashboardAccentOrange,
      ),
      DashboardReportMetric(
        title: 'Running',
        value: '14',
        changeLabel: 'Rutas visibles',
        icon: Icons.directions_run_rounded,
        accentColor: dashboardSupportGreen,
      ),
    ],
    filters: [
      DashboardReportFilter(label: 'Todas', matches: matchAll),
      DashboardReportFilter(label: 'Ciclismo', matches: matchesCiclismo),
      DashboardReportFilter(label: 'Senderismo', matches: matchesSenderismo),
      DashboardReportFilter(label: 'Running', matches: matchesRunning),
    ],
    primaryColumnLabel: 'Ruta',
    secondaryColumnLabel: 'Zona',
    detailColumnLabel: 'Tipo',
    activityColumnLabel: 'Actividad',
    showStatusColumn: false,
    rows: const [
      DashboardReportRow(
        primary: 'Ruta Central',
        secondary: 'San Jose',
        detail: '12 puntos',
        status: 'Activa',
        activity: 'Hace 11 min',
        actionLabel: 'Ver mapa',
      ),
      DashboardReportRow(
        primary: 'Ruta Norte',
        secondary: 'Heredia',
        detail: '9 puntos',
        status: 'Activa',
        activity: 'Hace 53 min',
        actionLabel: 'Ver mapa',
      ),
      DashboardReportRow(
        primary: 'Ruta Costera',
        secondary: 'Puntarenas',
        detail: '6 puntos',
        status: 'Revision',
        activity: 'Hace 4 h',
        actionLabel: 'Actualizar',
      ),
      DashboardReportRow(
        primary: 'Ruta Este',
        secondary: 'Cartago',
        detail: '8 puntos',
        status: 'Activa',
        activity: 'Hace 1 dia',
        actionLabel: 'Ver mapa',
      ),
      DashboardReportRow(
        primary: 'Ruta Intercantonal',
        secondary: 'Alajuela',
        detail: '5 puntos',
        status: 'Pendiente',
        activity: 'Hace 2 días',
        actionLabel: 'Revisar',
      ),
    ],
    asideTitle: 'Lecturas de rutas',
    asideSubtitle:
        'Indicadores clave y lectura reciente para rutas públicas visibles.',
    timeline: const [
      DashboardActivityItem(
        title: 'Nuevo punto en ruta',
        detail: 'Ruta Central incorporo un punto de visibilidad adicional.',
        timeLabel: 'Hace 17 min',
        icon: Icons.location_on_outlined,
        accentColor: dashboardSoftGreen,
      ),
      DashboardActivityItem(
        title: 'Zona de alta demanda',
        detail: 'Heredia reporta el mayor crecimiento en uso publico.',
        timeLabel: 'Hace 1 h',
        icon: Icons.public_outlined,
        accentColor: dashboardBrandGreen,
      ),
    ],
    highlights: const [
      ('Ruta con mas km', 'Ruta Central', dashboardSoftGreen),
      ('Cobertura media', '7.4 puntos', dashboardBrandGreen),
      ('Zona en expansion', 'Heredia', dashboardAccentOrange),
    ],
  ),
};

bool matchAll(DashboardReportRow row) => true;
bool matchesActivo(DashboardReportRow row) =>
    row.status.toLowerCase().contains('activo');
bool matchesPendiente(DashboardReportRow row) =>
    row.status.toLowerCase().contains('pendiente');
bool matchesRecent(DashboardReportRow row) =>
    row.activity.contains('min') || row.activity.contains('h');
bool matchesMovilidadOrRetail(DashboardReportRow row) =>
    row.secondary.toLowerCase().contains('movilidad') ||
    row.secondary.toLowerCase().contains('retail');
bool matchesActiva(DashboardReportRow row) =>
    row.status.toLowerCase().contains('activa');
bool matchesPausada(DashboardReportRow row) =>
    row.status.toLowerCase().contains('pausada');
bool matchesVencida(DashboardReportRow row) =>
    row.status.toLowerCase().contains('vencida');
bool matchesSistema(DashboardReportRow row) =>
    row.secondary.toLowerCase().contains('sistema');
bool matchesAdministracion(DashboardReportRow row) =>
    row.secondary.toLowerCase().contains('gestion') ||
    row.secondary.toLowerCase().contains('modulo');
bool matchesAlerta(DashboardReportRow row) =>
    row.primary.toLowerCase().contains('alerta') ||
    row.status.toLowerCase().contains('pendiente');
bool matchesSenderismo(DashboardReportRow row) =>
    row.detail.toLowerCase().contains('senderismo');
bool matchesCiclismo(DashboardReportRow row) =>
    row.detail.toLowerCase().contains('ciclismo');
bool matchesRunning(DashboardReportRow row) =>
    row.detail.toLowerCase().contains('running');
