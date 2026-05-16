import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../shared/dashboard_mock_ui.dart';

enum DashboardReportType {
  users,
  sponsors,
  ads,
  activity,
  publicRoutes,
}

class DashboardReportsSection extends StatefulWidget {
  const DashboardReportsSection({required this.reportType, super.key});

  final DashboardReportType reportType;

  @override
  State<DashboardReportsSection> createState() => _DashboardReportsSectionState();
}

class _DashboardReportsSectionState extends State<DashboardReportsSection> {
  static const int _pageSize = 4;

  late final TextEditingController _searchController;
  late String _selectedFilter;
  bool _sortAscending = false;
  int _currentPage = 0;
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;

  _ReportConfig get _config => _reportConfigs[widget.reportType]!;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedFilter = _config.filters.first.label;
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant DashboardReportsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportType != widget.reportType) {
      _selectedFilter = _config.filters.first.label;
      _currentPage = 0;
      _sortAscending = false;
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  List<_ReportRow> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    final selectedFilter = _config.filters.firstWhere(
      (filter) => filter.label == _selectedFilter,
      orElse: () => _config.filters.first,
    );

    final rows = _config.rows.where((row) {
      final matchesFilter = selectedFilter.matches(row);
      final haystack = [
        row.primary,
        row.secondary,
        row.detail,
        row.status,
        row.activity,
      ].join(' ').toLowerCase();
      final matchesQuery = query.isEmpty || haystack.contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    rows.sort((a, b) {
      final comparison = a.primary.toLowerCase().compareTo(b.primary.toLowerCase());
      return _sortAscending ? comparison : -comparison;
    });

    return rows;
  }

  int get _pageCount {
    final total = _filteredRows.length;
    if (total == 0) {
      return 1;
    }
    return (total / _pageSize).ceil();
  }

  List<_ReportRow> get _visibleRows {
    final rows = _filteredRows;
    final start = (_currentPage * _pageSize).clamp(0, rows.length);
    final end = (start + _pageSize).clamp(0, rows.length);
    return rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardHeroCard(
          title: config.title,
          subtitle: config.description,
          badges: [
            DashboardHeroBadge(
              label: 'Inicio / Reportes / ${config.shortLabel}',
              icon: Icons.chevron_right_rounded,
            ),
            DashboardHeroBadge(label: 'Datos mock', icon: config.icon),
          ],
          trailing: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DashboardActionGhostButton(
                label: _isExportingPdf ? 'Exportando PDF...' : 'Exportar PDF',
                icon: Icons.picture_as_pdf_outlined,
                onTap: _isExportingPdf ? null : _exportPdf,
              ),
              DashboardActionGhostButton(
                label: _isExportingExcel ? 'Exportando Excel...' : 'Exportar Excel',
                icon: Icons.table_chart_outlined,
                onTap: _isExportingExcel ? null : _exportExcel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        DashboardMetricGrid(metrics: config.metrics),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final table = _ReportTableCard(
              config: config,
              searchController: _searchController,
              selectedFilter: _selectedFilter,
              sortAscending: _sortAscending,
              visibleRows: _visibleRows,
              filteredCount: _filteredRows.length,
              currentPage: _currentPage,
              pageCount: _pageCount,
              onFilterSelected: _handleFilterSelected,
              onToggleSort: _toggleSort,
              onPreviousPage: _goToPreviousPage,
              onNextPage: _goToNextPage,
              onExportPdf: _isExportingPdf ? null : _exportPdf,
              onExportExcel: _isExportingExcel ? null : _exportExcel,
            );
            final side = _ReportAside(config: config);

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: table),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: side),
                ],
              );
            }

            return Column(
              children: [
                table,
                const SizedBox(height: 20),
                side,
              ],
            );
          },
        ),
      ],
    );
  }

  void _handleSearchChanged() {
    setState(() {
      _currentPage = 0;
    });
  }

  void _handleFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 0;
    });
  }

  void _toggleSort() {
    setState(() {
      _sortAscending = !_sortAscending;
      _currentPage = 0;
    });
  }

  void _goToPreviousPage() {
    if (_currentPage == 0) {
      return;
    }
    setState(() {
      _currentPage -= 1;
    });
  }

  void _goToNextPage() {
    if (_currentPage >= _pageCount - 1) {
      return;
    }
    setState(() {
      _currentPage += 1;
    });
  }

  Future<void> _exportPdf() async {
    setState(() {
      _isExportingPdf = true;
    });

    try {
      final pdf = pw.Document();
      final rows = _filteredRows;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text(
              _config.title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(_config.description),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: [
                _config.primaryColumnLabel,
                _config.secondaryColumnLabel,
                _config.detailColumnLabel,
                'Estado',
                'Actividad',
              ],
              data: rows
                  .map(
                    (row) => [
                      row.primary,
                      row.secondary,
                      row.detail,
                      row.status,
                      row.activity,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF012D1D),
              ),
              cellPadding: const pw.EdgeInsets.all(8),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      await FileSaver.instance.saveFile(
        name: _buildExportName(),
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      _showSnackBar('PDF exportado con datos mock.');
    } catch (error) {
      _showSnackBar('No se pudo exportar el PDF: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  Future<void> _exportExcel() async {
    setState(() {
      _isExportingExcel = true;
    });

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Reporte'];
      sheet.appendRow([
        TextCellValue(_config.primaryColumnLabel),
        TextCellValue(_config.secondaryColumnLabel),
        TextCellValue(_config.detailColumnLabel),
        TextCellValue('Estado'),
        TextCellValue('Actividad'),
      ]);

      for (final row in _filteredRows) {
        sheet.appendRow([
          TextCellValue(row.primary),
          TextCellValue(row.secondary),
          TextCellValue(row.detail),
          TextCellValue(row.status),
          TextCellValue(row.activity),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('No se pudieron generar los bytes del archivo Excel.');
      }

      await FileSaver.instance.saveFile(
        name: _buildExportName(),
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      _showSnackBar('Excel exportado con datos mock.');
    } catch (error) {
      _showSnackBar('No se pudo exportar el Excel: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingExcel = false;
        });
      }
    }
  }

  String _buildExportName() {
    final slug = _config.shortLabel.toLowerCase().replaceAll(' ', '_');
    return 'reporte_${slug}_mock';
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReportFilter {
  const _ReportFilter({required this.label, required this.matches});

  final String label;
  final bool Function(_ReportRow row) matches;
}

class _ReportMetric extends DashboardMetricData {
  const _ReportMetric({
    required super.title,
    required super.value,
    required super.changeLabel,
    required super.icon,
    required super.accentColor,
  });
}

class _ReportRow {
  const _ReportRow({
    required this.primary,
    required this.secondary,
    required this.detail,
    required this.status,
    required this.activity,
    required this.actionLabel,
  });

  final String primary;
  final String secondary;
  final String detail;
  final String status;
  final String activity;
  final String actionLabel;
}

class _ReportConfig {
  const _ReportConfig({
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.metrics,
    required this.filters,
    required this.primaryColumnLabel,
    required this.secondaryColumnLabel,
    required this.detailColumnLabel,
    required this.rows,
    required this.asideTitle,
    required this.asideSubtitle,
    required this.timeline,
    required this.highlights,
  });

  final String title;
  final String shortLabel;
  final String description;
  final IconData icon;
  final List<DashboardMetricData> metrics;
  final List<_ReportFilter> filters;
  final String primaryColumnLabel;
  final String secondaryColumnLabel;
  final String detailColumnLabel;
  final List<_ReportRow> rows;
  final String asideTitle;
  final String asideSubtitle;
  final List<DashboardActivityItem> timeline;
  final List<(String, String, Color)> highlights;
}

final _reportConfigs = {
  DashboardReportType.users: _ReportConfig(
    title: 'Reporte de usuarios',
    shortLabel: 'Usuarios',
    description:
        'Seguimiento visual de usuarios registrados, usuarios activos, crecimiento mensual y altas recientes dentro de EcoRutaCR.',
    icon: Icons.people_alt_outlined,
    metrics: const [
      _ReportMetric(
        title: 'Total de registros',
        value: '2,450',
        changeLabel: '+132 este mes',
        icon: Icons.people_alt_outlined,
        accentColor: dashboardBrandGreen,
      ),
      _ReportMetric(
        title: 'Usuarios activos',
        value: '1,984',
        changeLabel: '81% actividad',
        icon: Icons.person_search_outlined,
        accentColor: dashboardSoftGreen,
      ),
      _ReportMetric(
        title: 'Crecimiento mensual',
        value: '12.6%',
        changeLabel: 'Tendencia positiva',
        icon: Icons.trending_up_rounded,
        accentColor: dashboardAccentOrange,
      ),
      _ReportMetric(
        title: 'Ultimos registros',
        value: '48',
        changeLabel: 'Ultimos 7 dias',
        icon: Icons.schedule_outlined,
        accentColor: dashboardSupportGreen,
      ),
    ],
    filters: [
      _ReportFilter(label: 'Todos', matches: _matchAll),
      _ReportFilter(label: 'Activos', matches: _matchesActivo),
      _ReportFilter(label: 'Pendientes', matches: _matchesPendiente),
      _ReportFilter(label: 'Recientes', matches: _matchesRecent),
    ],
    primaryColumnLabel: 'Usuario',
    secondaryColumnLabel: 'Correo',
    detailColumnLabel: 'Ultimo acceso',
    rows: const [
      _ReportRow(
        primary: 'Andrea Solis',
        secondary: 'andrea@ecoruta.app',
        detail: 'Ruta Norte',
        status: 'Activo',
        activity: 'Hace 8 min',
        actionLabel: 'Ver perfil',
      ),
      _ReportRow(
        primary: 'Jorge Mora',
        secondary: 'jorge@ecoruta.app',
        detail: 'Registro pendiente',
        status: 'Pendiente',
        activity: 'Hace 1 h',
        actionLabel: 'Revisar',
      ),
      _ReportRow(
        primary: 'Karla Ruiz',
        secondary: 'karla@ecoruta.app',
        detail: 'Zona Central',
        status: 'Activo',
        activity: 'Hace 3 h',
        actionLabel: 'Ver perfil',
      ),
      _ReportRow(
        primary: 'Mario Chacon',
        secondary: 'mario@ecoruta.app',
        detail: 'Alta reciente',
        status: 'Activo',
        activity: 'Hace 5 h',
        actionLabel: 'Ver perfil',
      ),
      _ReportRow(
        primary: 'Laura Araya',
        secondary: 'laura@ecoruta.app',
        detail: 'Validacion documental',
        status: 'Pendiente',
        activity: 'Hace 1 dia',
        actionLabel: 'Revisar',
      ),
      _ReportRow(
        primary: 'Sofia Cordero',
        secondary: 'sofia@ecoruta.app',
        detail: 'Uso recurrente',
        status: 'Activo',
        activity: 'Hace 2 dias',
        actionLabel: 'Ver perfil',
      ),
    ],
    asideTitle: 'Lecturas de usuarios',
    asideSubtitle:
        'Indicadores complementarios sobre recurrencia, adopcion y comportamiento reciente.',
    timeline: const [
      DashboardActivityItem(
        title: 'Nuevo usuario validado',
        detail: 'Se completo el alta de una cuenta desde la ruta publica norte.',
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
      ('Region mas activa', 'San Jose Centro', dashboardSoftGreen),
      ('Perfil mas comun', 'Usuario recurrente', dashboardBrandGreen),
      ('Canal de ingreso', 'Registro web', dashboardAccentOrange),
    ],
  ),
  DashboardReportType.sponsors: _ReportConfig(
    title: 'Reporte de patrocinadores',
    shortLabel: 'Patrocinadores',
    description:
        'Resumen ejecutivo de patrocinadores activos, categorias, campanas vigentes y relaciones comerciales recientes.',
    icon: Icons.handshake_outlined,
    metrics: const [
      _ReportMetric(
        title: 'Patrocinadores activos',
        value: '128',
        changeLabel: '94% operativos',
        icon: Icons.handshake_outlined,
        accentColor: dashboardSoftGreen,
      ),
      _ReportMetric(
        title: 'Categorias',
        value: '14',
        changeLabel: 'Comercio y movilidad',
        icon: Icons.category_outlined,
        accentColor: dashboardBrandGreen,
      ),
      _ReportMetric(
        title: 'Campanas activas',
        value: '74',
        changeLabel: '+9 esta semana',
        icon: Icons.campaign_outlined,
        accentColor: dashboardAccentOrange,
      ),
      _ReportMetric(
        title: 'Patrocinadores recientes',
        value: '11',
        changeLabel: 'Ultimos 30 dias',
        icon: Icons.new_releases_outlined,
        accentColor: dashboardSupportGreen,
      ),
    ],
    filters: [
      _ReportFilter(label: 'Todos', matches: _matchAll),
      _ReportFilter(label: 'Activos', matches: _matchesActivo),
      _ReportFilter(label: 'Categoria', matches: _matchesMovilidadOrRetail),
      _ReportFilter(label: 'Recientes', matches: _matchesRecent),
    ],
    primaryColumnLabel: 'Patrocinador',
    secondaryColumnLabel: 'Categoria',
    detailColumnLabel: 'Campanas',
    rows: const [
      _ReportRow(
        primary: 'Verde Urbano',
        secondary: 'Movilidad sostenible',
        detail: '8 campanas',
        status: 'Activo',
        activity: 'Hace 20 min',
        actionLabel: 'Ver ficha',
      ),
      _ReportRow(
        primary: 'Cafe Ruta Viva',
        secondary: 'Alimentos',
        detail: '3 campanas',
        status: 'Revision',
        activity: 'Hace 2 h',
        actionLabel: 'Aprobar',
      ),
      _ReportRow(
        primary: 'BioMarket CR',
        secondary: 'Retail',
        detail: '5 campanas',
        status: 'Activo',
        activity: 'Hace 5 h',
        actionLabel: 'Ver ficha',
      ),
      _ReportRow(
        primary: 'Eco Wheels',
        secondary: 'Movilidad sostenible',
        detail: '6 campanas',
        status: 'Activo',
        activity: 'Hace 1 dia',
        actionLabel: 'Ver ficha',
      ),
      _ReportRow(
        primary: 'Ciudad Verde',
        secondary: 'Servicios urbanos',
        detail: '2 campanas',
        status: 'Pendiente',
        activity: 'Hace 2 dias',
        actionLabel: 'Revisar',
      ),
    ],
    asideTitle: 'Pulso comercial',
    asideSubtitle:
        'Lecturas institucionales sobre categorias dominantes y dinamica de patrocinio.',
    timeline: const [
      DashboardActivityItem(
        title: 'Campana renovada',
        detail: 'Verde Urbano amplio su cobertura a 4 zonas nuevas.',
        timeLabel: 'Hace 18 min',
        icon: Icons.campaign_outlined,
        accentColor: dashboardAccentOrange,
      ),
      DashboardActivityItem(
        title: 'Nueva categoria detectada',
        detail: 'Se abrio una linea de patrocinio para servicios urbanos.',
        timeLabel: 'Hace 1 h',
        icon: Icons.category_outlined,
        accentColor: dashboardSoftGreen,
      ),
    ],
    highlights: const [
      ('Categoria lider', 'Movilidad sostenible', dashboardSoftGreen),
      ('Patrocinador destacado', 'Verde Urbano', dashboardBrandGreen),
      ('Cobertura promedio', '5.8 zonas', dashboardAccentOrange),
    ],
  ),
  DashboardReportType.ads: _ReportConfig(
    title: 'Reporte de publicidades',
    shortLabel: 'Publicidades',
    description:
        'Panel visual para publicidades activas, pausadas, vencidas y metricas simuladas de visualizacion de anuncios.',
    icon: Icons.ads_click_outlined,
    metrics: const [
      _ReportMetric(
        title: 'Publicidades activas',
        value: '74',
        changeLabel: '61 en linea',
        icon: Icons.play_circle_outline_rounded,
        accentColor: dashboardSoftGreen,
      ),
      _ReportMetric(
        title: 'Pausadas',
        value: '12',
        changeLabel: 'Revision interna',
        icon: Icons.pause_circle_outline_rounded,
        accentColor: dashboardBrandGreen,
      ),
      _ReportMetric(
        title: 'Vencidas',
        value: '9',
        changeLabel: 'Pendientes de cierre',
        icon: Icons.timer_off_outlined,
        accentColor: dashboardAccentOrange,
      ),
      _ReportMetric(
        title: 'Visualizaciones mock',
        value: '84.2K',
        changeLabel: '+13% semanal',
        icon: Icons.visibility_outlined,
        accentColor: dashboardSupportGreen,
      ),
    ],
    filters: [
      _ReportFilter(label: 'Todas', matches: _matchAll),
      _ReportFilter(label: 'Activas', matches: _matchesActiva),
      _ReportFilter(label: 'Pausadas', matches: _matchesPausada),
      _ReportFilter(label: 'Vencidas', matches: _matchesVencida),
    ],
    primaryColumnLabel: 'Publicidad',
    secondaryColumnLabel: 'Patrocinador',
    detailColumnLabel: 'Impacto',
    rows: const [
      _ReportRow(
        primary: 'Campana Ruta Centro',
        secondary: 'Verde Urbano',
        detail: '24.6K vistas',
        status: 'Activa',
        activity: 'Hace 6 min',
        actionLabel: 'Analizar',
      ),
      _ReportRow(
        primary: 'Promo Zona Norte',
        secondary: 'BioMarket CR',
        detail: '8.2K vistas',
        status: 'Pausada',
        activity: 'Hace 2 h',
        actionLabel: 'Reactivar',
      ),
      _ReportRow(
        primary: 'Temporada Verde',
        secondary: 'Cafe Ruta Viva',
        detail: '12.1K vistas',
        status: 'Vencida',
        activity: 'Hace 1 dia',
        actionLabel: 'Renovar',
      ),
      _ReportRow(
        primary: 'Corredor Heredia',
        secondary: 'Eco Wheels',
        detail: '15.4K vistas',
        status: 'Activa',
        activity: 'Hace 1 dia',
        actionLabel: 'Analizar',
      ),
      _ReportRow(
        primary: 'Zona Este Promo',
        secondary: 'Ciudad Verde',
        detail: '6.8K vistas',
        status: 'Pausada',
        activity: 'Hace 3 dias',
        actionLabel: 'Revisar',
      ),
    ],
    asideTitle: 'Indicadores de impacto',
    asideSubtitle:
        'Resumen visual de alcance, rendimiento promedio y comportamiento del inventario publicitario.',
    timeline: const [
      DashboardActivityItem(
        title: 'Publicidad pausada',
        detail: 'Se puso en revision una pieza por ajuste de materiales.',
        timeLabel: 'Hace 24 min',
        icon: Icons.pause_circle_outline_rounded,
        accentColor: dashboardBrandGreen,
      ),
      DashboardActivityItem(
        title: 'Nuevo maximo de vistas',
        detail: 'Campana Ruta Centro alcanzo su mejor rendimiento semanal.',
        timeLabel: 'Hace 1 h',
        icon: Icons.visibility_outlined,
        accentColor: dashboardAccentOrange,
      ),
    ],
    highlights: const [
      ('Formato mas usado', 'Banner institucional', dashboardSoftGreen),
      ('Mejor rendimiento', 'Ruta Centro', dashboardBrandGreen),
      ('CTR mock', '6.1%', dashboardAccentOrange),
    ],
  ),
  DashboardReportType.activity: _ReportConfig(
    title: 'Reporte de actividad',
    shortLabel: 'Actividad',
    description:
        'Concentrado de actividad reciente del sistema, movimientos administrativos, registros del panel y eventos internos simulados.',
    icon: Icons.timeline_outlined,
    metrics: const [
      _ReportMetric(
        title: 'Eventos del dia',
        value: '186',
        changeLabel: 'Alta frecuencia',
        icon: Icons.timeline_outlined,
        accentColor: dashboardBrandGreen,
      ),
      _ReportMetric(
        title: 'Movimientos admin',
        value: '42',
        changeLabel: 'Ultimas 24 horas',
        icon: Icons.manage_accounts_outlined,
        accentColor: dashboardSoftGreen,
      ),
      _ReportMetric(
        title: 'Registros recientes',
        value: '73',
        changeLabel: '+11% diario',
        icon: Icons.history_toggle_off_outlined,
        accentColor: dashboardAccentOrange,
      ),
      _ReportMetric(
        title: 'Alertas internas',
        value: '7',
        changeLabel: 'Seguimiento medio',
        icon: Icons.notification_important_outlined,
        accentColor: dashboardSupportGreen,
      ),
    ],
    filters: [
      _ReportFilter(label: 'Todo', matches: _matchAll),
      _ReportFilter(label: 'Sistema', matches: _matchesSistema),
      _ReportFilter(label: 'Administracion', matches: _matchesAdministracion),
      _ReportFilter(label: 'Alertas', matches: _matchesAlerta),
    ],
    primaryColumnLabel: 'Evento',
    secondaryColumnLabel: 'Origen',
    detailColumnLabel: 'Nivel',
    rows: const [
      _ReportRow(
        primary: 'Ajuste de publicidad',
        secondary: 'Modulo de anuncios',
        detail: 'Impacto medio',
        status: 'Completado',
        activity: 'Hace 14 min',
        actionLabel: 'Ver detalle',
      ),
      _ReportRow(
        primary: 'Nuevo administrador',
        secondary: 'Gestion interna',
        detail: 'Impacto alto',
        status: 'Validado',
        activity: 'Hace 39 min',
        actionLabel: 'Auditar',
      ),
      _ReportRow(
        primary: 'Alerta de revision',
        secondary: 'Sistema',
        detail: 'Seguimiento medio',
        status: 'Pendiente',
        activity: 'Hace 2 h',
        actionLabel: 'Revisar',
      ),
      _ReportRow(
        primary: 'Alta de patrocinador',
        secondary: 'Modulo comercial',
        detail: 'Impacto medio',
        status: 'Pendiente',
        activity: 'Hace 3 h',
        actionLabel: 'Revisar',
      ),
      _ReportRow(
        primary: 'Limpieza de registros',
        secondary: 'Sistema',
        detail: 'Baja prioridad',
        status: 'Completado',
        activity: 'Hace 1 dia',
        actionLabel: 'Ver detalle',
      ),
    ],
    asideTitle: 'Timeline del sistema',
    asideSubtitle:
        'Secuencia visual de actividad interna y trazabilidad simulada del panel.',
    timeline: dashboardRecentActivity,
    highlights: const [
      ('Hora mas activa', '09:00 AM', dashboardSoftGreen),
      ('Modulo dominante', 'Publicidades', dashboardBrandGreen),
      ('Nivel de alertas', 'Moderado', dashboardAccentOrange),
    ],
  ),
  DashboardReportType.publicRoutes: _ReportConfig(
    title: 'Reporte de rutas publicas',
    shortLabel: 'Rutas publicas',
    description:
        'Vista institucional de rutas registradas, rutas activas, zonas mas utilizadas y comportamiento geografico simulado.',
    icon: Icons.route_outlined,
    metrics: const [
      _ReportMetric(
        title: 'Rutas registradas',
        value: '56',
        changeLabel: '+4 nuevas',
        icon: Icons.route_outlined,
        accentColor: dashboardBrandGreen,
      ),
      _ReportMetric(
        title: 'Rutas activas',
        value: '41',
        changeLabel: '73% operativas',
        icon: Icons.alt_route_rounded,
        accentColor: dashboardSoftGreen,
      ),
      _ReportMetric(
        title: 'Zonas mas usadas',
        value: '8',
        changeLabel: 'Alta demanda',
        icon: Icons.map_outlined,
        accentColor: dashboardAccentOrange,
      ),
      _ReportMetric(
        title: 'Actividad geografica',
        value: '312',
        changeLabel: 'Puntos asociados',
        icon: Icons.travel_explore_outlined,
        accentColor: dashboardSupportGreen,
      ),
    ],
    filters: [
      _ReportFilter(label: 'Todas', matches: _matchAll),
      _ReportFilter(label: 'Activas', matches: _matchesActiva),
      _ReportFilter(label: 'Urbanas', matches: _matchesUrbanas),
      _ReportFilter(label: 'Interurbanas', matches: _matchesInterurbanas),
    ],
    primaryColumnLabel: 'Ruta',
    secondaryColumnLabel: 'Zona',
    detailColumnLabel: 'Cobertura',
    rows: const [
      _ReportRow(
        primary: 'Ruta Central',
        secondary: 'San Jose',
        detail: '12 puntos',
        status: 'Activa',
        activity: 'Hace 11 min',
        actionLabel: 'Ver mapa',
      ),
      _ReportRow(
        primary: 'Ruta Norte',
        secondary: 'Heredia',
        detail: '9 puntos',
        status: 'Activa',
        activity: 'Hace 53 min',
        actionLabel: 'Ver mapa',
      ),
      _ReportRow(
        primary: 'Ruta Costera',
        secondary: 'Puntarenas',
        detail: '6 puntos',
        status: 'Revision',
        activity: 'Hace 4 h',
        actionLabel: 'Actualizar',
      ),
      _ReportRow(
        primary: 'Ruta Este',
        secondary: 'Cartago',
        detail: '8 puntos',
        status: 'Activa',
        activity: 'Hace 1 dia',
        actionLabel: 'Ver mapa',
      ),
      _ReportRow(
        primary: 'Ruta Intercantonal',
        secondary: 'Alajuela',
        detail: '5 puntos',
        status: 'Pendiente',
        activity: 'Hace 2 dias',
        actionLabel: 'Revisar',
      ),
    ],
    asideTitle: 'Lecturas geograficas',
    asideSubtitle:
        'Indicadores simulados de cobertura territorial y rendimiento de rutas publicas.',
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
      ('Ruta lider', 'Ruta Central', dashboardSoftGreen),
      ('Cobertura media', '7.4 puntos', dashboardBrandGreen),
      ('Zona en expansion', 'Heredia', dashboardAccentOrange),
    ],
  ),
};

class _ReportTableCard extends StatelessWidget {
  const _ReportTableCard({
    required this.config,
    required this.searchController,
    required this.selectedFilter,
    required this.sortAscending,
    required this.visibleRows,
    required this.filteredCount,
    required this.currentPage,
    required this.pageCount,
    required this.onFilterSelected,
    required this.onToggleSort,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  final _ReportConfig config;
  final TextEditingController searchController;
  final String selectedFilter;
  final bool sortAscending;
  final List<_ReportRow> visibleRows;
  final int filteredCount;
  final int currentPage;
  final int pageCount;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onToggleSort;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: 'Tabla administrativa',
      subtitle:
          'Consulta visual con busqueda, filtros, estados, acciones y paginacion para ${config.shortLabel.toLowerCase()}.',
      actions: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          DashboardActionGhostButton(
            label: 'Exportar PDF',
            icon: Icons.picture_as_pdf_outlined,
            onTap: onExportPdf,
          ),
          DashboardActionGhostButton(
            label: 'Exportar Excel',
            icon: Icons.table_chart_outlined,
            onTap: onExportExcel,
          ),
        ],
      ),
      child: Column(
        children: [
          _ReportToolbar(
            controller: searchController,
            sortAscending: sortAscending,
            onToggleSort: onToggleSort,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: config.filters
                .map(
                  (filter) => DashboardActionGhostButton(
                    label: filter.label,
                    icon: filter.label == selectedFilter
                        ? Icons.check_circle_outline_rounded
                        : Icons.tune_rounded,
                    onTap: () => onFilterSelected(filter.label),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: const BoxConstraints(minWidth: 940),
              decoration: BoxDecoration(
                border: Border.all(color: dashboardBorder),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        _headerCell(context, config.primaryColumnLabel, 170),
                        _headerCell(context, config.secondaryColumnLabel, 180),
                        _headerCell(context, config.detailColumnLabel, 150),
                        _headerCell(context, 'Estado', 140),
                        _headerCell(context, 'Actividad', 120),
                        _headerCell(context, 'Accion', 150),
                      ],
                    ),
                  ),
                  if (visibleRows.isEmpty)
                    const _EmptyTableState()
                  else
                    ...visibleRows.map((row) => _ReportTableRow(row: row)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PaginationBar(
            filteredCount: filteredCount,
            visibleCount: visibleRows.length,
            currentPage: currentPage,
            pageCount: pageCount,
            onPreviousPage: onPreviousPage,
            onNextPage: onNextPage,
          ),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String label, double width) {
    return SizedBox(
      width: width,
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _ReportToolbar extends StatelessWidget {
  const _ReportToolbar({
    required this.controller,
    required this.sortAscending,
    required this.onToggleSort,
  });

  final TextEditingController controller;
  final bool sortAscending;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final search = Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Buscar registros',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        );

        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            DashboardActionGhostButton(
              label: sortAscending ? 'Orden A-Z' : 'Orden Z-A',
              icon: Icons.sort_by_alpha_rounded,
              onTap: onToggleSort,
            ),
            DashboardActionGhostButton(
              label: 'Filtro activo',
              icon: Icons.filter_alt_outlined,
            ),
          ],
        );

        if (compact) {
          return Column(
            children: [
              Row(children: [search]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: actions)]),
            ],
          );
        }

        return Row(
          children: [
            search,
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class _ReportTableRow extends StatelessWidget {
  const _ReportTableRow({required this.row});

  final _ReportRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: dashboardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _cell(
            width: 170,
            child: Text(
              row.primary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dashboardBrandGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _cell(
            width: 180,
            child: Text(row.secondary, style: Theme.of(context).textTheme.bodyMedium),
          ),
          _cell(
            width: 150,
            child: Text(row.detail, style: Theme.of(context).textTheme.bodyMedium),
          ),
          _cell(
            width: 140,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DashboardStatusChip(
                label: row.status,
                color: _statusColor(row.status),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          _cell(
            width: 120,
            child: Text(row.activity, style: Theme.of(context).textTheme.bodyMedium),
          ),
          _cell(
            width: 150,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DashboardActionGhostButton(
                label: row.actionLabel,
                icon: Icons.open_in_new_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('activo') ||
        normalized.contains('activa') ||
        normalized.contains('completado') ||
        normalized.contains('validado')) {
      return dashboardSoftGreen;
    }
    if (normalized.contains('pendiente') ||
        normalized.contains('revision') ||
        normalized.contains('pausada') ||
        normalized.contains('vencida')) {
      return dashboardAccentOrange;
    }
    return dashboardBrandGreen;
  }
}

class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 36, color: dashboardSupportGreen),
            const SizedBox(height: 12),
            Text(
              'No hay registros para ese filtro o busqueda.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.filteredCount,
    required this.visibleCount,
    required this.currentPage,
    required this.pageCount,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final int filteredCount;
  final int visibleCount;
  final int currentPage;
  final int pageCount;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    final start = filteredCount == 0 ? 0 : (currentPage * _DashboardReportsSectionState._pageSize) + 1;
    final end = filteredCount == 0 ? 0 : start + visibleCount - 1;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        Text(
          'Mostrando $start-$end de $filteredCount registros',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DashboardActionGhostButton(
              label: 'Anterior',
              icon: Icons.chevron_left_rounded,
              onTap: currentPage == 0 ? null : onPreviousPage,
            ),
            const SizedBox(width: 10),
            DashboardStatusChip(
              label: '${currentPage + 1} / $pageCount',
              color: dashboardBrandGreen,
              backgroundColor: const Color(0xFFEAF5EF),
            ),
            const SizedBox(width: 10),
            DashboardActionGhostButton(
              label: 'Siguiente',
              icon: Icons.chevron_right_rounded,
              onTap: currentPage >= pageCount - 1 ? null : onNextPage,
            ),
          ],
        ),
      ],
    );
  }
}

class _ReportAside extends StatelessWidget {
  const _ReportAside({required this.config});

  final _ReportConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardSectionCard(
          title: config.asideTitle,
          subtitle: config.asideSubtitle,
          child: Column(
            children: config.highlights
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.$3,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: dashboardBrandGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        DashboardSectionCard(
          title: 'Timeline de actividad',
          subtitle:
              'Secuencia visual simulada de eventos recientes asociados a este reporte.',
          child: DashboardRecentActivityList(items: config.timeline),
        ),
      ],
    );
  }
}

bool _matchAll(_ReportRow row) => true;
bool _matchesActivo(_ReportRow row) => row.status.toLowerCase().contains('activo');
bool _matchesPendiente(_ReportRow row) => row.status.toLowerCase().contains('pendiente');
bool _matchesRecent(_ReportRow row) =>
    row.activity.contains('min') || row.activity.contains('h');
bool _matchesMovilidadOrRetail(_ReportRow row) =>
    row.secondary.toLowerCase().contains('movilidad') ||
    row.secondary.toLowerCase().contains('retail');
bool _matchesActiva(_ReportRow row) => row.status.toLowerCase().contains('activa');
bool _matchesPausada(_ReportRow row) => row.status.toLowerCase().contains('pausada');
bool _matchesVencida(_ReportRow row) => row.status.toLowerCase().contains('vencida');
bool _matchesSistema(_ReportRow row) =>
    row.secondary.toLowerCase().contains('sistema');
bool _matchesAdministracion(_ReportRow row) =>
    row.secondary.toLowerCase().contains('gestion') ||
    row.secondary.toLowerCase().contains('modulo');
bool _matchesAlerta(_ReportRow row) =>
    row.primary.toLowerCase().contains('alerta') ||
    row.status.toLowerCase().contains('pendiente');
bool _matchesUrbanas(_ReportRow row) =>
    row.secondary.toLowerCase().contains('san jose') ||
    row.secondary.toLowerCase().contains('heredia') ||
    row.secondary.toLowerCase().contains('cartago');
bool _matchesInterurbanas(_ReportRow row) =>
    row.primary.toLowerCase().contains('inter') ||
    row.secondary.toLowerCase().contains('puntarenas') ||
    row.secondary.toLowerCase().contains('alajuela');
