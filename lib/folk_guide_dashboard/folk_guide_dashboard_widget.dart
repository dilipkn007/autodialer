import '/components/stat_card_widget.dart';
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
import '/components/app_drawer.dart';
import 'recent_activity_widget.dart' show formatTime;
import '/events/create_event_dialog.dart';

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
    AuthService.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    _model.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    // Reload all dashboard data whenever the effective role or folk guide
    // changes (e.g. Admin ↔ Folk Guide mode, or switching between guides).
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    safeSetState(() {
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

      List<String>? folkContactIds;
      if (isFg) {
        final folkRes = await supabase
            .from('contact')
            .select('id')
            .eq('folk_guide', fgId!);
        folkContactIds = folkRes.map((c) => c['id'] as String).toList();
      }

      // Action Items
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      dynamic followUpsQuery = supabase.from('call_log').select('id').eq('next_call_date', todayStr);
      dynamic pendingQuery = supabase.from('assignment').select('id').eq('status', 'PENDING');

      // Funnel Stats
      dynamic totalAssignsQuery = supabase.from('assignment').select('id');
      dynamic totalCallsQuery = supabase.from('call_log').select('id');
      dynamic answeredCallsQuery = supabase.from('call_log').select('id').eq('call_outcome', 'ANSWERED');
      dynamic interestedCallsQuery = supabase.from('call_log').select('id').inFilter('follow_up_status', ['INTERESTED', 'JOINED']);

      if (isFg) {
        if (folkContactIds == null || folkContactIds.isEmpty) {
          final dummy = <String>[''];
          followUpsQuery = followUpsQuery.inFilter('contact_id', dummy);
          pendingQuery = pendingQuery.inFilter('contact_id', dummy);
          totalAssignsQuery = totalAssignsQuery.inFilter('contact_id', dummy);
          totalCallsQuery = totalCallsQuery.inFilter('contact_id', dummy);
          answeredCallsQuery = answeredCallsQuery.inFilter('contact_id', dummy);
          interestedCallsQuery = interestedCallsQuery.inFilter('contact_id', dummy);
        } else {
          followUpsQuery = followUpsQuery.inFilter('contact_id', folkContactIds);
          pendingQuery = pendingQuery.inFilter('contact_id', folkContactIds);
          totalAssignsQuery = totalAssignsQuery.inFilter('contact_id', folkContactIds);
          totalCallsQuery = totalCallsQuery.inFilter('contact_id', folkContactIds);
          answeredCallsQuery = answeredCallsQuery.inFilter('contact_id', folkContactIds);
          interestedCallsQuery = interestedCallsQuery.inFilter('contact_id', folkContactIds);
        }
      }

      final resultsList = await Future.wait<dynamic>([
        followUpsQuery.count(CountOption.exact),
        pendingQuery.count(CountOption.exact),
        totalAssignsQuery.count(CountOption.exact),
        totalCallsQuery.count(CountOption.exact),
        answeredCallsQuery.count(CountOption.exact),
        interestedCallsQuery.count(CountOption.exact),
      ]);

      final followUpsCount = resultsList[0];
      final pendingCount = resultsList[1];
      final totalAssigns = resultsList[2];
      final totalCalls = resultsList[3];
      final answeredCalls = resultsList[4];
      final interestedCalls = resultsList[5];

      // Active Campaigns Progress
      final campaigns = await supabase
          .from('event')
          .select('id, name')
          .eq('status', 'ACTIVE');

      // Fetch assignment counts (total + completed) for each campaign
      final campaignIds = campaigns.map((c) => c['id']).toList();
      Map<String, int> campaignTotalCounts = {};
      Map<String, int> campaignCompletedCounts = {};
      if (campaignIds.isNotEmpty) {
        dynamic assignCountQuery = supabase
            .from('assignment')
            .select('event_id, status')
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
        final assignmentRows = await assignCountQuery;
        for (var a in assignmentRows) {
          final eventId = a['event_id'] as String;
          campaignTotalCounts[eventId] = (campaignTotalCounts[eventId] ?? 0) + 1;
          if (a['status'] == 'COMPLETED') {
            campaignCompletedCounts[eventId] = (campaignCompletedCounts[eventId] ?? 0) + 1;
          }
        }
      }
      
      final campaignsWithCounts = campaigns
          .map<Map<String, dynamic>>((c) => {
        ...c,
        'assignment_count': campaignTotalCounts[c['id']] ?? 0,
        'completed_count': campaignCompletedCounts[c['id']] ?? 0,
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
      
      final activitiesWithNames = (activities as List)
          .map<Map<String, dynamic>>((a) => {
                ...(a as Map<String, dynamic>),
                'contact': {'name': activityNames[a['contact_id']] ?? ''},
                'enabler': {'name': activityNames[a['enabler_id']] ?? ''},
              })
          .toList();

      safeSetState(() {
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

        _activeCampaigns = campaignsWithCounts;
        _activities = activitiesWithNames;

        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      safeSetState(() {
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
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 14,
            backgroundColor: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final auth = AuthService.instance;
        if (auth.role != null && auth.effectiveRole != auth.role) {
          auth.setEffectiveRole(auth.role!);
          final target = switch (auth.role) {
            UserRole.ADMIN => '/folkGuideDashboard',
            UserRole.FOLK_GUIDE => '/folkGuideDashboard',
            UserRole.FOLK => '/folkDashboard',
            _ => '/assignedContacts',
          };
          Future.microtask(() {
            if (context.mounted) context.go(target);
          });
        }
      },
      child: GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        endDrawer: const AppDrawer(),
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
                      IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 28.0,
                        ),
                        onPressed: () {
                          scaffoldKey.currentState?.openEndDrawer();
                        },
                        tooltip: 'Menu',
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
                                        updateCallback: () =>
                                            safeSetState(() {}),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 26.0,
                                    ),
                                    tooltip: 'Create Event',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreateEventDialog(
                                            onEventCreated: _loadDashboardData,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
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
                                        final total = campaign['assignment_count'] as int? ?? 0;
                                        final completed = campaign['completed_count'] as int? ?? 0;
                                        final progress = total == 0
                                            ? 0.0
                                            : (completed / total).clamp(0.0, 1.0);
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
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(8.0),
                                            onTap: () {
                                              context.push('/events/analytics?eventId=${campaign['id']}');
                                            },
                                            child: Padding(
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
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4.0),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                          .alternate,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                          .primary,
                                                  minHeight: 6.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
