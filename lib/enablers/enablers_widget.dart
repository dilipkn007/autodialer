import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/admin_nav_bar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'enablers_model.dart';
import 'enabler_assignment_widget.dart';
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

  List<ListEnablersWithStatsUsers>? _enablers;
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
      final res = await DefaultConnector.instance.listEnablersWithStats().execute();
      setState(() {
        _enablers = res.data.users;
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
      await DefaultConnector.instance.setUserActiveStatus(uid: uid, isActive: isActive).execute();
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
    bool isSaving = false;

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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
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

                            // Pre-create the user record with the mobile number as their initial UID
                            var builder = DefaultConnector.instance.adminUpsertUser(
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
                          'Add Enabler',
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
    
    List<ListEnablersWithStatsUsers> sortedEnablers = [];

    if (_enablers != null) {
      enablerCount = _enablers!.where((u) => u.isActive).length;
      
      for (final enabler in _enablers!) {
        if (!enabler.isActive) continue;
        final assignments = enabler.assignments_on_enabler;
        totalAssignments += assignments.length;
        completedAssignments += assignments.where((a) => a.status == AssignmentStatus.COMPLETED).length;
        pendingAssignments += assignments.where((a) => a.status == AssignmentStatus.PENDING).length;
      }

      sortedEnablers = List.from(_enablers!.where((u) => u.isActive));
      sortedEnablers.sort((a, b) {
        final aCompleted = a.assignments_on_enabler.where((ass) => ass.status == AssignmentStatus.COMPLETED).length;
        final bCompleted = b.assignments_on_enabler.where((ass) => ass.status == AssignmentStatus.COMPLETED).length;
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
                                        color: Colors.green,
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
                                        color: Colors.orange,
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
                                          final completed = enabler.assignments_on_enabler.where((a) => a.status == AssignmentStatus.COMPLETED).length;
                                          
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
                                                    enabler.name,
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
                                      final total = enabler.assignments_on_enabler.length;
                                      final completed = enabler.assignments_on_enabler
                                          .where((a) => a.status == AssignmentStatus.COMPLETED)
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
    ListEnablersWithStatsUsers enabler,
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
                        color: enabler.isActive
                            ? FlutterFlowTheme.of(context).primary
                            : FlutterFlowTheme.of(context).alternate,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        enabler.avatarInitials ?? 'E',
                        style: FlutterFlowTheme.of(context).titleSmall.override(
                              font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                              color: enabler.isActive
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
                            enabler.name,
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
                              enabler.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ),
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: enabler.isActive,
                                onChanged: (val) {
                                  _toggleEnablerStatus(enabler.uid, val);
                                },
                                activeColor: FlutterFlowTheme.of(context).primary,
                              ),
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
