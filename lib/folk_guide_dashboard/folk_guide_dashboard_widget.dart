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
  int _dormantContacts = 0;
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
      final statsRes = await DefaultConnector.instance.getContactStats().execute();
      final activityRes = await DefaultConnector.instance.getRecentActivity(limit: 5).execute();

      setState(() {
        _totalContacts = statsRes.data.totalContacts.length;
        _activeContacts = statsRes.data.activeContacts.length;
        _dormantContacts = statsRes.data.dormantContacts.length;
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
                          Container(
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
                                      label: 'Dormant Contacts',
                                      value: _loading ? '...' : '$_dormantContacts',
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
                                      label: 'Joined (Week)',
                                      value: _loading ? '...' : '+${(_totalContacts * 0.01).round()}',
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
                                  'Follow-Up Status Distribution',
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
                                  height: 180.0,
                                  alignment:
                                      AlignmentDirectional(0.0, 0.0),
                                  child: Container(
                                    height: 140.0,
                                    child: FlutterFlowPieChart(
                                      data: FFPieChartData(
                                        values: _totalContacts == 0
                                            ? [45.0, 25.0, 15.0, 10.0, 5.0]
                                            : [
                                                _activeContacts.toDouble(),
                                                _dormantContacts.toDouble(),
                                                (_totalContacts - _activeContacts - _dormantContacts).clamp(0, 999999).toDouble(),
                                                _totalContacts * 0.05,
                                                _totalContacts * 0.02,
                                              ],
                                        colors:
                                            pieChartPieChartColorsList,
                                        radius: [50.0],
                                      ),
                                      donutHoleRadius: 40.0,
                                      donutHoleColor: Colors.transparent,
                                      sectionLabelType:
                                          PieChartSectionLabelType.value,
                                      sectionLabelStyle:
                                          FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                                color: Colors.white,
                                                fontSize: 10.0,
                                                lineHeight: 1.0,
                                              ),
                                      sectionsSpace: 4.0,
                                      startDegreeOffset: -90.0,
                                      labelPositionOffset: 0.6,
                                    ),
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
                              'Members by Center',
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
                                child: Container(
                                  height: 160.0,
                                  child: FlutterFlowBarChart(
                                    barData: [
                                      FFBarChartData(
                                        yData: ([
                                          120.0,
                                          95.0,
                                          80.0,
                                          65.0,
                                          40.0
                                        ]),
                                        color: FlutterFlowTheme.of(
                                                context)
                                            .primary,
                                      )
                                    ],
                                    xLabels: ([
                                      'Whitefield',
                                      'Koramangala',
                                      'HSR',
                                      'Electronic',
                                      'Marathahalli'
                                    ]),
                                    barWidth: 20.0,
                                    barBorderRadius:
                                        BorderRadius.circular(4.0),
                                    groupSpace: 12.0,
                                    alignment: BarChartAlignment
                                        .spaceEvenly,
                                    chartStylingInfo:
                                        ChartStylingInfo(
                                      backgroundColor:
                                          Colors.transparent,
                                      showBorder: false,
                                    ),
                                    axisBounds: AxisBounds(
                                      minY: 0.0,
                                      maxX: 4.0,
                                      maxY: 144.0,
                                    ),
                                    xAxisLabelInfo: AxisLabelInfo(
                                      showLabels: true,
                                      labelTextStyle:
                                          FlutterFlowTheme.of(
                                                  context)
                                              .bodySmall
                                              .override(
                                                font: GoogleFonts
                                                    .inter(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontWeight,
                                                ),
                                                color: FlutterFlowTheme
                                                        .of(context)
                                                    .secondaryText,
                                                fontSize: 10.0,
                                                lineHeight: 1.0,
                                              ),
                                      reservedSize: 20.0,
                                    ),
                                    yAxisLabelInfo: AxisLabelInfo(
                                      reservedSize: 0.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
