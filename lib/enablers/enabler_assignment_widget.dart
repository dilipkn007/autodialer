import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/button_widget.dart';
import '/components/member_card_widget.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';

class EnablerAssignmentWidget extends StatefulWidget {
  final ListEnablersWithStatsUsers enabler;
  const EnablerAssignmentWidget({super.key, required this.enabler});

  @override
  State<EnablerAssignmentWidget> createState() => _EnablerAssignmentWidgetState();
}

class _EnablerAssignmentWidgetState extends State<EnablerAssignmentWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  ListEventsEvents? _selectedEvent;
  List<ListEventsEvents> _events = [];

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

  String _searchQuery = "";
  bool _loading = true;
  int _displayLimit = 50;

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
      final eventsRes = await DefaultConnector.instance.listEvents().execute();
      _events = eventsRes.data.events;

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
      final contactsRes = await DefaultConnector.instance.listContacts(
        limit: 5000,
        offset: 0,
      ).search("").execute();

      _allContacts = contactsRes.data.contacts;

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
      _centerOptions = _allContacts.map((c) => c.center).whereType<String>().where((c) => c.trim().isNotEmpty).toSet().toList()..sort();
      _guideOptions = _allContacts.map((c) => c.folkGuide).whereType<String>().where((g) => g.trim().isNotEmpty).toSet().toList()..sort();
      _levelOptions = _allContacts.map((c) => c.folkLevel).whereType<String>().where((l) => l.trim().isNotEmpty).toSet().toList()..sort();
      _genderOptions = _allContacts.map((c) => c.gender).whereType<String>().where((g) => g.trim().isNotEmpty).toSet().toList()..sort();
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
        if (_selectedCenterFilter != null && c.center != _selectedCenterFilter) return false;
        if (_selectedGuideFilter != null && c.folkGuide != _selectedGuideFilter) return false;
        if (_selectedLevelFilter != null && c.folkLevel != _selectedLevelFilter) return false;
        if (_selectedGenderFilter != null && c.gender != _selectedGenderFilter) return false;
        return true;
      }).toList();
    });
  }

  Future<void> _confirmAssignments() async {
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create an Event campaign first.')),
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

    final enablerUid = widget.enabler.uid;
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
        SnackBar(
          content: Text('Assigned ${_selectedContactIds.length} contacts to ${widget.enabler.name} successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
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
          iconTheme: IconThemeData(color: FlutterFlowTheme.of(context).primaryText),
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
                'Assigning to ${widget.enabler.name}',
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
                    DropdownButtonFormField<ListEventsEvents>(
                      value: _selectedEvent,
                      decoration: InputDecoration(
                        labelText: 'Select Campaign Event',
                        labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
                      style: TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontSize: 14),
                      items: _events.map((e) {
                        return DropdownMenuItem<ListEventsEvents>(
                          value: e,
                          child: Text(e.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedEvent = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12.0),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                      decoration: InputDecoration(
                        hintText: 'Search Name, Mobile or Folk ID',
                        hintStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: FlutterFlowTheme.of(context).accent3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
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
                    const SizedBox(height: 12.0),
                    // Dynamic Filters Scroll Row
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
                              icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.redAccent),
                              label: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Filtered: ${_contacts.length} members',
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedContactIds.addAll(_contacts.map((c) => c.id));
                                        });
                                      },
                                      child: Text(
                                        'Select All Filtered',
                                        style: TextStyle(
                                          color: FlutterFlowTheme.of(context).primary,
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
                          ),
                          Expanded(
                            child: _contacts.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Text('No contacts found matching criteria.'),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    itemCount: math.min(_contacts.length, _displayLimit) + (_contacts.length > _displayLimit ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index >= _displayLimit) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: Center(
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  _displayLimit += 50;
                                                });
                                              },
                                              icon: const Icon(Icons.add_rounded, size: 18),
                                              label: Text('Load More (${_contacts.length - _displayLimit} remaining)'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                foregroundColor: FlutterFlowTheme.of(context).primaryText,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20.0),
                                                  side: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      final contact = _contacts[index];
                                      final isSelected = _selectedContactIds.contains(contact.id);
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedContactIds.remove(contact.id);
                                            } else {
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigning',
                            style: FlutterFlowTheme.of(context).labelSmall.override(
                                  font: GoogleFonts.inter(),
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                ),
                          ),
                          Text(
                            '${_selectedContactIds.length} Members',
                            style: FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                        ],
                      ),
                    ),
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
                        disabled: _loading || _selectedContactIds.isEmpty || _selectedEvent == null,
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
