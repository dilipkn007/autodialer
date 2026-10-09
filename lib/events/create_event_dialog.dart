import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:f_o_l_k_auto_dialer/models/enums.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'campaign_template_helper.dart';

enum EventCreationMode { manual, csvUpload }

class CreateEventDialog extends StatefulWidget {
  final VoidCallback onEventCreated;
  final Map<String, dynamic>? eventToEdit;
  const CreateEventDialog({super.key, required this.onEventCreated, this.eventToEdit});

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class QuestionCard {
  final Key key = UniqueKey();
  String? id;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController optionsController = TextEditingController();
  QuestionType type = QuestionType.DROPDOWN;
  bool isRequired = true;
  VoidCallback? onChanged;

  QuestionCard({
    this.id,
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

  // Creation mode & CSV upload state
  EventCreationMode _creationMode = EventCreationMode.manual;
  PlatformFile? _selectedCsvFile;
  String? _csvFileName;
  List<Map<String, dynamic>> _parsedContacts = [];
  final List<QuestionCard> _csvQuestions = [];
  List<Map<String, dynamic>> _enablers = [];
  String _selectedEnablerOption = 'round_robin'; // 'round_robin', 'csv', or enabler UUID
  bool _hasCsvEnablerColumn = false;
  bool _parsingCsv = false;
  String? _csvProgressMessage;

  // Manual Contact Assignment State
  final Set<String> _selectedContactIds = {};
  final List<Map<String, dynamic>> _selectedContactObjects = [];
  List<Map<String, dynamic>> _searchedContacts = [];
  bool _searchingContacts = false;
  final TextEditingController _contactSearchCtrl = TextEditingController();

  final List<QuestionCard> _questions = [];

  final List<String> _initialQuestionIds = [];

  @override
  void initState() {
    super.initState();
    final auth = AuthService.instance;
    final myId = auth.contactId ?? auth.currentUser?.id;
    if (auth.role != UserRole.ADMIN && myId != null) {
      _selectedEnablerOption = myId;
    }
    _loadEnablers();
    _searchContacts();
    if (widget.eventToEdit != null) {
      _nameController.text = widget.eventToEdit!['name'] as String;
      _descController.text = (widget.eventToEdit!['description'] as String?) ?? '';
      _selectedDate = DateTime.parse(widget.eventToEdit!['event_date'] as String);
      _selectedTime = _parseTime(widget.eventToEdit!['event_time'] as String?);
      _audienceFilter = (widget.eventToEdit!['audience_filter'] as String?) ?? 'All';
      _loadExistingQuestions();
    } else {
      // Add an initial empty question card
      _questions.add(QuestionCard(onChanged: () => setState(() {})));
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final ampm = parts[1].toUpperCase();
      if (ampm == 'PM' && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint("Error parsing time: $e");
      return null;
    }
  }

  Future<void> _loadExistingQuestions() async {
    setState(() {
      _saving = true;
    });
    try {
      final eventId = widget.eventToEdit!['id'] as String;
      final questions = await Supabase.instance.client
          .from('survey_question')
          .select()
          .eq('event_id', eventId)
          .order('sort_order', ascending: true);

      // Also load existing assigned contacts for this event
      final assignments = await Supabase.instance.client
          .from('assignment')
          .select('contact_id')
          .eq('event_id', eventId);
      final contactIds = assignments
          .map((a) => a['contact_id'] as String?)
          .whereType<String>()
          .toList();
      
      List<Map<String, dynamic>> existingContacts = [];
      if (contactIds.isNotEmpty) {
        final contactsRes = await Supabase.instance.client
            .from('contact')
            .select('id, name, mobile, folk_id, city, center, role')
            .inFilter('id', contactIds);
        existingContacts = List<Map<String, dynamic>>.from(contactsRes);
      }
      
      setState(() {
        _questions.clear();
        for (final q in questions) {
          final qTypeStr = q['question_type'] as String;
          QuestionType parsedType = QuestionType.DROPDOWN;
          try {
            parsedType = QuestionType.values.byName(qTypeStr);
          } catch (_) {}

          _questions.add(QuestionCard(
            id: q['id'] as String,
            title: q['question_title'] as String,
            questionType: parsedType,
            options: (q['options'] as String?) ?? '',
            required: (q['is_required'] as bool?) ?? true,
            onChanged: () => setState(() {}),
          ));
          _initialQuestionIds.add(q['id'] as String);
        }

        _selectedContactIds.clear();
        _selectedContactObjects.clear();
        for (final c in existingContacts) {
          final id = c['id'] as String;
          _selectedContactIds.add(id);
          _selectedContactObjects.add(c);
        }

        _saving = false;
      });
    } catch (e) {
      debugPrint("Error loading existing survey questions / contacts: $e");
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load event details: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _contactSearchCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    for (final q in _csvQuestions) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _searchContacts([String? query]) async {
    setState(() => _searchingContacts = true);
    try {
      final q = (query ?? _contactSearchCtrl.text).trim().toLowerCase();
      dynamic filterBuilder = Supabase.instance.client
          .from('contact')
          .select('id, name, mobile, folk_id, city, center, role');

      if (q.isNotEmpty) {
        filterBuilder = filterBuilder.or(
            'name.ilike.%$q%,mobile.ilike.%$q%,folk_id.ilike.%$q%,city.ilike.%$q%');
      }

      final res = await filterBuilder.order('name').limit(50);
      final list = List<Map<String, dynamic>>.from(res);
      if (mounted) {
        setState(() {
          _searchedContacts = list;
          _searchingContacts = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching contacts: $e');
      if (mounted) setState(() => _searchingContacts = false);
    }
  }

  void _toggleContactSelection(Map<String, dynamic> contact) {
    final id = contact['id'] as String;
    setState(() {
      if (_selectedContactIds.contains(id)) {
        _selectedContactIds.remove(id);
        _selectedContactObjects.removeWhere((c) => c['id'] == id);
      } else {
        _selectedContactIds.add(id);
        _selectedContactObjects.add(contact);
      }
    });
  }

  void _selectAllSearchedContacts() {
    setState(() {
      for (final c in _searchedContacts) {
        final id = c['id'] as String;
        if (!_selectedContactIds.contains(id)) {
          _selectedContactIds.add(id);
          _selectedContactObjects.add(c);
        }
      }
    });
  }

  void _clearSelectedContacts() {
    setState(() {
      _selectedContactIds.clear();
      _selectedContactObjects.clear();
    });
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

  Future<String> _ensureUserContactId() async {
    final auth = AuthService.instance;
    final user = auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    String? contactId = auth.contactId;

    // 1. If contactId is set, verify it exists in the contact table
    if (contactId != null) {
      try {
        final existing = await Supabase.instance.client
            .from('contact')
            .select('id')
            .eq('id', contactId)
            .maybeSingle();
        if (existing != null) {
          return existing['id'] as String;
        }
      } catch (e) {
        debugPrint('Error verifying contactId: $e');
      }
    }

    // 2. Check if auth user UID exists in contact table
    try {
      final byAuthId = await Supabase.instance.client
          .from('contact')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (byAuthId != null) {
        return byAuthId['id'] as String;
      }
    } catch (e) {
      debugPrint('Error checking contact by auth uid: $e');
    }

    // 3. Check by user's phone number
    final phone = user.phone ?? '';
    if (phone.isNotEmpty) {
      final raw10 = phone.length >= 10 ? phone.substring(phone.length - 10) : phone;
      final formats = <String>{phone, raw10, '91$raw10', '+91$raw10'}..remove('');
      try {
        final byPhone = await Supabase.instance.client
            .from('contact')
            .select('id')
            .inFilter('mobile', formats.toList())
            .limit(1);
        if (byPhone.isNotEmpty) {
          return byPhone.first['id'] as String;
        }
      } catch (e) {
        debugPrint('Error checking contact by phone: $e');
      }
    }

    // 4. If no contact record exists at all for this user, upsert one for user.id so the foreign key is satisfied
    final name = auth.userName ?? user.phone ?? 'Caller';
    final initials = name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    try {
      final inserted = await Supabase.instance.client.from('contact').upsert({
        'id': user.id,
        'mobile': phone,
        'name': name,
        if (auth.userEmail != null && auth.userEmail!.isNotEmpty) 'email': auth.userEmail,
        if (initials.isNotEmpty) 'avatar_initials': initials,
        'role': auth.role == UserRole.ADMIN ? 'ADMIN' : 'ENABLER',
        'is_active': true,
      }).select('id').single();

      return inserted['id'] as String;
    } catch (e) {
      debugPrint('Error upserting contact record: $e');
      return user.id;
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
      final creatorContactId = await _ensureUserContactId();

      final timeStr = _selectedTime != null ? _selectedTime!.format(context) : '00:00 AM';

      // 1. Insert Event
      final eventRes = await Supabase.instance.client.from('event').insert({
        'name': name,
        'event_date': _selectedDate!.toIso8601String().split('T')[0],
        'status': 'ACTIVE',
        'created_by': creatorContactId,
        'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        'event_time': timeStr,
        'audience_filter': _audienceFilter,
      }).select().single();

      final newEventId = eventRes['id'];

      // 2. Insert survey questions in parallel
      final futures = <Future>[];
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final qTitle = q.titleController.text.trim();
        if (qTitle.isEmpty) continue;

        final qMap = {
          'event_id': newEventId,
          'question_title': qTitle,
          'question_type': q.type.name,
          'sort_order': i,
          'is_required': q.isRequired,
        };

        if (q.type == QuestionType.DROPDOWN || q.type == QuestionType.MULTI_SELECT || q.type == QuestionType.RADIO) {
          final options = q.optionsController.text.trim();
          if (options.isNotEmpty) {
            qMap['options'] = options;
          }
        }
        futures.add(Supabase.instance.client.from('survey_question').insert(qMap));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      // 3. Create assignments for manually selected contacts
      if (_selectedContactIds.isNotEmpty) {
        final assignmentsToInsert = <Map<String, dynamic>>[];
        final auth = AuthService.instance;
        final isAdmin = auth.role == UserRole.ADMIN;
        final activeEnablerList = _enablers.isNotEmpty
            ? _enablers
            : [
                {'id': creatorContactId, 'name': auth.userName ?? 'Caller'}
              ];

        for (final contactId in _selectedContactIds) {
          String assignedEnablerId;
          if (!isAdmin) {
            assignedEnablerId = creatorContactId;
          } else if (_selectedEnablerOption == 'round_robin') {
            assignedEnablerId = activeEnablerList[
                assignmentsToInsert.length % activeEnablerList.length]['id'] as String;
          } else if (_selectedEnablerOption == 'csv') {
            assignedEnablerId = creatorContactId;
          } else {
            assignedEnablerId = _selectedEnablerOption;
          }

          assignmentsToInsert.add({
            'event_id': newEventId,
            'contact_id': contactId,
            'enabler_id': assignedEnablerId,
            'assigned_by': creatorContactId,
            'status': 'PENDING',
            'sort_order': assignmentsToInsert.length,
          });
        }

        const chunkSize = 200;
        for (int i = 0; i < assignmentsToInsert.length; i += chunkSize) {
          final chunk = assignmentsToInsert.sublist(
              i, (i + chunkSize).clamp(0, assignmentsToInsert.length));
          await Supabase.instance.client.from('assignment').insert(chunk);
        }
      }

      widget.onEventCreated();
      Navigator.pop(context);

      final successMsg = _selectedContactIds.isNotEmpty
          ? 'Event "$name" created with ${_selectedContactIds.length} assigned contacts!'
          : 'Event created successfully';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
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

  Future<void> _updateEvent() async {
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
      final timeStr = _selectedTime != null ? _selectedTime!.format(context) : '00:00 AM';
      final eventId = widget.eventToEdit!['id'] as String;

      // 1. Update Event metadata
      await Supabase.instance.client.from('event').update({
        'name': name,
        'event_date': _selectedDate!.toIso8601String().split('T')[0],
        'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        'event_time': timeStr,
        'audience_filter': _audienceFilter,
      }).eq('id', eventId);

      // 2. Identify deleted questions
      final currentIds = _questions.map((q) => q.id).where((id) => id != null).toSet();
      final deletedIds = _initialQuestionIds.where((id) => !currentIds.contains(id)).toList();

      final deleteFutures = deletedIds.map((id) {
        return Supabase.instance.client.from('survey_question').delete().eq('id', id);
      });

      if (deleteFutures.isNotEmpty) {
        await Future.wait(deleteFutures);
      }

      // 3. Upsert current questions (update existing ones, insert new ones)
      final upsertFutures = <Future>[];
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final qTitle = q.titleController.text.trim();
        if (qTitle.isEmpty) continue;

        final qMap = {
          if (q.id != null) 'id': q.id,
          'event_id': eventId,
          'question_title': qTitle,
          'question_type': q.type.name,
          'sort_order': i,
          'is_required': q.isRequired,
        };

        if (q.type == QuestionType.DROPDOWN || q.type == QuestionType.MULTI_SELECT || q.type == QuestionType.RADIO) {
          final options = q.optionsController.text.trim();
          if (options.isNotEmpty) {
            qMap['options'] = options;
          }
        }
        upsertFutures.add(Supabase.instance.client.from('survey_question').upsert(qMap));
      }

      if (upsertFutures.isNotEmpty) {
        await Future.wait(upsertFutures);
      }

      // 4. Save newly selected contacts as assignments
      if (_selectedContactIds.isNotEmpty) {
        final existingAssignments = await Supabase.instance.client
            .from('assignment')
            .select('contact_id')
            .eq('event_id', eventId);
        final existingContactIds = existingAssignments
            .map((a) => a['contact_id'] as String?)
            .whereType<String>()
            .toSet();

        final newContactIds = _selectedContactIds
            .where((id) => !existingContactIds.contains(id))
            .toList();

        if (newContactIds.isNotEmpty) {
          final creatorContactId = await _ensureUserContactId();
          final auth = AuthService.instance;
          final isAdmin = auth.role == UserRole.ADMIN;
          final activeEnablerList = _enablers.isNotEmpty
              ? _enablers
              : [
                  {'id': creatorContactId, 'name': auth.userName ?? 'Caller'}
                ];

          final assignmentsToInsert = <Map<String, dynamic>>[];
          for (final contactId in newContactIds) {
            String assignedEnablerId;
            if (!isAdmin) {
              assignedEnablerId = creatorContactId;
            } else if (_selectedEnablerOption == 'round_robin') {
              assignedEnablerId = activeEnablerList[
                  assignmentsToInsert.length % activeEnablerList.length]['id'] as String;
            } else if (_selectedEnablerOption == 'csv') {
              assignedEnablerId = creatorContactId;
            } else {
              assignedEnablerId = _selectedEnablerOption;
            }

            assignmentsToInsert.add({
              'event_id': eventId,
              'contact_id': contactId,
              'enabler_id': assignedEnablerId,
              'assigned_by': creatorContactId,
              'status': 'PENDING',
              'sort_order': existingContactIds.length + assignmentsToInsert.length,
            });
          }

          const chunkSize = 200;
          for (int i = 0; i < assignmentsToInsert.length; i += chunkSize) {
            final chunk = assignmentsToInsert.sublist(
                i, (i + chunkSize).clamp(0, assignmentsToInsert.length));
            await Supabase.instance.client.from('assignment').insert(chunk);
          }
        }
      }

      widget.onEventCreated();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update event: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _loadEnablers() async {
    try {
      final client = Supabase.instance.client;
      final auth = AuthService.instance;
      final myId = auth.contactId ?? auth.currentUser?.id;
      final myName = auth.userName ?? 'Myself';

      dynamic query = client
          .from('contact')
          .select('id, name, mobile, role, folk_id')
          .inFilter('role', ['ENABLER', 'FOLK', 'ADMIN', 'FOLK_GUIDE'])
          .eq('is_active', true)
          .order('name');
      if (auth.isFolkGuide && auth.folkGuideId != null) {
        query = query.eq('folk_guide', auth.folkGuideId!);
      }
      final res = await query;
      List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(res);
      if (list.isEmpty && auth.isFolkGuide) {
        final fallbackRes = await client
            .from('contact')
            .select('id, name, mobile, role, folk_id')
            .inFilter('role', ['ENABLER', 'FOLK', 'ADMIN', 'FOLK_GUIDE'])
            .eq('is_active', true)
            .order('name');
        list = List<Map<String, dynamic>>.from(fallbackRes);
      }

      // Ensure current user is in the list
      if (myId != null && !list.any((e) => e['id'] == myId)) {
        list.insert(0, {
          'id': myId,
          'name': myName,
          'mobile': auth.currentUser?.phone ?? '',
          'role': 'ENABLER',
        });
      }

      if (mounted) {
        setState(() {
          _enablers = list;
          if (auth.role != UserRole.ADMIN && myId != null && !_hasCsvEnablerColumn) {
            _selectedEnablerOption = myId;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading enablers: $e');
    }
  }

  void _addCsvQuestionCard() {
    setState(() {
      _csvQuestions.add(QuestionCard(onChanged: () => setState(() {})));
    });
  }

  void _removeCsvQuestionCard(int index) {
    setState(() {
      _csvQuestions[index].dispose();
      _csvQuestions.removeAt(index);
    });
  }

  Future<void> _downloadSampleCsvTemplate() async {
    await CampaignTemplateHelper.downloadSampleCsvTemplate(context);
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return;
      }

      setState(() => _parsingCsv = true);

      final platformFile = result.files.single;
      final file = File(platformFile.path!);
      final csvString = await file.readAsString();
      final List<List<dynamic>> csvData = Csv().decoder.convert(csvString);

      if (csvData.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV must contain headers and at least one contact row.')),
          );
        }
        setState(() => _parsingCsv = false);
        return;
      }

      final rawHeaders = csvData.first.map((e) => e?.toString().trim() ?? '').toList();
      final rows = csvData.skip(1).toList();

      final contactHeaderMap = <String, String>{
        'name': 'name',
        'contactname': 'name',
        'devoteename': 'name',
        'fullname': 'name',
        'studentname': 'name',

        'mobile': 'mobile',
        'contactmobile': 'mobile',
        'phone': 'mobile',
        'phonenumber': 'mobile',
        'mobilenumber': 'mobile',
        'contactno': 'mobile',
        'contactnumber': 'mobile',
        'whatsapp': 'whatsapp',
        'whatsappnumber': 'whatsapp',

        'folkid': 'folk_id',
        'devoteeid': 'folk_id',
        'id': 'folk_id',

        'folkguide': 'folk_guide',
        'guide': 'folk_guide',

        'folklevel': 'folk_level',
        'level': 'folk_level',

        'center': 'center',
        'centre': 'center',

        'gender': 'gender',
        'sex': 'gender',

        'email': 'email',
        'emailaddress': 'email',
        'mail': 'email',

        'city': 'city',
        'town': 'city',

        'state': 'state',
        'country': 'country',
        'occupation': 'occupation',
        'profession': 'occupation',
        'job': 'occupation',

        'address': 'address',
        'contactaddress': 'address',
        'residence': 'address',
        'permanentaddress': 'permanent_address',

        'age': 'age',
        'folkage': 'folk_age',
        'maritalstatus': 'marital_status',
        'stream': 'stream',
        'stay': 'stay',
        'higherqualification': 'higher_qualification',
        'highestqualification': 'highest_qualification',
      };

      final systemSkipHeaders = <String>{
        'callingstatus',
        'status',
        'calloutcome',
        'followupstatus',
        'followupnotes',
        'nextcalldate',
        'calledat',
        'callduration',
        'syncstatus',
        'event',
        'campaignevent',
      };

      final enablerHeaders = <String>{
        'enablerfolkid',
        'enablerid',
        'callerfolkid',
        'callerid',
        'assignedenablerfolkid',
        'assignedenablerid',
        'enabler',
        'enablername',
        'assignedenabler',
        'caller',
        'callername',
        'enablermobile',
      };

      final Map<int, String> contactColMap = {};
      int? enablerColIdx;
      final List<int> surveyColIndices = [];

      for (int i = 0; i < rawHeaders.length; i++) {
        final header = rawHeaders[i];
        if (header.isEmpty) continue;
        final normalized = header.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

        if (systemSkipHeaders.contains(normalized)) {
          continue;
        } else if (enablerHeaders.contains(normalized)) {
          enablerColIdx = i;
        } else if (contactHeaderMap.containsKey(normalized)) {
          contactColMap[i] = contactHeaderMap[normalized]!;
        } else {
          surveyColIndices.add(i);
        }
      }

      for (final q in _csvQuestions) {
        q.dispose();
      }
      _csvQuestions.clear();

      for (final colIdx in surveyColIndices) {
        final rawTitle = rawHeaders[colIdx];
        String title = rawTitle;
        String detectedOptions = '';
        QuestionType detectedType = QuestionType.TEXT;

        final bracketMatch = RegExp(r'[\(\[]([^\)\]]+)[\)\]]$').firstMatch(rawTitle);
        if (bracketMatch != null) {
          final inside = bracketMatch.group(1)!.trim();
          title = rawTitle.substring(0, bracketMatch.start).trim();
          final splitOptions = inside.split(RegExp(r'[,/|;]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          if (splitOptions.length >= 2) {
            detectedOptions = splitOptions.join(', ');
            detectedType = splitOptions.length == 2 ? QuestionType.RADIO : QuestionType.DROPDOWN;
          }
        }

        if (detectedOptions.isEmpty) {
          final distinctValues = <String>{};
          for (final row in rows) {
            if (colIdx < row.length) {
              final val = row[colIdx]?.toString().trim() ?? '';
              if (val.isNotEmpty && val.length <= 40) {
                distinctValues.add(val);
              }
            }
          }

          if (distinctValues.isNotEmpty && distinctValues.length <= 6) {
            detectedOptions = distinctValues.join(', ');
            detectedType = distinctValues.length == 2 ? QuestionType.RADIO : QuestionType.DROPDOWN;
          } else {
            detectedType = QuestionType.TEXT;
          }
        }

        _csvQuestions.add(QuestionCard(
          title: title.isEmpty ? 'Question' : title,
          questionType: detectedType,
          options: detectedOptions,
          required: false,
          onChanged: () => setState(() {}),
        ));
      }

      final List<Map<String, dynamic>> parsedList = [];
      for (final row in rows) {
        final Map<String, dynamic> contactMap = {};
        for (final entry in contactColMap.entries) {
          final colIdx = entry.key;
          final dbKey = entry.value;
          if (colIdx < row.length) {
            final val = row[colIdx]?.toString().trim() ?? '';
            if (val.isNotEmpty) {
              if (dbKey == 'age') {
                contactMap[dbKey] = int.tryParse(val);
              } else if (dbKey == 'mobile' || dbKey == 'whatsapp') {
                final cleaned = val.replaceAll(RegExp(r'[^0-9+]'), '');
                contactMap[dbKey] = cleaned;
              } else {
                contactMap[dbKey] = val;
              }
            }
          }
        }

        if (enablerColIdx != null && enablerColIdx < row.length) {
          final val = row[enablerColIdx]?.toString().trim() ?? '';
          if (val.isNotEmpty) {
            contactMap['enabler_raw'] = val;
          }
        }

        final mobile = (contactMap['mobile'] as String? ?? '').trim();
        final folkId = (contactMap['folk_id'] as String? ?? '').trim();

        // Contact is valid with Mobile or FOLK ID.
        // Name is NOT validated against DB as it may not exactly match.
        if (mobile.isNotEmpty || folkId.isNotEmpty) {
          if (!contactMap.containsKey('name') || (contactMap['name'] as String? ?? '').trim().isEmpty) {
            contactMap['name'] = folkId.isNotEmpty ? 'Devotee $folkId' : (mobile.isNotEmpty ? 'Devotee $mobile' : 'Devotee');
          }
          parsedList.add(contactMap);
        }
      }

      if (_nameController.text.trim().isEmpty) {
        final baseName = platformFile.name.replaceAll(RegExp(r'\.csv$', caseSensitive: false), '');
        final formattedName = baseName.replaceAll(RegExp(r'[_-]'), ' ').trim();
        if (formattedName.isNotEmpty) {
          _nameController.text = formattedName[0].toUpperCase() + formattedName.substring(1);
        }
      }

      setState(() {
        _selectedCsvFile = platformFile;
        _csvFileName = platformFile.name;
        _parsedContacts = parsedList;
        _hasCsvEnablerColumn = enablerColIdx != null;
        if (_hasCsvEnablerColumn) {
          _selectedEnablerOption = 'csv';
        } else if (_selectedEnablerOption == 'csv') {
          final auth = AuthService.instance;
          final myId = auth.contactId ?? auth.currentUser?.id;
          if (auth.role != UserRole.ADMIN && myId != null) {
            _selectedEnablerOption = myId;
          } else {
            _selectedEnablerOption = 'round_robin';
          }
        }
        _parsingCsv = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Parsed ${_parsedContacts.length} contacts and ${_csvQuestions.length} survey questions.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Error picking CSV file: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read CSV file: $e')),
        );
      }
      setState(() => _parsingCsv = false);
    }
  }

  Future<void> _createEventFromCsv() async {
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
    if (_parsedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a CSV with at least one valid contact (Name and Mobile required).')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _csvProgressMessage = 'Creating event...';
    });

    String? newEventId;
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      final creatorContactId = await _ensureUserContactId();

      final timeStr = _selectedTime != null ? _selectedTime!.format(context) : '00:00 AM';

      // 1. Insert Event
      final eventRes = await Supabase.instance.client.from('event').insert({
        'name': name,
        'event_date': _selectedDate!.toIso8601String().split('T')[0],
        'status': 'ACTIVE',
        'created_by': creatorContactId,
        'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        'event_time': timeStr,
        'audience_filter': _audienceFilter,
      }).select().single();

      newEventId = eventRes['id'] as String;

      // 2. Insert survey questions
      setState(() => _csvProgressMessage = 'Saving survey questions...');
      final questionInserts = <Map<String, dynamic>>[];
      for (int i = 0; i < _csvQuestions.length; i++) {
        final q = _csvQuestions[i];
        final qTitle = q.titleController.text.trim();
        if (qTitle.isEmpty) continue;

        final qMap = {
          'event_id': newEventId,
          'question_title': qTitle,
          'question_type': q.type.name,
          'sort_order': i,
          'is_required': q.isRequired,
        };

        if (q.type == QuestionType.DROPDOWN || q.type == QuestionType.MULTI_SELECT || q.type == QuestionType.RADIO) {
          final options = q.optionsController.text.trim();
          if (options.isNotEmpty) {
            qMap['options'] = options;
          }
        }
        questionInserts.add(qMap);
      }

      if (questionInserts.isNotEmpty) {
        await Supabase.instance.client.from('survey_question').insert(questionInserts);
      }

      // 3. Match / Validate contacts in Supabase DB using Mobile and FOLK ID (Name is NOT validated)
      setState(() => _csvProgressMessage = 'Validating contacts in database (${_parsedContacts.length})...');
      final Map<String, Map<String, dynamic>> existingByMobile = {};
      final Map<String, Map<String, dynamic>> existingByFolkId = {};

      final allMobiles = _parsedContacts
          .map((c) => (c['mobile'] as String? ?? '').trim())
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList();

      final allFolkIds = _parsedContacts
          .map((c) => (c['folk_id'] as String? ?? '').trim())
          .where((f) => f.isNotEmpty)
          .toSet()
          .toList();

      const chunkSize = 200;

      // Query existing contacts by Mobile
      for (int i = 0; i < allMobiles.length; i += chunkSize) {
        final chunk = allMobiles.sublist(i, (i + chunkSize).clamp(0, allMobiles.length));
        final existingRows = await Supabase.instance.client
            .from('contact')
            .select('id, name, mobile, folk_id')
            .inFilter('mobile', chunk);
        for (var r in existingRows) {
          final m = r['mobile']?.toString().trim();
          if (m != null && m.isNotEmpty) {
            existingByMobile[m] = Map<String, dynamic>.from(r);
          }
          final f = r['folk_id']?.toString().toLowerCase().trim();
          if (f != null && f.isNotEmpty) {
            existingByFolkId[f] = Map<String, dynamic>.from(r);
          }
        }
      }

      // Query existing contacts by FOLK ID
      for (int i = 0; i < allFolkIds.length; i += chunkSize) {
        final chunk = allFolkIds.sublist(i, (i + chunkSize).clamp(0, allFolkIds.length));
        final existingRows = await Supabase.instance.client
            .from('contact')
            .select('id, name, mobile, folk_id')
            .inFilter('folk_id', chunk);
        for (var r in existingRows) {
          final f = r['folk_id']?.toString().toLowerCase().trim();
          if (f != null && f.isNotEmpty) {
            existingByFolkId[f] = Map<String, dynamic>.from(r);
          }
          final m = r['mobile']?.toString().trim();
          if (m != null && m.isNotEmpty) {
            existingByMobile[m] = Map<String, dynamic>.from(r);
          }
        }
      }

      // Resolve contact IDs for each row:
      // Validation is performed strictly with Mobile and FOLK ID.
      // Name is intentionally NOT validated because names in CSV may differ from Supabase DB.
      final List<String?> resolvedContactIds = List.filled(_parsedContacts.length, null);

      for (int i = 0; i < _parsedContacts.length; i++) {
        final contactData = _parsedContacts[i];
        final mobile = (contactData['mobile'] as String? ?? '').trim();
        final folkId = (contactData['folk_id'] as String? ?? '').toLowerCase().trim();

        Map<String, dynamic>? matchedDbContact;

        if (folkId.isNotEmpty && existingByFolkId.containsKey(folkId)) {
          matchedDbContact = existingByFolkId[folkId];
        } else if (mobile.isNotEmpty && existingByMobile.containsKey(mobile)) {
          matchedDbContact = existingByMobile[mobile];
        }

        if (matchedDbContact != null) {
          resolvedContactIds[i] = matchedDbContact['id'] as String;
        } else if (mobile.isNotEmpty) {
          // If contact does not exist in DB yet, insert as new contact
          final insertData = Map<String, dynamic>.from(contactData);
          insertData.remove('enabler_raw');
          insertData.putIfAbsent('role', () => 'FOLK');
          if ((insertData['name'] as String? ?? '').trim().isEmpty) {
            insertData['name'] = folkId.isNotEmpty ? 'Devotee $folkId' : 'Devotee $mobile';
          }
          try {
            final inserted = await Supabase.instance.client
                .from('contact')
                .insert(insertData)
                .select('id, name, mobile, folk_id')
                .single();
            final insertedMap = Map<String, dynamic>.from(inserted);
            resolvedContactIds[i] = insertedMap['id'] as String;
            existingByMobile[mobile] = insertedMap;
            if (folkId.isNotEmpty) {
              existingByFolkId[folkId] = insertedMap;
            }
          } catch (e) {
            debugPrint('Failed to insert contact $mobile: $e');
          }
        }
      }

      // 4. Create assignments
      setState(() => _csvProgressMessage = 'Assigning contacts to callers...');
      final auth = AuthService.instance;
      final isAdmin = auth.role == UserRole.ADMIN;
      final activeEnablerList = _enablers.isNotEmpty
          ? _enablers
          : [
              {'id': creatorContactId, 'name': auth.userName ?? 'Caller'}
            ];

      final assignmentsToInsert = <Map<String, dynamic>>[];
      final seenContactIds = <String>{};
      for (int i = 0; i < _parsedContacts.length; i++) {
        final cData = _parsedContacts[i];
        final contactId = resolvedContactIds[i];
        if (contactId == null || seenContactIds.contains(contactId)) continue;
        seenContactIds.add(contactId);

        String assignedEnablerId;
        if (!isAdmin) {
          assignedEnablerId = creatorContactId;
        } else if (_selectedEnablerOption == 'csv') {
          final rawEnabler = cData['enabler_raw']?.toString().toLowerCase().trim();
          final matched = activeEnablerList.firstWhere(
            (e) =>
                (e['folk_id'] != null &&
                    e['folk_id'].toString().toLowerCase().trim() == rawEnabler) ||
                (e['name']?.toString().toLowerCase().trim() == rawEnabler) ||
                (e['mobile']?.toString().trim() == rawEnabler),
            orElse: () => activeEnablerList[assignmentsToInsert.length % activeEnablerList.length],
          );
          assignedEnablerId = matched['id'] as String;
        } else if (_selectedEnablerOption == 'round_robin') {
          assignedEnablerId = activeEnablerList[assignmentsToInsert.length % activeEnablerList.length]['id'] as String;
        } else {
          assignedEnablerId = _selectedEnablerOption;
        }

        assignmentsToInsert.add({
          'event_id': newEventId,
          'contact_id': contactId,
          'enabler_id': assignedEnablerId,
          'assigned_by': creatorContactId,
          'status': 'PENDING',
          'sort_order': assignmentsToInsert.length,
        });
      }

      if (assignmentsToInsert.isNotEmpty) {
        for (int i = 0; i < assignmentsToInsert.length; i += chunkSize) {
          final chunk = assignmentsToInsert.sublist(
              i, (i + chunkSize).clamp(0, assignmentsToInsert.length));
          await Supabase.instance.client
              .from('assignment')
              .insert(chunk);
        }

        // Promote assigned contacts with role 'FOLK' to 'ENABLER' so they appear in Enablers lists
        final assignedEnablerIds = assignmentsToInsert
            .map((a) => a['enabler_id'])
            .whereType<String>()
            .toSet()
            .toList();
        if (assignedEnablerIds.isNotEmpty) {
          try {
            await Supabase.instance.client
                .from('contact')
                .update({'role': 'ENABLER'})
                .inFilter('id', assignedEnablerIds)
                .eq('role', 'FOLK');
          } catch (pe) {
            debugPrint('Note: could not auto-promote assigned callers to ENABLER: $pe');
          }
        }
      }

      widget.onEventCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Campaign "$name" created with ${assignmentsToInsert.length} contacts and ${_csvQuestions.length} questions!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Error creating event from CSV: $e\n$st');
      if (newEventId != null) {
        try {
          await Supabase.instance.client.from('event').delete().eq('id', newEventId);
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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

  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _creationMode = EventCreationMode.manual),
              borderRadius: BorderRadius.circular(11.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: _creationMode == EventCreationMode.manual
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: _creationMode == EventCreationMode.manual
                          ? Colors.white
                          : FlutterFlowTheme.of(context).secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Manual Entry',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            color: _creationMode == EventCreationMode.manual
                                ? Colors.white
                                : FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _creationMode = EventCreationMode.csvUpload),
              borderRadius: BorderRadius.circular(11.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: _creationMode == EventCreationMode.csvUpload
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 18,
                      color: _creationMode == EventCreationMode.csvUpload
                          ? Colors.white
                          : FlutterFlowTheme.of(context).secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upload CSV',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            color: _creationMode == EventCreationMode.csvUpload
                                ? Colors.white
                                : FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateQuickBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _creationMode == EventCreationMode.manual
                ? 'Manual Event Creation'
                : 'Upload Contacts & Survey CSV',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 12,
                ),
          ),
          InkWell(
            onTap: _downloadSampleCsvTemplate,
            borderRadius: BorderRadius.circular(6.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    size: 15,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Download Template CSV',
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
        ],
      ),
    );
  }

  Widget _buildTemplateBanner() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              Icons.table_view_rounded,
              color: FlutterFlowTheme.of(context).primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSV Format Reference',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Download our sample CSV template with contacts and survey questions for reference.',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          ElevatedButton.icon(
            onPressed: _downloadSampleCsvTemplate,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text(
              'Download',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCsvUploadBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTemplateBanner(),
          const SizedBox(height: 16.0),
          _buildEventDetailsCard(),
          const SizedBox(height: 20.0),
          _buildCsvPickerCard(),
          if (_selectedCsvFile != null) ...[
            const SizedBox(height: 20.0),
            _buildEnablerAssignmentCard(),
            const SizedBox(height: 20.0),
            _buildCsvQuestionsSection(),
            const SizedBox(height: 20.0),
            _buildContactsPreviewCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCsvPickerCard() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload CSV File',
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'CSV containing contact details and survey questions',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(),
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _downloadSampleCsvTemplate,
                  icon: Icon(Icons.download_rounded, size: 16, color: FlutterFlowTheme.of(context).primary),
                  label: Text(
                    'Download Template',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: BorderSide(color: FlutterFlowTheme.of(context).primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            InkWell(
              onTap: _parsingCsv ? null : _pickCsvFile,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _selectedCsvFile != null
                        ? FlutterFlowTheme.of(context).primary
                        : FlutterFlowTheme.of(context).alternate,
                    width: _selectedCsvFile != null ? 1.5 : 1.0,
                  ),
                ),
                child: _parsingCsv
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedCsvFile != null
                                ? Icons.check_circle_rounded
                                : Icons.cloud_upload_outlined,
                            size: 40,
                            color: _selectedCsvFile != null
                                ? const Color(0xFF10B981)
                                : FlutterFlowTheme.of(context).primary,
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            _selectedCsvFile != null
                                ? _csvFileName ?? 'File Selected'
                                : 'Tap to select CSV file',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _selectedCsvFile != null
                                ? '${(_selectedCsvFile!.size / 1024).toStringAsFixed(1)} KB • Tap to change file'
                                : 'Supports Name, Mobile, and custom Question headers',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                ),
                          ),
                          if (_selectedCsvFile != null) ...[
                            const SizedBox(height: 12.0),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              alignment: WrapAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_parsedContacts.length} Contacts',
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.quiz_rounded, size: 14, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_csvQuestions.length} Questions',
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnablerAssignmentCard() {
    final isAdmin = AuthService.instance.role == UserRole.ADMIN;
    if (!isAdmin) {
      return const SizedBox.shrink();
    }

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
            Row(
              children: [
                Icon(Icons.headset_mic_rounded, color: FlutterFlowTheme.of(context).primary, size: 20),
                const SizedBox(width: 8.0),
                Text(
                  'Assign Contacts To',
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'Choose which caller/enabler receives these contacts in their dialer queue.',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: (_selectedEnablerOption == 'csv' ||
                      _selectedEnablerOption == 'round_robin' ||
                      _enablers.any((e) => e['id'] == _selectedEnablerOption) ||
                      (AuthService.instance.contactId != null &&
                          _selectedEnablerOption == AuthService.instance.contactId))
                  ? _selectedEnablerOption
                  : (AuthService.instance.contactId ?? 'round_robin'),
              dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
              style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
              decoration: InputDecoration(
                labelText: 'Enabler Assignment Mode',
                labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                prefixIcon: Icon(Icons.assignment_ind_rounded, color: FlutterFlowTheme.of(context).accent3),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              items: [
                if (_hasCsvEnablerColumn)
                  const DropdownMenuItem<String>(
                    value: 'csv',
                    child: Text('Match from CSV "Enabler FOLK ID" column',
                        overflow: TextOverflow.ellipsis),
                  ),
                if (AuthService.instance.contactId != null)
                  DropdownMenuItem<String>(
                    value: AuthService.instance.contactId!,
                    child: Text(
                      'Assign all to Myself (${AuthService.instance.userName ?? "You"})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const DropdownMenuItem<String>(
                  value: 'round_robin',
                  child: Text('Auto-distribute equally (Round-Robin)',
                      overflow: TextOverflow.ellipsis),
                ),
                ..._enablers
                    .where((e) => e['id'] != AuthService.instance.contactId)
                    .map((e) {
                  final folkId = e['folk_id'] != null && e['folk_id'].toString().trim().isNotEmpty
                      ? ' (${e['folk_id']})'
                      : '';
                  return DropdownMenuItem<String>(
                    value: e['id'] as String,
                    child: Text('Assign to: ${e['name']}$folkId',
                        overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedEnablerOption = val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCsvQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Survey Questions (${_csvQuestions.length})',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: FlutterFlowTheme.of(context).primary),
              onPressed: _addCsvQuestionCard,
              tooltip: 'Add Survey Question',
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'Questions detected from CSV headers. Customize question types or choices below:',
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.inter(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
        const SizedBox(height: 12.0),
        if (_csvQuestions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: FlutterFlowTheme.of(context).alternate),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 20),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'No survey questions detected in CSV. Tap (+) above to add questions for your callers.',
                    style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_csvQuestions.length, (index) {
            return _buildQuestionCard(index, _csvQuestions[index], isCsv: true);
          }),
      ],
    );
  }

  Widget _buildContactsPreviewCard() {
    final previewList = _parsedContacts.take(5).toList();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contacts Preview',
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
                Text(
                  '${_parsedContacts.length} Total',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            ...previewList.map((contact) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.15),
                      child: Text(
                        (contact['name'] as String? ?? (contact['folk_id'] as String? ?? 'D'))[0].toUpperCase(),
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name'] as String? ?? (contact['folk_id'] != null ? 'FOLK ID: ${contact['folk_id']}' : 'Devotee'),
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                          Text(
                            [
                              if (contact['mobile'] != null && (contact['mobile'] as String).isNotEmpty)
                                contact['mobile'] as String,
                              if (contact['folk_id'] != null && (contact['folk_id'] as String).isNotEmpty)
                                'ID: ${contact['folk_id']}',
                            ].join(' • '),
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (_parsedContacts.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Center(
                  child: Text(
                    '+ ${_parsedContacts.length - 5} more contacts will be imported',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenBody() {
    if (_creationMode == EventCreationMode.csvUpload) {
      return _buildCsvUploadBody();
    }
    return DragTarget<Object>(
      onWillAcceptWithDetails: (data) => true,
      onAcceptWithDetails: (details) {
        HapticFeedback.lightImpact();
        final data = details.data;
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
                const SizedBox(height: 20.0),
                _buildManualContactAssignmentCard(),
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

  Widget _buildManualContactAssignmentCard() {
    final auth = AuthService.instance;
    final myId = auth.contactId ?? auth.currentUser?.id;

    final validOption = _selectedEnablerOption == 'round_robin' ||
        _enablers.any((e) => e['id'] == _selectedEnablerOption) ||
        (myId != null && _selectedEnablerOption == myId);

    final currentOptionValue = validOption
        ? _selectedEnablerOption
        : (myId != null && auth.role != UserRole.ADMIN ? myId : 'round_robin');

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_search_rounded,
                        color: FlutterFlowTheme.of(context).primary, size: 22),
                    const SizedBox(width: 8.0),
                    Text(
                      'Assign Contacts (${_selectedContactIds.length})',
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                    ),
                  ],
                ),
                if (_selectedContactIds.isNotEmpty)
                  InkWell(
                    onTap: _clearSelectedContacts,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'Search and pick contacts from your database to assign to this campaign.',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
            const SizedBox(height: 16.0),

            // Search input
            TextField(
              controller: _contactSearchCtrl,
              onChanged: (val) => _searchContacts(val),
              style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
              decoration: InputDecoration(
                hintText: 'Search by Name, Mobile, FOLK ID, or City...',
                hintStyle: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded,
                    color: FlutterFlowTheme.of(context).accent3, size: 20),
                suffixIcon: _contactSearchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _contactSearchCtrl.clear();
                          _searchContacts('');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: FlutterFlowTheme.of(context).alternate),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: FlutterFlowTheme.of(context).primary),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // Quick Actions: Select all searched, Results count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchingContacts
                      ? 'Searching...'
                      : '${_searchedContacts.length} contacts found',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 12,
                  ),
                ),
                if (_searchedContacts.isNotEmpty)
                  InkWell(
                    onTap: _selectAllSearchedContacts,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.select_all_rounded,
                              size: 16,
                              color: FlutterFlowTheme.of(context).primary),
                          const SizedBox(width: 4),
                          Text(
                            'Select All Filtered',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10.0),

            // Selected Contacts Chips Carousel/List
            if (_selectedContactObjects.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 110),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                  border:
                      Border.all(color: FlutterFlowTheme.of(context).alternate),
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: _selectedContactObjects.map((c) {
                      final name = (c['name'] as String? ?? 'Contact');
                      final mobile = (c['mobile'] as String? ?? '');
                      return Chip(
                        backgroundColor:
                            FlutterFlowTheme.of(context).secondaryBackground,
                        side: BorderSide(
                            color: FlutterFlowTheme.of(context).primary),
                        label: Text(
                          '$name ($mobile)',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 11,
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        deleteIconColor: Colors.redAccent,
                        onDeleted: () => _toggleContactSelection(c),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
            ],

            // Searched Contacts Picker List
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: BorderRadius.circular(8.0),
                border:
                    Border.all(color: FlutterFlowTheme.of(context).alternate),
              ),
              child: _searchingContacts
                  ? const Center(child: CircularProgressIndicator())
                  : _searchedContacts.isEmpty
                      ? Center(
                          child: Text(
                            'No contacts found',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _searchedContacts.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          itemBuilder: (context, index) {
                            final contact = _searchedContacts[index];
                            final id = contact['id'] as String;
                            final isSelected = _selectedContactIds.contains(id);
                            final name = contact['name'] as String? ?? 'Contact';
                            final mobile = contact['mobile'] as String? ?? '';
                            final folkId = contact['folk_id'] as String? ?? '';
                            final city = contact['city'] as String? ?? '';

                            return InkWell(
                              onTap: () => _toggleContactSelection(contact),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_box_rounded
                                          : Icons.check_box_outline_blank_rounded,
                                      color: isSelected
                                          ? FlutterFlowTheme.of(context).primary
                                          : FlutterFlowTheme.of(context)
                                              .secondaryText,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: FlutterFlowTheme.of(context)
                                                  .primaryText,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Row(
                                            children: [
                                              if (mobile.isNotEmpty) ...[
                                                Text(
                                                  mobile,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              if (folkId.isNotEmpty) ...[
                                                Text(
                                                  'ID: $folkId',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .accent3,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              if (city.isNotEmpty) ...[
                                                Text(
                                                  city,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16.0),

            // Enabler Assignment Dropdown for selected contacts (Admin only)
            if (AuthService.instance.role == UserRole.ADMIN && _selectedContactIds.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: currentOptionValue,
                dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
                style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                decoration: InputDecoration(
                  labelText: 'Assign Selected Contacts To',
                  labelStyle: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText),
                  prefixIcon: Icon(Icons.assignment_ind_rounded,
                      color: FlutterFlowTheme.of(context).accent3),
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
                items: [
                  if (AuthService.instance.contactId != null)
                    DropdownMenuItem<String>(
                      value: AuthService.instance.contactId!,
                      child: Text(
                        'Assign all to Myself (${AuthService.instance.userName ?? "You"})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const DropdownMenuItem<String>(
                    value: 'round_robin',
                    child: Text('Auto-distribute equally (Round-Robin)',
                        overflow: TextOverflow.ellipsis),
                  ),
                  ..._enablers
                      .where((e) => e['id'] != AuthService.instance.contactId)
                      .map((e) {
                    final folkId = e['folk_id'] != null &&
                            e['folk_id'].toString().trim().isNotEmpty
                        ? ' (${e['folk_id']})'
                        : '';
                    return DropdownMenuItem<String>(
                      value: e['id'] as String,
                      child: Text('Assign to: ${e['name']}$folkId',
                          overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedEnablerOption = val);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, QuestionCard card, {bool isCsv = false}) {
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
                      if (!isCsv)
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: FlutterFlowTheme.of(context).accent3,
                          ),
                        )
                      else
                        Icon(
                          typeIcon,
                          size: 18,
                          color: typeColor,
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
                                onTap: () => isCsv ? _removeCsvQuestionCard(index) : _removeQuestionCard(index),
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
          widget.eventToEdit == null ? 'Create New Event' : 'Edit Event',
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
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: FlutterFlowTheme.of(context).primary),
            tooltip: 'Download Template CSV',
            onPressed: _downloadSampleCsvTemplate,
          ),
          TextButton(
            onPressed: _saving
                ? null
                : (widget.eventToEdit == null
                    ? (_creationMode == EventCreationMode.csvUpload
                        ? _createEventFromCsv
                        : _createEvent)
                    : _updateEvent),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    widget.eventToEdit == null ? 'Create' : 'Save',
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
          Column(
            children: [
              if (widget.eventToEdit == null) ...[
                _buildModeSwitcher(),
                _buildTemplateQuickBar(),
              ],
              Expanded(
                child: _buildFullScreenBody(),
              ),
            ],
          ),

          if (_creationMode == EventCreationMode.manual && _isMenuOpen)
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

          if (_creationMode == EventCreationMode.manual)
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

          if (_creationMode == EventCreationMode.manual && _isMenuOpen && _isPresetsOpen)
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

          if (_saving)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Card(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _csvProgressMessage ?? 'Saving event...',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _creationMode == EventCreationMode.csvUpload
          ? null
          : FloatingActionButton(
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
