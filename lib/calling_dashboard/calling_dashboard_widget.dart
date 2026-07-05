import '/components/accordion_item_widget.dart';
import '/components/button_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:f_o_l_k_auto_dialer/models/enums.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'calling_dashboard_model.dart';

export 'calling_dashboard_model.dart';

class CallingDashboardWidget extends StatefulWidget {
  const CallingDashboardWidget({super.key});

  static String routeName = 'CallingDashboard';
  static String routePath = '/callingDashboard';

  static Map<String, dynamic>? currentAssignment;
  static VoidCallback? onAssignmentUpdated;

  @override
  State<CallingDashboardWidget> createState() => _CallingDashboardWidgetState();
}

class _CallingDashboardWidgetState extends State<CallingDashboardWidget> {
  late CallingDashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _contactDetails;
  bool _loadingContact = true;
  bool _saving = false;

  FollowUpStatus _selectedStatus = FollowUpStatus.INTERESTED;
  CallOutcome _selectedOutcome = CallOutcome.ANSWERED;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nextCallController = TextEditingController();

  bool _loadingSurvey = false;
  List<dynamic> _surveyQuestions = [];
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
      _loadSurveyQuestions(assignment['event']['id']);
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
      final res = await Supabase.instance.client.from('contact').select().eq('id', assignment['contact']['id']).single();
      setState(() {
        _contactDetails = res;
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
      final res = await Supabase.instance.client.from('survey_question').select().eq('event_id', eventId);
      setState(() {
        _surveyQuestions = List<Map<String, dynamic>>.from(res);
      });
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

    var phone = assignment['contact']['mobile'].replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Normalize format to +91xxxxxxxxxx
    if (phone.startsWith('+91')) {
      // Already correct format
    } else if (phone.startsWith('91') && phone.length == 12) {
      phone = '+$phone';
    } else if (phone.startsWith('+')) {
      // Starts with + but not +91 (or some other format), keep as is
    } else if (phone.length == 10) {
      phone = '+91$phone';
    }
    
    try {
      final url = Uri(scheme: 'tel', path: phone);
      debugPrint("CallingDashboardWidget: Launching default dialer for $phone");
      await launchUrl(url);
    } catch (e) {
      debugPrint("Error launching dialer: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer for $phone')),
        );
      }
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

      final res = await Supabase.instance.client.from('call_log').insert({
        'assignment_id': assignment['id'],
        'contact_id': assignment['contact']['id'],
        'enabler_id': user.id,
        'event_id': assignment['event_id'] ?? assignment['event']?['id'],
        'call_outcome': _selectedOutcome.name,
        'follow_up_status': _selectedStatus.name,
        'follow_up_notes': _notesController.text.trim(),
        'next_call_date': nextCallDate?.toIso8601String(),
      }).select().single();

      final callLogId = res['id'];

      for (final question in _surveyQuestions) {
        final answer = _surveyAnswers[(question is Map) ? question['id'] : question.id] ?? "";
        if (answer.isNotEmpty) {
          await Supabase.instance.client.from('survey_response').insert({
            'call_log_id': callLogId,
            'question_id': (question is Map) ? question['id'] : question.id,
            'answer': answer,
          });
        }
      }

      // 2. Mark assignment complete
      await Supabase.instance.client.from('assignment').update({
        'status': 'COMPLETED',
      }).eq('id', assignment['id']);

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

    final contact = assignment['contact'];

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
                                  contact['name'],
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
                                  contact['mobile'],
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
                                      'FOLK ID: ${contact['folk_id'] ?? "N/A"}',
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
                                            "https://wa.me/${contact['mobile']}");
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
                                    : 'Center: ${_contactDetails!['center'] ?? "N/A"}\n'
                                        'Guide: ${_contactDetails!['folk_guide'] ?? "N/A"}\n'
                                        'Level: ${_contactDetails!['folk_level'] ?? "N/A"}\n'
                                        'Age: ${_contactDetails!['age'] ?? "N/A"}\n'
                                        'Gender: ${_contactDetails!['gender'] ?? "N/A"}\n'
                                        'Occupation: ${_contactDetails!['occupation'] ?? "N/A"}\n'
                                        'Address: ${_contactDetails!['address'] ?? "N/A"}\n'
                                        'Institution: ${_contactDetails!['academic_institution'] ?? "N/A"}',
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
                              initialValue: _selectedOutcome,
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
                              initialValue: _selectedStatus,
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
                                      final qId = (question is Map) ? question['id'] : question.id;
                                      final qTitle = (question is Map) ? (question['question_title'] ?? '') : question.questionTitle;
                                      final qType = (question is Map) ? (question['question_type'] ?? 'TEXT') : (question.questionType ?? 'TEXT');
                                      final qOptions = (question is Map) ? (question['options'] ?? '') : (question.options ?? '');
                                      final qRequired = (question is Map) ? (question['is_required'] ?? false) : (question.isRequired ?? false);

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              qTitle +
                                                  (qRequired
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
                                                initialValue:
                                                    _surveyAnswers[qId],
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
                                                      _surveyAnswers[qId] = val;
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
                                                    groupValue: _surveyAnswers[qId],
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() {
                                                          _surveyAnswers[qId] = val;
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
                                                    _surveyAnswers[qId]
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
                                                          _surveyAnswers[qId] =
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
                                                      _surveyAnswers[qId] =
                                                          picked
                                                              .toString()
                                                              .substring(0, 10);
                                                    });
                                                  }
                                                },
                                                child: IgnorePointer(
                                                  child: TextFormField(
                                                    key: ValueKey(
                                                        _surveyAnswers[qId] ??
                                                            ''),
                                                    initialValue:
                                                        _surveyAnswers[qId],
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
                                                    _surveyAnswers[qId],
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
                                                  _surveyAnswers[qId] = val;
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
