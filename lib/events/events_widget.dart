import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/admin_nav_bar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'create_event_dialog.dart';
import 'events_model.dart';
export 'events_model.dart';

class EventsWidget extends StatefulWidget {
  const EventsWidget({super.key});

  static String routeName = 'Events';
  static String routePath = '/events';

  @override
  State<EventsWidget> createState() => _EventsWidgetState();
}

class _EventsWidgetState extends State<EventsWidget> {
  late EventsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<ListEventsEvents>? _events;
  String? _selectedEventId;
  List<GetEventCallStatsCallLogs>? _selectedCallLogs;
  List<GetEventCallStatsAssignments>? _selectedAssignments;
  GetDashboardOverviewStatsData? _overviewStats;

  bool _loadingEvents = true;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EventsModel());
    _loadOverviewStats();
    _loadEvents();
  }

  Future<void> _loadOverviewStats() async {
    try {
      final res = await DefaultConnector.instance.getDashboardOverviewStats().execute();
      setState(() {
        _overviewStats = res.data;
      });
    } catch (e) {
      debugPrint("Error loading overview stats: $e");
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loadingEvents = true;
    });
    try {
      final res = await DefaultConnector.instance.listEvents().execute();
      setState(() {
        _events = res.data.events;
        _loadingEvents = false;
        if (_events!.isNotEmpty) {
          _selectedEventId = _events!.first.id;
        } else {
          _selectedEventId = null;
          _selectedCallLogs = null;
        }
      });
      if (_selectedEventId != null) {
        _loadStats(_selectedEventId!);
      }
    } catch (e) {
      debugPrint("Error loading events: $e");
      setState(() {
        _loadingEvents = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _loadStats(String eventId) async {
    setState(() {
      _loadingStats = true;
    });
    try {
      final res = await DefaultConnector.instance.getEventCallStats(eventId: eventId).execute();
      setState(() {
        _selectedCallLogs = res.data.callLogs;
        _selectedAssignments = res.data.assignments;
        _loadingStats = false;
      });
    } catch (e) {
      debugPrint("Error loading event stats: $e");
      setState(() {
        _loadingStats = false;
      });
    }
  }

  Future<void> _deleteEvent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          title: Text(
            'Delete Event',
            style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
          ),
          content: Text(
            'Are you sure you want to delete this event? All associated survey questions, assignments, and call outcomes will be permanently removed.',
            style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await DefaultConnector.instance.deleteEvent(id: id).execute();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted cleanly'), backgroundColor: Colors.green),
      );
      _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _onCreateEventTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventDialog(
          onEventCreated: _loadEvents,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int globalActiveEvents = _overviewStats?.activeEvents.length ?? 0;
    int globalTotalCalls = _overviewStats?.totalCalls.length ?? 0;

    // Compute RSVP analytics for selected event
    int going = 0;
    int notCaring = 0;
    int undecided = 0;

    if (_selectedCallLogs != null) {
      for (final log in _selectedCallLogs!) {
        final outcome = log.callOutcome;
        final outcomeVal = outcome is Known<CallOutcome> ? outcome.value : null;
        final followUp = log.followUpStatus;
        final followUpVal = followUp != null ? (followUp is Known<FollowUpStatus> ? followUp.value : null) : null;

        if (outcomeVal == CallOutcome.ANSWERED &&
            (followUpVal == FollowUpStatus.INTERESTED || followUpVal == FollowUpStatus.JOINED)) {
          going++;
        } else if (outcomeVal == CallOutcome.NO_RESPONSE ||
            outcomeVal == CallOutcome.BUSY ||
            outcomeVal == CallOutcome.NOT_REACHABLE ||
            outcomeVal == CallOutcome.WRONG_NUMBER ||
            outcomeVal == CallOutcome.SWITCHED_OFF ||
            followUpVal == FollowUpStatus.NOT_INTERESTED) {
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

    // Compute dialing progress for selected event
    int totalAssignments = _selectedAssignments?.length ?? 0;
    int completedAssignments = 0;
    if (_selectedAssignments != null) {
      completedAssignments = _selectedAssignments!.where((a) {
        return a.status is Known<AssignmentStatus> 
            ? (a.status as Known<AssignmentStatus>).value == AssignmentStatus.COMPLETED 
            : a.status.stringValue == 'COMPLETED';
      }).length;
    }

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
              // Header
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
                      padding: const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
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
                                style: FlutterFlowTheme.of(context).labelSmall.override(
                                      font: GoogleFonts.inter(fontWeight: FontWeight.w800),
                                      color: FlutterFlowTheme.of(context).primaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.2,
                                    ),
                              ),
                              Text(
                                'Events Calendar',
                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ].divide(const SizedBox(height: 4.0)),
                          ),
                          ElevatedButton.icon(
                            onPressed: _onCreateEventTapped,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create Event'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FlutterFlowTheme.of(context).primary,
                              foregroundColor: FlutterFlowTheme.of(context).onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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

              // Body
              Expanded(
                child: _loadingEvents
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Stats Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        context,
                                        label: 'Active Campaigns',
                                        value: '$globalActiveEvents',
                                        icon: Icons.event_available_rounded,
                                        color: FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        context,
                                        label: 'Total Calls Logged',
                                        value: '$globalTotalCalls',
                                        icon: Icons.call_rounded,
                                        color: FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24.0),

                                // RSVP Breakdown card (for selected event)
                                if (_selectedEventId != null) ...[
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
                                      padding: const EdgeInsets.all(16.0),
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
                                          if (_loadingStats)
                                            const Center(
                                                child: Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: CircularProgressIndicator(),
                                            ))
                                          else ...[
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Assignments Completed', style: FlutterFlowTheme.of(context).bodyMedium),
                                                Text('$completedAssignments / $totalAssignments', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(fontWeight: FontWeight.bold))),
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
                                                )
                                              )
                                            else ...[
                                              _buildRSVPProgressBar(context,
                                                  label: 'Going', pct: goingPct, color: FlutterFlowTheme.of(context).primary),
                                              const SizedBox(height: 12.0),
                                              _buildRSVPProgressBar(context,
                                                  label: 'Not Caring', pct: notCaringPct, color: FlutterFlowTheme.of(context).primaryText),
                                              const SizedBox(height: 12.0),
                                              _buildRSVPProgressBar(context,
                                                  label: 'Undecided',
                                                  pct: undecidedPct,
                                                  color: FlutterFlowTheme.of(context).accent3),
                                            ]
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24.0),
                                ],

                                // Section Title
                                Text(
                                  'Campaigns & Events',
                                  style: FlutterFlowTheme.of(context).titleMedium.override(
                                        font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                        color: FlutterFlowTheme.of(context).primaryText,
                                      ),
                                ),
                                const SizedBox(height: 12.0),

                                // Events List
                                if (_events == null || _events!.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Text(
                                        'No active campaigns/events scheduled',
                                        style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: _events!.map((event) {
                                      final isSelected = _selectedEventId == event.id;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedEventId = event.id;
                                            });
                                            _loadStats(event.id);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                              borderRadius: BorderRadius.circular(16.0),
                                              border: Border.all(
                                                color: isSelected
                                                    ? FlutterFlowTheme.of(context).primary
                                                    : FlutterFlowTheme.of(context).alternate,
                                                width: isSelected ? 2.0 : 1.0,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Flexible(
                                                                  child: Text(
                                                                    event.name,
                                                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                                          font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                        ),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 8.0),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                                  decoration: BoxDecoration(
                                                                    color: _getEventStatusColor(event.status).withOpacity(0.15),
                                                                    borderRadius: BorderRadius.circular(12.0),
                                                                  ),
                                                                  child: Text(
                                                                    event.status is Known<EventStatus> ? (event.status as Known<EventStatus>).value.name : event.status.stringValue,
                                                                    style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                          font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                                          color: _getEventStatusColor(event.status),
                                                                          fontSize: 10.0,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 4.0),
                                                            if (event.description != null &&
                                                                event.description!.isNotEmpty)
                                                              Text(
                                                                event.description!,
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                      font: GoogleFonts.inter(),
                                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                                    ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline_rounded,
                                                            color: Colors.redAccent, size: 20),
                                                        onPressed: () => _deleteEvent(event.id),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12.0),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.calendar_today_rounded,
                                                              size: 14, color: FlutterFlowTheme.of(context).accent3),
                                                          const SizedBox(width: 4.0),
                                                          Text(
                                                            '${DateFormat('EEEE, MMM d').format(event.eventDate)} • ${event.eventTime ?? '00:00 AM'}',
                                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                                  font: GoogleFonts.inter(),
                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          // Navigate to contact assignment with tab=contacts and eventId query param
                                                          context.go('/contactAssignment?tab=contacts&eventId=${event.id}');
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              FlutterFlowTheme.of(context).primaryContainer,
                                                          foregroundColor: FlutterFlowTheme.of(context).primary,
                                                          elevation: 0,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8.0),
                                                            side: BorderSide(
                                                              color: FlutterFlowTheme.of(context).primary,
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 12.0, vertical: 8.0),
                                                        ),
                                                        child: Text(
                                                          'Manage RSVP',
                                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                                color: FlutterFlowTheme.of(context).primary,
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
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),

              // Navigation Bar
              const AdminNavBar(currentTab: AdminTab.events),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 20),
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

  Widget _buildRSVPProgressBar(BuildContext context, {required String label, required int pct, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
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
        const SizedBox(height: 6.0),
        Stack(
          children: [
            Container(
              height: 8.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).alternate,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            Container(
              height: 8.0,
              width: (MediaQuery.of(context).size.width - 80) * (pct / 100),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getEventStatusColor(EnumValue<EventStatus> status) {
    final statusStr = status is Known<EventStatus> ? status.value.name : status.stringValue;
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
}
