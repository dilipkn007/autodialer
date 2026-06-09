import '/components/activity_item_widget.dart';
import '/components/stat_card_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'folk_guide_dashboard_model.dart';
import '/index.dart';
import '/components/admin_nav_bar.dart';

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

  List<GetRecentActivityCallLogs>? _activities;
  int _totalContacts = 0;
  int _activeContacts = 0;
  int _totalEnablers = 0;
  int _activeEvents = 0;
  
  Map<String, int> _callOutcomes = {};
  List<GetActiveCampaignsProgressEvents> _activeCampaigns = [];
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
      final overviewRes = await DefaultConnector.instance.getDashboardOverviewStats().execute();
      final outcomeRes = await DefaultConnector.instance.getCallOutcomeDistribution().execute();
      final campaignRes = await DefaultConnector.instance.getActiveCampaignsProgress().execute();
      final activityRes = await DefaultConnector.instance.getRecentActivity(limit: 5).execute();

      Map<String, int> outcomes = {};
      for (final log in outcomeRes.data.callLogs) {
        final outcome = log.callOutcome;
        final key = outcome is Known<CallOutcome> ? outcome.value.name : outcome.stringValue;
        outcomes[key] = (outcomes[key] ?? 0) + 1;
      }

      setState(() {
        _totalContacts = overviewRes.data.totalContacts.length;
        _activeContacts = overviewRes.data.activeContacts.length;
        _totalEnablers = overviewRes.data.totalEnablers.length;
        _activeEvents = overviewRes.data.activeEvents.length;
        
        _callOutcomes = outcomes;
        _activeCampaigns = campaignRes.data.events;
        _activities = activityRes.data.callLogs;
        
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  Color _getOutcomeColor(EnumValue<CallOutcome> outcome) {
    if (outcome is Known<CallOutcome>) {
      switch (outcome.value) {
        case CallOutcome.ANSWERED:
          return Colors.green;
        case CallOutcome.BUSY:
        case CallOutcome.NO_RESPONSE:
          return Colors.orange;
        default:
          return Colors.red;
      }
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final pieChartPieChartColorsList = [
      FlutterFlowTheme.of(context).primary,
      FlutterFlowTheme.of(context).secondary,
      FlutterFlowTheme.of(context).tertiary,
      FlutterFlowTheme.of(context).error,
      FlutterFlowTheme.of(context).success
    ];
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
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
                    child: Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FOLK AUTO DIALER',
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                      lineHeight: 1.2,
                                    ),
                              ),
                              Text(
                                'Folk Guide Dashboard',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ].divide(SizedBox(height: 4.0)),
                          ),
                          InkWell(
                            onTap: () {
                              context.go('/profile');
                            },
                            child: Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Text(
                                'FG',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).onPrimary,
                                      fontSize: 13.68,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                      lineHeight: 1.3,
                                    ),
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                                      label: 'Total Contacts',
                                      value: _loading ? '...' : '$_totalContacts',
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
                                      label: 'Active Contacts',
                                      value: _loading ? '...' : '$_activeContacts',
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
                                          label: 'Total Enablers',
                                          value: _loading ? '...' : '$_totalEnablers',
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
                                          label: 'Active Campaigns',
                                          value: _loading ? '...' : '$_activeEvents',
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
                                        color:
                                            FlutterFlowTheme.of(context)
                                                .primaryText,
                                        letterSpacing: 0.0,
                                        lineHeight: 1.4,
                                      ),
                                ),
                                Container(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: _callOutcomes.isEmpty 
                                      ? const Padding(
                                          padding: EdgeInsets.all(24.0),
                                          child: Text("No calls recorded yet", style: TextStyle(color: Colors.grey)),
                                        ) 
                                      : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 140.0,
                                              child: FlutterFlowPieChart(
                                                data: FFPieChartData(
                                                  values: _callOutcomes.values.map((v) => v.toDouble()).toList(),
                                                  colors: pieChartPieChartColorsList.take(_callOutcomes.length).toList(),
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
                                                sectionsSpace: 4.0,
                                                startDegreeOffset: -90.0,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            FlutterFlowChartLegendWidget(
                                              entries: _callOutcomes.entries.map((e) {
                                                final index = _callOutcomes.keys.toList().indexOf(e.key);
                                                return LegendEntry(pieChartPieChartColorsList[index % pieChartPieChartColorsList.length], e.key);
                                              }).toList(),
                                              textStyle: FlutterFlowTheme.of(context).bodySmall,
                                              indicatorSize: 10.0,
                                              indicatorBorderRadius: BorderRadius.circular(2.0),
                                              textPadding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
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
                            ..._activeCampaigns.isEmpty ? [
                              const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(child: Text("No active campaigns", style: TextStyle(color: Colors.grey))),
                              )
                            ] : _activeCampaigns.map((campaign) {
                              final total = campaign.assignments_on_event.length;
                              final completed = campaign.assignments_on_event.where((a) {
                                return a.status is Known<AssignmentStatus> 
                                    ? (a.status as Known<AssignmentStatus>).value == AssignmentStatus.COMPLETED 
                                    : a.status.stringValue == 'COMPLETED';
                              }).length;
                              final progress = total == 0 ? 0.0 : completed / total;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                                  ),
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(campaign.name, style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                                          Text('$completed / $total', style: FlutterFlowTheme.of(context).bodySmall),
                                        ],
                                      ),
                                      const SizedBox(height: 8.0),
                                      LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: FlutterFlowTheme.of(context).alternate,
                                        color: FlutterFlowTheme.of(context).primary,
                                        minHeight: 6.0,
                                        borderRadius: BorderRadius.circular(4.0),
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
                                    context.pushNamed(ContactAssignmentWidget.routeName);
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
                                          color: FlutterFlowTheme.of(context)
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
                                    : (_activities == null || _activities!.isEmpty)
                                        ? const Center(
                                            child: Text(
                                              'No recent activity logs',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          )
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: _activities!.map((activity) {
                                              final outcome = activity.callOutcome;
                                              final outcomeName = outcome is Known<CallOutcome> ? outcome.value.name : outcome.stringValue;
                                              final followUp = activity.followUpStatus;
                                              final followUpName = followUp != null
                                                  ? (followUp is Known<FollowUpStatus> ? " - ${followUp.value.name}" : " - ${followUp.stringValue}")
                                                  : "";

                                              return ActivityItemWidget(
                                                action: '${activity.enabler.name} called ${activity.contact.name}: $outcomeName$followUpName',
                                                dotColor: _getOutcomeColor(outcome),
                                                time: timeago.format(activity.calledAt.toDateTime()),
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
  );
}
}
