import '/components/stat_card_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:intl/intl.dart';
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
      final overviewRes =
          await DefaultConnector.instance.getDashboardOverviewStats().execute();
      final outcomeRes = await DefaultConnector.instance
          .getCallOutcomeDistribution()
          .execute();
      final campaignRes = await DefaultConnector.instance
          .getActiveCampaignsProgress()
          .execute();
      final activityRes =
          await DefaultConnector.instance.getRecentActivity(limit: 5).execute();

      Map<String, int> outcomes = {};
      for (final log in outcomeRes.data.callLogs) {
        final outcome = log.callOutcome;
        final key = outcome is Known<CallOutcome>
            ? outcome.value.name
            : outcome.stringValue;
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

  Color _getOutcomeColor(EnumValue<CallOutcome> outcome) {
    if (outcome is Known<CallOutcome>) {
      switch (outcome.value) {
        case CallOutcome.ANSWERED:
          return const Color(0xFF2E7D32);
        case CallOutcome.BUSY:
          return const Color(0xFFE65100);
        case CallOutcome.NO_RESPONSE:
          return const Color(0xFF6A1B9A);
        default:
          return const Color(0xFFC62828);
      }
    }
    return const Color(0xFF546E7A);
  }

  Color _getOutcomeBg(EnumValue<CallOutcome> outcome) {
    if (outcome is Known<CallOutcome>) {
      switch (outcome.value) {
        case CallOutcome.ANSWERED:
          return const Color(0xFFE8F5E9);
        case CallOutcome.BUSY:
          return const Color(0xFFFFF3E0);
        case CallOutcome.NO_RESPONSE:
          return const Color(0xFFF3E5F5);
        default:
          return const Color(0xFFFFEBEE);
      }
    }
    return const Color(0xFFECEFF1);
  }

  IconData _getOutcomeIcon(EnumValue<CallOutcome> outcome) {
    if (outcome is Known<CallOutcome>) {
      switch (outcome.value) {
        case CallOutcome.ANSWERED:
          return Icons.call_received_rounded;
        case CallOutcome.BUSY:
          return Icons.phone_missed_rounded;
        case CallOutcome.NO_RESPONSE:
          return Icons.phone_disabled_rounded;
        default:
          return Icons.phone_rounded;
      }
    }
    return Icons.phone_rounded;
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
                                alignment: const AlignmentDirectional(0.0, 0.0),
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
                                      updateCallback: () => safeSetState(() {}),
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
                                      updateCallback: () => safeSetState(() {}),
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
                                      updateCallback: () => safeSetState(() {}),
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
                                      updateCallback: () => safeSetState(() {}),
                                      child: StatCardWidget(
                                        label: 'Active \nCampaigns',
                                        value:
                                            _loading ? '...' : '$_activeEvents',
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  Container(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: _callOutcomes.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(24.0),
                                            child: Text("No calls recorded yet",
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          )
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 140.0,
                                                width: 140.0,
                                                child: FlutterFlowPieChart(
                                                  data: FFPieChartData(
                                                    values: _callOutcomes.values
                                                        .map(
                                                            (v) => v.toDouble())
                                                        .toList(),
                                                    colors: _callOutcomes.keys
                                                        .map((k) =>
                                                            _getColorForOutcomeString(
                                                                k))
                                                        .toList(),
                                                    radius: [30.0],
                                                  ),
                                                  donutHoleRadius: 36.0,
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
                                                            color: Colors.white,
                                                            fontSize: 10.0,
                                                            lineHeight: 1.0,
                                                          ),
                                                  labelFormatter: LabelFormatter(
                                                    numberFormat: (v) =>
                                                        v.toInt().toString(),
                                                  ),
                                                  sectionsSpace: 4.0,
                                                  startDegreeOffset: -90.0,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 24.0,
                                                runSpacing: 8.0,
                                                children: _callOutcomes.entries
                                                    .map((e) {
                                                  return Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 10.0,
                                                        height: 10.0,
                                                        decoration: BoxDecoration(
                                                          color: _getColorForOutcomeString(
                                                              e.key),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8.0),
                                                      Text(
                                                        e.key,
                                                        style: FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .override(
                                                              font: GoogleFonts
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
                                        fontWeight: FlutterFlowTheme.of(context)
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
                                      final total =
                                          campaign.assignments_on_event.length;
                                      final completed = campaign
                                          .assignments_on_event
                                          .where((a) {
                                        return a.status
                                                is Known<AssignmentStatus>
                                            ? (a.status as Known<
                                                        AssignmentStatus>)
                                                    .value ==
                                                AssignmentStatus.COMPLETED
                                            : a.status.stringValue ==
                                                'COMPLETED';
                                      }).length;
                                      final progress =
                                          total == 0 ? 0.0 : completed / total;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
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
                                                  Text(campaign.name,
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
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                minHeight: 6.0,
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
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
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
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
                                              children:
                                                  _activities!.map((activity) {
                                                final outcome =
                                                    activity.callOutcome;
                                                final outcomeName = outcome
                                                        is Known<CallOutcome>
                                                    ? outcome.value.name
                                                    : outcome.stringValue;
                                                final followUp =
                                                    activity.followUpStatus;
                                                final followUpName = followUp !=
                                                        null
                                                    ? (followUp is Known<
                                                            FollowUpStatus>
                                                        ? followUp.value.name
                                                            .replaceAll(
                                                                '_', ' ')
                                                        : followUp
                                                                .stringValue ??
                                                            '')
                                                    : '';
                                                final outcomeColor =
                                                    _getOutcomeColor(outcome);
                                                final outcomeBg =
                                                    _getOutcomeBg(outcome);
                                                final outcomeIcon =
                                                    _getOutcomeIcon(outcome);

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
                                                          BorderRadius.circular(
                                                              12),
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
                                                                    child: Text(
                                                                      activity
                                                                          .contact
                                                                          .name,
                                                                      style: GoogleFonts
                                                                          .outfit(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 6),
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
                                                                          BorderRadius.circular(
                                                                              20),
                                                                    ),
                                                                    child: Text(
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
                                                                activity.enabler
                                                                    .name,
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .accent3,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                              if (followUpName
                                                                  .isNotEmpty) ...[
                                                                const SizedBox(
                                                                    height: 3),
                                                                Text(
                                                                  followUpName,
                                                                  style:
                                                                      GoogleFonts
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
                                                                formatTime(activity
                                                                    .calledAt
                                                                    .toDateTime()),
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .accent3
                                                                      .withOpacity(
                                                                          0.7),
                                                                  fontSize: 10,
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
    );
  }
}
