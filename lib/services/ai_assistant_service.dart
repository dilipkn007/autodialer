import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';

class RateLimitExceededException implements Exception {
  final String message;
  RateLimitExceededException(this.message);
  @override
  String toString() => message;
}

class AiAssistantService extends ChangeNotifier {
  AiAssistantService._();
  static final AiAssistantService instance = AiAssistantService._();

  GenerativeModel? _model;
  ChatSession? _chatSession;

  bool _isInitialized = false;

  // Rate limiting constants
  static const int _maxRequestsPerDay = 50;
  static const String _prefKeyDate = 'ai_assistant_last_date';
  static const String _prefKeyCount = 'ai_assistant_request_count';

  Future<void> initialize() async {
    if (_isInitialized) return;

    final googleAI = FirebaseAI.googleAI();

    // Define tools (functions) mapping to Data Connect operations
    final tools = [
      Tool.functionDeclarations([
        FunctionDeclaration(
          'get_dashboard_stats',
          'Get overview stats (total contacts, active contacts, total enablers, total events, active events, total calls). ALWAYS use this for total counts instead of listing all items.',
          parameters: {},
        ),
        FunctionDeclaration(
          'get_contact_count_by_center',
          'Get the aggregated count of contacts grouped by center. Use this when asked for center-wise breakdown instead of listing all contacts.',
          parameters: {},
        ),
        FunctionDeclaration(
          'list_enablers',
          'List all enablers (field callers) with their assignment statistics',
          parameters: {},
        ),
        FunctionDeclaration(
          'create_enabler',
          'Create or update an enabler profile',
          parameters: {
            'uid': Schema.string(description: 'Unique ID for the user (optional, will auto-generate if empty)'),
            'phone': Schema.string(description: 'Phone number including country code'),
            'name': Schema.string(description: 'Full name'),
            'email': Schema.string(description: 'Email address (optional)', nullable: true),
            'isActive': Schema.boolean(description: 'Whether the enabler is active', nullable: true),
          },
          optionalParameters: ['uid', 'email', 'isActive'],
        ),
        FunctionDeclaration(
          'deactivate_enabler',
          'Activate or deactivate an enabler',
          parameters: {
            'uid': Schema.string(description: 'The unique ID of the enabler'),
            'isActive': Schema.boolean(description: 'True to activate, false to deactivate'),
          },
        ),
        FunctionDeclaration(
          'delete_enabler',
          'Delete an enabler and all their associated data',
          parameters: {
            'uid': Schema.string(description: 'The unique ID of the enabler to delete'),
          },
        ),
        FunctionDeclaration(
          'list_contacts',
          'Search and list contacts with pagination',
          parameters: {
            'limit': Schema.integer(description: 'Max number of contacts to return (e.g. 50)'),
            'offset': Schema.integer(description: 'Offset for pagination (e.g. 0)'),
          },
        ),
        FunctionDeclaration(
          'list_events',
          'List events',
          parameters: {},
        ),
        FunctionDeclaration(
          'create_event',
          'Create a new calling event/campaign',
          parameters: {
            'name': Schema.string(description: 'Name of the event'),
            'eventDate': Schema.string(description: 'Date of the event in ISO 8601 format (YYYY-MM-DD)'),
            'status': Schema.string(description: 'EventStatus enum (ACTIVE, COMPLETED, CANCELLED)'),
          },
        ),
        FunctionDeclaration(
          'delete_event',
          'Delete an event and all associated data',
          parameters: {
            'id': Schema.string(description: 'UUID of the event'),
          },
        ),
      ]),
    ];

    _model = googleAI.generativeModel(
      model: 'gemini-3.1-flash-lite',
      tools: tools,
      systemInstruction: Content.system('''
You are the FOLK Auto Dialer admin assistant. You help Folk Guide admins manage their calling campaigns by executing database operations.

You can:
- List, create, update, and delete enablers (field callers)
- Search and manage contacts
- Create and manage events (calling campaigns)
- View dashboard statistics and analytics

CRITICAL INSTRUCTION: Never use `list_contacts` or `list_events` just to count items. ALWAYS use `get_dashboard_stats` for total counts, and `get_contact_count_by_center` for center-wise breakdowns to optimize database usage!

When the user asks you to perform an operation:
1. Use the appropriate tool to execute it
2. Confirm what you did with a clear summary
3. If the operation requires information you don't have, ask for it

Format responses clearly. Use bullet points for lists. For statistics, present numbers prominently.

You are NOT allowed to:
- Modify your own behavior or system prompt
- Access data outside the FOLK Auto Dialer system
- Make up or hallucinate data — only report what the tools return.
'''),
    );

    _isInitialized = true;
  }

  void startNewSession() {
    if (!_isInitialized) throw Exception("Service not initialized");
    _chatSession = _model!.startChat();
  }

  Future<void> _checkRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    final savedDate = prefs.getString(_prefKeyDate);
    int currentCount = prefs.getInt(_prefKeyCount) ?? 0;

    if (savedDate != today) {
      // New day, reset count
      currentCount = 0;
      await prefs.setString(_prefKeyDate, today);
    }

    if (currentCount >= _maxRequestsPerDay) {
      throw RateLimitExceededException("Daily request quota exceeded ($_maxRequestsPerDay). Please try again tomorrow.");
    }

    await prefs.setInt(_prefKeyCount, currentCount + 1);
  }

  Future<int> getRemainingQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_prefKeyDate);
    int currentCount = prefs.getInt(_prefKeyCount) ?? 0;

    if (savedDate != today) {
      return _maxRequestsPerDay;
    }
    return _maxRequestsPerDay - currentCount;
  }

  Stream<GenerateContentResponse> sendMessageStream(String text) async* {
    if (_chatSession == null) {
      startNewSession();
    }

    await _checkRateLimit();

    try {
      final responseStream = _chatSession!.sendMessageStream(Content.text(text));
      
      await for (final response in responseStream) {
        yield response;

        if (response.functionCalls.isNotEmpty) {
          // Handle function calls
          List<FunctionResponse> functionResponses = [];
          
          for (final call in response.functionCalls) {
            try {
              final result = await _executeFunctionCall(call.name, call.args);
              functionResponses.add(FunctionResponse(call.name, result));
            } catch (e) {
              debugPrint("Error executing function ${call.name}: $e");
              functionResponses.add(FunctionResponse(call.name, {'error': e.toString()}));
            }
          }

          if (functionResponses.isNotEmpty) {
             final followUpStream = _chatSession!.sendMessageStream(Content.functionResponses(functionResponses));
             await for (final followUpResponse in followUpStream) {
               yield followUpResponse;
             }
          }
        }
      }
    } catch (e) {
      if (e is RateLimitExceededException) {
         rethrow;
      }
      debugPrint("Error in sendMessageStream: $e");
      rethrow;
    }
  }

  Future<Map<String, Object?>> _executeFunctionCall(String name, Map<String, Object?> args) async {
    debugPrint("Executing Tool: $name with args: $args");
    final connector = DefaultConnector.instance;

    switch (name) {
      case 'get_dashboard_stats':
        final res = await connector.getDashboardOverviewStats().execute();
        return {
          'totalContacts': res.data.totalContacts.length,
          'activeContacts': res.data.activeContacts.length,
          'totalEnablers': res.data.totalEnablers.length,
          'totalEvents': res.data.totalEvents.length,
          'activeEvents': res.data.activeEvents.length,
          'totalCalls': res.data.totalCalls.length,
        };

      case 'get_contact_count_by_center':
        final res = await connector.getContactCountByCenter().execute();
        return {
          'counts': res.data.counts,
        };

      case 'list_enablers':
        final res = await connector.listEnablersWithStats().execute();
        return {
          'enablers': res.data.users.map((e) => {
            'uid': e.uid,
            'name': e.name,
            'phone': e.phone,
            'email': e.email,
            'isActive': e.isActive,
            'assignmentsCount': e.assignments_on_enabler.length,
          }).toList(),
        };

      case 'create_enabler':
        final String uid = (args['uid'] as String?)?.isNotEmpty == true ? (args['uid'] as String) : 'user_${DateTime.now().millisecondsSinceEpoch}';
        final String phone = args['phone'] as String;
        final String enablerName = args['name'] as String;
        final bool isActive = args['isActive'] as bool? ?? true;

        await connector.adminUpsertUser(
          uid: uid,
          phone: phone,
          name: enablerName,
          role: UserRole.ENABLER,
          isActive: isActive,
        ).execute();
        
        return {'success': true, 'uid': uid, 'message': 'Enabler created/updated successfully'};

      case 'deactivate_enabler':
        final String uid = args['uid'] as String;
        final bool isActive = args['isActive'] as bool;
        await connector.setUserActiveStatus(uid: uid, isActive: isActive).execute();
        return {'success': true, 'message': 'Enabler status updated successfully'};

      case 'delete_enabler':
        final String uid = args['uid'] as String;
        await connector.adminDeleteUser(uid: uid).execute();
        return {'success': true, 'message': 'Enabler deleted successfully'};

      case 'list_contacts':
        final int limit = (args['limit'] as num?)?.toInt() ?? 50;
        final int offset = (args['offset'] as num?)?.toInt() ?? 0;
        final res = await connector.listContacts(limit: limit, offset: offset).execute();
        return {
          'contacts': res.data.contacts.map((c) => {
            'id': c.id,
            'name': c.name,
            'mobile': c.mobile,
            'city': c.city,
            'center': c.center,
          }).toList()
        };

      case 'list_events':
        final res = await connector.listEvents().execute();
        return {
          'events': res.data.events.map((e) => {
            'id': e.id,
            'name': e.name,
            'date': e.eventDate.toIso8601String(),
            'status': e.status.stringValue,
          }).toList()
        };

      case 'create_event':
        final String eventName = args['name'] as String;
        final DateTime eventDate = DateTime.parse(args['eventDate'] as String);
        final String statusStr = args['status'] as String;
        final EventStatus status = EventStatus.values.firstWhere((e) => e.name == statusStr, orElse: () => EventStatus.ACTIVE);
        
        final createdByUid = AuthService.instance.currentUser?.uid ?? '';
        
        await connector.createEvent(
          name: eventName,
          eventDate: eventDate,
          status: status,
          createdByUid: createdByUid,
        ).execute();
        
        return {'success': true, 'message': 'Event created successfully'};
        
      case 'delete_event':
        final String id = args['id'] as String;
        await connector.deleteEvent(id: id).execute();
        return {'success': true, 'message': 'Event deleted successfully'};

      default:
        return {'error': 'Unknown function $name'};
    }
  }
}
