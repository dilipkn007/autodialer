import '/components/accordion_item_widget.dart';
import '/components/button_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'calling_dashboard_model.dart';

export 'calling_dashboard_model.dart';

class CallingDashboardWidget extends StatefulWidget {
  const CallingDashboardWidget({super.key});

  static String routeName = 'CallingDashboard';
  static String routePath = '/callingDashboard';

  static ListAllAssignmentsForEnablerAssignments? currentAssignment;

  @override
  State<CallingDashboardWidget> createState() => _CallingDashboardWidgetState();
}

class _CallingDashboardWidgetState extends State<CallingDashboardWidget> {
  late CallingDashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  GetContactDetailsContact? _contactDetails;
  bool _loadingContact = true;
  bool _saving = false;

  FollowUpStatus _selectedStatus = FollowUpStatus.INTERESTED;
  CallOutcome _selectedOutcome = CallOutcome.ANSWERED;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nextCallController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CallingDashboardModel());

    _notesController.text = "Interested in attending weekend programs and activities.";
    _nextCallController.text = DateTime.now().add(const Duration(days: 7)).toString().substring(0, 10);

    _model.textFieldModel1.inputTextController = _notesController;
    _model.textFieldModel2.inputTextController = _nextCallController;

    _loadContactDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nextCallController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadContactDetails() async {
    final assignment = CallingDashboardWidget.currentAssignment;
    if (assignment == null) return;

    setState(() {
      _loadingContact = true;
    });

    try {
      final res = await DefaultConnector.instance.getContactDetails(id: assignment.contact.id).execute();
      setState(() {
        _contactDetails = res.data.contact;
        _loadingContact = false;
      });
    } catch (e) {
      debugPrint("Error loading contact details: $e");
      setState(() {
        _loadingContact = false;
      });
    }
  }

  Future<void> _makeCall() async {
    final assignment = CallingDashboardWidget.currentAssignment;
    if (assignment == null) return;

    final phone = assignment.contact.mobile;
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch dialer')),
      );
    }
  }

  Future<void> _saveAndGoBack() async {
    final assignment = CallingDashboardWidget.currentAssignment;
    if (assignment == null) return;

    setState(() {
      _saving = true;
    });

    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      // 1. Record call log
      final dateStr = _nextCallController.text.trim();
      DateTime? nextCallDate;
      try {
        nextCallDate = DateTime.parse(dateStr);
      } catch (_) {}

      await DefaultConnector.instance.recordCallLog(
        assignmentId: assignment.id,
        contactId: assignment.contact.id,
        enablerUid: user.uid,
        eventId: assignment.event.id,
        callOutcome: _selectedOutcome,
      )
      .followUpStatus(_selectedStatus)
      .followUpNotes(_notesController.text.trim())
      .nextCallDate(nextCallDate)
      .execute();

      // 2. Mark assignment complete
      await DefaultConnector.instance.updateAssignmentStatus(
        id: assignment.id,
        status: AssignmentStatus.COMPLETED,
      ).execute();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response logged successfully!')),
      );

      context.safePop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save log: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Widget _buildStatusChip(String label, FollowUpStatus status) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        height: 38.0,
        decoration: BoxDecoration(
          color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
        ),
        alignment: const AlignmentDirectional(0.0, 0.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: FlutterFlowTheme.of(context).onPrimary,
                  size: 16.0,
                ),
              if (isSelected) const SizedBox(width: 6),
              Text(
                label,
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.inter(),
                      color: isSelected ? FlutterFlowTheme.of(context).onPrimary : FlutterFlowTheme.of(context).primaryText,
                      fontSize: 14.0,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutcomeChip(String label, CallOutcome outcome) {
    final isSelected = _selectedOutcome == outcome;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOutcome = outcome;
        });
      },
      child: Container(
        height: 38.0,
        decoration: BoxDecoration(
          color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
        ),
        alignment: const AlignmentDirectional(0.0, 0.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: FlutterFlowTheme.of(context).onPrimary,
                  size: 16.0,
                ),
              if (isSelected) const SizedBox(width: 6),
              Text(
                label,
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.inter(),
                      color: isSelected ? FlutterFlowTheme.of(context).onPrimary : FlutterFlowTheme.of(context).primaryText,
                      fontSize: 14.0,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignment = CallingDashboardWidget.currentAssignment;
    if (assignment == null) {
      return const Scaffold(body: Center(child: Text('No active assignment loaded.')));
    }

    final contact = assignment.contact;

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
                color: FlutterFlowTheme.of(context).primaryBackground,
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
                            children: [
                              FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 40.0,
                                fillColor: Colors.transparent,
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  size: 24.0,
                                ),
                                onPressed: () => context.safePop(),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FOLK AUTO DIALER',
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                          ),
                                          color: FlutterFlowTheme.of(context).primaryText,
                                          lineHeight: 1.2,
                                        ),
                                  ),
                                  Text(
                                    'Call Session Active',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.inter(),
                                          color: FlutterFlowTheme.of(context).primary,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                ],
                              ),
                            ],
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
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                primary: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          borderRadius: BorderRadius.circular(16.0),
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                contact.name,
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      color: FlutterFlowTheme.of(context).primaryText,
                                      lineHeight: 1.2,
                                    ),
                              ),
                              Text(
                                contact.mobile,
                                style: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.outfit(),
                                      color: FlutterFlowTheme.of(context).primaryText70,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primary10,
                                  borderRadius: BorderRadius.circular(2.0),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 4.0, 8.0, 4.0),
                                  child: Text(
                                    'FOLK ID: ${contact.folkId ?? "N/A"}',
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          font: GoogleFonts.inter(),
                                          color: FlutterFlowTheme.of(context).onPrimary,
                                          lineHeight: 1.2,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 28),
                                    onPressed: () async {
                                      final url = Uri.parse("https://wa.me/${contact.mobile}");
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 24),
                                  InkWell(
                                    onTap: _makeCall,
                                    child: Container(
                                      width: 64.0,
                                      height: 64.0,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(9999.0),
                                        shape: BoxShape.rectangle,
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Icon(
                                        Icons.call_rounded,
                                        color: FlutterFlowTheme.of(context).onPrimary,
                                        size: 28.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline_rounded, size: 28),
                                    onPressed: _loadContactDetails,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _loadingContact
                          ? const Center(child: CircularProgressIndicator())
                          : AccordionItemWidget(
                              title: 'Detailed Profile Information',
                              content: _contactDetails == null
                                  ? 'No detailed profile information.'
                                  : 'Center: ${_contactDetails!.center ?? "N/A"}\n'
                                      'Guide: ${_contactDetails!.folkGuide ?? "N/A"}\n'
                                      'Level: ${_contactDetails!.folkLevel ?? "N/A"}\n'
                                      'Age: ${_contactDetails!.age ?? "N/A"}\n'
                                      'Gender: ${_contactDetails!.gender ?? "N/A"}\n'
                                      'Occupation: ${_contactDetails!.occupation ?? "N/A"}\n'
                                      'Address: ${_contactDetails!.address ?? "N/A"}\n'
                                      'Institution: ${_contactDetails!.academicInstitution ?? "N/A"}',
                              open: true,
                              last: true,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Select Call Outcome',
                            style: FlutterFlowTheme.of(context).titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              _buildOutcomeChip('Answered', CallOutcome.ANSWERED),
                              _buildOutcomeChip('Busy', CallOutcome.BUSY),
                              _buildOutcomeChip('No Response', CallOutcome.NO_RESPONSE),
                              _buildOutcomeChip('Switched Off', CallOutcome.SWITCHED_OFF),
                              _buildOutcomeChip('Not Reachable', CallOutcome.NOT_REACHABLE),
                              _buildOutcomeChip('Wrong Number', CallOutcome.WRONG_NUMBER),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Update Follow-up Status',
                            style: FlutterFlowTheme.of(context).titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              _buildStatusChip('Contacted', FollowUpStatus.CONTACTED),
                              _buildStatusChip('Interested', FollowUpStatus.INTERESTED),
                              _buildStatusChip('Joined', FollowUpStatus.JOINED),
                              _buildStatusChip('Pending', FollowUpStatus.PENDING),
                              _buildStatusChip('Dormant', FollowUpStatus.DORMANT),
                              _buildStatusChip('Not Interested', FollowUpStatus.NOT_INTERESTED),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          wrapWithModel(
                            model: _model.textFieldModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: TextFieldWidget(
                              label: 'Follow-up Notes',
                              labelPresent: true,
                              hint: 'Type here...',
                              value: _notesController.text,
                            ),
                          ),
                          wrapWithModel(
                            model: _model.textFieldModel2,
                            updateCallback: () => safeSetState(() {}),
                            child: TextFieldWidget(
                              label: 'Next Call Date',
                              labelPresent: true,
                              hint: 'YYYY-MM-DD',
                              value: _nextCallController.text,
                              trailingIcon: Icon(
                                Icons.calendar_today_rounded,
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                              trailingIconPresent: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                shape: BoxShape.rectangle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: InkWell(
                  onTap: _saveAndGoBack,
                  child: wrapWithModel(
                    model: _model.buttonModel,
                    updateCallback: () => safeSetState(() {}),
                    child: ButtonWidget(
                      iconPresent: false,
                      iconEndPresent: false,
                      content: 'SAVE & COMPLETE',
                      variant: 'primary',
                      size: 'large',
                      fullWidth: true,
                      loading: _saving,
                      disabled: _saving,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
