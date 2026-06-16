import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_analytics_model.dart';
export 'event_analytics_model.dart';

class EventAnalyticsWidget extends StatefulWidget {
  final String eventId;
  const EventAnalyticsWidget({super.key, required this.eventId});

  static String routeName = 'EventAnalytics';
  static String routePath = '/events/analytics';

  @override
  State<EventAnalyticsWidget> createState() => _EventAnalyticsWidgetState();
}

class _EventAnalyticsWidgetState extends State<EventAnalyticsWidget> {
  late EventAnalyticsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _event;
  List<dynamic>? _callLogs;
  List<dynamic>? _assignments;
  Map<String, int> _callOutcomes = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EventAnalyticsModel());
    _loadStats();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
    });
    try {
      final res = await Supabase.instance.client.rpc('get_event_call_stats', params: {'event_id': widget.eventId});
      
      Map<String, int> outcomes = {};
      for (final log in res['call_logs']) {
        final outcome = log['call_outcome'];
        final key = outcome as String;
        outcomes[key] = (outcomes[key] ?? 0) + 1;
      }

      setState(() {
        _event = res['event'];
        _callLogs = res['call_logs'];
        _assignments = res['assignments'];
        _callOutcomes = outcomes;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading event stats: $e");
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load stats: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Color _getColorForOutcomeString(String outcomeStr) {
    switch (outcomeStr) {
      case 'ANSWERED':
        return const Color(0xFF10B981);
      case 'BUSY':
        return const Color(0xFFF59E0B);
      case 'NO_RESPONSE':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getEventStatusColor(String? status) {
    if (status == null) return Colors.grey;
    final statusStr = status;
    switch (statusStr) {
      case 'ACTIVE':
        return FlutterFlowTheme.of(context).primary;
      case 'DRAFT':
        return FlutterFlowTheme.of(context).secondaryText;
      case 'COMPLETED':
        return FlutterFlowTheme.of(context).primaryText;
      default:
        return FlutterFlowTheme.of(context).primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: FlutterFlowTheme.of(context).primaryText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: FlutterFlowTheme.of(context).primaryText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Event not found or access denied',
            style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
          ),
        ),
      );
    }

    // Compute RSVP analytics
    int going = 0;
    int notCaring = 0;
    int undecided = 0;

    if (_callLogs != null) {
      for (final log in _callLogs!) {
        final outcomeVal = log['call_outcome'] as String?;
        final followUpVal = log['follow_up_status'] as String?;

        if (outcomeVal == 'ANSWERED' &&
            (followUpVal == 'INTERESTED' || followUpVal == 'JOINED')) {
          going++;
        } else if (outcomeVal == 'NO_RESPONSE' ||
            outcomeVal == 'BUSY' ||
            outcomeVal == 'NOT_REACHABLE' ||
            outcomeVal == 'WRONG_NUMBER' ||
            outcomeVal == 'SWITCHED_OFF' ||
            followUpVal == 'NOT_INTERESTED') {
          notCaring++;
        } else {
          undecided++;
        }
      }
    }

    final totalStats = going + notCaring + undecided;
    final goingPct = totalStats > 0 ? (going / totalStats * 100).round() : 0;
    final notCaringPct = totalStats > 0 ? (notCaring / totalStats * 100).round() : 0;
    final undecidedPct = totalStats > 0 ? (undecided / totalStats * 100).round() : 0;

    // Compute dialing progress
    int totalAssignments = _assignments?.length ?? 0;
    int completedAssignments = 0;
    if (_assignments != null) {
      completedAssignments = _assignments!.where((a) {
        return a['status'] == 'COMPLETED';
      }).length;
    }

    final completionPct = totalAssignments > 0 ? (completedAssignments / totalAssignments * 100).round() : 0;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with back button
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  shape: BoxShape.rectangle,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 24.0, 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 24),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _event!['name'],
                                        style: FlutterFlowTheme.of(context).titleLarge.override(
                                              font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                              color: FlutterFlowTheme.of(context).primaryText,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      decoration: BoxDecoration(
                                        color: _getEventStatusColor(_event!['status']).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: Text(
                                        _event!['status'],
                                        style: FlutterFlowTheme.of(context).bodySmall.override(
                                              font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                              color: _getEventStatusColor(_event!['status']),
                                              fontSize: 10.0,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 14, color: FlutterFlowTheme.of(context).accent3),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      '${DateFormat('EEEE, MMM d').format(DateTime.parse(_event!['event_date']))} • ${_event!['event_time'] ?? '00:00 AM'}',
                                      style: FlutterFlowTheme.of(context).labelMedium.override(
                                            font: GoogleFonts.inter(),
                                            color: FlutterFlowTheme.of(context).secondaryText,
                                          ),
                                    ),
                                  ],
                                ),
                                if (_event!['description'] != null && _event!['description']!.isNotEmpty) ...[
                                  const SizedBox(height: 8.0),
                                  Text(
                                    _event!['description']!,
                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                          font: GoogleFonts.inter(),
                                          color: FlutterFlowTheme.of(context).secondaryText,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ],
                ),
              ),

              // Analytics Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Stat Cards Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  label: 'Assignments',
                                  value: '$totalAssignments',
                                  icon: Icons.assignment_turned_in_rounded,
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  label: 'Completion',
                                  value: '$completionPct%',
                                  icon: Icons.check_circle_rounded,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24.0),

                          // RSVP and Progress Card
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondaryBackground,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dialing Progress & RSVPs',
                                    style: FlutterFlowTheme.of(context).titleMedium.override(
                                          font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                          color: FlutterFlowTheme.of(context).primaryText,
                                        ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Assignments Completed', style: FlutterFlowTheme.of(context).bodyMedium),
                                      Text('$completedAssignments / $totalAssignments',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(font: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),
                                  LinearProgressIndicator(
                                    value: totalAssignments > 0 ? completedAssignments / totalAssignments : 0.0,
                                    backgroundColor: FlutterFlowTheme.of(context).alternate,
                                    color: FlutterFlowTheme.of(context).primary,
                                    minHeight: 6.0,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  const SizedBox(height: 24.0),
                                  if (totalStats == 0)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text("No calls recorded yet", style: TextStyle(color: Colors.grey)),
                                      ),
                                    )
                                  else ...[
                                    _buildRSVPProgressBar(
                                      context,
                                      label: 'Going',
                                      pct: goingPct,
                                      count: going,
                                      color: FlutterFlowTheme.of(context).primary,
                                    ),
                                    const SizedBox(height: 16.0),
                                    _buildRSVPProgressBar(
                                      context,
                                      label: 'Not Caring',
                                      pct: notCaringPct,
                                      count: notCaring,
                                      color: FlutterFlowTheme.of(context).primaryText,
                                    ),
                                    const SizedBox(height: 16.0),
                                    _buildRSVPProgressBar(
                                      context,
                                      label: 'Undecided',
                                      pct: undecidedPct,
                                      count: undecided,
                                      color: FlutterFlowTheme.of(context).accent3,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0),

                          // Pie Chart Card
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondaryBackground,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Call Outcome Distribution',
                                    style: FlutterFlowTheme.of(context).titleMedium.override(
                                          font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                          color: FlutterFlowTheme.of(context).primaryText,
                                        ),
                                  ),
                                  const SizedBox(height: 24.0),
                                  Container(
                                    alignment: Alignment.center,
                                    child: _callOutcomes.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(24.0),
                                            child: Text(
                                              "No call outcomes recorded yet",
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          )
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 220.0,
                                                width: 220.0,
                                                child: FlutterFlowPieChart(
                                                  data: FFPieChartData(
                                                    values: _callOutcomes.values.map((v) => v.toDouble()).toList(),
                                                    colors: _callOutcomes.keys
                                                        .map((k) => _getColorForOutcomeString(k))
                                                        .toList(),
                                                    radius: [50.0],
                                                  ),
                                                  donutHoleRadius: 40.0,
                                                  donutHoleColor: Colors.transparent,
                                                  sectionLabelType: PieChartSectionLabelType.value,
                                                  sectionLabelStyle: FlutterFlowTheme.of(context).labelSmall.override(
                                                        font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                        color: Colors.white,
                                                        fontSize: 10.0,
                                                        lineHeight: 1.0,
                                                      ),
                                                  labelFormatter: LabelFormatter(
                                                    numberFormat: (v) => v.toInt().toString(),
                                                  ),
                                                  sectionsSpace: 4.0,
                                                  startDegreeOffset: -90.0,
                                                ),
                                              ),
                                              const SizedBox(height: 24.0),
                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 24.0,
                                                runSpacing: 8.0,
                                                children: _callOutcomes.entries.map((e) {
                                                  return Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 10.0,
                                                        height: 10.0,
                                                        decoration: BoxDecoration(
                                                          color: _getColorForOutcomeString(e.key),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8.0),
                                                      Text(
                                                        '${e.key} (${e.value})',
                                                        style: FlutterFlowTheme.of(context).bodySmall.override(
                                                              font: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                            ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
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

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    value,
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRSVPProgressBar(BuildContext context,
      {required String label, required int pct, required int count, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label ($count)',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            Text(
              '$pct%',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Stack(
          children: [
            Container(
              height: 8.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).alternate,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            LayoutBuilder(builder: (context, constraints) {
              return Container(
                height: 8.0,
                width: constraints.maxWidth * (pct / 100),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
