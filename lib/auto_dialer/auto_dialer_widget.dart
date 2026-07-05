import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:f_o_l_k_auto_dialer/models/enums.dart';
import 'package:f_o_l_k_auto_dialer/services/overlay_bridge.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/components/control_btn3b28c09c_widget.dart';
import '/components/form_label_c3deb8f0_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/survey_state_file.dart';
import 'auto_dialer_model.dart';

export 'auto_dialer_model.dart';

class AutoDialerWidget extends StatefulWidget {
  const AutoDialerWidget({super.key});

  static String routeName = 'AutoDialer';
  static String routePath = '/autoDialer';

  static List<Map<String, dynamic>> pendingAssignments = [];
  static VoidCallback? onAssignmentsUpdated;

  @override
  State<AutoDialerWidget> createState() => _AutoDialerWidgetState();
}

class _AutoDialerWidgetState extends State<AutoDialerWidget>
    with WidgetsBindingObserver {
  late AutoDialerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;
  List<dynamic> _surveyQuestions = [];
  Map<String, String> _surveyAnswers = {};
  bool _loadingSurvey = false;
  int _gapDuration = 20;
  int _secondsRemaining = 20;
  bool _timerRunning = false;
  Timer? _countdownTimer;
  bool _isCallStateActive = false;
  String? _loadedSurveyEventId;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nextCallController = TextEditingController();

  CallOutcome _selectedOutcome = CallOutcome.ANSWERED;
  FollowUpStatus _selectedStatus = FollowUpStatus.NEW;

  bool _overlayAvailable = false;
  bool _overlayActive = false;
  bool _paused = false;
  bool _savedCurrentCall = false;
  bool _isFirstCall = true;
  bool _submittingOverlay = false;
  StreamSubscription? _overlaySubscription;
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  bool _phoneCallObserved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model = createModel(context, () => AutoDialerModel());

    _nextCallController.text =
        DateTime.now().add(const Duration(days: 7)).toString().substring(0, 10);
    _model.textFieldModel.inputTextController ??= _nextCallController;

    debugPrint("AutoDialerWidget: initState. pendingAssignments length = ${AutoDialerWidget.pendingAssignments.length}");

    _loadSurveyQuestionsForCurrentEvent();

    _initPhoneStateListener();

    // Run overlay initialization, but guarantee _makeCall gets executed regardless of success/error/hang.
    Future.any([
      _initOverlay(),
      Future.delayed(const Duration(milliseconds: 1500)), // fallback timeout so we don't hang
    ]).catchError((e) {
      debugPrint("AutoDialerWidget: Error initializing overlay: $e");
    }).whenComplete(() {
      debugPrint("AutoDialerWidget: initOverlay complete. mounted = $mounted, pendingAssignments length = ${AutoDialerWidget.pendingAssignments.length}");
      if (mounted && AutoDialerWidget.pendingAssignments.isNotEmpty) {
        _startTimer();
      }
    });
  }

  Future<void> _initOverlay() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      bool granted = await OverlayBridge.instance.isPermissionGranted;
      if (!granted) {
        granted = await OverlayBridge.instance.requestPermission();
      }
      if (granted) {
        _overlayAvailable = true;
        _overlaySubscription = OverlayBridge.instance.onSurveyResult.listen(
          _handleOverlayResult,
          onError: (e) => debugPrint("Overlay listener error: $e"),
        );
      }
    }
  }

  Future<void> _initPhoneStateListener() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final permission = await Permission.phone.request();
    if (!permission.isGranted) {
      debugPrint('Phone-state permission denied; using app lifecycle fallback.');
      return;
    }

    _phoneStateSubscription ??= PhoneState.stream.listen(
      (state) {
        if (state.status == PhoneStateStatus.CALL_STARTED) {
          _phoneCallObserved = true;
          return;
        }

        if (state.status == PhoneStateStatus.CALL_ENDED &&
            _phoneCallObserved) {
          _phoneCallObserved = false;
          _handleCallDisconnected();
        }
      },
      onError: (error) => debugPrint('Phone-state listener error: $error'),
    );
  }

  void _handleOverlayResult(Map<String, dynamic> data) {
    debugPrint("_handleOverlayResult: RECEIVED type=${data['type']} data=$data");
    if (data['type'] == 'overlay_ready') {
      debugPrint("_handleOverlayResult: overlay_ready => pushing survey");
      _pushSurveyToOverlay();
      return;
    }
    if (data['type'] == 'survey_update') {
      if (mounted) {
        setState(() {
          _surveyAnswers = (data['surveyAnswers'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v.toString()));
          _selectedOutcome = _mapStringToCallOutcome(data['callOutcome'] as String? ?? 'ANSWERED');
          _selectedStatus = _mapStringToFollowUpStatus(data['followUpStatus'] as String? ?? 'NEW');
          _notesController.text = data['followUpNotes'] as String? ?? '';
          _nextCallController.text = data['nextCallDate'] as String? ?? _nextCallController.text;
        });
        debugPrint("_handleOverlayResult: survey_update applied");
      }
      return;
    }
    if (data['type'] == 'survey_submit') {
      debugPrint("_handleOverlayResult: survey_submit received, calling _submitCurrentCall");
      if (mounted) {
        setState(() {
          _surveyAnswers = (data['surveyAnswers'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v.toString()));
          _selectedOutcome = _mapStringToCallOutcome(data['callOutcome'] as String? ?? 'ANSWERED');
          _selectedStatus = _mapStringToFollowUpStatus(data['followUpStatus'] as String? ?? 'NEW');
          _notesController.text = data['followUpNotes'] as String? ?? '';
          _nextCallController.text = data['nextCallDate'] as String? ?? _nextCallController.text;
        });
        _submitCurrentCall();
      }
      return;
    }
    if (data['type'] == 'overlay_closed') {
      if (mounted) {
        setState(() {
          _overlayActive = false;
        });
      }
      return;
    }
    debugPrint("_handleOverlayResult: UNKNOWN type=${data['type']}");
  }

  Future<void> _submitCurrentCall() async {
    debugPrint("_submitCurrentCall: entered, _submittingOverlay=$_submittingOverlay");
    if (_submittingOverlay) return;
    _submittingOverlay = true;
    debugPrint("_submitCurrentCall: calling _saveCurrentCall...");

    try {
      final saved = await _saveCurrentCall();
      debugPrint("_submitCurrentCall: _saveCurrentCall returned saved=$saved");
      if (!mounted) return;

      if (!saved) {
        debugPrint("_submitCurrentCall: save returned false, notifying overlay");
        await OverlayBridge.instance.notifySaveFailed(
          'Could not save the response. Please try again.',
        );
        return;
      }

      setState(() => _savedCurrentCall = true);
      debugPrint("_submitCurrentCall: save succeeded via Save to Dialer");
      debugPrint("  outcome=${_selectedOutcome.name} status=${_selectedStatus.name} notes=${_notesController.text}");
      if (_overlayActive) {
        await OverlayBridge.instance.closeOverlay();
        if (mounted) {
          setState(() => _overlayActive = false);
        }
      }
      debugPrint("_submitCurrentCall: done");
    } catch (e) {
      debugPrint("_submitCurrentCall: save failed with exception: $e");
      debugPrint("_submitCurrentCall: stack trace: ${StackTrace.current}");
      await OverlayBridge.instance.notifySaveFailed(
        'Could not save the response. Please try again.',
      );
    } finally {
      _submittingOverlay = false;
      debugPrint("_submitCurrentCall: finally, _submittingOverlay reset to false");
    }
  }

  Future<void> _onGapEnd() async {
    debugPrint("_onGapEnd: entered. _paused=$_paused _savedCurrentCall=$_savedCurrentCall _currentIndex=$_currentIndex listLen=${AutoDialerWidget.pendingAssignments.length}");
    if (_paused) return;
    if (_savedCurrentCall) {
      debugPrint("_onGapEnd: _savedCurrentCall is true, resetting and skipping save");
      _savedCurrentCall = false;
    } else {
      debugPrint("_onGapEnd: saving current call");
      final saved = await _saveCurrentCall();
      if (!saved) {
        if (mounted) {
          setState(() => _paused = true);
        }
        return;
      }
    }
    if (_currentIndex + 1 >= AutoDialerWidget.pendingAssignments.length) {
      debugPrint("_onGapEnd: at end of list, showing completed");
      if (_overlayActive) {
        await OverlayBridge.instance.closeOverlay();
        setState(() => _overlayActive = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auto Dialer session completed!')),
      );
      Navigator.of(context).pop();
      return;
    }
    debugPrint("_onGapEnd: advancing to next call");
    await _advanceToNext();
  }

  Future<bool> _saveCurrentCall() async {
    final assignment = AutoDialerWidget.pendingAssignments[_currentIndex];
    debugPrint("_saveCurrentCall: assignment keys=${assignment.keys}");
    debugPrint("_saveCurrentCall: enabler_id=${assignment['enabler_id']} contact=${assignment['contact']?['id']} event_id=${assignment['event_id']} event?.id=${assignment['event']?['id']}");

    // Read overlay state from shared file (written by overlay widget)
    try {
      final overlayState = await SurveyStateFile.instance.read();
      if (overlayState != null) {
        debugPrint("_saveCurrentCall: applying overlay state from file: ${overlayState['callOutcome']} / ${overlayState['followUpStatus']} / ${overlayState['followUpNotes']}");
        setState(() {
          _selectedOutcome = _mapStringToCallOutcome(overlayState['callOutcome'] as String? ?? 'ANSWERED');
          _selectedStatus = _mapStringToFollowUpStatus(overlayState['followUpStatus'] as String? ?? 'NEW');
          _notesController.text = overlayState['followUpNotes'] as String? ?? '';
          _nextCallController.text = overlayState['nextCallDate'] as String? ?? _nextCallController.text;
          final answers = overlayState['surveyAnswers'] as Map<String, dynamic>?;
          if (answers != null) {
            _surveyAnswers = answers.map((k, v) => MapEntry(k, v.toString()));
          }
        });
        await SurveyStateFile.instance.clear();
        debugPrint("_saveCurrentCall: applied overlay state and cleared file");
      } else {
        debugPrint("_saveCurrentCall: no overlay state file found, using local state");
      }
    } catch (e) {
      debugPrint("_saveCurrentCall: error reading overlay state: $e");
    }

    debugPrint("_saveCurrentCall: outcome=${_selectedOutcome.name} status=${_selectedStatus.name} notes=${_notesController.text.trim()}");
    try {
      final dateStr = _nextCallController.text.trim();
      DateTime? nextCallDate;
      try { nextCallDate = DateTime.parse(dateStr); } catch (_) {}
      final enablerId = assignment['enabler_id'] as String? ?? '';
      if (enablerId.isEmpty) {
        debugPrint("_saveCurrentCall: ERROR - missing enabler_id in assignment");
        return false;
      }
      debugPrint("_saveCurrentCall: inserting into call_log...");
      final res = await Supabase.instance.client
          .from('call_log')
          .insert({
            'assignment_id': assignment['id'],
            'contact_id': assignment['contact']['id'],
            'enabler_id': enablerId,
            'event_id': assignment['event_id'] ?? assignment['event']?['id'],
            'call_outcome': _selectedOutcome.name,
            'follow_up_status': _selectedStatus.name,
            'follow_up_notes': _notesController.text.trim(),
            'next_call_date': nextCallDate?.toIso8601String(),
          })
          .select()
          .single();
      final callLogId = res['id'];
      debugPrint("_saveCurrentCall: call_log inserted, id=$callLogId, now inserting survey_responses...");
      int insertedCount = 0;
      for (final question in _surveyQuestions) {
        final answer =
            _surveyAnswers[(question is Map) ? question['id'] : question.id] ?? '';
        if (answer.isNotEmpty) {
          await Supabase.instance.client.from('survey_response').insert({
            'call_log_id': callLogId,
            'question_id': (question is Map) ? question['id'] : question.id,
            'answer': answer,
          });
          insertedCount++;
        }
      }
      debugPrint("_saveCurrentCall: inserted $insertedCount survey_responses");
      debugPrint("_saveCurrentCall: updating assignment status to COMPLETED...");
      await Supabase.instance.client.from('assignment').update({
        'status': 'COMPLETED',
      }).eq('id', assignment['id']);
      if (AutoDialerWidget.onAssignmentsUpdated != null) {
        AutoDialerWidget.onAssignmentsUpdated!();
      }
      debugPrint("_saveCurrentCall: SAVED call_log id=$callLogId for contact=${assignment['contact']?['name']}");
      return true;
    } catch (e) {
      debugPrint("_saveCurrentCall: ERROR: $e");
      debugPrint("_saveCurrentCall: stack trace: ${StackTrace.current}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save call response: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _advanceToNext() async {
    debugPrint("_advanceToNext: entering. currentIndex=$_currentIndex listLen=${AutoDialerWidget.pendingAssignments.length}");
    final nextAssignment =
        AutoDialerWidget.pendingAssignments[_currentIndex + 1];
    final currentEventId =
        AutoDialerWidget.pendingAssignments[_currentIndex]['event']['id'];
    final isEventChange = nextAssignment['event']['id'] != currentEventId;

    setState(() {
      _currentIndex++;
      _notesController.clear();
      _surveyAnswers.clear();
      _nextCallController.text = DateTime.now()
          .add(const Duration(days: 7))
          .toString()
          .substring(0, 10);
      _selectedOutcome = CallOutcome.ANSWERED;
      _selectedStatus = FollowUpStatus.NEW;
      _secondsRemaining = _gapDuration;
    });
    debugPrint("_advanceToNext: new _currentIndex=$_currentIndex isEventChange=$isEventChange");

    if (_loadedSurveyEventId != nextAssignment['event']['id']) {
      debugPrint("_advanceToNext: loading survey for new event ${nextAssignment['event']['id']}");
      await _loadSurveyQuestions(nextAssignment['event']['id']);
    }
    if (isEventChange) {
      _showEventChangeDialog(
        newEventName: nextAssignment['event']['name'],
        newEventDate: nextAssignment['event']['event_date'],
      );
    }
    debugPrint("_advanceToNext: calling _makeCall");
    await _makeCall();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlaySubscription?.cancel();
    _phoneStateSubscription?.cancel();
    OverlayBridge.instance.closeOverlay();
    _countdownTimer?.cancel();
    _notesController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleCallDisconnected();
    }
  }

  Future<void> _handleCallDisconnected() async {
    if (!_isCallStateActive) return;

    debugPrint('Call disconnected; closing the survey overlay.');
    _isCallStateActive = false;
    _phoneCallObserved = false;
    await OverlayBridge.instance.closeOverlay();
    if (!mounted) return;

    setState(() {
      _overlayActive = false;
      _secondsRemaining = _gapDuration;
    });
    _startTimer();
  }

  void _loadSurveyQuestionsForCurrentEvent() {
    if (AutoDialerWidget.pendingAssignments.isNotEmpty &&
        _currentIndex < AutoDialerWidget.pendingAssignments.length) {
      final eventId =
          AutoDialerWidget.pendingAssignments[_currentIndex]['event']['id'];
      _loadSurveyQuestions(eventId);
    }
  }

  Future<void> _loadSurveyQuestions(String eventId) async {
    setState(() {
      _loadingSurvey = true;
      _surveyQuestions = [];
      _surveyAnswers = {};
      _loadedSurveyEventId = eventId;
    });
    try {
      final questionsRes = await Supabase.instance.client
          .from('survey_question')
          .select()
          .eq('event_id', eventId);
      final eventRes = await Supabase.instance.client
          .from('event')
          .select('gap_duration')
          .eq('id', eventId)
          .single();
      if (mounted) {
        setState(() {
          _surveyQuestions = questionsRes
              .map((q) => q as Map<String, dynamic>)
              .toList();
          final gap = eventRes?['gap_duration'] as int?;
          if (gap != null) {
            _gapDuration = gap.clamp(5, 300);
            _secondsRemaining = _gapDuration;
          }
        });
        debugPrint("_loadSurveyQuestions: loaded ${_surveyQuestions.length} questions for event $eventId, gap=$_gapDuration");
        if (_overlayAvailable && _overlayActive) {
          _pushSurveyToOverlay();
        }
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

  Future<void> _pushSurveyToOverlay() async {
    if (!_overlayAvailable || !_overlayActive) return;
    try {
      final assignment = AutoDialerWidget.pendingAssignments[_currentIndex];
      final contact = assignment['contact'];
      await OverlayBridge.instance.updateSurveyData(
        contactName: contact['name'] as String? ?? '',
        contactPhone: contact['mobile'] as String? ?? '',
        surveyQuestions: _surveyQuestions.cast<Map<String, dynamic>>(),
        currentAnswers: _surveyAnswers,
      );
    } catch (e) {
      debugPrint("Error pushing survey to overlay: $e");
    }
  }

  Future<void> _showOverlay() async {
    if (!_overlayAvailable) return;
    if (!mounted) return;
    debugPrint("_showOverlay: starting, _overlayActive set to true");
    try {
      final assignment = AutoDialerWidget.pendingAssignments[_currentIndex];
      final contact = assignment['contact'];
      setState(() => _overlayActive = true);
      await OverlayBridge.instance.showSurveyOverlay(
        contactName: contact['name'] as String? ?? '',
        contactPhone: contact['mobile'] as String? ?? '',
        surveyQuestions: _surveyQuestions.cast<Map<String, dynamic>>(),
        currentAnswers: _surveyAnswers,
        timeout: const Duration(seconds: 10),
      );
      debugPrint("_showOverlay: completed successfully");
    } catch (e) {
      debugPrint("_showOverlay: error: $e");
    }
  }

  Future<void> _makeCall() async {
    debugPrint("AutoDialerWidget: _makeCall entered. _currentIndex = $_currentIndex, pendingAssignments count = ${AutoDialerWidget.pendingAssignments.length}");
    if (AutoDialerWidget.pendingAssignments.isEmpty ||
        _currentIndex >= AutoDialerWidget.pendingAssignments.length) {
      debugPrint("AutoDialerWidget: _makeCall early return. pendingAssignments is empty or _currentIndex out of bounds.");
      return;
    }

    _countdownTimer?.cancel();
    setState(() {
      _timerRunning = false;
      _isCallStateActive = true;
      _phoneCallObserved = false;
    });

    if (_overlayAvailable) {
      debugPrint("_makeCall: overlay available, _overlayActive=$_overlayActive");
      if (_overlayActive && await OverlayBridge.instance.isOverlayRunning) {
        debugPrint("_makeCall: overlay already active and running, pushing survey");
        _pushSurveyToOverlay();
      } else {
        debugPrint("_makeCall: showing new overlay (fire-and-forget, no short-circuit)");
        _showOverlay();
      }
      debugPrint("_makeCall: waiting 2s for overlay to initialize");
      await Future.delayed(const Duration(seconds: 2));
    } else {
      debugPrint("_makeCall: overlay not available, proceeding without overlay");
    }

    final contactName = AutoDialerWidget.pendingAssignments[_currentIndex]['contact']?['name'];
    debugPrint("AutoDialerWidget: _makeCall dialing: _currentIndex=$_currentIndex contact=$contactName");

    final assignment = AutoDialerWidget.pendingAssignments[_currentIndex];
    final rawPhone = assignment['contact']?['mobile'] as String? ?? '';
    var phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    
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

    if (phone.isEmpty) {
      debugPrint("_makeCall: empty phone for index $_currentIndex");
      return;
    }

    try {
      debugPrint("AutoDialerWidget: Dialing $phone via direct caller");
      final res = await FlutterPhoneDirectCaller.callNumber(phone);
      if (res == null || !res) {
        debugPrint("AutoDialerWidget: Direct call failed, falling back to launchUrl");
        final url = Uri(scheme: 'tel', path: phone);
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone dialer for $phone.')),
        );
      }
    }
  }

  void _startTimer() {
    if (_paused) return;
    _countdownTimer?.cancel();
    setState(() {
      _timerRunning = true;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _countdownTimer?.cancel();
        setState(() {
          _secondsRemaining = 0;
          _timerRunning = false;
        });
        debugPrint("AutoDialerWidget: timer fired. _isFirstCall=$_isFirstCall _currentIndex=$_currentIndex");
        if (_isFirstCall) {
          debugPrint("AutoDialerWidget: first call timer expiry, calling _makeCall");
          _isFirstCall = false;
          _makeCall();
        } else {
          debugPrint("AutoDialerWidget: subsequent timer expiry, calling _onGapEnd");
          _onGapEnd();
        }
      }
    });
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _timerRunning = false;
      _paused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _paused = false;
    });
    _startTimer();
  }

  void _updateGap(int seconds) {
    setState(() {
      _gapDuration = seconds;
      _secondsRemaining = seconds;
    });
    if (_timerRunning) {
      _startTimer();
    }
  }

  /// Shows a modal alert when the next contact belongs to a different event,
  /// so the enabler is never caught off-guard mid-session.
  Future<void> _showEventChangeDialog({
    required String newEventName,
    required DateTime newEventDate,
  }) async {
    final dateStr =
        '${newEventDate.day} ${_monthName(newEventDate.month)} ${newEventDate.year}';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz_rounded,
                color: FlutterFlowTheme.of(context).primary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Campaign Switch!',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The next contact belongs to a different campaign:',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.inter(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context)
                    .primary
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: FlutterFlowTheme.of(context)
                        .primary
                        .withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign_rounded,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          newEventName,
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                font: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold),
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: FlutterFlowTheme.of(context).secondaryText,
                          size: 14),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap OK to continue with the next call.',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.inter(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK, Got It',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                color: FlutterFlowTheme.of(context).primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  CallOutcome _mapStringToCallOutcome(String value) {
    switch (value.toLowerCase()) {
      case 'answered':
        return CallOutcome.ANSWERED;
      case 'busy':
        return CallOutcome.BUSY;
      case 'no response':
        return CallOutcome.NO_RESPONSE;
      case 'switched off':
        return CallOutcome.SWITCHED_OFF;
      case 'wrong number':
        return CallOutcome.WRONG_NUMBER;
      default:
        return CallOutcome.ANSWERED;
    }
  }

  FollowUpStatus _mapStringToFollowUpStatus(String value) {
    switch (value.toLowerCase()) {
      case 'new':
        return FollowUpStatus.NEW;
      case 'contacted':
        return FollowUpStatus.CONTACTED;
      case 'interested':
        return FollowUpStatus.INTERESTED;
      case 'not interested':
        return FollowUpStatus.NOT_INTERESTED;
      case 'joined':
        return FollowUpStatus.JOINED;
      case 'pending':
        return FollowUpStatus.PENDING;
      case 'dormant':
        return FollowUpStatus.DORMANT;
      default:
        return FollowUpStatus.NEW;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AutoDialerWidget.pendingAssignments.isEmpty) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: const Center(
          child: Text('No pending assignments found.'),
        ),
      );
    }

    final currentAssignment =
        AutoDialerWidget.pendingAssignments[_currentIndex];
    final contact = currentAssignment['contact'];
    final initials = contact['name']
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

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
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          24.0, 16.0, 24.0, 16.0),
                    child: Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                onPressed: () => Navigator.of(context).pop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              Icon(
                                Icons.settings_input_antenna_rounded,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 24.0,
                              ),
                              Text(
                                'AUTO DIALER',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ].divide(const SizedBox(width: 8.0)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).error10,
                              borderRadius: BorderRadius.circular(9999.0),
                              shape: BoxShape.rectangle,
                            ),
                            child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    8.0, 4.0, 8.0, 4.0),
                              child: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8.0,
                                      height: 8.0,
                                      decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          borderRadius:
                                              BorderRadius.circular(9999.0),
                                        shape: BoxShape.rectangle,
                                      ),
                                    ),
                                    Text(
                                        _timerRunning || _isCallStateActive
                                            ? 'SESSION ACTIVE'
                                            : 'SESSION PAUSED',
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontStyle,
                                            ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .onError,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .fontStyle,
                                            lineHeight: 1.2,
                                          ),
                                    ),
                                  ].divide(const SizedBox(width: 4.0)),
                                ),
                              ),
                            ),
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
            // Progress bar
            Container(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 0.0),
              color: FlutterFlowTheme.of(context).secondaryBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Session Progress',
                        style: FlutterFlowTheme.of(context).labelMedium,
                      ),
                      Text(
                        '${_currentIndex + 1} / ${AutoDialerWidget.pendingAssignments.length}',
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                font: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold),
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LinearProgressIndicator(
                        value: (_currentIndex + 1) /
                            AutoDialerWidget.pendingAssignments.length,
                      backgroundColor: FlutterFlowTheme.of(context).alternate,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).primary),
                      minHeight: 8.0,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],
              ),
            ),
            // Event Banner — always visible, updates per contact
            Container(
              width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 10.0),
              decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context)
                      .primary
                      .withValues(alpha: 0.08),
                border: Border(
                    bottom: BorderSide(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withValues(alpha: 0.2),
                        width: 1),
                    top: BorderSide(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withValues(alpha: 0.2),
                        width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAMPAIGN',
                            style: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                            color: FlutterFlowTheme.of(context).primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          currentAssignment['event']['name'],
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${DateTime.parse(currentAssignment['event']['event_date']).day} ${_monthName(DateTime.parse(currentAssignment['event']['event_date']).month)} ${DateTime.parse(currentAssignment['event']['event_date']).year}',
                            style: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600),
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .surfaceVariant30,
                                  borderRadius: BorderRadius.circular(16.0),
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                    width: 1.0,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Container(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                      children: [
                                          InkWell(
                                            onTap: () =>
                                                _showContactDetails(contact),
                                            borderRadius:
                                                BorderRadius.circular(24.0),
                                            child: Container(
                                          width: 48.0,
                                          height: 48.0,
                                          decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                            shape: BoxShape.circle,
                                          ),
                                              alignment:
                                                  const AlignmentDirectional(
                                                      0.0, 0.0),
                                          child: Text(
                                                initials.isNotEmpty
                                                    ? initials
                                                    : 'C',
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                .labelMedium
                                                .override(
                                                  font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                        .labelMedium
                                                        .fontStyle,
                                                  ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .onPrimary,
                                                  fontSize: 18.24,
                                                  letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                      .labelMedium
                                                      .fontStyle,
                                                  lineHeight: 1.3,
                                                ),
                                            overflow: TextOverflow.clip,
                                          ),
                                        ),
                                          ),
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact['name'],
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                    .titleMedium
                                                    .override(
                                                        font:
                                                            GoogleFonts.outfit(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                            .titleMedium
                                                            .fontStyle,
                                                      ),
                                                      letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                          .titleMedium
                                                          .fontStyle,
                                                      lineHeight: 1.4,
                                                    ),
                                              ),
                                              InkWell(
                                                onTap: _makeCall,
                                                child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 4.0),
                                                  child: Text(
                                                    '${contact['folk_id'] ?? 'No ID'} • ${contact['mobile']}',
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                        .bodySmall
                                                        .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                .bodySmall
                                                                .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                .bodySmall
                                                                .fontStyle,
                                                          ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                              .bodySmall
                                                              .fontStyle,
                                                          lineHeight: 1.4,
                                                                decoration:
                                                                    TextDecoration
                                                                        .underline,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .success10,
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            shape: BoxShape.rectangle,
                                          ),
                                          child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      8.0, 4.0, 8.0, 4.0),
                                            child: Container(
                                              child: Text(
                                                'ACTIVE',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                    .labelSmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                            .labelSmall
                                                            .fontStyle,
                                                      ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .onSurface,
                                                      letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                          .labelSmall
                                                          .fontStyle,
                                                      lineHeight: 1.2,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ].divide(const SizedBox(width: 16.0)),
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                    children: [
                                      wrapWithModel(
                                        model: _model.formLabelC3deb8f0Model1,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                        child: const FormLabelC3deb8f0Widget(
                                          label: 'Call Outcome',
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: FlutterFlowDropDown<String>(
                                            controller: _model
                                                    .dropdownValueController1 ??=
                                                FormFieldController<String>(
                                              _model.dropdownValue1 ??=
                                                  'Answered',
                                          ),
                                          options: const [
                                            'Answered',
                                            'Busy',
                                            'No Response',
                                            'Switched Off',
                                            'Wrong Number'
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              safeSetState(() {
                                                _model.dropdownValue1 = val;
                                                  _selectedOutcome =
                                                      _mapStringToCallOutcome(
                                                          val);
                                              });
                                            }
                                          },
                                          width: 200.0,
                                          height: 40.0,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                      .bodyMedium
                                                      .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                      .bodyMedium
                                                      .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                    .bodyMedium
                                                    .fontStyle,
                                                lineHeight: 1.5,
                                              ),
                                          hintText: 'Select outcome',
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                            size: 24.0,
                                          ),
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          elevation: 2.0,
                                            borderColor:
                                                FlutterFlowTheme.of(context)
                                                    .alternate,
                                          borderWidth: 1.0,
                                          borderRadius: 8.0,
                                            margin: const EdgeInsetsDirectional
                                                .fromSTEB(16.0, 0.0, 16.0, 0.0),
                                          hidesUnderline: true,
                                          isOverButton: false,
                                          isSearchable: false,
                                          isMultiSelect: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                    children: [
                                      wrapWithModel(
                                        model: _model.formLabelC3deb8f0Model2,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                        child: const FormLabelC3deb8f0Widget(
                                          label: 'Follow-Up Status',
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: FlutterFlowDropDown<String>(
                                            controller: _model
                                                    .dropdownValueController2 ??=
                                                FormFieldController<String>(
                                            _model.dropdownValue2 ??= 'New',
                                          ),
                                          options: const [
                                            'New',
                                            'Active',
                                            'Pending',
                                            'Contacted',
                                            'Interested',
                                            'Not Interested',
                                            'Joined',
                                            'Dormant'
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              safeSetState(() {
                                                _model.dropdownValue2 = val;
                                                  _selectedStatus =
                                                      _mapStringToFollowUpStatus(
                                                          val);
                                              });
                                            }
                                          },
                                          width: 200.0,
                                          height: 40.0,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                      .bodyMedium
                                                      .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                      .bodyMedium
                                                      .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                    .bodyMedium
                                                    .fontStyle,
                                                lineHeight: 1.5,
                                              ),
                                          hintText: 'Select status',
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                            size: 24.0,
                                          ),
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                          elevation: 2.0,
                                            borderColor:
                                                FlutterFlowTheme.of(context)
                                                    .alternate,
                                          borderWidth: 1.0,
                                          borderRadius: 8.0,
                                            margin: const EdgeInsetsDirectional
                                                .fromSTEB(16.0, 0.0, 16.0, 0.0),
                                          hidesUnderline: true,
                                          isOverButton: false,
                                          isSearchable: false,
                                          isMultiSelect: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                    children: [
                                      wrapWithModel(
                                        model: _model.formLabelC3deb8f0Model3,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                        child: const FormLabelC3deb8f0Widget(
                                          label: 'Next Follow-Up Date',
                                        ),
                                      ),
                                      wrapWithModel(
                                        model: _model.textFieldModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                        child: InkWell(
                                          onTap: () async {
                                              final picked =
                                                  await showDatePicker(
                                              context: context,
                                                initialDate: DateTime.now().add(
                                                    const Duration(days: 7)),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              safeSetState(() {
                                                  _nextCallController.text =
                                                      picked
                                                          .toString()
                                                          .substring(0, 10);
                                              });
                                            }
                                          },
                                          child: IgnorePointer(
                                            child: TextFieldWidget(
                                              label: '',
                                              labelPresent: false,
                                              helper: '',
                                              helperPresent: false,
                                              leadingIconPresent: false,
                                              trailingIcon: Icon(
                                                Icons.calendar_today_rounded,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                size: 24.0,
                                              ),
                                              trailingIconPresent: true,
                                              hint: 'YYYY-MM-DD',
                                              value: _nextCallController.text,
                                              onChange: '',
                                              onSubmit: '',
                                              variant: 'outlined',
                                              error: false,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                    children: [
                                      wrapWithModel(
                                        model: _model.formLabelC3deb8f0Model4,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                        child: const FormLabelC3deb8f0Widget(
                                          label: 'Follow-Up Notes',
                                        ),
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                        child: TextFormField(
                                          controller: _notesController,
                                          decoration: InputDecoration(
                                              hintText:
                                                  'Enter conversation notes...',
                                              fillColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            filled: true,
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .alternate,
                                              ),
                                            ),
                                          ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium,
                                          maxLines: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Dynamic survey questions section
                                  if (_overlayActive)
                                    const Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.touch_app, color: Colors.white54, size: 48),
                                            SizedBox(height: 12),
                                            Text(
                                              'Survey is on the floating overlay.\nCheck your screen edges.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.white54, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else if (_loadingSurvey)
                                    const Padding(
                                      padding: EdgeInsets.all(24.0),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                    )
                                  else if (_surveyQuestions.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(height: 12.0),
                                          Text(
                                            'Campaign Survey Questions',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleSmall
                                                  .override(
                                                    font: GoogleFonts.outfit(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          ..._surveyQuestions.map((question) {
                                              final qId = (question is Map)
                                                  ? question['id']
                                                  : question.id;
                                              final qTitle = (question is Map)
                                                  ? (question[
                                                          'question_title'] ??
                                                      '')
                                                  : (question.questionTitle ??
                                                      '');
                                              final qType = (question is Map)
                                                  ? (question[
                                                          'question_type'] ??
                                                      'TEXT')
                                                  : (question.questionType ??
                                                      'TEXT');
                                              final qOptions = (question is Map)
                                                  ? (question['options'] ?? '')
                                                  : (question.options ?? '');
                                              final qRequired = (question
                                                      is Map)
                                                  ? (question['is_required'] ??
                                                      false)
                                                  : (question.isRequired ??
                                                      false);

                                            return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 16.0),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                children: [
                                                  Text(
                                                      qTitle +
                                                          (qRequired
                                                              ? " *"
                                                              : ""),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font: GoogleFonts.inter(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                    if (qType ==
                                                            QuestionType
                                                                .DROPDOWN &&
                                                        qOptions.isNotEmpty)
                                                      DropdownButtonFormField<
                                                          String>(
                                                        initialValue:
                                                            _surveyAnswers[qId],
                                                        decoration:
                                                            InputDecoration(
                                                          fillColor: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                        filled: true,
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            borderSide: BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate),
                                                          ),
                                                        ),
                                                        dropdownColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryBackground,
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium,
                                                        hint: const Text(
                                                            'Select an option'),
                                                        items: qOptions
                                                            .split(',')
                                                            .map((opt) =>
                                                                opt.trim())
                                                            .map((opt) =>
                                                                DropdownMenuItem(
                                                        value: opt,
                                                                  child:
                                                                      Text(opt),
                                                                ))
                                                            .toList(),
                                                      onChanged: (val) {
                                                        if (val != null) {
                                                          setState(() {
                                                              _surveyAnswers[
                                                                  qId] = val;
                                                          });
                                                        }
                                                      },
                                                    )
                                                    else if (qType ==
                                                            QuestionType
                                                                .RADIO &&
                                                        qOptions.isNotEmpty)
                                                    Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: qOptions
                                                            .split(',')
                                                            .map((opt) =>
                                                                opt.trim())
                                                            .where((opt) =>
                                                                opt.isNotEmpty)
                                                            .map((opt) {
                                                          return RadioListTile<
                                                              String>(
                                                            title: Text(opt,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium),
                                                          value: opt,
                                                            groupValue:
                                                                _surveyAnswers[
                                                                    qId],
                                                          onChanged: (val) {
                                                            if (val != null) {
                                                              setState(() {
                                                                  _surveyAnswers[
                                                                          qId] =
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
                                                            QuestionType
                                                                .MULTI_SELECT &&
                                                        qOptions.isNotEmpty)
                                                    Builder(
                                                      builder: (context) {
                                                        final selectedList =
                                                            _surveyAnswers[qId]
                                                                    ?.split(',')
                                                                    .map((s) => s
                                                                        .trim())
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
                                                              .map((opt) =>
                                                                  opt.trim())
                                                              .where((opt) =>
                                                                  opt.isNotEmpty)
                                                              .map((opt) {
                                                            final isChecked =
                                                                selectedList
                                                                    .contains(
                                                                        opt);
                                                            return CheckboxListTile(
                                                              title: Text(opt,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium),
                                                              value: isChecked,
                                                              onChanged: (val) {
                                                                setState(() {
                                                                  if (val ==
                                                                      true) {
                                                                    if (!selectedList
                                                                        .contains(
                                                                            opt)) {
                                                                      selectedList
                                                                          .add(
                                                                              opt);
                                                                    }
                                                                  } else {
                                                                    selectedList
                                                                        .remove(
                                                                            opt);
                                                                  }
                                                                  _surveyAnswers[
                                                                          qId] =
                                                                      selectedList
                                                                          .join(
                                                                              ', ');
                                                                });
                                                              },
                                                              activeColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              dense: true,
                                                              controlAffinity:
                                                                  ListTileControlAffinity
                                                                      .leading,
                                                            );
                                                          }).toList(),
                                                        );
                                                      })
                                                    else if (qType ==
                                                        QuestionType.DATE)
                                                    InkWell(
                                                      onTap: () async {
                                                          final picked =
                                                              await showDatePicker(
                                                          context: context,
                                                            initialDate:
                                                                DateTime.now(),
                                                            firstDate:
                                                                DateTime(2000),
                                                            lastDate:
                                                                DateTime(2100),
                                                        );
                                                        if (picked != null) {
                                                          setState(() {
                                                              _surveyAnswers[
                                                                      qId] =
                                                                  picked
                                                                      .toString()
                                                                      .substring(
                                                                          0,
                                                                          10);
                                                          });
                                                        }
                                                      },
                                                      child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16.0,
                                                                  vertical:
                                                                      12.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryBackground,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            border: Border.all(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate),
                                                        ),
                                                        child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                          children: [
                                                            Text(
                                                                _surveyAnswers[
                                                                        qId] ??
                                                                    'Select date',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium,
                                                            ),
                                                              Icon(
                                                                  Icons
                                                                      .calendar_today_rounded,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  size: 20),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    TextFormField(
                                                        initialValue:
                                                            _surveyAnswers[qId],
                                                        decoration:
                                                            InputDecoration(
                                                          hintText:
                                                              'Enter response...',
                                                          fillColor: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                        filled: true,
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                            borderSide: BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate),
                                                          ),
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium,
                                                        maxLines: qType ==
                                                                QuestionType
                                                                    .TEXT
                                                            ? 3
                                                            : 1,
                                                      onChanged: (val) {
                                                          _surveyAnswers[qId] =
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
                                ].divide(const SizedBox(height: 16.0)),
                              ),
                            ].divide(const SizedBox(height: 24.0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Next call after:',
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                      lineHeight: 1.3,
                                    ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                      _timerRunning
                                          ? '$_secondsRemaining'
                                          : 'Paused',
                                    style: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                .titleLarge
                                                .fontStyle,
                                          ),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                .titleLarge
                                                .fontStyle,
                                          lineHeight: 1.3,
                                        ),
                                  ),
                                  if (_timerRunning)
                                    Text(
                                      'seconds',
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                            ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                            letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                            lineHeight: 1.3,
                                          ),
                                    ),
                                ].divide(const SizedBox(width: 4.0)),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () {
                                    if (_timerRunning) {
                                      _pauseTimer();
                                    } else {
                                      _resumeTimer();
                                    }
                                  },
                                  child: wrapWithModel(
                                    model: _model.controlBtn3b28c09cModel,
                                    updateCallback: () => safeSetState(() {}),
                                    child: ControlBtn3b28c09cWidget(
                                      bg: 'surface_variant',
                                        borderColor:
                                            FlutterFlowTheme.of(context)
                                                .alternate,
                                      color: 'primary_text',
                                        icon: _timerRunning
                                            ? 'pause_rounded'
                                            : 'play_arrow_rounded',
                                        label:
                                            _timerRunning ? 'Pause' : 'Resume',
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: _makeCall,
                                  child: ControlBtn3b28c09cWidget(
                                    bg: 'primary',
                                    borderColor: Colors.transparent,
                                    color: 'on_primary',
                                    icon: 'call_rounded',
                                    label: 'Call Now',
                                  ),
                                ),
                              ),
                            ].divide(const SizedBox(width: 16.0)),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Gap:',
                                  style: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .override(
                                        font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .fontStyle,
                                        ),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                        lineHeight: 1.2,
                                      ),
                                ),
                                ...[5, 10, 20, 30, 60].map((sec) {
                                  final isSelected = _gapDuration == sec;
                                  return InkWell(
                                    onTap: () => _updateGap(sec),
                                    child: Container(
                                      height: 34.0,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                              ? FlutterFlowTheme.of(context)
                                                  .primary
                                              : FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.transparent
                                                : FlutterFlowTheme.of(context)
                                                    .alternate,
                                          width: 1.0,
                                        ),
                                      ),
                                        alignment:
                                            const AlignmentDirectional(0.0, 0.0),
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                          children: [
                                            if (isSelected)
                                              Icon(
                                                Icons.check_rounded,
                                                  color:
                                                      FlutterFlowTheme.of(context)
                                                          .onPrimary,
                                                size: 16.0,
                                              ),
                                            Text(
                                              '${sec}s',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                  .labelMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                          .labelMedium
                                                          .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                          .labelMedium
                                                          .fontStyle,
                                                    ),
                                                    color: isSelected
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .onPrimary
                                                          : FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                          .labelMedium
                                                          .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                          .labelMedium
                                                          .fontStyle,
                                                    lineHeight: 1.3,
                                                  ),
                                            ),
                                          ].divide(const SizedBox(width: 6.0)),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ].divide(const SizedBox(width: 8.0)),
                            ),
                          ),
                        ].divide(const SizedBox(height: 16.0)),
                      ),
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

  void _showContactDetails(Map<String, dynamic> contact) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Row(
          children: [
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context)
                    .primary
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: const AlignmentDirectional(0.0, 0.0),
              child: Text(
                (contact['name']
                        ?.toString()
                        .trim()
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase() ??
                    'C'),
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      color: FlutterFlowTheme.of(context).primary,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Contact Details',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  context, 'Name', contact['name'], Icons.person_rounded),
              _buildDetailRow(
                  context, 'Mobile', contact['mobile'], Icons.phone_rounded),
              _buildDetailRow(
                  context, 'FOLK ID', contact['folk_id'], Icons.tag_rounded),
              _buildDetailRow(context, 'FOLK Guide', contact['folk_guide'],
                  Icons.groups_rounded),
              _buildDetailRow(
                  context, 'Email', contact['email'], Icons.email_rounded),
              _buildDetailRow(context, 'Village', contact['village'],
                  Icons.location_on_rounded),
              _buildDetailRow(
                  context, 'District', contact['district'], Icons.map_rounded),
              _buildDetailRow(
                  context, 'State', contact['state'], Icons.public_rounded),
              _buildDetailRow(context, 'Pincode',
                  contact['pincode']?.toString(), Icons.pin_drop_rounded),
              _buildDetailRow(context, 'Age', contact['age']?.toString(),
                  Icons.cake_rounded),
              _buildDetailRow(
                  context, 'Gender', contact['gender'], Icons.wc_rounded),
              _buildDetailRow(context, 'Caste', contact['caste'],
                  Icons.diversity_3_rounded),
              _buildDetailRow(context, 'Religion', contact['religion'],
                  Icons.temple_hindu_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    color: FlutterFlowTheme.of(context).primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, dynamic value, IconData icon) {
    final displayValue = value?.toString();
    if (displayValue == null || displayValue.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: FlutterFlowTheme.of(context).secondaryText, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: FlutterFlowTheme.of(context).labelSmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
