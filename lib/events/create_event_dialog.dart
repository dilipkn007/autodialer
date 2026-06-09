import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';

class CreateEventDialog extends StatefulWidget {
  final VoidCallback onEventCreated;
  const CreateEventDialog({super.key, required this.onEventCreated});

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class QuestionCard {
  final Key key = UniqueKey();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController optionsController = TextEditingController();
  QuestionType type = QuestionType.DROPDOWN;
  bool isRequired = true;
  VoidCallback? onChanged;

  QuestionCard({
    String title = '',
    QuestionType questionType = QuestionType.DROPDOWN,
    String options = '',
    bool required = true,
    this.onChanged,
  }) {
    titleController.text = title;
    optionsController.text = options;
    type = questionType;
    isRequired = required;

    titleController.addListener(_notify);
    optionsController.addListener(_notify);
  }

  void _notify() {
    if (onChanged != null) {
      onChanged!();
    }
  }

  void dispose() {
    titleController.removeListener(_notify);
    optionsController.removeListener(_notify);
    titleController.dispose();
    optionsController.dispose();
  }
}


class _CreateEventDialogState extends State<CreateEventDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _audienceFilter = 'All';
  bool _saving = false;
  bool _isMenuOpen = false;
  bool _isPresetsOpen = false;

  final List<QuestionCard> _questions = [];

  @override
  void initState() {
    super.initState();
    // Add an initial empty question card
    _questions.add(QuestionCard(onChanged: () => setState(() {})));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestionCard() {
    setState(() {
      _questions.add(QuestionCard(onChanged: () => setState(() {})));
    });
  }

  void _addQuestionWithType(QuestionType type) {
    setState(() {
      String defaultTitle = '';
      String defaultOptions = '';
      switch (type) {
        case QuestionType.TEXT:
          defaultTitle = 'New Text Question';
          break;
        case QuestionType.DROPDOWN:
          defaultTitle = 'New Dropdown Question';
          defaultOptions = 'Option 1, Option 2';
          break;
        case QuestionType.RADIO:
          defaultTitle = 'New Radio Buttons Question';
          defaultOptions = 'Option 1, Option 2';
          break;
        case QuestionType.MULTI_SELECT:
          defaultTitle = 'New Checkbox Question';
          defaultOptions = 'Option 1, Option 2';
          break;
        case QuestionType.DATE:
          defaultTitle = 'New Date Question';
          break;
      }
      _questions.add(QuestionCard(
        title: defaultTitle,
        questionType: type,
        options: defaultOptions,
        required: true,
        onChanged: () => setState(() {}),
      ));
    });
  }

  void _addTemplate(String title, QuestionType type, String options) {
    setState(() {
      _questions.add(QuestionCard(
        title: title,
        questionType: type,
        options: options,
        required: true,
        onChanged: () => setState(() {}),
      ));
    });
  }

  void _removeQuestionCard(int index) {
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: FlutterFlowTheme.of(context).primary,
              onPrimary: FlutterFlowTheme.of(context).onPrimary,
              surface: FlutterFlowTheme.of(context).secondaryBackground,
              onSurface: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: FlutterFlowTheme.of(context).primary,
              onPrimary: FlutterFlowTheme.of(context).onPrimary,
              surface: FlutterFlowTheme.of(context).secondaryBackground,
              onSurface: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createEvent() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event title is required')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event date is required')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final timeStr = _selectedTime != null ? _selectedTime!.format(context) : '00:00 AM';

      // 1. Insert Event
      final eventRes = await DefaultConnector.instance
          .createEvent(
            name: name,
            eventDate: _selectedDate!,
            status: EventStatus.ACTIVE,
            createdByUid: user.uid,
          )
          .description(_descController.text.trim().isNotEmpty ? _descController.text.trim() : null)
          .eventTime(timeStr)
          .audienceFilter(_audienceFilter)
          .execute();

      final newEventId = eventRes.data.event_insert.id;

      // 2. Insert survey questions in parallel
      final futures = <Future>[];
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final qTitle = q.titleController.text.trim();
        if (qTitle.isEmpty) continue;

        var builder = DefaultConnector.instance.addSurveyQuestion(
          eventId: newEventId,
          questionTitle: qTitle,
          questionType: q.type,
          sortOrder: i,
          isRequired: q.isRequired,
        );

        if (q.type == QuestionType.DROPDOWN || q.type == QuestionType.MULTI_SELECT || q.type == QuestionType.RADIO) {
          final options = q.optionsController.text.trim();
          if (options.isNotEmpty) {
            builder = builder.options(options);
          }
        }
        futures.add(builder.execute());
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      widget.onEventCreated();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildFabMenuItem({
    required String label,
    required IconData icon,
    required Color color,
    QuestionType? type,
    VoidCallback? onTap,
  }) {
    final cardWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          const SizedBox(width: 8.0),
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 16),
          ),
        ],
      ),
    );

    if (type == null) {
      return GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return Draggable<QuestionType>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: color, width: 2.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              const SizedBox(width: 8.0),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: cardWidget,
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isMenuOpen = false;
            _isPresetsOpen = false;
          });
          HapticFeedback.lightImpact();
          _addQuestionWithType(type);
        },
        child: cardWidget,
      ),
    );
  }

  Widget _buildFabPresetItem({
    required String label,
    required QuestionType type,
    required String options,
    required IconData icon,
    required Color color,
  }) {
    final dataMap = {
      'type': type,
      'title': label,
      'options': options,
    };

    final presetWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryContainer,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: FlutterFlowTheme.of(context).alternate),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    return Draggable<Map<String, dynamic>>(
      data: dataMap,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryContainer.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: color, width: 2.0),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: presetWidget,
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isMenuOpen = false;
            _isPresetsOpen = false;
          });
          HapticFeedback.lightImpact();
          _addTemplate(label, type, options);
        },
        child: presetWidget,
      ),
    );
  }

  Widget _buildEmptyCanvasIndicator() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 36),
            const SizedBox(height: 12.0),
            Text(
              'No survey questions added yet.',
              style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Drag fields or tap (+) at bottom-right to add',
              style: TextStyle(color: FlutterFlowTheme.of(context).accent3, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallDropIndicator() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate.withValues(alpha: 0.5),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 18),
            const SizedBox(width: 8.0),
            Text(
              'Drag & drop a field here to append',
              style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenBody() {
    return DragTarget<Object>(
      onWillAccept: (data) => true,
      onAccept: (data) {
        HapticFeedback.lightImpact();
        if (data is QuestionType) {
          _addQuestionWithType(data);
        } else if (data is Map<String, dynamic>) {
          _addTemplate(
            data['title'] as String,
            data['type'] as QuestionType,
            data['options'] as String,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          color: isHovering 
              ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.04) 
              : Colors.transparent,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEventDetailsCard(),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Survey Questions (${_questions.length})',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline_rounded, color: FlutterFlowTheme.of(context).primary),
                      onPressed: _addQuestionCard,
                      tooltip: 'Add Blank Field',
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                if (isHovering) ...[
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: FlutterFlowTheme.of(context).primary, width: 2.0),
                    ),
                    child: Center(
                      child: Text(
                        'Drop to Add Question',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_questions.isEmpty)
                  _buildEmptyCanvasIndicator()
                else ...[
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _questions.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = _questions.removeAt(oldIndex);
                        _questions.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final card = _questions[index];
                      return _buildQuestionCard(index, card);
                    },
                  ),
                  const SizedBox(height: 16.0),
                  _buildSmallDropIndicator(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventDetailsCard() {
    return Card(
      color: FlutterFlowTheme.of(context).secondaryBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: FlutterFlowTheme.of(context).alternate),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Event Details',
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _nameController,
              style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
              decoration: InputDecoration(
                labelText: 'Event Title',
                labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                prefixIcon: Icon(Icons.title_rounded, color: FlutterFlowTheme.of(context).accent3),
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
              controller: _descController,
              maxLines: 2,
              style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
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
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: FlutterFlowTheme.of(context).accent3),
                          const SizedBox(width: 8.0),
                          Text(
                            _selectedDate == null
                                ? 'MM/DD/YYYY'
                                : DateFormat('MM/dd/yyyy').format(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate == null
                                  ? FlutterFlowTheme.of(context).secondaryText
                                  : FlutterFlowTheme.of(context).primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 18, color: FlutterFlowTheme.of(context).accent3),
                          const SizedBox(width: 8.0),
                          Text(
                            _selectedTime == null ? '00:00 AM' : _selectedTime!.format(context),
                            style: TextStyle(
                              color: _selectedTime == null
                                  ? FlutterFlowTheme.of(context).secondaryText
                                  : FlutterFlowTheme.of(context).primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              initialValue: _audienceFilter,
              dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
              style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
              decoration: InputDecoration(
                labelText: 'Select Target Audience',
                labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                prefixIcon: Icon(Icons.people_outline_rounded, color: FlutterFlowTheme.of(context).accent3),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              items: ['All', 'Active', 'Dormant'].map((filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _audienceFilter = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, QuestionCard card) {
    Color typeColor;
    String typeLabel;
    IconData typeIcon;

    switch (card.type) {
      case QuestionType.TEXT:
        typeColor = Colors.teal;
        typeLabel = 'Short Text';
        typeIcon = Icons.short_text_rounded;
        break;
      case QuestionType.DROPDOWN:
        typeColor = Colors.amber;
        typeLabel = 'Dropdown';
        typeIcon = Icons.arrow_drop_down_circle_rounded;
        break;
      case QuestionType.RADIO:
        typeColor = Colors.indigo;
        typeLabel = 'Radio Buttons';
        typeIcon = Icons.radio_button_checked_rounded;
        break;
      case QuestionType.MULTI_SELECT:
        typeColor = Colors.purple;
        typeLabel = 'Checkboxes';
        typeIcon = Icons.checklist_rounded;
        break;
      case QuestionType.DATE:
        typeColor = Colors.pink;
        typeLabel = 'Date Picker';
        typeIcon = Icons.calendar_today_rounded;
        break;
    }

    return Card(
      key: card.key,
      color: FlutterFlowTheme.of(context).primaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: FlutterFlowTheme.of(context).alternate),
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: typeColor, width: 5.0),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: FlutterFlowTheme.of(context).accent3,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Question #${index + 1}',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const SizedBox(width: 30.0), // Indent to align with the question title text
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(color: typeColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(typeIcon, color: typeColor, size: 10),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      typeLabel,
                                      style: TextStyle(
                                        color: typeColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Text(
                                'Required',
                                style: FlutterFlowTheme.of(context).labelSmall.override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                              ),
                              const SizedBox(width: 4.0),
                              Transform.scale(
                                scale: 0.7,
                                child: Switch(
                                  value: card.isRequired,
                                  onChanged: (val) {
                                    setState(() {
                                      card.isRequired = val;
                                    });
                                  },
                                  activeTrackColor: FlutterFlowTheme.of(context).primary,
                                  activeThumbColor: Colors.white,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              GestureDetector(
                                onTap: () => _removeQuestionCard(index),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                  child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: card.titleController,
                style: TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Question Title',
                  labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 13),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              DropdownButtonFormField<QuestionType>(
                initialValue: card.type,
                dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
                style: TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Question Type',
                  labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 13),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: QuestionType.TEXT, child: Text('Short Text Field')),
                  DropdownMenuItem(value: QuestionType.DROPDOWN, child: Text('Dropdown (Single Selection)')),
                  DropdownMenuItem(value: QuestionType.RADIO, child: Text('Radio Buttons (Single Selection)')),
                  DropdownMenuItem(value: QuestionType.MULTI_SELECT, child: Text('Checkboxes (Multiple Selection)')),
                  DropdownMenuItem(value: QuestionType.DATE, child: Text('Date Picker')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      card.type = val;
                    });
                  }
                },
              ),
              if (card.type == QuestionType.DROPDOWN ||
                  card.type == QuestionType.MULTI_SELECT ||
                  card.type == QuestionType.RADIO) ...[
                const SizedBox(height: 12.0),
                TextField(
                  controller: card.optionsController,
                  style: TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Options (comma separated)',
                    labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 12),
                    helperText: 'e.g., Yes, No, Maybe  or  S, M, L, XL',
                    helperStyle: TextStyle(color: FlutterFlowTheme.of(context).accent3, fontSize: 11),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: FlutterFlowTheme.of(context).alternate.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIELD PREVIEW',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _buildFieldPreview(card),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldPreview(QuestionCard card) {
    final title = card.titleController.text.trim().isNotEmpty 
        ? card.titleController.text.trim() 
        : 'Untitled Question';

    final isRequired = card.isRequired;

    Widget previewInput;
    switch (card.type) {
      case QuestionType.TEXT:
        previewInput = Container(
          height: 38,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          alignment: Alignment.centerLeft,
          child: Text(
            'Short answer text placeholder...',
            style: TextStyle(color: FlutterFlowTheme.of(context).accent3, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        );
        break;

      case QuestionType.DATE:
        previewInput = Container(
          height: 38,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Date (MM/DD/YYYY)',
                style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 12),
              ),
              Icon(Icons.calendar_today_rounded, size: 16, color: FlutterFlowTheme.of(context).accent3),
            ],
          ),
        );
        break;

      case QuestionType.DROPDOWN:
        final opts = card.optionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        previewInput = Container(
          height: 38,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                opts.isEmpty ? 'Select an option' : 'Choose: ${opts.first}',
                style: TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontSize: 12),
              ),
              Icon(Icons.arrow_drop_down_rounded, size: 24, color: FlutterFlowTheme.of(context).secondaryText),
            ],
          ),
        );
        break;

      case QuestionType.RADIO:
        final opts = card.optionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (opts.isEmpty) {
          previewInput = Text(
            'Add comma-separated options to preview radio buttons.',
            style: TextStyle(color: FlutterFlowTheme.of(context).accent3, fontSize: 12, fontStyle: FontStyle.italic),
          );
        } else {
          previewInput = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: opts.map((opt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: opt,
                    groupValue: opts.first,
                    onChanged: null,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8.0),
                  Text(opt, style: TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontSize: 12)),
                ],
              ),
            )).toList(),
          );
        }
        break;

      case QuestionType.MULTI_SELECT:
        final opts = card.optionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (opts.isEmpty) {
          previewInput = Text(
            'Add comma-separated options to preview checkboxes.',
            style: TextStyle(color: FlutterFlowTheme.of(context).accent3, fontSize: 12, fontStyle: FontStyle.italic),
          );
        } else {
          previewInput = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: opts.map((opt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: false,
                    onChanged: null,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8.0),
                  Text(opt, style: TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontSize: 12)),
                ],
              ),
            )).toList(),
          );
        }
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title + (isRequired ? ' *' : ''),
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        previewInput,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: Text(
          'Create New Event',
          style: FlutterFlowTheme.of(context).titleLarge.override(
                font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                color: FlutterFlowTheme.of(context).primaryText,
              ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: FlutterFlowTheme.of(context).secondaryText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _createEvent,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Create',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8.0),
        ],
        elevation: 1,
      ),
      body: Stack(
        children: [
          _buildFullScreenBody(),

          if (_isMenuOpen)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isMenuOpen = false;
                  _isPresetsOpen = false;
                });
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),

          Positioned(
            bottom: 90,
            right: 16,
            child: AnimatedOpacity(
              opacity: _isMenuOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_isMenuOpen,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildFabMenuItem(
                      label: 'Quick Presets',
                      icon: Icons.auto_awesome_motion_rounded,
                      color: Colors.amber,
                      onTap: () {
                        setState(() {
                          _isPresetsOpen = !_isPresetsOpen;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFabMenuItem(
                      label: 'Checkboxes',
                      icon: Icons.checklist_rounded,
                      color: Colors.purple,
                      type: QuestionType.MULTI_SELECT,
                    ),
                    const SizedBox(height: 10),
                    _buildFabMenuItem(
                      label: 'Radio Buttons',
                      icon: Icons.radio_button_checked_rounded,
                      color: Colors.indigo,
                      type: QuestionType.RADIO,
                    ),
                    const SizedBox(height: 10),
                    _buildFabMenuItem(
                      label: 'Dropdown',
                      icon: Icons.arrow_drop_down_circle_rounded,
                      color: Colors.amber,
                      type: QuestionType.DROPDOWN,
                    ),
                    const SizedBox(height: 10),
                    _buildFabMenuItem(
                      label: 'Date Picker',
                      icon: Icons.calendar_today_rounded,
                      color: Colors.pink,
                      type: QuestionType.DATE,
                    ),
                    const SizedBox(height: 10),
                    _buildFabMenuItem(
                      label: 'Short Text',
                      icon: Icons.short_text_rounded,
                      color: Colors.teal,
                      type: QuestionType.TEXT,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isMenuOpen && _isPresetsOpen)
            Positioned(
              bottom: 120,
              right: 180,
              child: Card(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PRESET TEMPLATES',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Divider(),
                      _buildFabPresetItem(
                        label: 'RSVP Status',
                        type: QuestionType.DROPDOWN,
                        options: 'Going, Not Going, Undecided',
                        icon: Icons.event_available_rounded,
                        color: Colors.amber,
                      ),
                      _buildFabPresetItem(
                        label: 'Yes / No',
                        type: QuestionType.RADIO,
                        options: 'Yes, No',
                        icon: Icons.thumbs_up_down_rounded,
                        color: Colors.indigo,
                      ),
                      _buildFabPresetItem(
                        label: 'T-Shirt Size',
                        type: QuestionType.DROPDOWN,
                        options: 'S, M, L, XL, XXL',
                        icon: Icons.checkroom_rounded,
                        color: Colors.amber,
                      ),
                      _buildFabPresetItem(
                        label: 'Food Preference',
                        type: QuestionType.DROPDOWN,
                        options: 'Veg, Non-Veg',
                        icon: Icons.restaurant_rounded,
                        color: Colors.amber,
                      ),
                      _buildFabPresetItem(
                        label: 'Rating (1-5)',
                        type: QuestionType.RADIO,
                        options: '1, 2, 3, 4, 5',
                        icon: Icons.star_rounded,
                        color: Colors.indigo,
                      ),
                      _buildFabPresetItem(
                        label: 'Feedback',
                        type: QuestionType.TEXT,
                        options: '',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isMenuOpen = !_isMenuOpen;
            if (!_isMenuOpen) {
              _isPresetsOpen = false;
            }
          });
        },
        backgroundColor: FlutterFlowTheme.of(context).primary,
        child: AnimatedRotation(
          turns: _isMenuOpen ? 0.125 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}
