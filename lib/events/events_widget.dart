import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/admin_nav_bar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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

  List<Map<String, dynamic>>? _events;

  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EventsModel());
    _loadEvents();
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
      final res = await Supabase.instance.client
          .from('event')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _events = res;
        _loadingEvents = false;
      });
    } catch (e) {
      debugPrint("Error loading events: $e");
      setState(() {
        _loadingEvents = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load events: $e'),
            backgroundColor: Colors.redAccent),
      );
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
              child: Text('Cancel',
                  style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.from('event').delete().eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Event deleted cleanly'),
            backgroundColor: Colors.green),
      );
      _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to delete event: $e'),
            backgroundColor: Colors.redAccent),
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
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          24.0, 16.0, 24.0, 16.0),
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
                                          fontWeight: FontWeight.w800),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.2,
                                    ),
                              ),
                              Text(
                                'Events Calendar',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
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
                              backgroundColor:
                                  FlutterFlowTheme.of(context).primary,
                              foregroundColor:
                                  FlutterFlowTheme.of(context).onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
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
                                // Section Title
                                Text(
                                  'Campaigns & Events',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                      ),
                                ),
                                const SizedBox(height: 16.0),

                                // Events List
                                if (_events == null || _events!.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Text(
                                        'No active campaigns/events scheduled',
                                        style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: _events!.map((event) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                            border: Border.all(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .alternate,
                                              width: 2.0,
                                            ),
                                          ),
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
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Flexible(
                                                                child: Text(
                                                                  event['name'] as String,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .override(
                                                                        font: GoogleFonts.inter(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                      ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8.0),
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8.0,
                                                                    vertical:
                                                                        4.0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: _getEventStatusColor(
                                                                          event['status'] as String)
                                                                      .withOpacity(
                                                                          0.15),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12.0),
                                                                ),
                                                                child: Text(
                                                                  event['status'] as String,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .override(
                                                                        font: GoogleFonts.inter(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        color: _getEventStatusColor(
                                                                            event['status'] as String),
                                                                        fontSize:
                                                                            10.0,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 4.0),
                                                          if (event['description'] !=
                                                                  null &&
                                                              (event['description'] as String)
                                                                  .isNotEmpty)
                                                            Text(
                                                              event['description'] as String,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmall
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                                  ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary,
                                                              size: 20),
                                                          onPressed: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        CreateEventDialog(
                                                                  onEventCreated:
                                                                      _loadEvents,
                                                                  eventToEdit:
                                                                      event,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons
                                                                  .delete_outline_rounded,
                                                              color: Colors
                                                                  .redAccent,
                                                              size: 20),
                                                          onPressed: () =>
                                                              _deleteEvent(
                                                                  event['id'] as String),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16.0),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .calendar_today_rounded,
                                                            size: 14,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .accent3),
                                                        const SizedBox(
                                                            width: 4.0),
                                                        Expanded(
                                                          child: Text(
                                                            '${DateFormat('EEEE, MMM d').format(DateTime.parse(event['event_date'] as String))} • ${event['event_time'] ?? '00:00 AM'}',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .inter(),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5.0),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton
                                                              .icon(
                                                            onPressed: () {
                                                              context.push(
                                                                  '/events/analytics?eventId=${event['id']}');
                                                            },
                                                            icon: const Icon(
                                                                Icons
                                                                    .analytics_outlined,
                                                                size: 14),
                                                            label: const Text(
                                                                'Dashboard'),
                                                            style:
                                                                OutlinedButton
                                                                    .styleFrom(
                                                              foregroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                              side: BorderSide(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary),
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8.0)),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10.0,
                                                                      vertical:
                                                                          6.0),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8.0),
                                                        Expanded(
                                                          child: ElevatedButton
                                                              .icon(
                                                            onPressed: () {
                                                              context.go(
                                                                  '/contactAssignment?tab=contacts&eventId=${event['id']}');
                                                            },
                                                            icon: const Icon(
                                                                Icons
                                                                    .people_alt_outlined,
                                                                size: 14),
                                                            label: const Text(
                                                                'Manage RSVP'),
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                              foregroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .onPrimary,
                                                              elevation: 0,
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8.0)),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10.0,
                                                                      vertical:
                                                                          6.0),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
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

  Color _getEventStatusColor(String statusStr) {
    switch (statusStr.toUpperCase()) {
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
