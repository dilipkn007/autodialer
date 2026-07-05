import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:f_o_l_k_auto_dialer/services/survey_state_file.dart';

class OverlaySurveyWidget extends StatefulWidget {
  const OverlaySurveyWidget({super.key});

  @override
  State<OverlaySurveyWidget> createState() => _OverlaySurveyWidgetState();
}

class _OverlaySurveyWidgetState extends State<OverlaySurveyWidget> {
  String _contactName = '';
  String _contactPhone = '';
  List<Map<String, dynamic>> _surveyQuestions = [];
  Map<String, String> _surveyAnswers = {};
  String _callOutcome = 'ANSWERED';
  String _followUpStatus = 'NEW';
  String _followUpNotes = '';
  String _nextCallDate = '';
  bool _initialized = false;
  bool _saving = false;
  String? _saveError;
  Timer? _debounceTimer;

  static const _outcomes = ['ANSWERED', 'BUSY', 'NO_RESPONSE', 'SWITCHED_OFF', 'WRONG_NUMBER'];
  static const _followUps = ['NEW', 'CONTACTED', 'INTERESTED', 'NOT_INTERESTED', 'JOINED', 'PENDING', 'DORMANT'];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    debugPrint("OverlaySurveyWidget: initState");
    _nextCallDate = DateTime.now().add(const Duration(days: 7)).toString().substring(0, 10);
    FlutterOverlayWindow.overlayListener.listen((event) {
      debugPrint("OverlaySurveyWidget: received event: $event");
      if (event is String) {
        final data = jsonDecode(event) as Map<String, dynamic>;
        if (data['type'] == 'show_survey') {
          debugPrint("OverlaySurveyWidget: show_survey received, setting state");
          setState(() {
            _contactName = data['contactName'] as String? ?? '';
            _contactPhone = data['contactPhone'] as String? ?? '';
            _surveyQuestions = (data['surveyQuestions'] as List? ?? [])
                .map((q) => q as Map<String, dynamic>)
                .toList();
            final saved = data['currentAnswers'] as Map<String, dynamic>? ?? {};
            _surveyAnswers = saved.map((k, v) => MapEntry(k, v.toString()));
            _saving = false;
            _saveError = null;
            if (!_initialized) {
              _nextCallDate = DateTime.now()
                  .add(const Duration(days: 7))
                  .toString()
                  .substring(0, 10);
            }
            _initialized = true;
          });
        }
        if (data['type'] == 'close_overlay') {
          debugPrint("OverlaySurveyWidget: received close_overlay command from main app!");
          FlutterOverlayWindow.closeOverlay();
        }
        if (data['type'] == 'save_failed') {
          setState(() {
            _saving = false;
            _saveError = data['message'] as String? ??
                'Could not save the response. Please try again.';
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("OverlaySurveyWidget: post-frame callback, sending overlay_ready");
      FlutterOverlayWindow.shareData(jsonEncode({'type': 'overlay_ready'}));
    });
  }

  void _writeState() {
    SurveyStateFile.instance.write({
      'surveyAnswers': _surveyAnswers,
      'callOutcome': _callOutcome,
      'followUpStatus': _followUpStatus,
      'followUpNotes': _followUpNotes,
      'nextCallDate': _nextCallDate,
    });
  }

  void _debouncedSend() {
    _writeState();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), _sendUpdate);
  }

  Future<void> _sendUpdate() async {
    final result = jsonEncode({
      'type': 'survey_update',
      'surveyAnswers': _surveyAnswers,
      'callOutcome': _callOutcome,
      'followUpStatus': _followUpStatus,
      'followUpNotes': _followUpNotes,
      'nextCallDate': _nextCallDate,
    });
    await FlutterOverlayWindow.shareData(result);
  }

  Future<void> _submitSurvey() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    debugPrint("Save to Dialer button clicked in overlay!");
    // Write latest state to shared file for main app to read
    _writeState();
    try {
      final result = jsonEncode({
        'type': 'survey_submit',
        'surveyAnswers': _surveyAnswers,
        'callOutcome': _callOutcome,
        'followUpStatus': _followUpStatus,
        'followUpNotes': _followUpNotes,
        'nextCallDate': _nextCallDate,
      });
      await FlutterOverlayWindow.shareData(result);
    } catch (e) {
      debugPrint("Error submitting survey: $e");
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = 'Could not send the response. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Material(
        color: Colors.transparent,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final overlayHeight = MediaQuery.of(context).size.height * 0.65;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          height: overlayHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          margin: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildContactInfo(),
                    const SizedBox(height: 12),
                    _buildCallOutcome(),
                    const SizedBox(height: 12),
                    ..._buildSurveyQuestions(),
                    const SizedBox(height: 12),
                    _buildFollowUpStatus(),
                    const SizedBox(height: 12),
                    _buildNotes(),
                    const SizedBox(height: 12),
                    _buildNextCallDate(),
                    if (_saveError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _saveError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_input_antenna, color: Color(0xFF4FC3F7), size: 18),
          const SizedBox(width: 8),
          const Text(
            'Survey',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final result = jsonEncode({
                'type': 'overlay_closed',
              });
              await FlutterOverlayWindow.shareData(result);
              await FlutterOverlayWindow.closeOverlay();
            },
            child: const Icon(Icons.close, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4FC3F7),
            radius: 16,
            child: Text(
              _contactName.isNotEmpty ? _contactName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_contactName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(_contactPhone,
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallOutcome() {
    return _buildDropdown(
      label: 'Call Outcome',
      value: _callOutcome,
      items: _outcomes,
      onChanged: (v) { setState(() => _callOutcome = v!); _debouncedSend(); },
    );
  }

  List<Widget> _buildSurveyQuestions() {
    return _surveyQuestions.map((q) {
      final qId = q['id'].toString();
      final qTitle = q['question_title'] as String? ?? '';
      final qType = q['question_type'] as String? ?? 'TEXT';
      final qOptions = q['options'] as String? ?? '';
      final qRequired = q['is_required'] == true;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$qTitle${qRequired ? " *" : ""}',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            _buildQuestionInput(qType, qId, qOptions),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildQuestionInput(String qType, String qId, String qOptions) {
    switch (qType) {
      case 'DROPDOWN':
        if (qOptions.isEmpty) return const SizedBox.shrink();
        return _buildCompactDropdown(
          value: _surveyAnswers[qId],
          items: qOptions.split(',').map((o) => o.trim()).where((o) => o.isNotEmpty).toList(),
          hint: 'Select an option',
          onChanged: (v) {
            if (v != null) { setState(() => _surveyAnswers[qId] = v); _debouncedSend(); }
          },
        );

      case 'RADIO':
        if (qOptions.isEmpty) return const SizedBox.shrink();
        return Column(
          children: qOptions
              .split(',')
              .map((o) => o.trim())
              .where((o) => o.isNotEmpty)
              .map((opt) => RadioListTile<String>(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    value: opt,
                    groupValue: _surveyAnswers[qId],
                    onChanged: (v) {
                      if (v != null) { setState(() => _surveyAnswers[qId] = v); _debouncedSend(); }
                    },
                    activeColor: const Color(0xFF4FC3F7),
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        );

      case 'MULTI_SELECT':
        if (qOptions.isEmpty) return const SizedBox.shrink();
        final selected = _surveyAnswers[qId]?.split(',').map((s) => s.trim()).toList() ?? [];
        return Column(
          children: qOptions
              .split(',')
              .map((o) => o.trim())
              .where((o) => o.isNotEmpty)
              .map((opt) => CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    value: selected.contains(opt),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (!selected.contains(opt)) selected.add(opt);
                        } else {
                          selected.remove(opt);
                        }
                        _surveyAnswers[qId] = selected.join(', ');
                      });
                      _debouncedSend();
                    },
                    activeColor: const Color(0xFF4FC3F7),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ))
              .toList(),
        );

      case 'DATE':
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => _surveyAnswers[qId] = picked.toString().substring(0, 10));
              _debouncedSend();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _surveyAnswers[qId] ?? 'Select date',
                  style: TextStyle(color: _surveyAnswers[qId] != null ? Colors.white : Colors.white38, fontSize: 12),
                ),
                const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
              ],
            ),
          ),
        );

      default:
        return TextField(
          controller: TextEditingController(text: _surveyAnswers[qId] ?? '')
            ..selection = TextSelection.collapsed(offset: (_surveyAnswers[qId] ?? '').length),
          decoration: InputDecoration(
            hintText: 'Enter response...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF16213E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          maxLines: qType == 'TEXT' ? 2 : 1,
          onChanged: (v) { _surveyAnswers[qId] = v; _debouncedSend(); },
        );
    }
  }

  Widget _buildFollowUpStatus() {
    return _buildDropdown(
      label: 'Follow-up Status',
      value: _followUpStatus,
      items: _followUps,
      onChanged: (v) { setState(() => _followUpStatus = v!); _debouncedSend(); },
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: _followUpNotes)
            ..selection = TextSelection.collapsed(offset: _followUpNotes.length),
          decoration: InputDecoration(
            hintText: 'Add notes...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF16213E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          maxLines: 3,
          onChanged: (v) { _followUpNotes = v; _debouncedSend(); },
        ),
      ],
    );
  }

  Widget _buildNextCallDate() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _nextCallDate = picked.toString().substring(0, 10));
          _debouncedSend();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next Call Date',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(_nextCallDate, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
            const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
          child: ElevatedButton(
          onPressed: _saving ? null : _submitSurvey,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FC3F7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save to Dialer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item.replaceAll('_', ' ')),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDropdown({
    String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value != null && items.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          dropdownColor: const Color(0xFF16213E),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
