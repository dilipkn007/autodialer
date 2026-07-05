import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/admin_nav_bar.dart';
import '/components/app_drawer.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'enablers_model.dart';
import 'enabler_assignment_widget.dart';
import 'package:uuid/uuid.dart';
export 'enablers_model.dart';

class EnablersWidget extends StatefulWidget {
  const EnablersWidget({super.key});

  static String routeName = 'Enablers';
  static String routePath = '/enablers';

  @override
  State<EnablersWidget> createState() => _EnablersWidgetState();
}

class _EnablersWidgetState extends State<EnablersWidget> {
  late EnablersModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>>? _enablers;
  bool _loading = true;
  static const int _pageSize = 25;
  int _currentPage = 0;
  int _totalEnablerCount = 0;
  int _enablerRequestId = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  // Event / Campaign filter
  List<Map<String, dynamic>> _events = [];
  String? _selectedEventId; // null = show all events

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EnablersModel());
    _searchController.addListener(() {
      _searchQuery = _searchController.text;
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        _loadEnablers(resetPage: true);
      });
      setState(() {});
    });
    _loadEvents();
    _loadEnablers();
    AuthService.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    _loadEnablers();
  }

  Future<void> _loadEvents() async {
    try {
      final res = await Supabase.instance.client
          .from('event')
          .select('id, name')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _events = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint('Error loading events for filter: $e');
    }
  }

  Future<void> _loadEnablers({bool resetPage = false}) async {
    if (resetPage) _currentPage = 0;
    final requestId = ++_enablerRequestId;
    setState(() {
      _loading = true;
    });
    try {
      final client = Supabase.instance.client;
      final auth = AuthService.instance;
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;
      // --- Event filter: if an event is selected, find enabler IDs for that event first ---
      List<String>? eventFilteredEnablerIds;
      if (_selectedEventId != null) {
        final assignRes = await client
            .from('assignment')
            .select('enabler_id')
            .eq('event_id', _selectedEventId!);
        if (requestId != _enablerRequestId) return;
        eventFilteredEnablerIds = (assignRes as List)
            .map((a) => a['enabler_id'] as String)
            .toSet()
            .toList();
        // If no enablers are assigned to this event, short-circuit
        if (eventFilteredEnablerIds.isEmpty) {
          if (!mounted) return;
          setState(() {
            _enablers = [];
            _totalEnablerCount = 0;
            _loading = false;
          });
          return;
        }
      }

      // Fetch all distinct enabler_ids from assignment table so that contacts
      // with any role (ADMIN, FOLK_GUIDE, etc.) who are acting as enablers
      // also appear in this list.
      final allAssignEnablerRes = await client
          .from('assignment')
          .select('enabler_id');
      if (requestId != _enablerRequestId) return;
      final assignmentEnablerIds = (allAssignEnablerRes as List)
          .map((a) => a['enabler_id'] as String)
          .toSet()
          .toList();

      // Build OR filter: role = ENABLER  OR  id in (assignment enabler ids)
      // When an event filter is active, restrict to that event's enabler IDs.
      final effectiveEnablerIds = eventFilteredEnablerIds ?? assignmentEnablerIds;

      dynamic dataQuery;
      dynamic countQuery;

      if (effectiveEnablerIds.isNotEmpty) {
        dataQuery = client
            .from('contact')
            .select('id, name, mobile, email, is_active, role, avatar_initials')
            .or('role.eq.ENABLER,id.in.(${effectiveEnablerIds.join(',')})');
        countQuery = client
            .from('contact')
            .select('id')
            .or('role.eq.ENABLER,id.in.(${effectiveEnablerIds.join(',')})');
      } else {
        // No assignments exist yet — fall back to role = ENABLER only
        dataQuery = client
            .from('contact')
            .select('id, name, mobile, email, is_active, role, avatar_initials')
            .eq('role', 'ENABLER');
        countQuery = client
            .from('contact')
            .select('id')
            .eq('role', 'ENABLER');
      }

      // Folk guide: only show enablers under this guide
      if (auth.isFolkGuide && auth.folkGuideId != null) {
        dataQuery = dataQuery.eq('folk_guide', auth.folkGuideId!);
        countQuery = countQuery.eq('folk_guide', auth.folkGuideId!);
      }

      dataQuery = _applyEnablerSearch(dataQuery);
      countQuery = _applyEnablerSearch(countQuery);
      final results = await Future.wait<dynamic>([
        dataQuery.order('name').range(from, to),
        countQuery.count(CountOption.exact),
      ]);
      if (requestId != _enablerRequestId) return;
      final pageEnablers = List<Map<String, dynamic>>.from(results[0]);
      final totalCount = (results[1] as PostgrestResponse).count;
      
      // Assignment statistics are only needed for the visible page.
      Map<String, int> enablerAssignmentCounts = {};
      Map<String, int> enablerCompletedCounts = {};
      
      if (pageEnablers.isNotEmpty) {
        final enablerIds = pageEnablers.map((e) => e['id']).toList();
        List<String>? folkContactIds;
        if (auth.isFolkGuide && auth.folkGuideId != null) {
          final folkRes = await client
              .from('contact')
              .select('id')
              .eq('folk_guide', auth.folkGuideId!);
          folkContactIds = folkRes.map((c) => c['id'] as String).toList();
        }
        const int batchSize = 20;
        final batchRequests = <Future<dynamic>>[];
        for (int i = 0; i < enablerIds.length; i += batchSize) {
          final batch = enablerIds.skip(i).take(batchSize).toList();
          dynamic assignQuery = client
              .from('assignment')
              .select('enabler_id, status')
              .inFilter('enabler_id', batch);
          // Scope stats to selected event
          if (_selectedEventId != null) {
            assignQuery = assignQuery.eq('event_id', _selectedEventId!);
          }
          if (folkContactIds != null && folkContactIds.isNotEmpty) {
            assignQuery = assignQuery.inFilter('contact_id', folkContactIds);
          }
          batchRequests.add(assignQuery);
        }
        final assignmentBatches = await Future.wait<dynamic>(batchRequests);
        if (requestId != _enablerRequestId) return;
        for (final assignments in assignmentBatches) {
          for (var a in assignments) {
            final enablerId = a['enabler_id'] as String;
            enablerAssignmentCounts[enablerId] =
                (enablerAssignmentCounts[enablerId] ?? 0) + 1;
            if (a['status'] == 'COMPLETED') {
              enablerCompletedCounts[enablerId] =
                  (enablerCompletedCounts[enablerId] ?? 0) + 1;
            }
          }
        }
      }
      
      // Attach stats to each enabler
      for (var enabler in pageEnablers) {
        enabler['assignment_count'] =
            enablerAssignmentCounts[enabler['id']] ?? 0;
        enabler['completed_count'] = enablerCompletedCounts[enabler['id']] ?? 0;
      }
      
      if (!mounted || requestId != _enablerRequestId) return;
      setState(() {
        _enablers = pageEnablers;
        _totalEnablerCount = totalCount;
        _loading = false;
      });
    } catch (e) {
      if (requestId != _enablerRequestId) return;
      debugPrint("Error loading enablers: $e");
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error loading enablers: $e'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  dynamic _applyEnablerSearch(dynamic query) {
    final search = _searchQuery.trim().replaceAll(RegExp(r'[,()]'), ' ');
    if (search.isNotEmpty) {
      query = query.or(
          'name.ilike.%$search%,mobile.ilike.%$search%,email.ilike.%$search%');
    }
    return query;
  }

  Future<void> _toggleEnablerStatus(String id, bool isActive) async {
    try {
      await Supabase.instance.client
          .from('contact')
          .update({'is_active': isActive}).eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Enabler activated' : 'Enabler deactivated'),
          backgroundColor: Colors.green,
        ),
      );
      _loadEnablers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showAddEnablerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final searchController = TextEditingController();
    bool isSaving = false;

    // Toggle mode
    bool fromContactsMode = true;

    // Search contacts state
    List<Map<String, dynamic>> searchedContacts = [];
    bool isSearchingContacts = false;
    final Set<String> selectedContactIds = {};
    Timer? debounceTimer;

    Future<void> searchContacts(String query, StateSetter setDialogState) async {
      if (query.trim().isEmpty) {
        setDialogState(() {
          searchedContacts = [];
          isSearchingContacts = false;
        });
        return;
      }
      setDialogState(() {
        isSearchingContacts = true;
      });
      try {
        dynamic contactQuery = Supabase.instance.client
            .from('contact')
            .select('id, name, mobile, email')
            .or('name.ilike.%$query%,mobile.like.%$query%')
            .limit(20);
        final auth = AuthService.instance;
        if (auth.isFolkGuide && auth.folkGuideId != null) {
          contactQuery = contactQuery.eq('folk_guide', auth.folkGuideId!);
        }
        final res = await contactQuery;
        setDialogState(() {
          searchedContacts = List<Map<String, dynamic>>.from(res);
          isSearchingContacts = false;
        });
      } catch (e) {
        debugPrint("Error searching contacts: $e");
        setDialogState(() {
          isSearchingContacts = false;
        });
      }
    }

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
                    // Mode Toggle (Select from Contacts vs Manual Entry)
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  fromContactsMode = true;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: fromContactsMode
                                      ? FlutterFlowTheme.of(context).secondaryBackground
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'From Contacts',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: fromContactsMode ? FontWeight.bold : FontWeight.normal,
                                    color: fromContactsMode
                                        ? FlutterFlowTheme.of(context).primaryText
                                        : FlutterFlowTheme.of(context).secondaryText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  fromContactsMode = false;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !fromContactsMode
                                      ? FlutterFlowTheme.of(context).secondaryBackground
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Add Manually',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: !fromContactsMode ? FontWeight.bold : FontWeight.normal,
                                    color: !fromContactsMode
                                        ? FlutterFlowTheme.of(context).primaryText
                                        : FlutterFlowTheme.of(context).secondaryText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    if (fromContactsMode) ...[
                      // Search Bar
                      TextField(
                        controller: searchController,
                        style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                        decoration: InputDecoration(
                          hintText: 'Search Contacts (name or phone)',
                          hintStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: FlutterFlowTheme.of(context).secondaryText),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    searchController.clear();
                                    searchContacts('', setDialogState);
                                  },
                                )
                              : null,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                        ),
                        onChanged: (val) {
                          if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
                          debounceTimer = Timer(const Duration(milliseconds: 300), () {
                            searchContacts(val, setDialogState);
                          });
                        },
                      ),
                      const SizedBox(height: 12.0),

                      // Search Results List
                      if (isSearchingContacts)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else if (searchedContacts.isEmpty && searchController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No matching contacts found',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 13),
                          ),
                        )
                      else if (searchedContacts.isEmpty && searchController.text.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              Icon(Icons.contact_phone_outlined, size: 36, color: FlutterFlowTheme.of(context).secondaryText.withOpacity(0.4)),
                              const SizedBox(height: 8.0),
                              Text(
                                'Type to search existing contacts',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: searchedContacts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final contact = entry.value;
                              final id = contact['id'] as String;
                              final name = contact['name'] as String;
                              final mobile = contact['mobile'] as String? ?? '';
                              final isSelected = selectedContactIds.contains(id);

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (index > 0)
                                    Divider(height: 1, color: FlutterFlowTheme.of(context).alternate),
                                  CheckboxListTile(
                                    value: isSelected,
                                    activeColor: FlutterFlowTheme.of(context).primary,
                                    checkColor: Colors.white,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    title: Text(
                                      name,
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context).primaryText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      mobile,
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context).secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onChanged: (checked) {
                                      setDialogState(() {
                                        if (checked == true) {
                                          selectedContactIds.add(id);
                                        } else {
                                          selectedContactIds.remove(id);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ] else ...[
                      // Manual Entry Form
                      TextField(
                        controller: nameController,
                        style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                        decoration: InputDecoration(
                          labelText: '10-Digit Mobile',
                          labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                          prefixText: '+91 ',
                          prefixStyle: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                        decoration: InputDecoration(
                          labelText: 'Email Address (Optional)',
                          labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () {
                    debounceTimer?.cancel();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving || (fromContactsMode && selectedContactIds.isEmpty)
                      ? null
                      : () async {
                          if (fromContactsMode) {
                            setDialogState(() {
                              isSaving = true;
                            });

                            try {
                              final db = Supabase.instance.client;
                              int successCount = 0;

                              for (final id in selectedContactIds) {
                                await db.from('contact').update({
                                  'role': 'ENABLER',
                                  'is_active': true,
                                }).eq('id', id);

                                successCount++;
                              }

                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Successfully promoted $successCount contact(s) to enablers!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadEnablers();
                            } catch (e) {
                              setDialogState(() {
                                isSaving = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to promote contacts: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } else {
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
                              final formattedPhone = '91$phoneVal';
                              final initials = name
                                  .trim()
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .take(2)
                                  .join()
                                  .toUpperCase();

                              final newUid = const Uuid().v4();

                              await Supabase.instance.client
                                  .from('contact')
                                  .upsert({
                                'id': newUid,
                                'mobile': formattedPhone,
                                'name': name,
                                'role': 'ENABLER',
                                'is_active': true,
                                'email': email.isNotEmpty ? email : null,
                                'avatar_initials':
                                    initials.isNotEmpty ? initials : 'E',
                              });

                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enabler invited successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadEnablers();
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
                          fromContactsMode
                              ? (selectedContactIds.isEmpty
                                  ? 'Add Selected'
                                  : 'Add Selected (${selectedContactIds.length})')
                              : 'Add Enabler',
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

  @override
  Widget build(BuildContext context) {
    // Compute Stats
    int totalAssignments = 0;
    int completedAssignments = 0;
    int pendingAssignments = 0;
    int enablerCount = _totalEnablerCount;
    
    List<Map<String, dynamic>> sortedEnablers = [];

    if (_enablers != null) {
      for (final enabler in _enablers!) {
        if (enabler['is_active'] != true) continue;
        final assignmentCount = enabler['assignment_count'] as int? ?? 0;
        final completedCount = enabler['completed_count'] as int? ?? 0;
        totalAssignments += assignmentCount;
        completedAssignments += completedCount;
        pendingAssignments += assignmentCount - completedCount;
      }

      sortedEnablers =
          List.from(_enablers!.where((u) => u['is_active'] == true));
      sortedEnablers.sort((a, b) {
        final aCompleted = a['completed_count'] as int? ?? 0;
        final bCompleted = b['completed_count'] as int? ?? 0;
        return bCompleted.compareTo(aCompleted);
      });
    }
    
    final topPerformers = sortedEnablers.take(3).toList();

    return GestureDetector(
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
                                'Enablers',
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
                              ElevatedButton.icon(
                                onPressed: _showAddEnablerDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Enabler'),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 12.0),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search by name, mobile or email',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: _searchController.clear,
                                  icon: const Icon(Icons.clear_rounded),
                                )
                              : null,
                          filled: true,
                          fillColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    // Campaign / Event Filter
                    if (_events.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).secondaryBackground,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: _selectedEventId != null
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).alternate,
                              width: _selectedEventId != null ? 1.5 : 1.0,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButton<String?>(
                                value: _selectedEventId,
                                isExpanded: true,
                                dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
                                borderRadius: BorderRadius.circular(12.0),
                                hint: Row(
                                  children: [
                                    Icon(
                                      Icons.campaign_rounded,
                                      size: 18,
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Filter by Campaign / Event',
                                      style: TextStyle(
                                        color: FlutterFlowTheme.of(context).secondaryText,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                icon: _selectedEventId != null
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedEventId = null;
                                          });
                                          _loadEnablers(resetPage: true);
                                        },
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                          color: FlutterFlowTheme.of(context).primary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: FlutterFlowTheme.of(context).secondaryText,
                                      ),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.all_inclusive_rounded,
                                          size: 16,
                                          color: FlutterFlowTheme.of(context).secondaryText,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'All Campaigns',
                                          style: TextStyle(
                                            color: FlutterFlowTheme.of(context).primaryText,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ..._events.map((event) {
                                    return DropdownMenuItem<String?>(
                                      value: event['id'] as String,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.event_rounded,
                                            size: 16,
                                            color: FlutterFlowTheme.of(context).primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              event['name'] as String? ?? 'Unnamed Event',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: FlutterFlowTheme.of(context).primaryText,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedEventId = value;
                                  });
                                  _loadEnablers(resetPage: true);
                                },
                              ),
                            ),
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
              // Body
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadEnablers,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Team Workload Summary Cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        context,
                                        label: 'Page Assigned',
                                        value: '$totalAssignments',
                                        icon: Icons.people_alt_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        context,
                                        label: 'Page Completed',
                                        value: '$completedAssignments',
                                        icon:
                                            Icons.check_circle_outline_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        context,
                                        label: 'Page Pending',
                                        value: '$pendingAssignments',
                                        icon: Icons.pending_actions_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24.0),

                                // Enabler Leaderboard
                                if (topPerformers.isNotEmpty) ...[
                                  Text(
                                    'Page Top Performers',
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
                                  Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: topPerformers
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final index = entry.key;
                                          final enabler = entry.value;
                                          final completed =
                                              enabler['completed_count']
                                                      as int? ??
                                                  0;
                                          
                                          Color medalColor = Colors.grey;
                                          if (index == 0)
                                            medalColor =
                                                const Color(0xFFFFD700); // Gold
                                          else if (index == 1)
                                            medalColor = const Color(
                                                0xFFC0C0C0); // Silver
                                          else if (index == 2)
                                            medalColor = const Color(
                                                0xFFCD7F32); // Bronze
                                          
                                          return Padding(
                                            padding: EdgeInsets.only(
                                                bottom: index ==
                                                        topPerformers.length - 1
                                                    ? 0
                                                    : 12.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.emoji_events_rounded,
                                                    color: medalColor,
                                                    size: 24),
                                                const SizedBox(width: 12.0),
                                                Expanded(
                                                  child: Text(
                                                    enabler['name'] as String,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyLarge
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                        ),
                                                  ),
                                                ),
                                                Text(
                                                  '$completed Calls',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24.0),
                                ],

                                // High Performance Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'All Enablers ($enablerCount)',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12.0),

                                // Enablers List
                                if (_enablers == null || _enablers!.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Text(
                                        'No enablers found',
                                        style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: _enablers!.map((enabler) {
                                      final total =
                                          enabler['assignment_count'] as int? ??
                                              0;
                                      final completed =
                                          enabler['completed_count'] as int? ??
                                              0;

                                      return _buildEnablerListItem(
                                          context, enabler, total, completed);
                                    }).toList(),
                                  ),
                                if (_totalEnablerCount > _pageSize) ...[
                                  const SizedBox(height: 16.0),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        tooltip: 'Previous page',
                                        onPressed: _currentPage > 0
                                            ? () async {
                                                _currentPage--;
                                                await _loadEnablers();
                                              }
                                            : null,
                                        icon: const Icon(
                                            Icons.chevron_left_rounded),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0),
                                        child: Text(
                                          'Page ${_currentPage + 1} of ${(_totalEnablerCount / _pageSize).ceil()}',
                                          style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Next page',
                                        onPressed:
                                            (_currentPage + 1) * _pageSize <
                                                    _totalEnablerCount
                                                ? () async {
                                                    _currentPage++;
                                                    await _loadEnablers();
                                                  }
                                                : null,
                                        icon: const Icon(
                                            Icons.chevron_right_rounded),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              // Navigation Bar
              const AdminNavBar(currentTab: AdminTab.enablers),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditEnablerDialog(Map<String, dynamic> enabler) {
    final nameController =
        TextEditingController(text: enabler['name'] as String);
    final rawPhone = enabler['mobile'] as String? ?? '';
    final localPhone = rawPhone.replaceFirst(RegExp(r'^\+?91'), '');
    final phoneController = TextEditingController(text: localPhone);
    final emailController =
        TextEditingController(text: enabler['email'] as String? ?? '');
    UserRole selectedRole = UserRole.values.firstWhere(
        (r) => r.name == enabler['role'],
        orElse: () => UserRole.ENABLER);
    bool isSaving = false;
    bool isDeleting = false;

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
                'Edit Enabler',
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
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      dropdownColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      decoration: InputDecoration(
                        labelText: 'Role',
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
                      items: const [
                        DropdownMenuItem(
                            value: UserRole.ENABLER, child: Text('Enabler')),
                        DropdownMenuItem(
                            value: UserRole.ADMIN, child: Text('Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: phoneController,
                      enabled: false,
                      style: TextStyle(
                          color: FlutterFlowTheme.of(context).secondaryText),
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Read-only)',
                        labelStyle: TextStyle(
                            color: FlutterFlowTheme.of(context).secondaryText),
                        prefixText: '+91 ',
                        prefixStyle: TextStyle(
                            color: FlutterFlowTheme.of(context).secondaryText),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'To change the phone number (login credential), you must delete and re-create this enabler.',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
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
                    const SizedBox(height: 24.0),
                    OutlinedButton.icon(
                      onPressed: isDeleting
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Enabler'),
                                  content: Text(
                                      'Are you sure you want to completely remove ${enabler['name']}? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete',
                                          style: TextStyle(
                                              color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                setDialogState(() => isDeleting = true);
                                try {
                                  await Supabase.instance.client
                                      .from('contact')
                                      .delete()
                                      .eq('id', enabler['id']);
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Enabler deleted successfully'),
                                        backgroundColor: Colors.green),
                                  );
                                  _loadEnablers();
                                } catch (e) {
                                  setDialogState(() => isDeleting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to delete enabler: $e'),
                                        backgroundColor: Colors.redAccent),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.delete_forever_rounded,
                          color: Colors.redAccent),
                      label: Text('Delete Enabler',
                          style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: (isSaving || isDeleting)
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText),
                  ),
                ),
                ElevatedButton(
                  onPressed: (isSaving || isDeleting)
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Name is required')));
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final initials = name
                                .trim()
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .take(2)
                                .join()
                                .toUpperCase();
                            final avatarInitials =
                                enabler['avatar_initials'] as String? ??
                                    (initials.isNotEmpty ? initials : 'E');
                            
                            await Supabase.instance.client
                                .from('contact')
                                .update({
                                   'name': name,
                                   'role': selectedRole.name,
                                   'email': email.isNotEmpty ? email : null,
                                   'avatar_initials': avatarInitials,
                                 }).eq('id', enabler['id']);

                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enabler updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadEnablers();
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update enabler: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
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

  Widget _buildEnablerListItem(
    BuildContext context,
    Map<String, dynamic> enabler,
    int total,
    int completed,
  ) {
    final rate = total > 0 ? (completed / total) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EnablerAssignmentWidget(enabler: enabler),
              ),
            ).then((_) {
              _loadEnablers();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: enabler['is_active'] == true
                            ? FlutterFlowTheme.of(context).primary
                            : FlutterFlowTheme.of(context).alternate,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        enabler['avatar_initials'] as String? ?? 'E',
                        style: FlutterFlowTheme.of(context).titleSmall.override(
                              font: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold),
                              color: enabler['is_active'] == true
                                  ? FlutterFlowTheme.of(context).onPrimary
                                  : FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    // Enabler details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            enabler['name'] as String,
                            style: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '$completed / $total Completed',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    // Active Toggle and Icon
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              enabler['is_active'] == true
                                  ? 'Active'
                                  : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ),
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: enabler['is_active'] == true,
                                onChanged: (val) {
                                  _toggleEnablerStatus(
                                      enabler['id'] as String, val);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20),
                              onPressed: () => _showEditEnablerDialog(enabler),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: LinearProgressIndicator(
                          value: rate,
                          minHeight: 8.0,
                          backgroundColor:
                              FlutterFlowTheme.of(context).alternate,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            rate >= 0.8
                                ? Colors.green
                                : (rate >= 0.5
                                    ? Colors.orange
                                    : FlutterFlowTheme.of(context).primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Text(
                      '${(rate * 100).round()}%',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font:
                                GoogleFonts.inter(fontWeight: FontWeight.bold),
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                    ),
                    const SizedBox(width: 8.0),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
