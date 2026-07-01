import 'dart:async';
import '/components/button_widget.dart';
import '/components/member_card_widget.dart';
import '/components/section_header_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'package:uuid/uuid.dart';
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
  static const _contactListColumns =
      'id, name, mobile, folk_id, center, folk_guide, folk_level, gender';

  late ContactAssignmentModel _model;
  Function(int processed, int success, int fail, List<String> errors)?
      _updateImportProgress;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _selectedEvent;
  List<Map<String, dynamic>> _events = [];

  Map<String, dynamic>? _selectedEnabler;
  List<Map<String, dynamic>> _enablers = [];

  List<Map<String, dynamic>> _contacts = [];
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

  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _filteredAssignments = [];
  Map<String, String> _contactIdToEnablerName = {};

  String _searchQuery = "";
  bool _isBulkMode = true;
  bool _loading = true;
  static const int _pageSize = 50;
  int _currentPage = 0;
  int _totalContactCount = 0;
  int _contactRequestId = 0;
  Timer? _searchDebounce;
  bool _filterOptionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ContactAssignmentModel());

    // Listen to search field changes if available
    _model.textFieldModel.inputTextController ??= TextEditingController();
    _model.textFieldModel.inputTextController!.addListener(() {
        _searchQuery = _model.textFieldModel.inputTextController!.text;
      if (widget.tab == 'calls') {
        setState(() {});
        _filterAssignments();
      } else {
        _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 350), () {
          _loadContacts(resetPage: true);
        });
      }
    });

    _loadInitialData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
    });

    try {
      final client = Supabase.instance.client;

      // Events and enablers are independent, so do not make the page wait for
      // two consecutive network round trips.
      final initialResults = await Future.wait<dynamic>([
        client.from('event').select('id, name, event_date, status'),
        if (widget.tab == 'contacts')
          client
              .from('contact')
              .select('id, name, mobile, avatar_initials')
              .eq('role', 'ENABLER')
              .eq('is_active', true),
      ]);
      _events = List<Map<String, dynamic>>.from(initialResults[0]);

      if (_events.isEmpty) {
        // Create a default event if none exist so user is not blocked
        final adminUid = AuthService.instance.currentUser?.id ?? "";
        if (adminUid.isNotEmpty) {
          final defaultDate = DateTime.now();
          await client.from('event').insert({
            'name': "FOLK Camp Campaign",
            'event_date': defaultDate.toIso8601String(),
            'status': 'ACTIVE',
            'created_by': adminUid
          });

          final freshEventsRes =
              await client.from('event').select('id, name, event_date, status');
          _events = List<Map<String, dynamic>>.from(freshEventsRes);
        }
      }

      if (_events.isNotEmpty) {
        if (widget.eventId != null) {
          _selectedEvent = _events.firstWhere(
            (e) => e['id'] == widget.eventId,
            orElse: () => _events.first,
          );
        } else {
          _selectedEvent = _events.first;
        }
      }

      if (widget.tab == 'contacts') {
        _enablers = List<Map<String, dynamic>>.from(initialResults[1]);
        if (_enablers.isNotEmpty) {
          _selectedEnabler = _enablers.first;
        }
      }

      if (widget.tab == 'calls') {
        await _loadAssignments();
      } else {
        await _loadContacts();
        unawaited(_loadFilterOptions());
      }
    } catch (e) {
      debugPrint("Error loading assignment details: $e");
    } finally {
      if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
      }

  Future<void> _loadContacts({bool resetPage = false}) async {
    if (resetPage) _currentPage = 0;
    final requestId = ++_contactRequestId;

    try {
      if (mounted) setState(() => _loading = true);
      final client = Supabase.instance.client;
      final eventId = _selectedEvent?['id'];
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;

      dynamic dataQuery = client.from('contact').select(_contactListColumns);
      dynamic countQuery = client.from('contact').select('id');
      dataQuery = _applyServerContactFilters(dataQuery);
      countQuery = _applyServerContactFilters(countQuery);

      final pageResults = await Future.wait<dynamic>([
        dataQuery.order('name').range(from, to),
        countQuery.count(CountOption.exact),
      ]);
      if (requestId != _contactRequestId) return;

      final contacts = List<Map<String, dynamic>>.from(pageResults[0]);
      final totalCount = (pageResults[1] as PostgrestResponse).count;
      final contactIds =
          contacts.map((c) => c['id']).whereType<String>().toList();

      List<Map<String, dynamic>> assignments = [];
      if (eventId != null && contactIds.isNotEmpty) {
        final assignmentRows = await client
            .from('assignment')
            .select('contact_id, enabler_id')
            .eq('event_id', eventId)
            .inFilter('contact_id', contactIds);
        assignments = List<Map<String, dynamic>>.from(assignmentRows);
        }
      if (requestId != _contactRequestId) return;
        
      final enablerNames = {
        for (final enabler in _enablers)
          if (enabler['id'] is String)
            enabler['id'] as String: (enabler['name'] as String? ?? '')
        };
      final missingEnablerIds = assignments
          .map((a) => a['enabler_id'])
          .whereType<String>()
          .where((id) => !enablerNames.containsKey(id))
          .toSet();
      if (missingEnablerIds.isNotEmpty) {
        final rows = await client
            .from('contact')
            .select('id, name')
            .inFilter('id', missingEnablerIds.toList());
        for (final row in rows) {
          enablerNames[row['id'] as String] = row['name'] as String? ?? '';
      }
      }
      if (requestId != _contactRequestId || !mounted) return;

      _updateFilterOptions(contacts);
      setState(() {
        _contacts = contacts;
        _totalContactCount = totalCount;
        _assignments = assignments;
        _contactIdToEnablerName = {
          for (final assignment in assignments)
            assignment['contact_id']:
                enablerNames[assignment['enabler_id']] ?? ''
        };
      });
    } catch (e) {
      debugPrint("Error loading contacts: $e");
    } finally {
      if (mounted && requestId == _contactRequestId) {
      setState(() {
        _loading = false;
      });
    }
  }
  }

  dynamic _applyServerContactFilters(dynamic query) {
    final search = _searchQuery.trim().replaceAll(RegExp(r'[,()]'), ' ');
    if (search.isNotEmpty) {
      query = query.or(
          'name.ilike.%$search%,mobile.ilike.%$search%,folk_id.ilike.%$search%');
    }
    if (_selectedCenterFilter != null) {
      query = query.eq('center', _selectedCenterFilter!);
    }
    if (_selectedGuideFilter != null) {
      query = query.eq('folk_guide', _selectedGuideFilter!);
    }
    if (_selectedLevelFilter != null) {
      query = query.eq('folk_level', _selectedLevelFilter!);
    }
    if (_selectedGenderFilter != null) {
      query = query.eq('gender', _selectedGenderFilter!);
    }
    return query;
  }

  void _updateFilterOptions(List<Map<String, dynamic>> contacts) {
    void merge(List<String> target, String field) {
      target.addAll(contacts
          .map((contact) => contact[field])
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty));
      final unique = target.toSet().toList()..sort();
      target
        ..clear()
        ..addAll(unique);
    }

    merge(_centerOptions, 'center');
    merge(_guideOptions, 'folk_guide');
    merge(_levelOptions, 'folk_level');
    merge(_genderOptions, 'gender');
    }

  Future<void> _loadFilterOptions() async {
    if (_filterOptionsLoaded) return;
    _filterOptionsLoaded = true;
    try {
      final rows = await Supabase.instance.client
          .from('contact')
          .select('center, folk_guide, folk_level, gender')
          .range(0, 999);
      if (!mounted) return;
    setState(() {
        _updateFilterOptions(List<Map<String, dynamic>>.from(rows));
    });
    } catch (e) {
      _filterOptionsLoaded = false;
      debugPrint('Error loading contact filter options: $e');
    }
  }

  Future<void> _loadAssignments() async {
    final eventId = _selectedEvent?['id'];
    if (eventId == null) return;

    try {
      final res = await Supabase.instance.client
          .from('assignment')
          .select('contact_id, enabler_id, status, sort_order')
          .eq('event_id', eventId);
      
      // Fetch contact and enabler data
      final contactIds = res.map((a) => a['contact_id']).toSet().toList();
      final enablerIds = res.map((a) => a['enabler_id']).toSet().toList();
      
      final allIds = {...contactIds, ...enablerIds}.toList();
      Map<String, Map<String, dynamic>> allContactData = {};
      if (allIds.isNotEmpty) {
        final contactsRes = await Supabase.instance.client
            .from('contact')
            .select()
            .inFilter('id', allIds);
        allContactData = {for (var c in contactsRes) c['id'] as String: c};
      }
      
      final assignmentsWithContacts = res.map((a) {
        final contactData = allContactData[a['contact_id']] ?? {};
        final enablerData = allContactData[a['enabler_id']] ?? {};
        return {
          ...a,
          'contact': contactData,
          'enabler': enablerData,
        };
      }).toList();
      
      setState(() {
        _assignments = assignmentsWithContacts;
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
          final contactName = a['contact']['name'].toLowerCase();
          final contactMobile = a['contact']['mobile'].toLowerCase();
          final contactFolkId = (a['contact']['folk_id'] ?? "").toLowerCase();
          final enablerName = a['enabler'].name.toLowerCase();
          return contactName.contains(query) ||
              contactMobile.contains(query) ||
              contactFolkId.contains(query) ||
              enablerName.contains(query);
        }).toList();
      });
    }
  }

  void _selectEnablerBottomSheet() {
    // Keep state variables outside builder to persist across rebuilds
    String searchQuery = '';
    List<Map<String, dynamic>>? filteredEnablers;

    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Determine which list to display
            final displayList =
                searchQuery.isEmpty ? _enablers : (filteredEnablers ?? []);

        return Container(
          padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  // Header
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
                  // Search field
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by name or mobile',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      searchQuery = value.toLowerCase();
                      filteredEnablers = searchQuery.isEmpty
                          ? null
                          : _enablers.where((enabler) {
                              final name = (enabler['name'] as String? ?? '')
                                  .toLowerCase();
                              final mobile =
                                  (enabler['mobile'] as String? ?? '')
                                      .toLowerCase();
                              return name.contains(searchQuery) ||
                                  mobile.contains(searchQuery);
                            }).toList();
                      setModalState(() {}); // Trigger rebuild
                    },
                  ),
                  const SizedBox(height: 12),
                  // Enabler list
              Expanded(
                    child: displayList.isEmpty
                        ? Center(
                              child: Text(
                              _enablers.isEmpty
                                  ? 'No enablers registered yet.'
                                  : 'No enablers match your search.',
                              style: TextStyle(
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final enabler = displayList[index];
                              return _EnablerListItem(
                                enabler: enabler,
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
      },
    );
  }

  Widget _EnablerListItem({
    required Map<String, dynamic> enabler,
    required VoidCallback onTap,
  }) {
    final name = enabler['name'] as String? ?? 'Unknown';
    final mobile = enabler['mobile'] as String? ?? '';
    final avatarInitials = (enabler['avatar_initials'] as String?) ??
        (name.isNotEmpty ? name[0].toUpperCase() : 'E');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        child: Text(
          avatarInitials,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(name),
      subtitle: mobile.isNotEmpty ? Text(mobile) : null,
      onTap: onTap,
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

                            final newId = const Uuid().v4();
                            final Map<String, dynamic> insertData = {
                              'id': newId,
                              'mobile': formattedPhone,
                              'name': name,
                              'role': 'ENABLER',
                              'is_active': true
                            };

                            if (email.isNotEmpty) {
                              insertData['email'] = email;
                            }
                            insertData['avatar_initials'] =
                                initials.isNotEmpty ? initials : 'E';

                            await Supabase.instance.client
                                .from('contact')
                                .upsert(insertData);

                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enabler invited successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Reload enablers and auto-select the newly added enabler
                            final enablersRes = await Supabase.instance.client
                                .from('contact')
                                .select()
                                .eq('role', 'ENABLER');
                            setState(() {
                              _enablers = enablersRes;
                              _selectedEnabler = _enablers.firstWhere(
                                (u) => u['mobile'] == formattedPhone,
                                orElse: () =>
                                    _selectedEnabler ?? _enablers.first,
                              );
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
                            title: Text(event['name']),
                            subtitle: Text(event['event_date'].toString()),
                            onTap: () async {
                              setState(() {
                                _selectedEvent = event;
                                _selectedContactIds.clear();
                              });
                              Navigator.pop(context);
                              if (widget.tab == 'calls') {
                                await _loadAssignments();
                              } else {
                                await _loadContacts(resetPage: true);
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
                final adminUid = AuthService.instance.currentUser?.id ?? "";
                if (name.isNotEmpty && adminUid.isNotEmpty) {
                  try {
                    await Supabase.instance.client.from('event').insert({
                      'name': name,
                      'event_date': DateTime.now().toIso8601String(),
                      'status': 'ACTIVE',
                      'created_by': adminUid
                    });
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

    final enablerId = _selectedEnabler!['id'];
    final eventId = _selectedEvent!['id'];
    final adminId = AuthService.instance.currentUser!.id;

    try {
      int sortOrder = 0;
      await Future.wait(_selectedContactIds.map((contactId) {
        return Supabase.instance.client.from('assignment').upsert({
          'contact_id': contactId,
          'enabler_id': enablerId,
          'event_id': eventId,
          'sort_order': sortOrder++,
          'assigned_by': adminId,
          'status': 'PENDING'
        });
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
                                    _selectedEvent?['name'] ??
                                        'No Event Active',
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
                            margin:
                                const EdgeInsets.symmetric(horizontal: 12.0),
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
                                        : _selectedEnabler!['name'],
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
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterDropdown(
                                    hint: 'Center',
                                    value: _selectedCenterFilter,
                                    options: _centerOptions,
                                    onChanged: (val) async {
                                      setState(() {
                                        _selectedCenterFilter = val;
                                      });
                                      await _loadContacts(resetPage: true);
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  _buildFilterDropdown(
                                    hint: 'Guide',
                                    value: _selectedGuideFilter,
                                    options: _guideOptions,
                                    onChanged: (val) async {
                                      setState(() {
                                        _selectedGuideFilter = val;
                                      });
                                      await _loadContacts(resetPage: true);
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  _buildFilterDropdown(
                                    hint: 'Level',
                                    value: _selectedLevelFilter,
                                    options: _levelOptions,
                                    onChanged: (val) async {
                                      setState(() {
                                        _selectedLevelFilter = val;
                                      });
                                      await _loadContacts(resetPage: true);
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  _buildFilterDropdown(
                                    hint: 'Gender',
                                    value: _selectedGenderFilter,
                                    options: _genderOptions,
                                    onChanged: (val) async {
                                      setState(() {
                                        _selectedGenderFilter = val;
                                      });
                                      await _loadContacts(resetPage: true);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedCenterFilter != null ||
                              _selectedGuideFilter != null ||
                              _selectedLevelFilter != null ||
                              _selectedGenderFilter != null) ...[
                            const SizedBox(width: 8.0),
                            TextButton.icon(
                              onPressed: () async {
                                setState(() {
                                  _selectedCenterFilter = null;
                                  _selectedGuideFilter = null;
                                  _selectedLevelFilter = null;
                                  _selectedGenderFilter = null;
                                });
                                await _loadContacts(resetPage: true);
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
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
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: [
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                          _totalContactCount == 0
                                              ? 'No members'
                                              : 'Showing ${_currentPage * _pageSize + 1}-${_currentPage * _pageSize + _contacts.length} of $_totalContactCount members',
                                            style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (_selectedContactIds.length -
                                                  _contacts
                                                      .where((c) =>
                                                          _selectedContactIds
                                                            .contains(c['id']))
                                                      .length >
                                              0)
                                            Text(
                                              '+ ${_selectedContactIds.length - _contacts.where((c) => _selectedContactIds.contains(c['id'])).length} hidden selected',
                                              style: TextStyle(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedContactIds.addAll(
                                                  _contacts
                                                      .map((c) => c['id']));
                                            });
                                          },
                                          child: Text(
                                            'Select Page',
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
                                          child: Text(
                                            'Clear All (${_selectedContactIds.length})',
                                            style: const TextStyle(
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
                                              itemCount: _contacts.length,
                                              itemBuilder: (context, index) {
                                                final contact =
                                                    _contacts[index];
                                                final isSelected =
                                                    _selectedContactIds
                                                        .contains(
                                                            contact['id']);
                                                return InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      if (isSelected) {
                                                        _selectedContactIds
                                                            .remove(
                                                                contact['id']);
                                                      } else {
                                                        if (!_isBulkMode) {
                                                          _selectedContactIds
                                                              .clear();
                                                        }
                                                        _selectedContactIds
                                                            .add(contact['id']);
                                                      }
                                                    });
                                                  },
                                                  child: MemberCardWidget(
                                                    currentEnabler:
                                                        _contactIdToEnablerName[
                                                                contact[
                                                                    'id']] ??
                                                            'Unassigned',
                                                    folkId:
                                                        contact['folk_id'] ??
                                                            'No ID',
                                                    name: contact['name'],
                                                    selected: isSelected,
                                                  ),
                                                );
                                              },
                                            ),
                                            if (_totalContactCount >
                                                _pageSize) ...[
                                              const SizedBox(height: 12.0),
                                              Center(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Previous page',
                                                      onPressed:
                                                          _currentPage > 0
                                                              ? () async {
                                                                  _currentPage--;
                                                                  await _loadContacts();
                                                                }
                                                              : null,
                                                      icon: const Icon(Icons
                                                          .chevron_left_rounded),
                                                    ),
                                                    Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                          horizontal: 12),
                                                      child: Text(
                                                        'Page ${_currentPage + 1} of ${(_totalContactCount / _pageSize).ceil()}',
                                                        style: TextStyle(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                                    IconButton(
                                                      tooltip: 'Next page',
                                                      onPressed: (_currentPage +
                                                                      1) *
                                                                  _pageSize <
                                                              _totalContactCount
                                                          ? () async {
                                                              _currentPage++;
                                                              await _loadContacts();
                                                            }
                                                          : null,
                                                      icon: const Icon(Icons
                                                          .chevron_right_rounded),
                                                    ),
                                                  ],
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
                                            final initials =
                                                assignment['contact']['name']
                                                .trim()
                                                .split(' ')
                                                    .map((e) => e.isNotEmpty
                                                        ? e[0]
                                                        : '')
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
                                                              assignment[
                                                                      'contact']
                                                                  ['name'],
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
                                                              'Folk ID: ${assignment['contact']['folk_id'] ?? "N/A"} • ${assignment['contact']['mobile']}',
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
                                                              'Caller: ${assignment['enabler'].name}',
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
                                                                  assignment[
                                                                      'status']),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          assignment['status']
                                                              .stringValue
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color: _getStatusTextColor(
                                                                assignment[
                                                                    'status']),
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

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.amber.withAlpha(26);
      case 'IN_PROGRESS':
        return Colors.blue.withAlpha(26);
      case 'COMPLETED':
        return Colors.green.withAlpha(26);
      case 'SKIPPED':
        return Colors.grey.withAlpha(26);
      default:
        return Colors.grey.withAlpha(26);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.amber[800]!;
      case 'IN_PROGRESS':
        return Colors.blue[800]!;
      case 'COMPLETED':
        return Colors.green[800]!;
      case 'SKIPPED':
        return Colors.grey[800]!;
      default:
        return Colors.grey[800]!;
    }
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
                  leading: Icon(Icons.person_add_rounded,
                      color: FlutterFlowTheme.of(context).primary),
                  title: Text(
                    'Add Contact',
                    style: FlutterFlowTheme.of(context).bodyLarge,
                  ),
                  subtitle:
                      const Text('Add an individual contact record manually'),
                  onTap: () {
                    Navigator.pop(context);
                    _addContactDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.file_download_rounded,
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
                  leading: Icon(Icons.file_upload_rounded,
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

  void _addContactDialog() {
    final nameCont = TextEditingController();
    final mobileCont = TextEditingController();
    final folkIdCont = TextEditingController();
    final centerCont = TextEditingController();
    final guideCont = TextEditingController();
    final levelCont = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Add Individual Contact',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCont,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g. John Doe',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileCont,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: 'e.g. 9876543210',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: folkIdCont,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'FOLK ID (Optional)',
                    hintText: 'e.g. BLR-1234',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: centerCont,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Center (Optional)',
                    hintText: 'e.g. Rajajinagar',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: guideCont,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'FOLK Guide (Optional)',
                    hintText: 'e.g. Dilip Prabhu',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: levelCont,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'FOLK Level (Optional)',
                    hintText: 'e.g. L1, L2',
                  ),
                ),
              ],
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
                final mobile = mobileCont.text.trim();
                final folkId = folkIdCont.text.trim();
                final center = centerCont.text.trim();
                final guide = guideCont.text.trim();
                final level = levelCont.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }
                if (mobile.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mobile number is required')),
                  );
                  return;
                }

                try {
                  await Supabase.instance.client.from('contact').insert({
                        'name': name,
                        'mobile': mobile,
                        'folk_id': folkId.isNotEmpty ? folkId : null,
                        'center': center.isNotEmpty ? center : null,
                        'folk_guide': guide.isNotEmpty ? guide : null,
                        'folk_level': level.isNotEmpty ? level : null,
                      });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Contact "$name" added successfully.')),
                  );
                  await _loadContacts();
                } catch (e) {
                  final errMsg = e.toString();
                  String displayError = 'Failed to add contact: $errMsg';
                  if (errMsg.contains('unique_folkid') ||
                      errMsg.contains('violates unique constraint')) {
                    displayError =
                        'A contact with FOLK ID "$folkId" or mobile "$mobile" already exists.';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(displayError)),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

    Future<void> _importCSVFlow() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        return; // User canceled
      }

      setState(() {
        _loading = true;
      });

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final List<List<dynamic>> csvData = Csv().decoder.convert(csvString);

      if (csvData.length < 2) {
        _showMsgDialog('Import Error',
            'CSV must contain headers and at least one row of data.');
        return;
      }

      final headers = csvData.first.map((e) => e.toString().trim()).toList();
      final rows = csvData.skip(1).toList();

      final Map<String, String> headerMap = {
        'Sync Status': 'sync_status',
        'Name': 'name',
        'Mobile': 'mobile',
        'Email': 'email',
        'Whatsapp': 'whatsapp',
        'Date of Birth': 'date_of_birth',
        'Age': 'age',
        'FOLK Age': 'folk_age',
        'Gender': 'gender',
        'FOLK ID': 'folk_id',
        'FOLK Guide': 'folk_guide',
        'FOLK Level': 'folk_level',
        'Occupation': 'occupation',
        'Marital Status': 'marital_status',
        'Language': 'language',
        'Living Status': 'living_status',
        'Address': 'address',
        'Permanent Address': 'permanent_address',
        'City': 'city',
        'State': 'state',
        'Country': 'country',
        'Higher Qualification': 'higher_qualification',
        'Academic Institution': 'academic_institution',
        'Institution Location': 'institution_location',
        'Organization': 'organization',
        'Designation': 'designation',
        'Organization Location': 'organization_location',
        'Residency Interest': 'residency_interest',
        'Origin': 'origin',
        'Journey': 'journey',
        'Current Status': 'current_status',
        'Last Activity Type': 'last_activity_type',
        'Last Activity': 'last_activity',
        'Last Seen': 'last_seen',
        'YFH ID': 'yfh_id',
        'Center': 'center',
        'Stay': 'stay',
        'Stream': 'stream',
        'Highest Qualification': 'highest_qualification',
        'Source': 'source',
        'Talents': 'talents',
        'FOLK Residency Interest': 'folk_residency_interest',
        'T-Shirt Size': 't_shirt_size',
        'Sent': 'sent',
      };

      List<Map<String, dynamic>> recordsToInsert = [];

      for (var row in rows) {
        Map<String, dynamic> record = {};
        for (int i = 0; i < headers.length; i++) {
          if (i >= row.length) break;
          final header = headers[i];
          final dbKey = headerMap[header];
          if (dbKey != null) {
            final value = row[i];
            if (value != null && value.toString().isNotEmpty) {
              if (dbKey == 'age') {
                record[dbKey] = int.tryParse(value.toString());
              } else {
                record[dbKey] = value.toString();
              }
            }
          }
        }
        if (record.isNotEmpty &&
            record.containsKey('name') &&
            record.containsKey('mobile')) {
          recordsToInsert.add(record);
        }
      }

      if (recordsToInsert.isEmpty) {
        _showMsgDialog('Import Error',
            'No valid rows found to import. Make sure Name and Mobile are present.');
        return;
      }

      int successCount = 0;
      int errorCount = 0;
      int total = recordsToInsert.length;

      // Hide the infinite loader since we will show a progress dialog
      setState(() {
        _loading = false;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
            return StatefulBuilder(builder: (context, setDialogState) {
              _updateImportProgress =
                  (int processed, int success, int fail, List<String> errors) {
                if (context.mounted) {
                  setDialogState(() {});
                }
              };
              int processed = successCount + errorCount;
              double progress = total > 0 ? processed / total : 0.0;
              return AlertDialog(
                title: const Text('Importing Contacts'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Text('$processed / $total processed'),
                    Text('Success: $successCount, Failed: $errorCount',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            });
          });

      // Inserting individually to avoid whole batch failing due to one duplicate folk_id/mobile
      for (var record in recordsToInsert) {
        try {
          await Supabase.instance.client.from('contact').insert(record);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Error inserting row: $e');
        }
        if (_updateImportProgress != null) {
          _updateImportProgress!(
              successCount + errorCount, successCount, errorCount, []);
        }
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
      }

      _showMsgDialog('Import Complete',
          'Successfully imported $successCount contacts. Failed $errorCount contacts (likely duplicates).');
      await _loadContacts();
    } catch (e) {
      _showMsgDialog('Import Error', 'An error occurred during import: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _exportContactsFlow() async {
    setState(() {
      _loading = true;
    });
    try {
            List<Map<String, dynamic>> allContactsToExport = [];
      int offset = 0;
      const limit = 1000;
      while (true) {
        final chunk = await Supabase.instance.client
            .from('contact')
            .select()
            .range(offset, offset + limit - 1);
        allContactsToExport.addAll(List<Map<String, dynamic>>.from(chunk));
        if (chunk.length < limit) break;
        offset += limit;
      }
      final res = allContactsToExport;
      final contacts = res as List<dynamic>;

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
        'Center',
        'Stay',
        'Stream',
        'Highest Qualification',
        'Source',
        'Talents',
        'FOLK Residency Interest',
        'T-Shirt Size',
        'Sent',
        'Role'
      ]);

      for (final c in contacts) {
        csvData.add([
          c['sync_status'] ?? '',
          c['name'] ?? '',
          c['mobile'] ?? '',
          c['email'] ?? '',
          c['whatsapp'] ?? '',
          c['date_of_birth'] ?? '',
          c['age']?.toString() ?? '',
          c['folk_age']?.toString() ?? '',
          c['gender'] ?? '',
          c['folk_id'] ?? '',
          c['folk_guide'] ?? '',
          c['folk_level'] ?? '',
          c['occupation'] ?? '',
          c['marital_status'] ?? '',
          c['language'] ?? '',
          c['living_status'] ?? '',
          c['address'] ?? '',
          c['permanent_address'] ?? '',
          c['city'] ?? '',
          c['state'] ?? '',
          c['country'] ?? '',
          c['higher_qualification'] ?? '',
          c['academic_institution'] ?? '',
          c['institution_location'] ?? '',
          c['organization'] ?? '',
          c['designation'] ?? '',
          c['organization_location'] ?? '',
          c['residency_interest'] ?? '',
          c['origin'] ?? '',
          c['journey'] ?? '',
          c['current_status'] ?? '',
          c['last_activity_type'] ?? '',
          c['last_activity'] ?? '',
          c['last_seen'] ?? '',
          c['yfh_id'] ?? '',
          c['center'] ?? '',
          c['stay'] ?? '',
          c['stream'] ?? '',
          c['highest_qualification'] ?? '',
          c['source'] ?? '',
          c['talents'] ?? '',
          c['folk_residency_interest'] ?? '',
          c['t_shirt_size'] ?? '',
          c['sent']?.toString() ?? '',
          c['role']?.toString() ?? ''
        ]);
      }

      final csvString = Csv().encoder.convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/contacts_export.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      await Share.shareXFiles([XFile(path)], text: 'Contacts Export CSV');
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
      // Fetch call logs without joins
      final res = await Supabase.instance.client.from('call_log').select();
      final callLogs = List<Map<String, dynamic>>.from(res);

      if (callLogs.isEmpty) {
        _showMsgDialog('Export Empty',
            'There are no call logs in the database to export.');
        return;
      }

      // Fetch contact and enabler data
      final contactIds = callLogs.map((l) => l['contact_id']).toSet().toList();
      final enablerIds = callLogs.map((l) => l['enabler_id']).toSet().toList();
      final eventIds = callLogs.map((l) => l['event_id']).toSet().toList();

      final allIds = {...contactIds, ...enablerIds}.toList()
        ..removeWhere((id) => id == null);
      Map<String, Map<String, dynamic>> contactData = {};
      if (allIds.isNotEmpty) {
        final contactsRes = await Supabase.instance.client
            .from('contact')
            .select()
            .inFilter('id', allIds);
        contactData = {for (var c in contactsRes) c['id'] as String: c};
      }

      final eventsRes = await Supabase.instance.client
          .from('event')
          .select('id, name')
          .inFilter('id', eventIds.where((id) => id != null).toList());
      Map<String, String> eventNames = {
        for (var e in eventsRes) e['id'] as String: e['name'] as String
      };

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
      ];
      csvData.add(headers);

      for (final log in callLogs) {
        final outcome = log['call_outcome'] ?? '';
        final followUpStatus = log['follow_up_status'] ?? '';
        final contact = contactData[log['contact_id']] ?? {};
        final enabler = contactData[log['enabler_id']] ?? {};

        final List<dynamic> row = [
          log['called_at'] != null
              ? DateTime.parse(log['called_at']).toLocal().toString()
              : '',
          eventNames[log['event_id']] ?? '',
          enabler['name'] ?? '',
          enabler['mobile'] ?? '',
          contact['name'] ?? '',
          contact['mobile'] ?? '',
          contact['folk_id'] ?? '',
          contact['folk_guide'] ?? '',
          outcome,
          followUpStatus,
          log['follow_up_notes'] ?? '',
          log['next_call_date'] != null
              ? (log['next_call_date'] as String).split(' ')[0]
              : '',
          log['call_duration'] ?? '',
        ];

        csvData.add(row);
      }

      final csvString = Csv().encoder.convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/call_logs_export.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      await Share.shareXFiles([XFile(path)], text: 'Call Logs Export CSV');
    } catch (e) {
      _showMsgDialog('Export Error', 'Failed to export call logs: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
