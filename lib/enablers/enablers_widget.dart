import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/admin_nav_bar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:f_o_l_k_auto_dialer/models/enums.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EnablersModel());
    _loadEnablers();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadEnablers() async {
    setState(() {
      _loading = true;
    });
    try {
      final res = await Supabase.instance.client.from('users').select('uid, name, phone, email, is_active, role, avatar_initials, assignment!assignment_enabler_id_fkey(status)').eq('role', 'ENABLER');
      setState(() {
        _enablers = res;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading enablers: $e");
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading enablers: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _toggleEnablerStatus(String uid, bool isActive) async {
    try {
      await Supabase.instance.client.from('users').update({'is_active': isActive}).eq('uid', uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Enabler activated' : 'Enabler deactivated'),
          backgroundColor: Colors.green,
        ),
      );
      _loadEnablers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.redAccent),
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
        final res = await Supabase.instance.client
            .from('contact')
            .select('id, name, mobile, email')
            .or('name.ilike.%$query%,mobile.like.%$query%')
            .limit(20);
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
                    style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
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
                                final contact = searchedContacts.firstWhere((c) => c['id'] == id);
                                final name = contact['name'] as String;
                                final mobile = contact['mobile'] as String? ?? '';
                                final email = contact['email'] as String? ?? '';

                                if (mobile.isEmpty) continue;

                                String normalizePhoneLocal(String ph) {
                                  final clean = ph.replaceAll(RegExp(r'\D'), '');
                                  if (clean.length == 10) return '+91$clean';
                                  if (clean.length == 12 && clean.startsWith('91')) return '+$clean';
                                  return '+$clean';
                                }

                                final phoneFormatted = normalizePhoneLocal(mobile);
                                final base10 = phoneFormatted.substring(phoneFormatted.length - 10);

                                // Check if user already exists in users table
                                final existingUser = await db
                                    .from('users')
                                    .select('uid, role')
                                    .or('phone.eq.$phoneFormatted,phone.eq.$base10,phone.eq.91$base10,phone.eq.+91$base10')
                                    .maybeSingle();

                                final initials = name
                                    .trim()
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .take(2)
                                    .join()
                                    .toUpperCase();

                                if (existingUser != null) {
                                  final uid = existingUser['uid'] as String;
                                  await db.from('users').update({
                                    'role': 'ENABLER',
                                    'is_active': true,
                                  }).eq('uid', uid);
                                } else {
                                  final newUid = const Uuid().v4();
                                  await db.from('users').insert({
                                    'uid': newUid,
                                    'phone': phoneFormatted,
                                    'name': name,
                                    'role': 'ENABLER',
                                    'is_active': true,
                                    if (email.isNotEmpty) 'email': email,
                                    'avatar_initials': initials.isNotEmpty ? initials : 'E',
                                  });
                                }

                                await db.from('contact').update({
                                  'is_enabler': 'true',
                                }).eq('id', id);

                                successCount++;
                              }

                              debounceTimer?.cancel();
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
                            // Manual Entry Mode
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
                                const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
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

                              final newUid = const Uuid().v4();

                              // Check if user already exists
                              final db = Supabase.instance.client;
                              final existingUser = await db
                                  .from('users')
                                  .select('uid')
                                  .or('phone.eq.$formattedPhone,phone.eq.91$phoneVal,phone.eq.+$phoneVal')
                                  .maybeSingle();

                              if (existingUser != null) {
                                final uid = existingUser['uid'] as String;
                                await db.from('users').update({
                                  'role': 'ENABLER',
                                  'is_active': true,
                                  'name': name,
                                  if (email.isNotEmpty) 'email': email,
                                }).eq('uid', uid);
                              } else {
                                await db.from('users').insert({
                                  'uid': newUid,
                                  'phone': formattedPhone,
                                  'name': name,
                                  'role': 'ENABLER',
                                  'is_active': true,
                                  'email': email.isNotEmpty ? email : null,
                                  'avatar_initials': initials.isNotEmpty ? initials : 'E',
                                });
                              }

                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enabler added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadEnablers();
                            } catch (e) {
                              setDialogState(() {
                                isSaving = false;
                              });
                              final errStr = e.toString();
                              String userFriendlyMsg = 'Failed to invite enabler: $e';
                              if (errStr.contains('user_phone_uidx') ||
                                  errStr.contains('unique constraint') ||
                                  errStr.contains('ALREADY_EXISTS') ||
                                  errStr.contains('duplicate key')) {
                                userFriendlyMsg = 'A user with this mobile number already exists.';
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          fromContactsMode
                              ? (selectedContactIds.isEmpty
                                  ? 'Add Selected'
                                  : 'Add Selected (${selectedContactIds.length})')
                              : 'Add Enabler',
                          style: TextStyle(color: FlutterFlowTheme.of(context).onPrimary),
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
    int enablerCount = 0;
    
    List<Map<String, dynamic>> sortedEnablers = [];

    if (_enablers != null) {
      enablerCount = _enablers!.where((u) => u['is_active'] == true).length;
      
      for (final enabler in _enablers!) {
        if (enabler['is_active'] != true) continue;
        final assignments = (enabler['assignment'] as List<dynamic>?) ?? [];
        totalAssignments += assignments.length;
        completedAssignments += assignments.where((a) => a['status'] == 'COMPLETED').length;
        pendingAssignments += assignments.where((a) => a['status'] == 'PENDING').length;
      }

      sortedEnablers = List.from(_enablers!.where((u) => u['is_active'] == true));
      sortedEnablers.sort((a, b) {
        final aAssignments = (a['assignment'] as List<dynamic>?) ?? [];
        final bAssignments = (b['assignment'] as List<dynamic>?) ?? [];
        final aCompleted = aAssignments.where((ass) => ass['status'] == 'COMPLETED').length;
        final bCompleted = bAssignments.where((ass) => ass['status'] == 'COMPLETED').length;
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
                                'Enablers',
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
                            onPressed: _showAddEnablerDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Enabler'),
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
                                        label: 'Total Assigned',
                                        value: '$totalAssignments',
                                        icon: Icons.people_alt_rounded,
                                        color: FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        context,
                                        label: 'Completed Calls',
                                        value: '$completedAssignments',
                                        icon: Icons.check_circle_outline_rounded,
                                        color: FlutterFlowTheme.of(context).primary,
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
                                        label: 'Pending Calls',
                                        value: '$pendingAssignments',
                                        icon: Icons.pending_actions_rounded,
                                        color: FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24.0),

                                // Enabler Leaderboard
                                if (topPerformers.isNotEmpty) ...[
                                  Text(
                                    'Top Performers',
                                    style: FlutterFlowTheme.of(context).titleMedium.override(
                                          font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                          color: FlutterFlowTheme.of(context).primaryText,
                                        ),
                                  ),
                                  const SizedBox(height: 16.0),
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
                                        children: topPerformers.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final enabler = entry.value;
                                          final completed = (enabler['assignment'] as List<dynamic>?)?.where((a) => a['status'] == 'COMPLETED').length ?? 0;
                                          
                                          Color medalColor = Colors.grey;
                                          if (index == 0) medalColor = const Color(0xFFFFD700); // Gold
                                          else if (index == 1) medalColor = const Color(0xFFC0C0C0); // Silver
                                          else if (index == 2) medalColor = const Color(0xFFCD7F32); // Bronze
                                          
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: index == topPerformers.length - 1 ? 0 : 12.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.emoji_events_rounded, color: medalColor, size: 24),
                                                const SizedBox(width: 12.0),
                                                Expanded(
                                                  child: Text(
                                                    enabler['name'] as String,
                                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                          font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                        ),
                                                  ),
                                                ),
                                                Text(
                                                  '$completed Calls',
                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                        font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                        color: FlutterFlowTheme.of(context).secondaryText,
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'All Enablers ($enablerCount)',
                                      style: FlutterFlowTheme.of(context).titleMedium.override(
                                            font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                            color: FlutterFlowTheme.of(context).primaryText,
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
                                        style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: _enablers!.map((enabler) {
                                      final assignments = (enabler['assignment'] as List<dynamic>?) ?? [];
                                      final total = assignments.length;
                                      final completed = assignments
                                          .where((a) => a['status'] == 'COMPLETED')
                                          .length;

                                      return _buildEnablerListItem(context, enabler, total, completed);
                                    }).toList(),
                                  ),
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
    final nameController = TextEditingController(text: enabler['name'] as String);
    final rawPhone = enabler['phone'] as String? ?? '';
    final localPhone = rawPhone.replaceFirst(RegExp(r'^\+?91'), '');
    final phoneController = TextEditingController(text: localPhone);
    final emailController = TextEditingController(text: enabler['email'] as String? ?? '');
    UserRole selectedRole = UserRole.values.firstWhere((r) => r.name == enabler['role'], orElse: () => UserRole.ENABLER);
    bool isSaving = false;
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
                      decoration: InputDecoration(
                        labelText: 'Role',
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
                      items: const [
                        DropdownMenuItem(value: UserRole.ENABLER, child: Text('Enabler')),
                        DropdownMenuItem(value: UserRole.ADMIN, child: Text('Admin')),
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
                      style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Read-only)',
                        labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                        prefixText: '+91 ',
                        prefixStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
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
                    const SizedBox(height: 24.0),
                    OutlinedButton.icon(
                      onPressed: isDeleting
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Enabler'),
                                  content: Text('Are you sure you want to completely remove ${enabler['name']}? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                setDialogState(() => isDeleting = true);
                                try {
                                  await Supabase.instance.client.from('users').delete().eq('uid', enabler['uid']);
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Enabler deleted successfully'), backgroundColor: Colors.green),
                                  );
                                  _loadEnablers();
                                } catch (e) {
                                  setDialogState(() => isDeleting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to delete enabler: $e'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                      label: Text('Delete Enabler', style: TextStyle(color: Colors.redAccent)),
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
                  onPressed: (isSaving || isDeleting) ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                  ),
                ),
                ElevatedButton(
                  onPressed: (isSaving || isDeleting)
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final initials = name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
                            final avatarInitials = enabler['avatar_initials'] as String? ?? (initials.isNotEmpty ? initials : 'E');
                            
                            await Supabase.instance.client.from('users').update({
                              'name': name,
                              'role': selectedRole.name,
                              'email': email.isNotEmpty ? email : null,
                              'avatar_initials': avatarInitials,
                            }).eq('uid', enabler['uid']);

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(color: Colors.white)),
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
                              font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
                            style: FlutterFlowTheme.of(context).bodyLarge.override(
                                  font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '$completed / $total Completed',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: FlutterFlowTheme.of(context).secondaryText,
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
                              enabler['is_active'] == true ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ),
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: enabler['is_active'] == true,
                                onChanged: (val) {
                                  _toggleEnablerStatus(enabler['uid'] as String, val);
                                },
                                activeThumbColor: FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 20),
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
                          backgroundColor: FlutterFlowTheme.of(context).alternate,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            rate >= 0.8 ? Colors.green : (rate >= 0.5 ? Colors.orange : FlutterFlowTheme.of(context).primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Text(
                      '${(rate * 100).round()}%',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
