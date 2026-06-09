import 'dart:math' as math;
import '/components/button_widget.dart';
import '/components/member_card_widget.dart';
import '/components/section_header_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import '/components/admin_nav_bar.dart';
import 'contact_assignment_model.dart';

export 'contact_assignment_model.dart';

class ContactAssignmentWidget extends StatefulWidget {
  final String tab;
  final String? eventId;
  const ContactAssignmentWidget(
      {super.key, this.tab = 'contacts', this.eventId});

  static String routeName = 'ContactAssignment';
  static String routePath = '/contactAssignment';

  @override
  State<ContactAssignmentWidget> createState() =>
      _ContactAssignmentWidgetState();
}

class _ContactAssignmentWidgetState extends State<ContactAssignmentWidget> {
  late ContactAssignmentModel _model;
  Function(int processed, int success, int fail, List<String> errors)?
      _updateImportProgress;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  ListEventsEvents? _selectedEvent;
  List<ListEventsEvents> _events = [];

  ListEnablersUsers? _selectedEnabler;
  List<ListEnablersUsers> _enablers = [];

  List<ListContactsContacts> _allContacts = [];
  List<ListContactsContacts> _contacts = [];
  final Set<String> _selectedContactIds = {};

  // Filters
  String? _selectedCenterFilter;
  String? _selectedGuideFilter;
  String? _selectedLevelFilter;
  String? _selectedGenderFilter;

  // Filter Options (Computed dynamically)
  List<String> _centerOptions = [];
  List<String> _guideOptions = [];
  List<String> _levelOptions = [];
  List<String> _genderOptions = [];

  List<ListAssignmentsForEventAssignments> _assignments = [];
  List<ListAssignmentsForEventAssignments> _filteredAssignments = [];
  Map<String, String> _contactIdToEnablerName = {};

  String _searchQuery = "";
  bool _isBulkMode = true;
  bool _loading = true;
  int _displayLimit = 50;

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
      if (widget.tab == 'calls') {
        _filterAssignments();
      } else {
        _applyFilters();
      }
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
          await DefaultConnector.instance
              .createEvent(
                name: "FOLK Camp Campaign",
                eventDate: defaultDate,
                status: EventStatus.ACTIVE,
                createdByUid: adminUid,
              )
              .execute();

          final freshEventsRes =
              await DefaultConnector.instance.listEvents().execute();
          _events = freshEventsRes.data.events;
        }
      }

      if (_events.isNotEmpty) {
        if (widget.eventId != null) {
          _selectedEvent = _events.firstWhere(
            (e) => e.id == widget.eventId,
            orElse: () => _events.first,
          );
        } else {
          _selectedEvent = _events.first;
        }
      }

      // 2. Load enablers
      if (widget.tab == 'contacts') {
        final enablersRes =
            await DefaultConnector.instance.listEnablers().execute();
        _enablers = enablersRes.data.users;
        if (_enablers.isNotEmpty) {
          _selectedEnabler = _enablers.first;
        }
      }

      // 3. Load contacts or assignments
      if (widget.tab == 'calls') {
        await _loadAssignments();
      } else {
        await _loadContacts();
      }
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
      setState(() {
        _loading = true;
      });
      // Load all contacts (up to 5000) so we can do local Excel-like filters
      final contactsRes = await DefaultConnector.instance
          .listContacts(
            limit: 5000,
            offset: 0,
          )
          .search("")
          .execute();

      _allContacts = contactsRes.data.contacts;

      // Fetch assignments for the selected event to build lookup map
      final eventId = _selectedEvent?.id;
      if (eventId != null) {
        final assignmentsRes = await DefaultConnector.instance
            .listAssignmentsForEvent(eventId: eventId)
            .execute();
        _assignments = assignmentsRes.data.assignments;
        _contactIdToEnablerName = {
          for (var a in _assignments) a.contact.id: a.enabler.name
        };
      } else {
        _assignments = [];
        _contactIdToEnablerName = {};
      }

      // Clear options so they are re-evaluated from the new dataset
      _centerOptions.clear();
      _guideOptions.clear();
      _levelOptions.clear();
      _genderOptions.clear();

      _applyFilters();
    } catch (e) {
      debugPrint("Error loading contacts: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    // 1. Compute dynamic filter options from all contacts (if options are empty)
    if (_centerOptions.isEmpty && _allContacts.isNotEmpty) {
      _centerOptions = _allContacts
          .map((c) => c.center)
          .whereType<String>()
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _guideOptions = _allContacts
          .map((c) => c.folkGuide)
          .whereType<String>()
          .where((g) => g.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _levelOptions = _allContacts
          .map((c) => c.folkLevel)
          .whereType<String>()
          .where((l) => l.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _genderOptions = _allContacts
          .map((c) => c.gender)
          .whereType<String>()
          .where((g) => g.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    }

    final query = _searchQuery.trim().toLowerCase();
    setState(() {
      _contacts = _allContacts.where((c) {
        if (query.isNotEmpty) {
          final nameMatch = c.name.toLowerCase().contains(query);
          final phoneMatch = c.mobile.contains(query);
          final folkIdMatch = (c.folkId ?? '').toLowerCase().contains(query);
          if (!nameMatch && !phoneMatch && !folkIdMatch) {
            return false;
          }
        }
        if (_selectedCenterFilter != null && c.center != _selectedCenterFilter)
          return false;
        if (_selectedGuideFilter != null && c.folkGuide != _selectedGuideFilter)
          return false;
        if (_selectedLevelFilter != null && c.folkLevel != _selectedLevelFilter)
          return false;
        if (_selectedGenderFilter != null && c.gender != _selectedGenderFilter)
          return false;
        return true;
      }).toList();
    });
  }

  Future<void> _loadAssignments() async {
    final eventId = _selectedEvent?.id;
    if (eventId == null) return;

    try {
      final res = await DefaultConnector.instance
          .listAssignmentsForEvent(eventId: eventId)
          .execute();
      setState(() {
        _assignments = res.data.assignments;
        _filterAssignments();
      });
    } catch (e) {
      debugPrint("Error loading assignments: $e");
    }
  }

  void _filterAssignments() {
    if (_searchQuery.isEmpty) {
      _filteredAssignments = _assignments;
    } else {
      final query = _searchQuery.toLowerCase();
      setState(() {
        _filteredAssignments = _assignments.where((a) {
          final contactName = a.contact.name.toLowerCase();
          final contactMobile = a.contact.mobile.toLowerCase();
          final contactFolkId = (a.contact.folkId ?? "").toLowerCase();
          final enablerName = a.enabler.name.toLowerCase();
          return contactName.contains(query) ||
              contactMobile.contains(query) ||
              contactFolkId.contains(query) ||
              enablerName.contains(query);
        }).toList();
      });
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Enabler',
                    style: FlutterFlowTheme.of(context).titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddEnablerDialog();
                    },
                  ),
                ],
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
                              backgroundColor:
                                  FlutterFlowTheme.of(context).primary,
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
                                _selectedContactIds.clear();
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

  void _showAddEnablerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: Text(
                'Add New Enabler',
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(
                            color: FlutterFlowTheme.of(context).secondaryText),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText),
                      decoration: InputDecoration(
                        labelText: '10-Digit Mobile',
                        labelStyle: TextStyle(
                            color: FlutterFlowTheme.of(context).secondaryText),
                        prefixText: '+91 ',
                        prefixStyle: TextStyle(
                            color: FlutterFlowTheme.of(context).primaryText),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText),
                      decoration: InputDecoration(
                        labelText: 'Email Address (Optional)',
                        labelStyle: TextStyle(
                            color: FlutterFlowTheme.of(context).secondaryText),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final phoneVal = phoneController.text.trim();
                          final email = emailController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name is required')),
                            );
                            return;
                          }
                          if (phoneVal.isEmpty || phoneVal.length != 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter a valid 10-digit mobile number')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final formattedPhone = '+91$phoneVal';
                            final initials = name
                                .trim()
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .take(2)
                                .join()
                                .toUpperCase();

                            var builder =
                                DefaultConnector.instance.adminUpsertUser(
                              uid: formattedPhone,
                              phone: formattedPhone,
                              name: name,
                              role: UserRole.ENABLER,
                              isActive: true,
                            );

                            if (email.isNotEmpty) {
                              builder = builder.email(email);
                            }
                            if (initials.isNotEmpty) {
                              builder = builder.avatarInitials(initials);
                            } else {
                              builder = builder.avatarInitials('E');
                            }

                            await builder.execute();

                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enabler invited successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Reload enablers and auto-select the newly added enabler
                            final enablersRes = await DefaultConnector.instance
                                .listEnablers()
                                .execute();
                            setState(() {
                              _enablers = enablersRes.data.users;
                              _selectedEnabler = _enablers.firstWhere(
                                (u) => u.phone == formattedPhone,
                                orElse: () =>
                                    _selectedEnabler ?? _enablers.first,
                              );
                              _selectedContactIds.clear();
                            });
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });
                            final errStr = e.toString();
                            String userFriendlyMsg =
                                'Failed to invite enabler: $e';
                            if (errStr.contains('user_phone_uidx') ||
                                errStr.contains('unique constraint') ||
                                errStr.contains('ALREADY_EXISTS') ||
                                errStr.contains('duplicate key')) {
                              userFriendlyMsg =
                                  'A user with this mobile number already exists.';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(userFriendlyMsg),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Add Enabler',
                          style: TextStyle(
                              color: FlutterFlowTheme.of(context).onPrimary),
                        ),
                ),
              ],
            );
          },
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
                            onTap: () async {
                              setState(() {
                                _selectedEvent = event;
                                _selectedContactIds.clear();
                              });
                              Navigator.pop(context);
                              if (widget.tab == 'calls') {
                                await _loadAssignments();
                              } else {
                                await _loadContacts();
                              }
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
                    await DefaultConnector.instance
                        .createEvent(
                          name: name,
                          eventDate: DateTime.now(),
                          status: EventStatus.ACTIVE,
                          createdByUid: adminUid,
                        )
                        .execute();
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
        const SnackBar(
            content: Text('Please select or create an Event campaign first.')),
      );
      return;
    }
    if (_selectedEnabler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an Enabler to assign contacts to.')),
      );
      return;
    }
    if (_selectedContactIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one contact card below.')),
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
        return DefaultConnector.instance
            .reassignContact(
              contactId: contactId,
              enablerUid: enablerUid,
              eventId: eventId,
              sortOrder: sortOrder++,
              assignedByUid: adminUid,
            )
            .execute();
      }));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Assigned ${_selectedContactIds.length} contacts successfully!')),
      );

      setState(() {
        _selectedContactIds.clear();
      });

      await _loadContacts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to assign contacts: $e'),
            backgroundColor: Colors.redAccent),
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
        body: SafeArea(
          child: Column(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (Navigator.of(context).canPop())
                            FlutterFlowIconButton(
                              borderRadius: 8.0,
                              buttonSize: 40.0,
                              fillColor: Colors.transparent,
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 24.0,
                              ),
                              onPressed: () {
                                context.safePop();
                              },
                            ),
                          // Left side: Campaign Event
                          Expanded(
                            child: InkWell(
                              onTap: _selectEventBottomSheet,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CAMPAIGN EVENT',
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                              fontSize: 10.0,
                                              fontWeight: FontWeight.bold),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    _selectedEvent?.name ?? 'No Event Active',
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          lineHeight: 1.2,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Vertical divider line
                          Container(
                            height: 28.0,
                            width: 1.0,
                            color: FlutterFlowTheme.of(context).alternate,
                            margin: const EdgeInsets.symmetric(horizontal: 12.0),
                          ),
                          // Right side: Target Enabler (Caller)
                          Expanded(
                            child: InkWell(
                              onTap: _selectEnablerBottomSheet,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'TARGET ENABLER',
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                              fontSize: 10.0,
                                              fontWeight: FontWeight.bold),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                        ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    _selectedEnabler == null
                                        ? 'Select Enabler'
                                        : _selectedEnabler!.name,
                                    style: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          lineHeight: 1.2,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // More Options Menu
                          FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 40.0,
                            fillColor: Colors.transparent,
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            onPressed: () {
                              _showAdminToolsBottomSheet(context);
                            },
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
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
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
                        hint: widget.tab == 'calls'
                            ? 'Search Name, Mobile, Folk ID or Caller'
                            : 'Search Name, Mobile or Folk ID',
                        value: '',
                        onChange: '',
                        onSubmit: '',
                        variant: 'outlined',
                        error: false,
                      ),
                    ),
                    if (widget.tab == 'contacts') ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterDropdown(
                              hint: 'Center',
                              value: _selectedCenterFilter,
                              options: _centerOptions,
                              onChanged: (val) {
                                setState(() {
                                  _selectedCenterFilter = val;
                                  _applyFilters();
                                });
                              },
                            ),
                            const SizedBox(width: 8.0),
                            _buildFilterDropdown(
                              hint: 'Guide',
                              value: _selectedGuideFilter,
                              options: _guideOptions,
                              onChanged: (val) {
                                setState(() {
                                  _selectedGuideFilter = val;
                                  _applyFilters();
                                });
                              },
                            ),
                            const SizedBox(width: 8.0),
                            _buildFilterDropdown(
                              hint: 'Level',
                              value: _selectedLevelFilter,
                              options: _levelOptions,
                              onChanged: (val) {
                                setState(() {
                                  _selectedLevelFilter = val;
                                  _applyFilters();
                                });
                              },
                            ),
                            const SizedBox(width: 8.0),
                            _buildFilterDropdown(
                              hint: 'Gender',
                              value: _selectedGenderFilter,
                              options: _genderOptions,
                              onChanged: (val) {
                                setState(() {
                                  _selectedGenderFilter = val;
                                  _applyFilters();
                                });
                              },
                            ),
                            if (_selectedCenterFilter != null ||
                                _selectedGuideFilter != null ||
                                _selectedLevelFilter != null ||
                                _selectedGenderFilter != null) ...[
                              const SizedBox(width: 8.0),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedCenterFilter = null;
                                    _selectedGuideFilter = null;
                                    _selectedLevelFilter = null;
                                    _selectedGenderFilter = null;
                                    _applyFilters();
                                  });
                                },
                                icon: const Icon(Icons.clear_rounded,
                                    size: 16, color: Colors.redAccent),
                                label: const Text(
                                  'Clear',
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ].divide(const SizedBox(height: 16.0)),
                ),
              ),
              Expanded(
                flex: 1,
                child: widget.tab == 'contacts'
                    ? SingleChildScrollView(
                        primary: false,
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              wrapWithModel(
                                model: _model.sectionHeaderModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: SectionHeaderWidget(
                                  count: '${_selectedContactIds.length}',
                                  title: 'Selected Contacts',
                                ),
                              ),
                              if (widget.tab == 'contacts' &&
                                  _isBulkMode &&
                                  !_loading &&
                                  _contacts.isNotEmpty) ...[
                                const SizedBox(height: 8.0),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Filtered: ${_contacts.length} members',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedContactIds.addAll(
                                                  _contacts.map((c) => c.id));
                                            });
                                          },
                                          child: Text(
                                            'Select All Filtered',
                                            style: TextStyle(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedContactIds.clear();
                                            });
                                          },
                                          child: const Text(
                                            'Clear',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8.0),
                              _loading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : _contacts.isEmpty
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24.0),
                                            child: Text(
                                                'No contacts found matching search.'),
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: math.min(
                                                  _contacts.length,
                                                  _displayLimit),
                                              itemBuilder: (context, index) {
                                                final contact =
                                                    _contacts[index];
                                                final isSelected =
                                                    _selectedContactIds
                                                        .contains(contact.id);
                                                return InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      if (isSelected) {
                                                        _selectedContactIds
                                                            .remove(contact.id);
                                                      } else {
                                                        if (!_isBulkMode) {
                                                          _selectedContactIds
                                                              .clear();
                                                        }
                                                        _selectedContactIds
                                                            .add(contact.id);
                                                      }
                                                    });
                                                  },
                                                  child: MemberCardWidget(
                                                    currentEnabler:
                                                        _contactIdToEnablerName[contact.id] ?? 'Unassigned',
                                                    folkId: contact.folkId ??
                                                        'No ID',
                                                    name: contact.name,
                                                    selected: isSelected,
                                                  ),
                                                );
                                              },
                                            ),
                                            if (_contacts.length >
                                                _displayLimit) ...[
                                              const SizedBox(height: 12.0),
                                              Center(
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _displayLimit += 50;
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      Icons.add_rounded,
                                                      size: 18),
                                                  label: Text(
                                                      'Load More (${_contacts.length - _displayLimit} remaining)'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .secondaryBackground,
                                                    foregroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryText,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0),
                                                      side: BorderSide(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .alternate),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 8.0),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        primary: false,
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              wrapWithModel(
                                model: _model.sectionHeaderModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: SectionHeaderWidget(
                                  count: '${_filteredAssignments.length}',
                                  title: 'Assigned Calls',
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              _loading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : _filteredAssignments.isEmpty
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24.0),
                                            child: Text(
                                                'No assigned calls found matching search.'),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              _filteredAssignments.length,
                                          itemBuilder: (context, index) {
                                            final assignment =
                                                _filteredAssignments[index];
                                            final initials = assignment
                                                .contact.name
                                                .trim()
                                                .split(' ')
                                                .map((e) =>
                                                    e.isNotEmpty ? e[0] : '')
                                                .take(2)
                                                .join()
                                                .toUpperCase();

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      16.0),
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        child: Text(
                                                          initials.isNotEmpty
                                                              ? initials
                                                              : 'C',
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              assignment
                                                                  .contact.name,
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .titleMedium
                                                                  .override(
                                                                    font: GoogleFonts.outfit(
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Text(
                                                              'Folk ID: ${assignment.contact.folkId ?? "N/A"} • ${assignment.contact.mobile}',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelSmall
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Text(
                                                              'Caller: ${assignment.enabler.name}',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelSmall
                                                                  .override(
                                                                    font: GoogleFonts.inter(
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              _getStatusBgColor(
                                                                  assignment
                                                                      .status),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          assignment.status
                                                              .stringValue
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color:
                                                                _getStatusTextColor(
                                                                    assignment
                                                                        .status),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                            ],
                          ),
                        ),
                      ),
              ),
              if (widget.tab == 'contacts')
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
                        padding: const EdgeInsets.all(12.0),
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
                                                      .fontWeight),
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
                                              fontWeight: FontWeight.bold),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                ].divide(const SizedBox(height: 4.0)),
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
                                    color:
                                        FlutterFlowTheme.of(context).onPrimary,
                                    size: 24.0,
                                  ),
                                  iconPresent: true,
                                  iconEndPresent: false,
                                  content: 'Confirm Assignment',
                                  variant: 'primary',
                                  size: 'large',
                                  fullWidth: false,
                                  loading: _loading,
                                  disabled:
                                      _loading || _selectedContactIds.isEmpty,
                                ),
                              ),
                            ),
                          ].divide(const SizedBox(width: 16.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              AdminNavBar(
                currentTab: AdminTab.contacts,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: value != null
            ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.08)
            : FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: value != null
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(
            color: FlutterFlowTheme.of(context).secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        underline: const SizedBox(),
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          color: value != null
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryText,
          size: 18,
        ),
        dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
        style: TextStyle(
          color: value != null
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).primaryText,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        isDense: true,
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('All ${hint}s'),
          ),
          ...options.map((opt) => DropdownMenuItem<String>(
                value: opt,
                child: Text(opt),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Color _getStatusBgColor(EnumValue<AssignmentStatus> status) {
    if (status is Known<AssignmentStatus>) {
      switch (status.value) {
        case AssignmentStatus.PENDING:
          return Colors.amber.withAlpha(26);
        case AssignmentStatus.IN_PROGRESS:
          return Colors.blue.withAlpha(26);
        case AssignmentStatus.COMPLETED:
          return Colors.green.withAlpha(26);
        case AssignmentStatus.SKIPPED:
          return Colors.grey.withAlpha(26);
      }
    }
    return Colors.grey.withAlpha(26);
  }

  Color _getStatusTextColor(EnumValue<AssignmentStatus> status) {
    if (status is Known<AssignmentStatus>) {
      switch (status.value) {
        case AssignmentStatus.PENDING:
          return Colors.amber[800]!;
        case AssignmentStatus.IN_PROGRESS:
          return Colors.blue[800]!;
        case AssignmentStatus.COMPLETED:
          return Colors.green[800]!;
        case AssignmentStatus.SKIPPED:
          return Colors.grey[800]!;
      }
    }
    return Colors.grey[800]!;
  }

  void _showMsgDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAdminToolsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Admin Tools',
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                        font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                ListTile(
                  leading: Icon(Icons.file_upload_rounded,
                      color: FlutterFlowTheme.of(context).primary),
                  title: Text(
                    'Import Contacts (CSV)',
                    style: FlutterFlowTheme.of(context).bodyLarge,
                  ),
                  subtitle: const Text('Add new contact records in bulk'),
                  onTap: () {
                    Navigator.pop(context);
                    _importCSVFlow();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.download_rounded,
                      color: FlutterFlowTheme.of(context).primary),
                  title: Text(
                    'Export Contacts (CSV)',
                    style: FlutterFlowTheme.of(context).bodyLarge,
                  ),
                  subtitle: const Text('Export all contact records from DB'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportContactsFlow();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.phone_callback_rounded,
                      color: FlutterFlowTheme.of(context).primary),
                  title: Text(
                    'Export Call Logs (CSV)',
                    style: FlutterFlowTheme.of(context).bodyLarge,
                  ),
                  subtitle:
                      const Text('Export calling details & survey answers'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportCallLogsFlow();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _importCSVFlow() async {
    try {
      // 1. Pick CSV File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return; // Canceled
      }

      final filePath = result.files.single.path!;
      final csvFile = File(filePath);
      final csvString = await csvFile.readAsString();

      // 2. Parse CSV
      final List<List<dynamic>> rows = Csv().decoder.convert(csvString);
      if (rows.isEmpty) {
        _showMsgDialog('Empty File', 'The selected CSV file contains no data.');
        return;
      }

      final headers = rows.first.map((e) => e.toString().trim()).toList();
      final dataRows = rows.skip(1).toList();

      if (dataRows.isEmpty) {
        _showMsgDialog('No Data Rows', 'The CSV file only contains headers.');
        return;
      }

      // Map headers to column indices
      final nameIdx = headers.indexWhere((h) => h.toLowerCase() == 'name');
      final mobileIdx = headers.indexWhere((h) => h.toLowerCase() == 'mobile');

      if (nameIdx == -1 || mobileIdx == -1) {
        _showMsgDialog(
          'Missing Columns',
          'The CSV must contain "Name" and "Mobile" columns (case-insensitive).\nFound headers: ${headers.join(", ")}',
        );
        return;
      }

      // Helper function to safely get cell string value
      String getVal(List<dynamic> row, String columnName) {
        final idx = headers
            .indexWhere((h) => h.toLowerCase() == columnName.toLowerCase());
        if (idx == -1 || idx >= row.length) return "";
        return row[idx]?.toString().trim() ?? "";
      }

      // 3. Show Progress Dialog
      int totalRows = dataRows.length;
      int processedCount = 0;
      int successCount = 0;
      int failCount = 0;
      List<String> errors = [];
      bool cancelled = false;

      // StatefulBuilder inside dialog to show progress updates
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              _updateImportProgress =
                  (int current, int success, int fail, List<String> errs) {
                setDialogState(() {
                  processedCount = current;
                  successCount = success;
                  failCount = fail;
                  errors = errs;
                });
              };

              final progressVal =
                  totalRows > 0 ? (processedCount / totalRows) : 0.0;

              return AlertDialog(
                title: Text('Importing Contacts',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: progressVal),
                    const SizedBox(height: 16),
                    Text('Processed: $processedCount of $totalRows rows'),
                    Text('Success: $successCount',
                        style: const TextStyle(color: Colors.green)),
                    Text('Failed: $failCount',
                        style: const TextStyle(color: Colors.red)),
                    if (errors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Recent error: ${errors.last}',
                        style:
                            const TextStyle(color: Colors.orange, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      cancelled = true;
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Cancel / Stop'),
                  ),
                ],
              );
            },
          );
        },
      );

      // 4. Batch Import Loop
      final batchSize = 10;
      for (int i = 0; i < dataRows.length && !cancelled; i += batchSize) {
        final batch = dataRows.sublist(i,
            i + batchSize > dataRows.length ? dataRows.length : i + batchSize);

        await Future.wait(batch.map((row) async {
          if (cancelled) return;

          final name = row[nameIdx]?.toString().trim() ?? "";
          final mobile = row[mobileIdx]?.toString().trim() ?? "";

          if (name.isEmpty || mobile.isEmpty) {
            failCount++;
            errors.add(
                'Row ${i + batch.indexOf(row) + 2}: Missing Name or Mobile number.');
            processedCount++;
            return;
          }

          // Generate or fetch other optional fields
          final syncStatus = getVal(row, 'sync status');
          final email = getVal(row, 'email');
          final whatsapp = getVal(row, 'whatsapp');
          final dob = getVal(row, 'date of birth');
          final ageVal = getVal(row, 'age');
          final age = int.tryParse(ageVal);
          final folkAge = getVal(row, 'folk age');
          final gender = getVal(row, 'gender');
          final folkId = getVal(row, 'folk id');
          final folkGuide = getVal(row, 'folk guide');
          final folkLevel = getVal(row, 'folk level');
          final occupation = getVal(row, 'occupation');
          final maritalStatus = getVal(row, 'marital status');
          final language = getVal(row, 'language');
          final livingStatus = getVal(row, 'living status');
          final address = getVal(row, 'address');
          final permanentAddress = getVal(row, 'permanent address');
          final city = getVal(row, 'city');
          final state = getVal(row, 'state');
          final country = getVal(row, 'country');
          final higherQual = getVal(row, 'higher qualification');
          final acadInst = getVal(row, 'academic institution');
          final instLoc = getVal(row, 'institution location');
          final org = getVal(row, 'organization');
          final desig = getVal(row, 'designation');
          final orgLoc = getVal(row, 'organization location');
          final resInterest = getVal(row, 'residency interest');
          final origin = getVal(row, 'origin');
          final journey = getVal(row, 'journey');
          final currentStatus = getVal(row, 'current status');
          final lastActType = getVal(row, 'last activity type');
          final lastAct = getVal(row, 'last activity');
          final lastSeen = getVal(row, 'last seen');
          final yfhId = getVal(row, 'yfh id');

          // Note the second City column mapping
          final yfhCity = getVal(row, 'city');
          final center = getVal(row, 'center');
          final stay = getVal(row, 'stay');
          final stream = getVal(row, 'stream');
          final highestQual = getVal(row, 'highest qualification');
          final source = getVal(row, 'source');
          final talents = getVal(row, 'talents');
          final folkResInterest = getVal(row, 'folk residency interest');

          // Note the second Address column mapping
          final contactAddress = getVal(row, 'address');
          final tShirtSize = getVal(row, 't-shirt size');
          final sent = getVal(row, 'sent');
          final isEnabler = getVal(row, 'is enabler?');

          try {
            await DefaultConnector.instance
                .insertContact(
                  name: name,
                  mobile: mobile,
                )
                .syncStatus(syncStatus.isNotEmpty ? syncStatus : null)
                .email(email.isNotEmpty ? email : null)
                .whatsapp(whatsapp.isNotEmpty ? whatsapp : null)
                .dateOfBirth(dob.isNotEmpty ? dob : null)
                .age(age)
                .folkAge(folkAge.isNotEmpty ? folkAge : null)
                .gender(gender.isNotEmpty ? gender : null)
                .folkId(folkId.isNotEmpty ? folkId : null)
                .folkGuide(folkGuide.isNotEmpty ? folkGuide : null)
                .folkLevel(folkLevel.isNotEmpty ? folkLevel : null)
                .occupation(occupation.isNotEmpty ? occupation : null)
                .maritalStatus(maritalStatus.isNotEmpty ? maritalStatus : null)
                .language(language.isNotEmpty ? language : null)
                .livingStatus(livingStatus.isNotEmpty ? livingStatus : null)
                .address(address.isNotEmpty ? address : null)
                .permanentAddress(
                    permanentAddress.isNotEmpty ? permanentAddress : null)
                .city(city.isNotEmpty ? city : null)
                .state(state.isNotEmpty ? state : null)
                .country(country.isNotEmpty ? country : null)
                .higherQualification(higherQual.isNotEmpty ? higherQual : null)
                .academicInstitution(acadInst.isNotEmpty ? acadInst : null)
                .institutionLocation(instLoc.isNotEmpty ? instLoc : null)
                .organization(org.isNotEmpty ? org : null)
                .designation(desig.isNotEmpty ? desig : null)
                .organizationLocation(orgLoc.isNotEmpty ? orgLoc : null)
                .residencyInterest(resInterest.isNotEmpty ? resInterest : null)
                .origin(origin.isNotEmpty ? origin : null)
                .journey(journey.isNotEmpty ? journey : null)
                .currentStatus(currentStatus.isNotEmpty ? currentStatus : null)
                .lastActivityType(lastActType.isNotEmpty ? lastActType : null)
                .lastActivity(lastAct.isNotEmpty ? lastAct : null)
                .lastSeen(lastSeen.isNotEmpty ? lastSeen : null)
                .yfhId(yfhId.isNotEmpty ? yfhId : null)
                .yfhCity(yfhCity.isNotEmpty ? yfhCity : null)
                .center(center.isNotEmpty ? center : null)
                .stay(stay.isNotEmpty ? stay : null)
                .stream(stream.isNotEmpty ? stream : null)
                .highestQualification(
                    highestQual.isNotEmpty ? highestQual : null)
                .source(source.isNotEmpty ? source : null)
                .talents(talents.isNotEmpty ? talents : null)
                .folkResidencyInterest(
                    folkResInterest.isNotEmpty ? folkResInterest : null)
                .contactAddress(
                    contactAddress.isNotEmpty ? contactAddress : null)
                .tShirtSize(tShirtSize.isNotEmpty ? tShirtSize : null)
                .sent(sent.isNotEmpty ? sent : null)
                .isEnabler(isEnabler.isNotEmpty ? isEnabler : null)
                .execute();
            successCount++;
          } catch (err) {
            failCount++;
            final errMsg = err.toString();
            if (errMsg.contains('unique_folkid') ||
                errMsg.contains('violates unique constraint')) {
              errors.add(
                  'Row ${i + batch.indexOf(row) + 2} ($name): Duplicate FOLK ID "$folkId".');
            } else {
              errors.add('Row ${i + batch.indexOf(row) + 2} ($name): $errMsg');
            }
          }
          processedCount++;
        }));

        if (_updateImportProgress != null && !cancelled) {
          _updateImportProgress!(
              processedCount, successCount, failCount, errors);
        }
      }

      if (!cancelled) {
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text('Import Summary',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Total Rows Processed: $processedCount'),
                    Text('Successfully Imported: $successCount',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('Failed to Import: $failCount',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                    if (errors.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Errors / Warnings (max 5 shown):',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: errors
                              .take(5)
                              .map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0),
                                    child: Text('• $e',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText)),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _loadContacts();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      _showMsgDialog(
          'Import Error', 'An error occurred during file parsing: $e');
    }
  }

  Future<void> _exportContactsFlow() async {
    setState(() {
      _loading = true;
    });
    try {
      final res =
          await DefaultConnector.instance.listAllContactsForExport().execute();
      final contacts = res.data.contacts;

      if (contacts.isEmpty) {
        _showMsgDialog(
            'Export Empty', 'There are no contacts in the database to export.');
        return;
      }

      final List<List<dynamic>> csvData = [];

      csvData.add([
        'Sync Status',
        'Name',
        'Mobile',
        'Email',
        'Whatsapp',
        'Date of Birth',
        'Age',
        'FOLK Age',
        'Gender',
        'FOLK ID',
        'FOLK Guide',
        'FOLK Level',
        'Occupation',
        'Marital Status',
        'Language',
        'Living Status',
        'Address',
        'Permanent Address',
        'City',
        'State',
        'Country',
        'Higher Qualification',
        'Academic Institution',
        'Institution Location',
        'Organization',
        'Designation',
        'Organization Location',
        'Residency Interest',
        'Origin',
        'Journey',
        'Current Status',
        'Last Activity Type',
        'Last Activity',
        'Last Seen',
        'YFH ID',
        'City',
        'Center',
        'Stay',
        'Stream',
        'Highest Qualification',
        'Source',
        'Talents',
        'FOLK Residency Interest',
        'Address',
        'T-Shirt Size',
        'Sent',
        'Is Enabler?'
      ]);

      for (final c in contacts) {
        csvData.add([
          c.syncStatus ?? '',
          c.name,
          c.mobile,
          c.email ?? '',
          c.whatsapp ?? '',
          c.dateOfBirth ?? '',
          c.age ?? '',
          c.folkAge ?? '',
          c.gender ?? '',
          c.folkId ?? '',
          c.folkGuide ?? '',
          c.folkLevel ?? '',
          c.occupation ?? '',
          c.maritalStatus ?? '',
          c.language ?? '',
          c.livingStatus ?? '',
          c.address ?? '',
          c.permanentAddress ?? '',
          c.city ?? '',
          c.state ?? '',
          c.country ?? '',
          c.higherQualification ?? '',
          c.academicInstitution ?? '',
          c.institutionLocation ?? '',
          c.organization ?? '',
          c.designation ?? '',
          c.organizationLocation ?? '',
          c.residencyInterest ?? '',
          c.origin ?? '',
          c.journey ?? '',
          c.currentStatus ?? '',
          c.lastActivityType ?? '',
          c.lastActivity ?? '',
          c.lastSeen ?? '',
          c.yfhId ?? '',
          c.yfhCity ?? '',
          c.center ?? '',
          c.stay ?? '',
          c.stream ?? '',
          c.highestQualification ?? '',
          c.source ?? '',
          c.talents ?? '',
          c.folkResidencyInterest ?? '',
          c.contactAddress ?? '',
          c.tShirtSize ?? '',
          c.sent ?? '',
          c.isEnabler ?? ''
        ]);
      }

      final csvString = Csv().encoder.convert(csvData);

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Contacts CSV',
        fileName: 'contacts_export.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(csvString);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Contacts exported successfully to $outputPath')),
        );
      }
    } catch (e) {
      _showMsgDialog('Export Error', 'Failed to export contacts: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _exportCallLogsFlow() async {
    setState(() {
      _loading = true;
    });
    try {
      final res =
          await DefaultConnector.instance.listAllCallLogsForExport().execute();
      final callLogs = res.data.callLogs;

      if (callLogs.isEmpty) {
        _showMsgDialog('Export Empty',
            'There are no call logs in the database to export.');
        return;
      }

      final Set<String> surveyQuestionTitles = {};
      for (final log in callLogs) {
        for (final resp in log.surveyResponses_on_callLog) {
          surveyQuestionTitles.add(resp.question.questionTitle);
        }
      }
      final surveyHeaders = surveyQuestionTitles.toList()..sort();

      final List<List<dynamic>> csvData = [];

      final headers = [
        'Called At',
        'Campaign Event',
        'Enabler Name',
        'Enabler Phone',
        'Contact Name',
        'Contact Mobile',
        'FOLK ID',
        'FOLK Guide',
        'Call Outcome',
        'Follow Up Status',
        'Follow Up Notes',
        'Next Call Date',
        'Call Duration (s)',
        ...surveyHeaders
      ];
      csvData.add(headers);

      for (final log in callLogs) {
        final outcome = log.callOutcome is Known<CallOutcome>
            ? (log.callOutcome as Known<CallOutcome>).value.name
            : log.callOutcome.stringValue;

        final followUpStatus = log.followUpStatus;
        final followUp = followUpStatus != null
            ? (followUpStatus is Known<FollowUpStatus>
                ? followUpStatus.value.name
                : followUpStatus.stringValue)
            : '';

        final Map<String, String> answersMap = {};
        for (final resp in log.surveyResponses_on_callLog) {
          answersMap[resp.question.questionTitle] = resp.answer;
        }

        final List<dynamic> row = [
          log.calledAt.toDateTime().toLocal().toString(),
          log.event.name,
          log.enabler.name,
          log.enabler.phone,
          log.contact.name,
          log.contact.mobile,
          log.contact.folkId ?? '',
          log.contact.folkGuide ?? '',
          outcome,
          followUp,
          log.followUpNotes ?? '',
          log.nextCallDate != null
              ? log.nextCallDate.toString().split(' ')[0]
              : '',
          log.callDuration ?? '',
        ];

        for (final title in surveyHeaders) {
          row.add(answersMap[title] ?? '');
        }

        csvData.add(row);
      }

      final csvString = Csv().encoder.convert(csvData);

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Call Logs CSV',
        fileName: 'call_logs_export.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(csvString);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Call logs exported successfully to $outputPath')),
        );
      }
    } catch (e) {
      _showMsgDialog('Export Error', 'Failed to export call logs: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
