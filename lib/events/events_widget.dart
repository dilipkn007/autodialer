import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/admin_nav_bar.dart';
import '/components/app_drawer.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'create_event_dialog.dart';
import 'campaign_template_helper.dart';
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
  Set<String> _currentUserIds = {};
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
      final client = Supabase.instance.client;
      final auth = AuthService.instance;
      final isAdmin = auth.role == UserRole.ADMIN;

      if (isAdmin) {
        final res = await client
            .from('event')
            .select()
            .order('created_at', ascending: false);
        if (mounted) {
          setState(() {
            _events = res;
            _loadingEvents = false;
          });
        }
        return;
      }

      // Non-admin user: Show events created by the user OR assigned to the user
      final uid = auth.currentUser?.id ?? "";
      final userIds = <String>{};
      if (uid.isNotEmpty) userIds.add(uid);
      if (auth.contactId != null && auth.contactId!.isNotEmpty) {
        userIds.add(auth.contactId!);
      }

      final authPhone = auth.currentUser?.phone ?? "";
      final cleanDigits = authPhone.replaceAll(RegExp(r'\D'), '');
      if (cleanDigits.isNotEmpty) {
        final raw10 = cleanDigits.length >= 10
            ? cleanDigits.substring(cleanDigits.length - 10)
            : cleanDigits;
        final formatVariants = <String>{
          authPhone,
          cleanDigits,
          raw10,
          '91$raw10',
          '+91$raw10',
          '0$raw10',
        };
        formatVariants.remove('');

        final phoneContacts = await client
            .from('contact')
            .select('id, mobile')
            .inFilter('mobile', formatVariants.toList());

        for (var c in phoneContacts) {
          final cid = c['id'] as String?;
          if (cid != null && cid.isNotEmpty) userIds.add(cid);
        }
      }

      final authEmail = auth.userEmail ?? auth.currentUser?.email;
      if (authEmail != null && authEmail.isNotEmpty) {
        final emailContacts = await client
            .from('contact')
            .select('id')
            .eq('email', authEmail);
        for (var c in emailContacts) {
          final cid = c['id'] as String?;
          if (cid != null && cid.isNotEmpty) userIds.add(cid);
        }
      }

      _currentUserIds = userIds;

      if (userIds.isEmpty) {
        if (mounted) {
          setState(() {
            _events = [];
            _loadingEvents = false;
          });
        }
        return;
      }

      // 1. Fetch events created by user
      final createdEvents = await client
          .from('event')
          .select()
          .inFilter('created_by', userIds.toList());

      // 2. Fetch events assigned to user
      final userAssignments = await client
          .from('assignment')
          .select('event_id')
          .inFilter('enabler_id', userIds.toList());

      final assignedEventIds = userAssignments
          .map((a) => a['event_id'] as String?)
          .whereType<String>()
          .toSet();

      List<Map<String, dynamic>> assignedEvents = [];
      if (assignedEventIds.isNotEmpty) {
        assignedEvents = await client
            .from('event')
            .select()
            .inFilter('id', assignedEventIds.toList());
      }

      // 3. Merge and sort by created_at descending
      final Map<String, Map<String, dynamic>> eventMap = {};
      for (final ev in createdEvents) {
        final id = ev['id'] as String?;
        if (id != null) eventMap[id] = ev;
      }
      for (final ev in assignedEvents) {
        final id = ev['id'] as String?;
        if (id != null) eventMap[id] = ev;
      }

      final allEvents = eventMap.values.toList();
      allEvents.sort((a, b) {
        final aDate = a['created_at'] != null
            ? DateTime.tryParse(a['created_at'].toString()) ?? DateTime(1970)
            : DateTime(1970);
        final bDate = b['created_at'] != null
            ? DateTime.tryParse(b['created_at'].toString()) ?? DateTime(1970)
            : DateTime(1970);
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _events = allEvents;
          _loadingEvents = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading events: $e");
      if (mounted) {
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
    final isAdmin = AuthService.instance.role == UserRole.ADMIN;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        floatingActionButton: FloatingActionButton(
          onPressed: _onCreateEventTapped,
          backgroundColor: FlutterFlowTheme.of(context).primary,
          child: const Icon(Icons.add),
        ),
        endDrawer: const AppDrawer(),
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
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.file_download_outlined,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 26.0,
                                ),
                                onPressed: () => CampaignTemplateHelper.downloadSampleCsvTemplate(context),
                                tooltip: 'Download Campaign CSV Template',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 28.0,
                                ),
                                onPressed: _onCreateEventTapped,
                                tooltip: 'Create Event',
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
                                        'No campaigns/events scheduled or assigned yet.\nTap "+" to create your first event.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: _events!.map((event) {
                                      final canManage = isAdmin ||
                                          (event['created_by'] != null &&
                                              _currentUserIds.contains(
                                                  event['created_by']));
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
                                                    if (canManage)
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
                                                    const SizedBox(height: 8.0),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton.icon(
                                                        onPressed: () {
                                                          context.go(
                                                              '/assignedContacts?eventId=${event['id']}');
                                                        },
                                                        icon: const Icon(
                                                            Icons
                                                                .phone_in_talk_rounded,
                                                            size: 16),
                                                        label: const Text(
                                                            'Start Calling'),
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
                                                                      14.0,
                                                                  vertical:
                                                                      10.0),
                                                        ),
                                                      ),
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
