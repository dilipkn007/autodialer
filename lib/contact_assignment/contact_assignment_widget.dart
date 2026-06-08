import '/components/button_widget.dart';
import '/components/member_card_widget.dart';
import '/components/section_header_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'contact_assignment_model.dart';

export 'contact_assignment_model.dart';

class ContactAssignmentWidget extends StatefulWidget {
  const ContactAssignmentWidget({super.key});

  static String routeName = 'ContactAssignment';
  static String routePath = '/contactAssignment';

  @override
  State<ContactAssignmentWidget> createState() =>
      _ContactAssignmentWidgetState();
}

class _ContactAssignmentWidgetState extends State<ContactAssignmentWidget> {
  late ContactAssignmentModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  ListEventsEvents? _selectedEvent;
  List<ListEventsEvents> _events = [];

  ListEnablersUsers? _selectedEnabler;
  List<ListEnablersUsers> _enablers = [];

  List<ListContactsContacts> _contacts = [];
  final Set<String> _selectedContactIds = {};

  String _searchQuery = "";
  bool _isBulkMode = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ContactAssignmentModel());
    
    // Listen to search field changes if available
    _model.textFieldModel.inputTextController ??= TextEditingController();
    _model.textFieldModel.inputTextController!.addListener(() {
      setState(() {
        _searchQuery = _model.textFieldModel.inputTextController!.text;
      });
      _loadContacts();
    });

    _loadInitialData();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
    });

    try {
      // 1. Load active events
      final eventsRes = await DefaultConnector.instance.listEvents().execute();
      _events = eventsRes.data.events;

      if (_events.isEmpty) {
        // Create a default event if none exist so user is not blocked
        final adminUid = AuthService.instance.currentUser?.uid ?? "";
        if (adminUid.isNotEmpty) {
          final defaultDate = DateTime.now();
          await DefaultConnector.instance.createEvent(
            name: "FOLK Camp Campaign",
            eventDate: defaultDate,
            status: EventStatus.ACTIVE,
            createdByUid: adminUid,
          ).execute();
          
          final freshEventsRes = await DefaultConnector.instance.listEvents().execute();
          _events = freshEventsRes.data.events;
        }
      }

      if (_events.isNotEmpty) {
        _selectedEvent = _events.first;
      }

      // 2. Load enablers
      final enablersRes = await DefaultConnector.instance.listEnablers().execute();
      _enablers = enablersRes.data.users;
      if (_enablers.isNotEmpty) {
        _selectedEnabler = _enablers.first;
      }

      // 3. Load contacts
      await _loadContacts();

    } catch (e) {
      debugPrint("Error loading assignment details: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadContacts() async {
    try {
      final contactsRes = await DefaultConnector.instance.listContacts(
        limit: 50,
        offset: 0,
      ).search(_searchQuery.isNotEmpty ? _searchQuery : null).execute();

      setState(() {
        _contacts = contactsRes.data.contacts;
      });
    } catch (e) {
      debugPrint("Error loading contacts: $e");
    }
  }

  void _selectEnablerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Enabler',
                style: FlutterFlowTheme.of(context).titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _enablers.isEmpty
                    ? const Center(child: Text('No enablers registered yet.'))
                    : ListView.builder(
                        itemCount: _enablers.length,
                        itemBuilder: (context, index) {
                          final enabler = _enablers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: FlutterFlowTheme.of(context).primary,
                              child: Text(
                                enabler.avatarInitials ?? 'E',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(enabler.name),
                            subtitle: Text(enabler.phone),
                            onTap: () {
                              setState(() {
                                _selectedEnabler = enabler;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectEventBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Campaign Event',
                    style: FlutterFlowTheme.of(context).titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      Navigator.pop(context);
                      _createEventDialog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _events.isEmpty
                    ? const Center(child: Text('No events created yet.'))
                    : ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return ListTile(
                            leading: const Icon(Icons.campaign_outlined),
                            title: Text(event.name),
                            subtitle: Text(event.eventDate.toString()),
                            onTap: () {
                              setState(() {
                                _selectedEvent = event;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _createEventDialog() {
    final nameCont = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Campaign Event'),
          content: TextField(
            controller: nameCont,
            decoration: const InputDecoration(
              hintText: 'e.g. Orientation Camp Sunday',
              labelText: 'Campaign Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCont.text.trim();
                final adminUid = AuthService.instance.currentUser?.uid ?? "";
                if (name.isNotEmpty && adminUid.isNotEmpty) {
                  try {
                    await DefaultConnector.instance.createEvent(
                      name: name,
                      eventDate: DateTime.now(),
                      status: EventStatus.ACTIVE,
                      createdByUid: adminUid,
                    ).execute();
                    Navigator.pop(context);
                    await _loadInitialData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create event: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAssignments() async {
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create an Event campaign first.')),
      );
      return;
    }
    if (_selectedEnabler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Enabler to assign contacts to.')),
      );
      return;
    }
    if (_selectedContactIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact card below.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    final enablerUid = _selectedEnabler!.uid;
    final eventId = _selectedEvent!.id;
    final adminUid = AuthService.instance.currentUser!.uid;

    try {
      int sortOrder = 0;
      await Future.wait(_selectedContactIds.map((contactId) {
        return DefaultConnector.instance.assignContact(
          contactId: contactId,
          enablerUid: enablerUid,
          eventId: eventId,
          sortOrder: sortOrder++,
          assignedByUid: adminUid,
        ).execute();
      }));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned ${_selectedContactIds.length} contacts successfully!')),
      );

      setState(() {
        _selectedContactIds.clear();
      });

      await _loadContacts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign contacts: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
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
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
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
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 40.0,
                                fillColor: Colors.transparent,
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 24.0,
                                ),
                                onPressed: () {
                                  context.safePop();
                                },
                              ),
                              InkWell(
                                onTap: _selectEventBottomSheet,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedEvent?.name ?? 'No Event Active',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            lineHeight: 1.3,
                                          ),
                                    ),
                                    Text(
                                      'Tap to switch campaign',
                                      style: FlutterFlowTheme.of(context).bodySmall.override(
                                            font: GoogleFonts.inter(),
                                            color: FlutterFlowTheme.of(context).accent3,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ].divide(SizedBox(width: 8.0)),
                          ),
                          FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 40.0,
                            fillColor: Colors.transparent,
                            icon: Icon(
                              Icons.info_outline_rounded,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            onPressed: () {
                              // Details
                            },
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
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                      hint: 'Search Name, Mobile or Folk ID',
                      value: '',
                      onChange: '',
                      onSubmit: '',
                      variant: 'outlined',
                      error: false,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isBulkMode = true;
                            });
                          },
                          child: wrapWithModel(
                            model: _model.buttonModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: ButtonWidget(
                              icon: Icon(
                                Icons.select_all_rounded,
                                color: _isBulkMode ? FlutterFlowTheme.of(context).onPrimary : FlutterFlowTheme.of(context).primaryText,
                                size: 24.0,
                              ),
                              iconPresent: true,
                              iconEndPresent: false,
                              content: 'Bulk Mode',
                              variant: _isBulkMode ? 'primary' : 'secondary',
                              size: 'medium',
                              fullWidth: true,
                              loading: false,
                              disabled: false,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isBulkMode = false;
                            });
                          },
                          child: wrapWithModel(
                            model: _model.buttonModel2,
                            updateCallback: () => safeSetState(() {}),
                            child: ButtonWidget(
                              icon: Icon(
                                Icons.person_outline_rounded,
                                color: !_isBulkMode ? FlutterFlowTheme.of(context).onPrimary : FlutterFlowTheme.of(context).primaryText,
                                size: 24.0,
                              ),
                              iconPresent: true,
                              iconEndPresent: false,
                              content: 'Individual',
                              variant: !_isBulkMode ? 'primary' : 'secondary',
                              size: 'medium',
                              fullWidth: true,
                              loading: false,
                              disabled: false,
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
                ].divide(SizedBox(height: 16.0)),
              ),
            ),
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                primary: false,
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: _selectEnablerBottomSheet,
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(16.0),
                            shape: BoxShape.rectangle,
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).primary20,
                              width: 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40.0,
                                  height: 40.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primary,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment:
                                      AlignmentDirectional(0.0, 0.0),
                                  child: Text(
                                    _selectedEnabler?.avatarInitials ?? 'FG',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          color:
                                              FlutterFlowTheme.of(context)
                                                  .onPrimary,
                                          fontSize: 15.2,
                                          lineHeight: 1.3,
                                        ),
                                    overflow: TextOverflow.clip,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Target Enabler (Caller)',
                                        style:
                                            FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .override(
                                                  font: GoogleFonts.inter(),
                                                  color:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .onPrimaryContainer,
                                                  lineHeight: 1.2,
                                                ),
                                      ),
                                      Text(
                                        _selectedEnabler == null
                                            ? 'No Enabler Selected'
                                            : '${_selectedEnabler!.name} (${_selectedEnabler!.phone})',
                                        style: FlutterFlowTheme.of(
                                                context)
                                            .titleMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                              color: FlutterFlowTheme.of(
                                                      context)
                                                  .onPrimaryContainer,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ].divide(SizedBox(height: 4.0)),
                                  ),
                                ),
                                FlutterFlowIconButton(
                                  borderRadius: 8.0,
                                  buttonSize: 40.0,
                                  fillColor: FlutterFlowTheme.of(context)
                                      .onPrimaryContainer10,
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .primary,
                                    size: 24.0,
                                  ),
                                  onPressed: _selectEnablerBottomSheet,
                                ),
                              ].divide(SizedBox(width: 16.0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      wrapWithModel(
                        model: _model.sectionHeaderModel1,
                        updateCallback: () => safeSetState(() {}),
                        child: SectionHeaderWidget(
                          count: '${_selectedContactIds.length}',
                          title: 'Selected Contacts',
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _contacts.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Text('No contacts found matching search.'),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _contacts.length,
                                  itemBuilder: (context, index) {
                                    final contact = _contacts[index];
                                    final isSelected = _selectedContactIds.contains(contact.id);
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedContactIds.remove(contact.id);
                                          } else {
                                            if (!_isBulkMode) {
                                              _selectedContactIds.clear();
                                            }
                                            _selectedContactIds.add(contact.id);
                                          }
                                        });
                                      },
                                      child: MemberCardWidget(
                                        currentEnabler: 'Unassigned',
                                        folkId: contact.folkId ?? 'No ID',
                                        name: contact.name,
                                        selected: isSelected,
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                shape: BoxShape.rectangle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 1.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      shape: BoxShape.rectangle,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ready to assign',
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight:
                                            FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .fontWeight,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.2,
                                    ),
                              ),
                              Text(
                                '${_selectedContactIds.length} Members',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ].divide(SizedBox(height: 4.0)),
                          ),
                        ),
                        InkWell(
                          onTap: _confirmAssignments,
                          child: wrapWithModel(
                            model: _model.buttonModel3,
                            updateCallback: () => safeSetState(() {}),
                            child: ButtonWidget(
                              icon: Icon(
                                Icons.check_circle_rounded,
                                color: FlutterFlowTheme.of(context).onPrimary,
                                size: 24.0,
                              ),
                              iconPresent: true,
                              iconEndPresent: false,
                              content: 'Confirm Assignment',
                              variant: 'primary',
                              size: 'large',
                              fullWidth: false,
                              loading: _loading,
                              disabled: _loading || _selectedContactIds.isEmpty,
                            ),
                          ),
                        ),
                      ].divide(SizedBox(width: 16.0)),
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
}
