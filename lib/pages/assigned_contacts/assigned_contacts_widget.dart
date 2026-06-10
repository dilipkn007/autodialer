import '/components/button_widget.dart';
import '/components/local_contact_card_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'assigned_contacts_model.dart';

export 'assigned_contacts_model.dart';

class AssignedContactsWidget extends StatefulWidget {
  const AssignedContactsWidget({super.key});

  static String routeName = 'AssignedContacts';
  static String routePath = '/assignedContacts';

  @override
  State<AssignedContactsWidget> createState() => _AssignedContactsWidgetState();
}

class _AssignedContactsWidgetState extends State<AssignedContactsWidget> {
  late AssignedContactsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<ListAllAssignmentsForEnablerAssignments> _assignments = [];
  List<ListAllAssignmentsForEnablerAssignments> _filteredAssignments = [];
  bool _loading = true;
  String _searchQuery = "";

  List<ListAllAssignmentsForEnablerAssignmentsEvent> _uniqueEvents = [];
  ListAllAssignmentsForEnablerAssignmentsEvent? _selectedEvent;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AssignedContactsModel());

    _model.textFieldModel.inputTextController ??= TextEditingController();
    _model.textFieldModel.inputTextController!.addListener(() {
      setState(() {
        _searchQuery = _model.textFieldModel.inputTextController!.text.toLowerCase();
        _filterAssignments();
      });
    });

    _loadAssignments();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadAssignments() async {
    final uid = AuthService.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final res = await DefaultConnector.instance.listAllAssignmentsForEnabler(enablerUid: uid).execute();
      setState(() {
        _assignments = res.data.assignments;
        
        final seenEvents = <String>{};
        _uniqueEvents = [];
        for (var a in _assignments) {
          if (!seenEvents.contains(a.event.id)) {
            seenEvents.add(a.event.id);
            _uniqueEvents.add(a.event);
          }
        }
        if (_uniqueEvents.isNotEmpty && _selectedEvent == null) {
          _selectedEvent = _uniqueEvents.first;
        }

        _filterAssignments();
      });
    } catch (e) {
      debugPrint("Error loading assignments: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _filterAssignments() {
    _filteredAssignments = _assignments.where((a) {
      if (_selectedEvent != null && a.event.id != _selectedEvent!.id) {
        return false;
      }

      if (_statusFilter == 'Pending') {
        if (a.status.stringValue != 'PENDING' && a.status.stringValue != 'NEW') return false;
      } else if (_statusFilter == 'Completed') {
        if (a.status.stringValue != 'COMPLETED') return false;
      }

      if (_searchQuery.isNotEmpty) {
        final name = a.contact.name.toLowerCase();
        final mobile = a.contact.mobile.toLowerCase();
        final folkId = (a.contact.folkId ?? "").toLowerCase();
        if (!name.contains(_searchQuery) &&
            !mobile.contains(_searchQuery) &&
            !folkId.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
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
                padding: EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 16.0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
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
                                'Assigned Contacts',
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .fontStyle,
                                      lineHeight: 1.2,
                                    ),
                              ),
                              Text(
                                'Manage your follow-up list',
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
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.logout_rounded, color: FlutterFlowTheme.of(context).primaryText),
                            onPressed: () async {
                              await AuthService.instance.signOut();
                            },
                          ),
                        ],
                      ),
                      wrapWithModel(
                        model: _model.textFieldModel,
                        updateCallback: () => safeSetState(() {}),
                        child: TextFieldWidget(
                          label: '',
                          labelPresent: false,
                          helper: '',
                          helperPresent: false,
                          leadingIcon: Icon(
                            Icons.search_rounded,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                          leadingIconPresent: true,
                          trailingIconPresent: false,
                          hint: 'Search Name, Mobile, or Folk ID...',
                          value: '',
                          onChange: '',
                          onSubmit: '',
                          variant: 'outlined',
                          error: false,
                        ),
                      ),
                      if (_uniqueEvents.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _uniqueEvents.map((event) {
                              final isSelected = _selectedEvent?.id == event.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(event.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedEvent = event;
                                        _filterAssignments();
                                      });
                                    }
                                  },
                                  selectedColor: FlutterFlowTheme.of(context).primary,
                                  backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                                  labelStyle: TextStyle(
                                    color: isSelected ? FlutterFlowTheme.of(context).onPrimary : FlutterFlowTheme.of(context).primaryText,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Builder(builder: (context) {
                          final campaignAssignments = _assignments.where((a) => a.event.id == _selectedEvent?.id).toList();
                          final total = campaignAssignments.length;
                          final completed = campaignAssignments.where((a) => a.status.stringValue == 'COMPLETED').length;
                          final progress = total > 0 ? completed / total : 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Progress: ${(progress * 100).toInt()}%', style: FlutterFlowTheme.of(context).bodyMedium),
                                  Text('$completed/$total Completed', style: FlutterFlowTheme.of(context).bodyMedium),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(FlutterFlowTheme.of(context).primary),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Pending', 'Completed'].map((status) {
                              final isSelected = _statusFilter == status;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(status),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _statusFilter = status;
                                        _filterAssignments();
                                      });
                                    }
                                  },
                                  selectedColor: FlutterFlowTheme.of(context).alternate,
                                  backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
                                  labelStyle: TextStyle(
                                    color: isSelected ? FlutterFlowTheme.of(context).primaryText : FlutterFlowTheme.of(context).secondaryText,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ].divide(SizedBox(height: 16.0)),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: RefreshIndicator(
                onRefresh: _loadAssignments,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredAssignments.isEmpty
                        ? ListView(
                            children: const [
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(48.0),
                                  child: Text('No assigned contacts found.'),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _filteredAssignments.length,
                            itemBuilder: (context, index) {
                              final assignment = _filteredAssignments[index];
                              final contact = assignment.contact;
                              final initials = contact.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
                              
                              return InkWell(
                                onTap: () {
                                  CallingDashboardWidget.currentAssignment = assignment;
                                  CallingDashboardWidget.onAssignmentUpdated = () {
                                    if (mounted) _loadAssignments();
                                  };
                                  context.pushNamed(CallingDashboardWidget.routeName);
                                },
                                child: LocalContactCardWidget(
                                  city: contact.city ?? 'Unknown',
                                  date: assignment.status.stringValue,
                                  folkId: contact.folkId ?? 'No ID',
                                  initials: initials.isNotEmpty ? initials : 'C',
                                  name: contact.name,
                                ),
                              );
                            },
                          ),
              ),
            ),
            if (!_loading && _assignments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () async {
                        final pending = _assignments
                            .where((a) => a.event.id == _selectedEvent?.id && (a.status.stringValue == 'PENDING' || a.status.stringValue == 'NEW'))
                            .toList();
                        if (pending.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No pending assignments to call!')),
                          );
                          return;
                        }
                        AutoDialerWidget.pendingAssignments = pending;
                        AutoDialerWidget.onAssignmentsUpdated = () {
                          if (mounted) _loadAssignments();
                        };
                        context.pushNamed(AutoDialerWidget.routeName);
                      },
                      child: wrapWithModel(
                        model: _model.buttonModel,
                        updateCallback: () => safeSetState(() {}),
                        child: ButtonWidget(
                          icon: Icon(
                            Icons.play_arrow_rounded,
                            color: FlutterFlowTheme.of(context).onPrimary,
                            size: 24.0,
                          ),
                          iconPresent: true,
                          iconEndPresent: false,
                          content: 'Start Auto Dialer (${_filteredAssignments.where((a) => a.status.stringValue != 'COMPLETED').length} Pending)',
                          variant: 'primary',
                          size: 'large',
                          fullWidth: false,
                          loading: false,
                          disabled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}
