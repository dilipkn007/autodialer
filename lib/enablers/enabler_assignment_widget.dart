import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/button_widget.dart';
import '/components/member_card_widget.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';

class EnablerAssignmentWidget extends StatefulWidget {
  final Map<String, dynamic> enabler;
  const EnablerAssignmentWidget({super.key, required this.enabler});

  @override
  State<EnablerAssignmentWidget> createState() =>
      _EnablerAssignmentWidgetState();
}

class _EnablerAssignmentWidgetState extends State<EnablerAssignmentWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _selectedEvent;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _assignments = [];
  Map<String, String> _contactIdToEnablerName = {};
  Map<String, String> _contactIdToAssignmentStatus = {};

  List<Map<String, dynamic>> _allContacts = [];
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

  String _searchQuery = "";
  bool _loading = true;
  int _displayLimit = 50;
  bool _isManageMode = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _applyFilters();
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
    });

    try {
      // 1. Load active events
      final eventsRes = await Supabase.instance.client.from('event').select();
      _events = eventsRes;

      if (_events.isNotEmpty) {
        _selectedEvent = _events.first;
      }

      // 2. Load contacts
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
            List<Map<String, dynamic>> loadedContacts = [];
      int offset = 0;
      const limit = 1000;
      while (true) {
        final chunk = await Supabase.instance.client
            .from('contact')
            .select()
            .range(offset, offset + limit - 1);
        loadedContacts.addAll(List<Map<String, dynamic>>.from(chunk));
        if (chunk.length < limit) break;
        offset += limit;
      }
      final contactsRes = loadedContacts;

      _allContacts = contactsRes;

      // Fetch assignments for the selected event to build lookup map
      final eventId = _selectedEvent?['id'];
      if (eventId != null) {
        final assignmentsRes = await Supabase.instance.client
            .from('assignment')
            .select('contact_id, enabler_id, status')
            .eq('event_id', eventId);
        _assignments = assignmentsRes;
        
        // Fetch enabler names for the assignments
        final enablerIds =
            assignmentsRes.map((a) => a['enabler_id']).toSet().toList();
        Map<String, String> enablerNames = {};
        if (enablerIds.isNotEmpty) {
          final enablersRes = await Supabase.instance.client
              .from('contact')
              .select('id, name')
              .inFilter('id', enablerIds);
          enablerNames = {
            for (var e in enablersRes) e['id'] as String: e['name'] as String
          };
        }
        
        _contactIdToEnablerName = {
          for (var a in _assignments)
            a['contact_id']: enablerNames[a['enabler_id']] ?? ''
        };
        _contactIdToAssignmentStatus = {
          for (var a in _assignments) a['contact_id']: a['status'] as String
        };
      } else {
        _assignments = [];
        _contactIdToEnablerName = {};
        _contactIdToAssignmentStatus = {};
      }

      // Reset dynamic filter options
      _centerOptions.clear();
      _guideOptions.clear();
      _levelOptions.clear();
      _genderOptions.clear();

      _applyFilters();
    } catch (e) {
      debugPrint("Error loading contacts: $e");
    }
  }

  void _applyFilters() {
    // 1. Compute dynamic filter options from all contacts (if options are empty)
    if (_centerOptions.isEmpty && _allContacts.isNotEmpty) {
      _centerOptions = _allContacts
          .map((c) => c['center'])
          .whereType<String>()
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _guideOptions = _allContacts
          .map((c) => c['folk_guide'])
          .whereType<String>()
          .where((g) => g.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _levelOptions = _allContacts
          .map((c) => c['folk_level'])
          .whereType<String>()
          .where((l) => l.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _genderOptions = _allContacts
          .map((c) => c['gender'])
          .whereType<String>()
          .where((g) => g.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    }

    final query = _searchQuery.trim().toLowerCase();
    setState(() {
      _contacts = _allContacts.where((c) {
        // Mode filter
        final isAssignedToThis =
            _contactIdToEnablerName[c['id']] == widget.enabler['name'];
        if (_isManageMode && !isAssignedToThis) return false;
        if (!_isManageMode && isAssignedToThis) return false;

        if (query.isNotEmpty) {
          final nameMatch = c['name'].toLowerCase().contains(query);
          final phoneMatch = c['mobile'].contains(query);
          final folkIdMatch =
              (c['folk_id'] ?? '').toLowerCase().contains(query);
          if (!nameMatch && !phoneMatch && !folkIdMatch) {
            return false;
          }
        }
        if (_selectedCenterFilter != null &&
            c['center'] != _selectedCenterFilter) return false;
        if (_selectedGuideFilter != null &&
            c['folk_guide'] != _selectedGuideFilter) return false;
        if (_selectedLevelFilter != null &&
            c['folk_level'] != _selectedLevelFilter) return false;
        if (_selectedGenderFilter != null &&
            c['gender'] != _selectedGenderFilter) return false;
        return true;
      }).toList();
    });
  }

  Future<void> _confirmAssignments() async {
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select or create an Event campaign first.')),
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

    final enablerId = widget.enabler['id'];
    final eventId = _selectedEvent!['id'];
    final adminId = AuthService.instance.currentUser!.id;

    try {
      int sortOrder = 0;
      // Use reassignContact which atomically removes any existing assignment
      // for this contact+event before inserting the new one.
      // This handles both first-time assignments and re-assignments cleanly.
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
              'Assigned ${_selectedContactIds.length} contacts to ${widget.enabler['name']} successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
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

  Future<void> _unassignContacts() async {
    if (_selectedEvent == null || _selectedContactIds.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final futures = _selectedContactIds.map((contactId) {
        return Supabase.instance.client.from('assignment').delete().match(
            {'contact_id': contactId, 'event_id': _selectedEvent!['id']});
      });

      await Future.wait(futures);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully unassigned ${_selectedContactIds.length} contacts.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedContactIds.clear();
      });
      await _loadContacts();
    } catch (e) {
      debugPrint("Error unassigning contacts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unassign contacts: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showTransferDialog() async {
    if (_selectedEvent == null || _selectedContactIds.isEmpty) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await Supabase.instance.client
          .from('contact')
          .select()
          .eq('is_active', true);
      Navigator.pop(context); // close loading

      final activeEnablers = res
          .where(
              (e) => e['is_active'] == true && e['id'] != widget.enabler['id'])
          .toList();

      if (activeEnablers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No other active enablers found to transfer to.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (dialogContext) {
          String? selectedEnablerId;
          String searchQuery = '';
          List<Map<String, dynamic>> filteredEnablers =
              List.from(activeEnablers);

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor:
                    FlutterFlowTheme.of(context).secondaryBackground,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                title: Text(
                  'Transfer Contacts',
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                        font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select an enabler to transfer ${_selectedContactIds.length} contacts to:',
                        style: TextStyle(
                            color: FlutterFlowTheme.of(context).secondaryText),
                    ),
                    const SizedBox(height: 16),
                      TextField(
                      decoration: InputDecoration(
                          labelText: 'Search enablers',
                          labelStyle: TextStyle(
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 13),
                          hintText: 'Enter name or mobile number',
                          prefixIcon: Icon(Icons.search,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 10.0),
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
                      onChanged: (val) {
                        setDialogState(() {
                            searchQuery = val.toLowerCase();
                            filteredEnablers = activeEnablers.where((e) {
                              final name =
                                  (e['name'] as String? ?? '').toLowerCase();
                              final mobile =
                                  (e['mobile'] as String? ?? '').toLowerCase();
                              return name.contains(searchQuery) ||
                                  mobile.contains(searchQuery);
                            }).toList();
                        });
                      },
                    ),
                      const SizedBox(height: 8),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: filteredEnablers.isEmpty
                            ? Center(
                                child: Text('No enablers found',
                                    style: TextStyle(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText)))
                            : ListView.builder(
                                itemCount: filteredEnablers.length,
                                itemBuilder: (context, index) {
                                  final enabler = filteredEnablers[index];
                                  final isSelected =
                                      selectedEnablerId == enabler['id'];
                                  return ListTile(
                                    selected: isSelected,
                                    selectedTileColor:
                                        FlutterFlowTheme.of(context)
                                            .primary
                                            .withValues(alpha: 0.1),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          FlutterFlowTheme.of(context)
                                              .primaryContainer,
                                      child: Text(
                                        (enabler['name'] as String? ?? '?')[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(enabler['name'] ?? '',
                                        style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText)),
                                    subtitle: Text(enabler['mobile'] ?? '',
                                        style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 12)),
                                    onTap: () {
                                      setDialogState(() {
                                        selectedEnablerId = enabler['id'];
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                  ],
                ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: FlutterFlowTheme.of(context).secondaryText)),
                  ),
                  ElevatedButton(
                    onPressed: selectedEnablerId == null
                        ? null
                        : () async {
                            Navigator.pop(dialogContext);
                            await _transferContacts(selectedEnablerId!);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: FlutterFlowTheme.of(context).onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text('Transfer'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load enablers: $e')),
      );
    }
  }

  Future<void> _transferContacts(String targetEnablerId) async {
    setState(() {
      _loading = true;
    });

    try {
      final adminId = AuthService.instance.currentUser?.id;
      final futures = _selectedContactIds.map((contactId) async {
        return await Supabase.instance.client.from('assignment').upsert({
          'contact_id': contactId,
          'enabler_id': targetEnablerId,
          'event_id': _selectedEvent!['id'],
          'sort_order': 0,
          'assigned_by': adminId ?? '',
          'status': 'PENDING'
        });
      });

      await Future.wait(futures);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully transferred ${_selectedContactIds.length} contacts.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedContactIds.clear();
      });
      await _loadContacts();
    } catch (e) {
      debugPrint("Error transferring contacts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to transfer contacts: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
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
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          iconTheme:
              IconThemeData(color: FlutterFlowTheme.of(context).primaryText),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Contacts',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              Text(
                'Assigning to ${widget.enabler['name']}',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(),
                      color: FlutterFlowTheme.of(context).accent3,
                    ),
              ),
            ],
          ),
          elevation: 1.0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Filters Card
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Event Selector
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedEvent,
                      decoration: InputDecoration(
                        labelText: 'Select Campaign Event',
                        labelStyle: TextStyle(
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 12.0),
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
                      dropdownColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 14),
                      items: _events.map((e) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: e,
                          child: Text(e['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedEvent = val;
                          _selectedContactIds.clear();
                        });
                        _loadContacts();
                      },
                    ),
                    const SizedBox(height: 16.0),
                    // Mode Toggle
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isManageMode = false;
                                _selectedContactIds.clear();
                                _applyFilters();
                              });
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              decoration: BoxDecoration(
                                color: !_isManageMode
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: !_isManageMode
                                      ? FlutterFlowTheme.of(context).primary
                                      : FlutterFlowTheme.of(context).alternate,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Assign New',
                                style: TextStyle(
                                  color: !_isManageMode
                                      ? FlutterFlowTheme.of(context).onPrimary
                                      : FlutterFlowTheme.of(context)
                                          .primaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isManageMode = true;
                                _selectedContactIds.clear();
                                _applyFilters();
                              });
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              decoration: BoxDecoration(
                                color: _isManageMode
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: _isManageMode
                                      ? FlutterFlowTheme.of(context).primary
                                      : FlutterFlowTheme.of(context).alternate,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Manage Assigned',
                                style: TextStyle(
                                  color: _isManageMode
                                      ? FlutterFlowTheme.of(context).onPrimary
                                      : FlutterFlowTheme.of(context)
                                          .primaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      style: TextStyle(
                          color: FlutterFlowTheme.of(context).primaryText),
                      decoration: InputDecoration(
                        hintText: 'Search Name, Mobile or Folk ID',
                        hintStyle: TextStyle(
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: FlutterFlowTheme.of(context).accent3),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 12.0),
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
                    const SizedBox(height: 12.0),
                    // Dynamic Filters Scroll Row
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
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // Contacts List Area
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // Batch Selection Action row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 8.0),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: [
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Filtered: ${_contacts.length} members',
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
                                          color: FlutterFlowTheme.of(context)
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
                                              _contacts.map((c) => c['id']));
                                        });
                                      },
                                      child: Text(
                                        'Select All Filtered',
                                        style: TextStyle(
                                          color: FlutterFlowTheme.of(context)
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
                          ),
                          Expanded(
                            child: _contacts.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Text(
                                          'No contacts found matching criteria.'),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0),
                                    itemCount: math.min(
                                            _contacts.length, _displayLimit) +
                                        (_contacts.length > _displayLimit
                                            ? 1
                                            : 0),
                                    itemBuilder: (context, index) {
                                      if (index >= _displayLimit) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16.0),
                                          child: Center(
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
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                foregroundColor:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                  side: BorderSide(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .alternate),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 8.0),
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      final contact = _contacts[index];
                                      final isSelected = _selectedContactIds
                                          .contains(contact['id']);
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedContactIds
                                                  .remove(contact['id']);
                                            } else {
                                              _selectedContactIds
                                                  .add(contact['id']);
                                            }
                                          });
                                        },
                                        child: MemberCardWidget(
                                          currentEnabler:
                                              _contactIdToEnablerName[
                                                      contact['id']] ??
                                                  'Unassigned',
                                          folkId: contact['folk_id'] ?? 'No ID',
                                          name: contact['name'],
                                          selected: isSelected,
                                          assignmentStatus: _isManageMode
                                              ? _contactIdToAssignmentStatus[
                                                  contact['id']]
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ),
              // Bottom Action Bar
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24.0),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isManageMode ? 'Managing' : 'Assigning',
                          style: FlutterFlowTheme.of(context)
                              .labelSmall
                              .override(
                                  font: GoogleFonts.inter(),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                ),
                          ),
                          Text(
                            '${_selectedContactIds.length} Members',
                          style: FlutterFlowTheme.of(context)
                              .titleMedium
                              .override(
                                font: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold),
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                        ],
                      ),
                    if (_isManageMode)
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: (_loading ||
                                    _selectedContactIds.isEmpty ||
                                    _selectedEvent == null)
                                ? null
                                : _showTransferDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  FlutterFlowTheme.of(context).primary,
                              foregroundColor:
                                  FlutterFlowTheme.of(context).onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                            ),
                            child: const Text('Transfer'),
                          ),
                          const SizedBox(width: 12.0),
                          ElevatedButton(
                            onPressed: (_loading ||
                                    _selectedContactIds.isEmpty ||
                                    _selectedEvent == null)
                                ? null
                                : _unassignContacts,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                            ),
                            child: const Text('Unassign'),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _confirmAssignments,
                        child: ButtonWidget(
                          icon: Icon(
                            Icons.check_circle_rounded,
                            color: FlutterFlowTheme.of(context).onPrimary,
                            size: 24.0,
                          ),
                          iconPresent: true,
                          iconEndPresent: false,
                          content: 'Assign to Enabler',
                          variant: 'primary',
                          size: 'large',
                          fullWidth: false,
                          loading: _loading,
                          disabled: _loading ||
                              _selectedContactIds.isEmpty ||
                              _selectedEvent == null,
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
