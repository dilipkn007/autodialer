import '/components/stat_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // New Data
  int _todayFollowUpsCount = 0;
  int _pendingAssignmentsCount = 0;
  
  int _totalAssignments = 0;
  int _totalCallsMade = 0;
  int _totalAnswered = 0;
  int _totalInterested = 0;

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

      // Overview Stats
      final contactsCount = await supabase.from('contact').select('id').count(CountOption.exact);
      final enablersCount = await supabase.from('users').select('uid').eq('role', 'ENABLER').count(CountOption.exact);
      final eventsCount = await supabase.from('event').select('id').eq('status', 'ACTIVE').count(CountOption.exact);

      // Action Items
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final followUpsCount = await supabase.from('call_log').select('id').eq('next_call_date', todayStr).count(CountOption.exact);
      final pendingCount = await supabase.from('assignment').select('id').eq('status', 'PENDING').count(CountOption.exact);

      // Funnel Stats
      final totalAssigns = await supabase.from('assignment').select('id').count(CountOption.exact);
      final totalCalls = await supabase.from('call_log').select('id').count(CountOption.exact);
      final answeredCalls = await supabase.from('call_log').select('id').eq('call_outcome', 'ANSWERED').count(CountOption.exact);
      final interestedCalls = await supabase.from('call_log').select('id').inFilter('follow_up_status', ['INTERESTED', 'JOINED']).count(CountOption.exact);

      // Active Campaigns Progress
      final campaigns = await supabase.from('event')
          .select('id, name, assignment(id, status)')
          .eq('status', 'ACTIVE');
          
      // Recent Activity
      final activities = await supabase.from('call_log')
          .select('*, contact:contact_id(name), user:users(name)')
          .order('called_at', ascending: false)
          .limit(5);

      setState(() {
        _totalContacts = contactsCount.count;
        _activeContacts = contactsCount.count; // Placeholder
        _totalEnablers = enablersCount.count;
        _activeEvents = eventsCount.count;
        
        _todayFollowUpsCount = followUpsCount.count;
        _pendingAssignmentsCount = pendingCount.count;
        
        _totalAssignments = totalAssigns.count;
        _totalCallsMade = totalCalls.count;
        _totalAnswered = answeredCalls.count;
        _totalInterested = interestedCalls.count;

        _activeCampaigns = campaigns;
        _activities = activities;

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

  Widget _buildFunnelStep(String title, int value, int maxVal, Color color) {
    double progress = maxVal == 0 ? 0 : value / maxVal;
    // ensure progress is <= 1.0 (sometimes calls made can exceed assignments if multiple calls are made)
    if (progress > 1.0) progress = 1.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: FlutterFlowTheme.of(context).primaryText)),
            Text('$value', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 28,
          width: double.infinity,
          decoration: BoxDecoration(color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: progress > 0.1 ? Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ) : const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
                                        label: 'Today\'s \nFollow-ups',
                                        value: _loading
                                            ? '...'
                                            : '$_todayFollowUpsCount',
                                        icon: Icons.calendar_today_rounded,
                                        iconColor: const Color(0xFFEF4444), // Red for urgent
                                        iconBgColor: const Color(0xFFFEE2E2),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: wrapWithModel(
                                      model: _model.statCardModel2,
                                      updateCallback: () => safeSetState(() {}),
                                      child: StatCardWidget(
                                        label: 'Pending \nAssignments',
                                        value: _loading
                                            ? '...'
                                            : '$_pendingAssignmentsCount',
                                        icon: Icons.assignment_late_rounded,
                                        iconColor: const Color(0xFFF59E0B), // Orange/Amber
                                        iconBgColor: const Color(0xFFFEF3C7),
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
                                    'Conversion Funnel',
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
                                  const SizedBox(height: 24.0),
                                  if (_totalAssignments == 0 && _totalCallsMade == 0)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: Text("No data available for funnel",
                                            style: TextStyle(color: Colors.grey)),
                                      ),
                                    )
                                  else
                                    Column(
                                      children: [
                                        _buildFunnelStep('Total Assigned', _totalAssignments, _totalAssignments, const Color(0xFF3B82F6)),
                                        const SizedBox(height: 16),
                                        _buildFunnelStep('Calls Made', _totalCallsMade, _totalAssignments, const Color(0xFF8B5CF6)),
                                        const SizedBox(height: 16),
                                        _buildFunnelStep('Answered', _totalAnswered, _totalAssignments, const Color(0xFFF59E0B)),
                                        const SizedBox(height: 16),
                                        _buildFunnelStep('Interested / Joined', _totalInterested, _totalAssignments, const Color(0xFF10B981)),
                                      ],
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
                                      final assignments = campaign['assignment'] as List<dynamic>? ?? [];
                                      final total = assignments.length;
                                      final completed = assignments.where((a) => a['status'] == 'COMPLETED').length;
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
                                                  Text(campaign['name'] as String,
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
                                                final outcomeName = activity['call_outcome'] as String? ?? 'UNKNOWN';
                                                final followUpName = activity['follow_up_status'] as String?;
                                                
                                                final contactName = activity['contact'] != null ? activity['contact']['name'] : 'Unknown';
                                                final enablerName = activity['user'] != null ? activity['user']['name'] : 'Unknown';
                                                
                                                final outcomeColor =
                                                    _getOutcomeColorString(outcomeName);
                                                final outcomeBg =
                                                    _getOutcomeBgString(outcomeName);
                                                final outcomeIcon =
                                                    _getOutcomeIconString(outcomeName);

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
                                                                      contactName,
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
                                                                '$enablerName logged call with $contactName',
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .accent3,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                              if (followUpName != null &&
                                                                  followUpName
                                                                  .isNotEmpty) ...[
                                                                const SizedBox(
                                                                    height: 3),
                                                                Text(
                                                                  followUpName.replaceAll('_', ' '),
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
                                                                '${formatTime(DateTime.parse(activity['called_at'] as String))} • $outcomeName',
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
