import '/components/stat_card_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'folk_guide_dashboard_model.dart';
import '/index.dart';
import '/components/admin_nav_bar.dart';
import 'recent_activity_widget.dart' show formatTime;

export 'folk_guide_dashboard_model.dart';

class FolkGuideDashboardWidget extends StatefulWidget {
  const FolkGuideDashboardWidget({super.key});

  static String routeName = 'FolkGuideDashboard';
  static String routePath = '/folkGuideDashboard';

  @override
  State<FolkGuideDashboardWidget> createState() =>
      _FolkGuideDashboardWidgetState();
}

class _FolkGuideDashboardWidgetState extends State<FolkGuideDashboardWidget> {
  late FolkGuideDashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>>? _activities;
  int _totalContacts = 0;
  int _activeContacts = 0;
  int _totalEnablers = 0;
  int _activeEvents = 0;

  Map<String, int> _callOutcomes = {};
  List<Map<String, dynamic>> _activeCampaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FolkGuideDashboardModel());
    _loadDashboardData();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
    });
    try {
      final supabase = Supabase.instance.client;
      final auth = AuthService.instance;
      final isFg = auth.isFolkGuide && auth.folkGuideId != null;
      final fgId = auth.folkGuideId;

      // Overview Stats
      dynamic contactCountQuery = supabase.from('contact').select('id');
      dynamic enablerCountQuery = supabase.from('contact').select('id').eq('role', 'ENABLER');
      if (isFg) {
        contactCountQuery = contactCountQuery.eq('folk_guide', fgId!);
      }
      final contactsCount = await contactCountQuery.count(CountOption.exact);
      final enablersCount = await enablerCountQuery.count(CountOption.exact);
      final eventsCount = await supabase
          .from('event')
          .select('id')
          .eq('status', 'ACTIVE')
          .count(CountOption.exact);

      // Call Outcomes — filter by folk_guide contacts
      dynamic callLogQuery = supabase.from('call_log').select('call_outcome');
      if (isFg) {
        final folkContactIds = await supabase
            .from('contact')
            .select('id')
            .eq('folk_guide', fgId!);
        final ids = folkContactIds.map((c) => c['id'] as String).toList();
        if (ids.isNotEmpty) {
          callLogQuery = callLogQuery.inFilter('contact_id', ids);
        } else {
          callLogQuery = callLogQuery.inFilter('contact_id', <String>['']);
        }
      }
      final callLogs = await callLogQuery;
      Map<String, int> outcomes = {};
      for (final log in callLogs) {
        final outcome = log['call_outcome'] as String? ?? 'UNKNOWN';
        outcomes[outcome] = (outcomes[outcome] ?? 0) + 1;
      }

      // Active Campaigns Progress
      final campaigns = await supabase
          .from('event')
          .select('id, name')
          .eq('status', 'ACTIVE');

      // Fetch assignment counts for each campaign
      final campaignIds = campaigns.map((c) => c['id']).toList();
      Map<String, int> campaignAssignmentCounts = {};
      if (campaignIds.isNotEmpty) {
        dynamic assignCountQuery = supabase
            .from('assignment')
            .select('event_id')
            .inFilter('event_id', campaignIds);
        if (isFg) {
          final folkAssignContactIds = await supabase
              .from('contact')
              .select('id')
              .eq('folk_guide', fgId!);
          final aIds = folkAssignContactIds.map((c) => c['id'] as String).toList();
          if (aIds.isNotEmpty) {
            assignCountQuery = assignCountQuery.inFilter('contact_id', aIds);
          } else {
            assignCountQuery = assignCountQuery.inFilter('contact_id', <String>['']);
          }
        }
        final assignmentCounts = await assignCountQuery;
        for (var a in assignmentCounts) {
          final eventId = a['event_id'] as String;
          campaignAssignmentCounts[eventId] =
              (campaignAssignmentCounts[eventId] ?? 0) + 1;
        }
      }
      
      final campaignsWithCounts = campaigns
          .map((c) => {
        ...c,
        'assignment': [], // Placeholder for UI compatibility
        'assignment_count': campaignAssignmentCounts[c['id']] ?? 0,
              })
          .toList();

      // Recent Activity
      dynamic activityQuery = supabase
          .from('call_log')
          .select('contact_id, enabler_id, called_at');
      if (isFg) {
        final folkActContactIds = await supabase
            .from('contact')
            .select('id')
            .eq('folk_guide', fgId!);
        final actIds = folkActContactIds.map((c) => c['id'] as String).toList();
        if (actIds.isNotEmpty) {
          activityQuery = activityQuery.inFilter('contact_id', actIds);
        } else {
          activityQuery = activityQuery.inFilter('contact_id', <String>['']);
        }
      }
      final activities = await activityQuery
          .order('called_at', ascending: false)
          .limit(5);
      
      // Fetch contact and enabler names for activities
      final activityContactIds =
          activities.map((a) => a['contact_id']).toList();
      final activityEnablerIds =
          activities.map((a) => a['enabler_id']).toList();
      final allActivityIds =
          <String>{...activityContactIds, ...activityEnablerIds}.toList();
      Map<String, String> activityNames = {};
      if (allActivityIds.isNotEmpty) {
        final namesRes = await supabase
            .from('contact')
            .select('id, name')
            .inFilter('id', allActivityIds);
        activityNames = {
          for (var n in namesRes) n['id'] as String: n['name'] as String
        };
      }
      
      final activitiesWithNames = activities
          .map((a) => {
        ...a,
        'contact': {'name': activityNames[a['contact_id']] ?? ''},
        'enabler': {'name': activityNames[a['enabler_id']] ?? ''},
              })
          .toList();

      setState(() {
        _totalContacts = contactsCount.count;
        _activeContacts = contactsCount.count; // Placeholder
        _totalEnablers = enablersCount.count;
        _activeEvents = eventsCount.count;

        _callOutcomes = outcomes;
        _activeCampaigns = campaignsWithCounts;
        _activities = activitiesWithNames;

        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      setState(() {
        _loading = false;
      });
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

  Color _getOutcomeColorString(String outcome) {
    switch (outcome) {
      case 'ANSWERED':
        return const Color(0xFF2E7D32);
      case 'BUSY':
        return const Color(0xFFE65100);
      case 'NO_RESPONSE':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFFC62828);
    }
  }

  Color _getOutcomeBgString(String outcome) {
    switch (outcome) {
      case 'ANSWERED':
        return const Color(0xFFE8F5E9);
      case 'BUSY':
        return const Color(0xFFFFF3E0);
      case 'NO_RESPONSE':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFFFEBEE);
    }
  }

  IconData _getOutcomeIconString(String outcome) {
    switch (outcome) {
      case 'ANSWERED':
        return Icons.call_received_rounded;
      case 'BUSY':
        return Icons.phone_missed_rounded;
      case 'NO_RESPONSE':
        return Icons.phone_disabled_rounded;
      default:
        return Icons.phone_rounded;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  String _getFormattedDate() {
    return DateFormat('EEEE, MMM d').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        AuthService.instance.clearEffectiveRole();
        Future.microtask(() {
          if (context.mounted) context.go('/welcome');
        });
      },
      child: GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  shape: BoxShape.rectangle,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    'FOLK AUTO DIALER',
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontSize: 9.0,
                                          letterSpacing: 1.0,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              _getGreeting(),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 22.0,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              '${_getFormattedDate()} • Folk Guide Dashboard',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 12.0,
                                    lineHeight: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          context.go('/profile');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2.0),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 44.0,
                                height: 44.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6.0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                  alignment:
                                      const AlignmentDirectional(0.0, 0.0),
                                child: Text(
                                  'FG',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .onPrimary,
                                        fontSize: 14.0,
                                        lineHeight: 1.3,
                                      ),
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                              Container(
                                width: 12.0,
                                height: 12.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    width: 1.5,
                                  ),
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
              Expanded(
                flex: 1,
                child: RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    primary: false,
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: wrapWithModel(
                                      model: _model.statCardModel1,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                      child: StatCardWidget(
                                        label: 'Total \nContacts',
                                        value: _loading
                                            ? '...'
                                            : '$_totalContacts',
                                        icon: Icons.people_alt_rounded,
                                        iconColor: const Color(0xFF3B82F6),
                                        iconBgColor: const Color(0xFFEFF6FF),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: wrapWithModel(
                                      model: _model.statCardModel2,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                      child: StatCardWidget(
                                        label: 'Active \nContacts',
                                        value: _loading
                                            ? '...'
                                            : '$_activeContacts',
                                        icon: Icons.phone_in_talk_rounded,
                                        iconColor: const Color(0xFF10B981),
                                        iconBgColor: const Color(0xFFECFDF5),
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: wrapWithModel(
                                      model: _model.statCardModel3,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                      child: StatCardWidget(
                                        label: 'Total \nEnablers',
                                        value: _loading
                                            ? '...'
                                            : '$_totalEnablers',
                                        icon: Icons.support_agent_rounded,
                                        iconColor: const Color(0xFFF59E0B),
                                        iconBgColor: const Color(0xFFFEF3C7),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: wrapWithModel(
                                      model: _model.statCardModel4,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                      child: StatCardWidget(
                                        label: 'Active \nCampaigns',
                                          value: _loading
                                              ? '...'
                                              : '$_activeEvents',
                                        icon: Icons.campaign_rounded,
                                        iconColor: const Color(0xFFEC4899),
                                        iconBgColor: const Color(0xFFFDF2F8),
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                          const SizedBox(height: 24.0),
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(8.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Call Outcome Distribution',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                  const SizedBox(height: 24.0),
                                  Container(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: _callOutcomes.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(24.0),
                                              child: Text(
                                                  "No calls recorded yet",
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          )
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 220.0,
                                                width: 220.0,
                                                child: FlutterFlowPieChart(
                                                  data: FFPieChartData(
                                                      values: _callOutcomes
                                                          .values
                                                          .map((v) =>
                                                              v.toDouble())
                                                        .toList(),
                                                    colors: _callOutcomes.keys
                                                        .map((k) =>
                                                            _getColorForOutcomeString(
                                                                k))
                                                        .toList(),
                                                    radius: [50.0],
                                                  ),
                                                  donutHoleRadius: 40.0,
                                                  donutHoleColor:
                                                      Colors.transparent,
                                                  sectionLabelType:
                                                      PieChartSectionLabelType
                                                          .value,
                                                  sectionLabelStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .override(
                                                            font: GoogleFonts.inter(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                              color:
                                                                  Colors.white,
                                                            fontSize: 10.0,
                                                            lineHeight: 1.0,
                                                          ),
                                                  labelFormatter:
                                                      LabelFormatter(
                                                    numberFormat: (v) =>
                                                        v.toInt().toString(),
                                                  ),
                                                  sectionsSpace: 4.0,
                                                  startDegreeOffset: -90.0,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Wrap(
                                                  alignment:
                                                      WrapAlignment.center,
                                                spacing: 24.0,
                                                runSpacing: 8.0,
                                                  children: _callOutcomes
                                                      .entries
                                                    .map((e) {
                                                  return Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 10.0,
                                                        height: 10.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              _getColorForOutcomeString(
                                                                  e.key),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 8.0),
                                                      Text(
                                                        e.key,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                                .bodySmall
                                                                .override(
                                                                font:
                                                                    GoogleFonts
                                                                      .outfit(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                  ),
                                ].divide(SizedBox(height: 16.0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Active Campaigns Progress',
                                style: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.outfit(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontWeight,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 16.0),
                              ..._activeCampaigns.isEmpty
                                  ? [
                                      const Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: Center(
                                            child: Text("No active campaigns",
                                                style: TextStyle(
                                                    color: Colors.grey))),
                                      )
                                    ]
                                  : _activeCampaigns.map((campaign) {
                                        final assignments =
                                            campaign['assignment']
                                                    as List<dynamic>? ??
                                                [];
                                      final total = assignments.length;
                                        final completed = assignments
                                            .where((a) =>
                                                a['status'] == 'COMPLETED')
                                            .length;
                                        final progress = total == 0
                                            ? 0.0
                                            : completed / total;
                                      return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 12.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            border: Border.all(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                        .alternate),
                                          ),
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                    Text(
                                                        campaign['name']
                                                            as String,
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                              font: GoogleFonts.inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600))),
                                                  Text('$completed / $total',
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall),
                                                ],
                                              ),
                                              const SizedBox(height: 8.0),
                                              LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                        .alternate,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                        .primary,
                                                minHeight: 6.0,
                                                borderRadius:
                                                      BorderRadius.circular(
                                                          4.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                            ],
                          ),
                          const SizedBox(height: 24.0),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Recent Activity',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      context.pushNamed(
                                          RecentActivityWidget.routeName);
                                    },
                                    child: Text(
                                      'View All',
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontWeight,
                                            ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                            lineHeight: 1.3,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(8.0),
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                    width: 1.0,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: _loading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : (_activities == null ||
                                              _activities!.isEmpty)
                                          ? const Center(
                                              child: Text(
                                                'No recent activity logs',
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            )
                                          : Column(
                                              mainAxisSize: MainAxisSize.min,
                                                children: _activities!
                                                    .map((activity) {
                                                  final outcomeName =
                                                      activity['call_outcome']
                                                              as String? ??
                                                          'UNKNOWN';
                                                  final followUpName = activity[
                                                          'follow_up_status']
                                                      as String?;
                                                
                                                  final contactName =
                                                      activity['contact'] !=
                                                              null
                                                          ? activity['contact']
                                                              ['name']
                                                          : 'Unknown';
                                                  final enablerName =
                                                      activity['enabler'] !=
                                                              null
                                                          ? activity['enabler']
                                                              ['name']
                                                          : 'Unknown';
                                                
                                                final outcomeColor =
                                                      _getOutcomeColorString(
                                                          outcomeName);
                                                final outcomeBg =
                                                      _getOutcomeBgString(
                                                          outcomeName);
                                                final outcomeIcon =
                                                      _getOutcomeIconString(
                                                          outcomeName);

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 10),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .primaryBackground,
                                                      borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      border: Border.all(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .alternate),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width: 38,
                                                          height: 38,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: outcomeBg,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: Icon(
                                                              outcomeIcon,
                                                              color:
                                                                  outcomeColor,
                                                              size: 18),
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                      child:
                                                                          Text(
                                                                      contactName,
                                                                      style: GoogleFonts
                                                                          .outfit(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primaryText,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                      overflow:
                                                                            TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                        width:
                                                                            6),
                                                                  Container(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            2),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color:
                                                                          outcomeBg,
                                                                      borderRadius:
                                                                            BorderRadius.circular(20),
                                                                    ),
                                                                      child:
                                                                          Text(
                                                                      outcomeName ??
                                                                          '',
                                                                      style: GoogleFonts
                                                                          .inter(
                                                                        color:
                                                                            outcomeColor,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        fontSize:
                                                                            9,
                                                                        letterSpacing:
                                                                            0.3,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 3),
                                                              Text(
                                                                '$enablerName logged call with $contactName',
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .accent3,
                                                                    fontSize:
                                                                        11,
                                                                ),
                                                              ),
                                                                if (followUpName !=
                                                                        null &&
                                                                  followUpName
                                                                  .isNotEmpty) ...[
                                                                const SizedBox(
                                                                      height:
                                                                          3),
                                                                Text(
                                                                    followUpName
                                                                        .replaceAll(
                                                                            '_',
                                                                            ' '),
                                                                    style: GoogleFonts
                                                                          .inter(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                )
                                                              ],
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                '${formatTime(DateTime.parse(activity['called_at'] as String))} • $outcomeName',
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .accent3
                                                                      .withOpacity(
                                                                          0.7),
                                                                    fontSize:
                                                                        10,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const AdminNavBar(currentTab: AdminTab.dashboard),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
