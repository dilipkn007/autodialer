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
  static VoidCallback? onAssignmentUpdated;

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

  bool _loadingSurvey = false;
  List<GetEventWithSurveyEventSurveyQuestionsOnEvent> _surveyQuestions = [];
  Map<String, String> _surveyAnswers = {};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CallingDashboardModel());

    _notesController.text =
        "Interested in attending weekend programs and activities.";
    _nextCallController.text =
        DateTime.now().add(const Duration(days: 7)).toString().substring(0, 10);

    _model.textFieldModel1.inputTextController = _notesController;
    _model.textFieldModel2.inputTextController = _nextCallController;

    _loadContactDetails();

    final assignment = CallingDashboardWidget.currentAssignment;
    if (assignment != null) {
      _loadSurveyQuestions(assignment.event.id);
    }
  }

  @override
  void dispose() {
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
      final res = await DefaultConnector.instance
          .getContactDetails(id: assignment.contact.id)
          .execute();
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

  Future<void> _loadSurveyQuestions(String eventId) async {
    setState(() {
      _loadingSurvey = true;
      _surveyQuestions = [];
      _surveyAnswers = {};
    });
    try {
      final res = await DefaultConnector.instance
          .getEventWithSurvey(eventId: eventId)
          .execute();
      if (res.data.event != null) {
        setState(() {
          _surveyQuestions = res.data.event!.surveyQuestions_on_event;
        });
      }
    } catch (e) {
      debugPrint("Error loading survey questions: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingSurvey = false;
        });
      }
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

      final res = await DefaultConnector.instance
          .recordCallLog(
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

      final callLogId = res.data.callLog_insert.id;

      for (final question in _surveyQuestions) {
        final answer = _surveyAnswers[question.id] ?? "";
        if (answer.isNotEmpty) {
          await DefaultConnector.instance
              .recordSurveyResponse(
                callLogId: callLogId,
                questionId: question.id,
                answer: answer,
              )
              .execute();
        }
      }

      // 2. Mark assignment complete
      await DefaultConnector.instance
          .updateAssignmentStatus(
            id: assignment.id,
            status: AssignmentStatus.COMPLETED,
          )
          .execute();

      if (CallingDashboardWidget.onAssignmentUpdated != null) {
        CallingDashboardWidget.onAssignmentUpdated!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response logged successfully!')),
      );

      context.safePop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save log: $e'),
            backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final assignment = CallingDashboardWidget.currentAssignment;
    if (assignment == null) {
      return const Scaffold(
          body: Center(child: Text('No active assignment loaded.')));
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          24.0, 16.0, 24.0, 16.0),
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
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
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
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            lineHeight: 1.2,
                                          ),
                                    ),
                                    Text(
                                      'Call Session Active',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.inter(),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
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
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
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
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        lineHeight: 1.2,
                                      ),
                                ),
                                Text(
                                  contact.mobile,
                                  style: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.outfit(),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText70,
                                        lineHeight: 1.4,
                                      ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        FlutterFlowTheme.of(context).primary10,
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
                                            color: FlutterFlowTheme.of(context)
                                                .onBackground,
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
                                      icon: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 28),
                                      onPressed: () async {
                                        final url = Uri.parse(
                                            "https://wa.me/${contact.mobile}");
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
                                          borderRadius:
                                              BorderRadius.circular(9999.0),
                                          shape: BoxShape.rectangle,
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.call_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .onPrimary,
                                          size: 28.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.info_outline_rounded,
                                          size: 28),
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
                            DropdownButtonFormField<CallOutcome>(
                              value: _selectedOutcome,
                              decoration: InputDecoration(
                                fillColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      width: 1.5),
                                ),
                              ),
                              dropdownColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText),
                              items: const [
                                DropdownMenuItem(
                                    value: CallOutcome.ANSWERED,
                                    child: Text('Answered')),
                                DropdownMenuItem(
                                    value: CallOutcome.BUSY,
                                    child: Text('Busy')),
                                DropdownMenuItem(
                                    value: CallOutcome.NO_RESPONSE,
                                    child: Text('No Response')),
                                DropdownMenuItem(
                                    value: CallOutcome.SWITCHED_OFF,
                                    child: Text('Switched Off')),
                                DropdownMenuItem(
                                    value: CallOutcome.NOT_REACHABLE,
                                    child: Text('Not Reachable')),
                                DropdownMenuItem(
                                    value: CallOutcome.WRONG_NUMBER,
                                    child: Text('Wrong Number')),
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedOutcome = val);
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Update Follow-up Status',
                              style: FlutterFlowTheme.of(context).titleSmall,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<FollowUpStatus>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                fillColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      width: 1.5),
                                ),
                              ),
                              dropdownColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText),
                              items: const [
                                DropdownMenuItem(
                                    value: FollowUpStatus.CONTACTED,
                                    child: Text('Contacted')),
                                DropdownMenuItem(
                                    value: FollowUpStatus.INTERESTED,
                                    child: Text('Interested')),
                                DropdownMenuItem(
                                    value: FollowUpStatus.JOINED,
                                    child: Text('Joined')),
                                DropdownMenuItem(
                                    value: FollowUpStatus.PENDING,
                                    child: Text('Pending')),
                                DropdownMenuItem(
                                    value: FollowUpStatus.DORMANT,
                                    child: Text('Dormant')),
                                DropdownMenuItem(
                                    value: FollowUpStatus.NOT_INTERESTED,
                                    child: Text('Not Interested')),
                                DropdownMenuItem(
                                    value: FollowUpStatus.NEW,
                                    child: Text('New')),
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedStatus = val);
                              },
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
                                leadingIconPresent: false,
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
                                leadingIconPresent: false,
                                hint: 'YYYY-MM-DD',
                                value: _nextCallController.text,
                                trailingIcon: Icon(
                                  Icons.calendar_today_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                                trailingIconPresent: true,
                              ),
                            ),
                            if (_loadingSurvey)
                              const Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            else if (_surveyQuestions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 24.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Campaign Survey Questions',
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 16.0),
                                    ..._surveyQuestions.map((question) {
                                      final qTitle = question.questionTitle;
                                      final qType = question.questionType
                                              is Known<QuestionType>
                                          ? (question.questionType
                                                  as Known<QuestionType>)
                                              .value
                                          : QuestionType.TEXT;
                                      final qOptions = question.options ?? "";

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              qTitle +
                                                  (question.isRequired
                                                      ? " *"
                                                      : ""),
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                  ),
                                            ),
                                            const SizedBox(height: 8.0),
                                            if (qType ==
                                                    QuestionType.DROPDOWN &&
                                                qOptions.isNotEmpty)
                                              DropdownButtonFormField<String>(
                                                value:
                                                    _surveyAnswers[question.id],
                                                decoration: InputDecoration(
                                                  fillColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondaryBackground,
                                                  filled: true,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    borderSide: BorderSide(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .alternate),
                                                  ),
                                                ),
                                                dropdownColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium,
                                                hint: const Text(
                                                    'Select an option'),
                                                items: qOptions
                                                    .split(',')
                                                    .map((opt) => opt.trim())
                                                    .map((opt) =>
                                                        DropdownMenuItem(
                                                          value: opt,
                                                          child: Text(opt),
                                                        ))
                                                    .toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(() {
                                                      _surveyAnswers[
                                                          question.id] = val;
                                                    });
                                                  }
                                                },
                                              )
                                            else if (qType ==
                                                    QuestionType.RADIO &&
                                                qOptions.isNotEmpty)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: qOptions
                                                    .split(',')
                                                    .map((opt) => opt.trim())
                                                    .where(
                                                        (opt) => opt.isNotEmpty)
                                                    .map((opt) {
                                                  return RadioListTile<String>(
                                                    title: Text(opt,
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium),
                                                    value: opt,
                                                    groupValue: _surveyAnswers[
                                                        question.id],
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() {
                                                          _surveyAnswers[
                                                                  question.id] =
                                                              val;
                                                        });
                                                      }
                                                    },
                                                    activeColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    dense: true,
                                                  );
                                                }).toList(),
                                              )
                                            else if (qType ==
                                                    QuestionType.MULTI_SELECT &&
                                                qOptions.isNotEmpty)
                                              Builder(builder: (context) {
                                                final selectedList =
                                                    _surveyAnswers[question.id]
                                                            ?.split(',')
                                                            .map(
                                                                (s) => s.trim())
                                                            .where((s) =>
                                                                s.isNotEmpty)
                                                            .toList() ??
                                                        [];
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: qOptions
                                                      .split(',')
                                                      .map((opt) => opt.trim())
                                                      .where((opt) =>
                                                          opt.isNotEmpty)
                                                      .map((opt) {
                                                    final isChecked =
                                                        selectedList
                                                            .contains(opt);
                                                    return CheckboxListTile(
                                                      title: Text(opt,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium),
                                                      value: isChecked,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          if (val == true) {
                                                            if (!selectedList
                                                                .contains(
                                                                    opt)) {
                                                              selectedList
                                                                  .add(opt);
                                                            }
                                                          } else {
                                                            selectedList
                                                                .remove(opt);
                                                          }
                                                          _surveyAnswers[
                                                                  question.id] =
                                                              selectedList
                                                                  .join(', ');
                                                        });
                                                      },
                                                      activeColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      dense: true,
                                                      controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                    );
                                                  }).toList(),
                                                );
                                              })
                                            else if (qType == QuestionType.DATE)
                                              InkWell(
                                                onTap: () async {
                                                  final picked =
                                                      await showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now(),
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  );
                                                  if (picked != null) {
                                                    setState(() {
                                                      _surveyAnswers[
                                                              question.id] =
                                                          picked
                                                              .toString()
                                                              .substring(0, 10);
                                                    });
                                                  }
                                                },
                                                child: IgnorePointer(
                                                  child: TextFormField(
                                                    key: ValueKey(
                                                        _surveyAnswers[
                                                                question.id] ??
                                                            ''),
                                                    initialValue:
                                                        _surveyAnswers[
                                                            question.id],
                                                    decoration: InputDecoration(
                                                      hintText: 'Select Date',
                                                      fillColor: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      filled: true,
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        borderSide: BorderSide(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .alternate),
                                                      ),
                                                      suffixIcon: Icon(
                                                          Icons.calendar_today,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText),
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium,
                                                  ),
                                                ),
                                              )
                                            else
                                              TextFormField(
                                                initialValue:
                                                    _surveyAnswers[question.id],
                                                decoration: InputDecoration(
                                                  hintText: 'Enter your answer',
                                                  fillColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondaryBackground,
                                                  filled: true,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    borderSide: BorderSide(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .alternate),
                                                  ),
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium,
                                                maxLines: null,
                                                onChanged: (val) {
                                                  _surveyAnswers[question.id] =
                                                      val;
                                                },
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
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
      ),
    );
  }
}
