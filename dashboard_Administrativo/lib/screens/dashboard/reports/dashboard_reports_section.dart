export 'models/report_models.dart' show DashboardReportType;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../services/dashboard_reports_service.dart';
import '../../../widgets/reports/report_aside.dart';
import '../../../widgets/reports/report_table_card.dart';
import '../shared/dashboard_mock_ui.dart';
import 'data/report_configs.dart';
import 'export/dashboard_report_excel_template.dart';
import 'models/report_models.dart';

class DashboardReportsSection extends StatefulWidget {
  const DashboardReportsSection({required this.reportType, super.key});

  final DashboardReportType reportType;

  @override
  State<DashboardReportsSection> createState() =>
      _DashboardReportsSectionState();
}

class _DashboardReportsSectionState extends State<DashboardReportsSection> {
  static const int _pageSize = 4;

  late final TextEditingController _searchController;
  late final DashboardReportsService _service;
  late String _selectedFilter;
  late DashboardReportConfig _resolvedConfig;
  bool _sortAscending = false;
  int _currentPage = 0;
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;
  bool _isLoadingLiveData = false;
  Object? _loadingError;

  DashboardReportConfig get _baseConfig =>
      dashboardReportConfigs[widget.reportType]!;

  bool get _usesLiveData =>
      widget.reportType == DashboardReportType.users ||
      widget.reportType == DashboardReportType.publicRoutes;

  DashboardReportConfig get _initialConfig =>
      _usesLiveData ? _baseConfig.withLiveEmptyState() : _baseConfig;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _service = DashboardReportsService();
    _resolvedConfig = _initialConfig;
    _selectedFilter = _initialConfig.filters.first.label;
    _searchController.addListener(_handleSearchChanged);
    _loadReportData();
  }

  @override
  void didUpdateWidget(covariant DashboardReportsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportType != widget.reportType) {
      _resolvedConfig = _initialConfig;
      _selectedFilter = _initialConfig.filters.first.label;
      _currentPage = 0;
      _sortAscending = false;
      _loadingError = null;
      _searchController.clear();
      _loadReportData();
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  List<DashboardReportRow> get _filteredRows {
    final query = _searchController.text.trim().toLowerCase();
    final selectedFilter = _resolvedConfig.filters.firstWhere(
      (filter) => filter.label == _selectedFilter,
      orElse: () => _resolvedConfig.filters.first,
    );

    final rows = _resolvedConfig.rows.where((row) {
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
      final comparison = a.primary.toLowerCase().compareTo(
        b.primary.toLowerCase(),
      );
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

  List<DashboardReportRow> get _visibleRows {
    final rows = _filteredRows;
    final start = (_currentPage * _pageSize).clamp(0, rows.length);
    final end = (start + _pageSize).clamp(0, rows.length);
    return rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final config = _resolvedConfig;

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
                label: _isExportingExcel
                    ? 'Exportando Excel...'
                    : 'Exportar Excel',
                icon: Icons.table_chart_outlined,
                onTap: _isExportingExcel ? null : _exportExcel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_loadingError != null) ...[
          DashboardSectionCard(
            title: 'Lectura parcial',
            subtitle:
                'No fue posible actualizar este reporte con Firebase, asi que se mantuvo el contenido disponible.',
            child: Text(
              'Revisa consola para el detalle del error: $_loadingError',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
        ],
        DashboardMetricGrid(metrics: config.metrics),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final table = ReportTableCard(
              config: config,
              searchController: _searchController,
              selectedFilter: _selectedFilter,
              sortAscending: _sortAscending,
              visibleRows: _visibleRows,
              filteredCount: _filteredRows.length,
              currentPage: _currentPage,
              pageCount: _pageCount,
              pageSize: _pageSize,
              onFilterSelected: _handleFilterSelected,
              onToggleSort: _toggleSort,
              onPreviousPage: _goToPreviousPage,
              onNextPage: _goToNextPage,
              isLoading: _isLoadingLiveData,
            );
            final side = ReportAside(config: config);

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

            return Column(children: [table, const SizedBox(height: 20), side]);
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
              _resolvedConfig.title,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(_resolvedConfig.description),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: _pdfHeaders(),
              data: rows.map((row) => _pdfRow(row)).toList(),
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
      _showSnackBar(
        _usesLiveData
            ? 'PDF exportado con datos actuales.'
            : 'PDF exportado con datos mock.',
      );
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

  List<String> _pdfHeaders() {
    final headers = [
      _resolvedConfig.primaryColumnLabel,
      _resolvedConfig.secondaryColumnLabel,
      _resolvedConfig.detailColumnLabel,
    ];
    if (_resolvedConfig.showStatusColumn) {
      headers.add('Estado');
    }
    headers.add(_resolvedConfig.activityColumnLabel);
    return headers;
  }

  List<String> _pdfRow(DashboardReportRow row) {
    final values = [row.primary, row.secondary, row.detail];
    if (_resolvedConfig.showStatusColumn) {
      values.add(row.status);
    }
    values.add(row.activity);
    return values;
  }

  Future<void> _exportExcel() async {
    setState(() {
      _isExportingExcel = true;
    });

    try {
      final bytes = DashboardReportExcelTemplate.buildWorkbook(
        config: _resolvedConfig,
        rows: _filteredRows,
        usesLiveData: _usesLiveData,
      );

      await FileSaver.instance.saveFile(
        name: _buildExportName(),
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      _showSnackBar(
        _usesLiveData
            ? 'Excel exportado con datos actuales.'
            : 'Excel exportado con datos mock.',
      );
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
    final slug = _resolvedConfig.shortLabel.toLowerCase().replaceAll(' ', '_');
    final suffix = _usesLiveData ? 'live' : 'mock';
    return 'reporte_${slug}_$suffix';
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadReportData() async {
    if (!_usesLiveData) {
      if (mounted) {
        setState(() {
          _resolvedConfig = _initialConfig;
          _isLoadingLiveData = false;
          _loadingError = null;
        });
      }
      return;
    }

    setState(() {
      _isLoadingLiveData = true;
      _loadingError = null;
    });

    try {
      final payload = widget.reportType == DashboardReportType.users
          ? await _service.loadUsersReport()
          : await _service.loadPublicRoutesReport();

      if (!mounted) {
        return;
      }

      setState(() {
        _resolvedConfig = _baseConfig.copyWith(
          metrics: payload.metrics,
          rows: payload.rows
              .map(
                (row) => DashboardReportRow(
                  primary: row.primary,
                  secondary: row.secondary,
                  detail: row.detail,
                  status: row.status,
                  activity: row.activity,
                  actionLabel: row.actionLabel,
                ),
              )
              .toList(),
          timeline: payload.timeline,
          highlights: payload.highlights
              .map((item) => (item.label, item.value, item.color))
              .toList(),
        );
        _isLoadingLiveData = false;
        _loadingError = null;
        _currentPage = 0;
      });
    } catch (error, stackTrace) {
      debugPrint('DashboardReportsSection._loadReportData error: $error');
      debugPrint('$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _resolvedConfig = _initialConfig;
        _isLoadingLiveData = false;
        _loadingError = error;
      });
    }
  }
}
