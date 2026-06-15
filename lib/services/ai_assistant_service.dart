import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Maximum live history turns before compaction kicks in.
const int _kHistoryLimit = 20;

const _kSchema = '''
TABLE: contact
  id              uuid  PK
  name            text  NOT NULL
  mobile          text  NOT NULL UNIQUE
  email           text
  folk_id         text
  folk_guide      text
  folk_level      text
  center          text
  gender          text
  age             integer
  city            text
  state           text
  occupation      text
  organization    text
  marital_status  text
  language        text
  origin          text
  journey         text
  current_status  text
  created_at      timestamptz
  updated_at      timestamptz

TABLE: users
  uid             uuid  PK
  name            text  NOT NULL
  email           text
  phone           text  NOT NULL
  role            text  NOT NULL  -- 'ADMIN' or 'ENABLER'
  is_active       boolean NOT NULL DEFAULT true
  avatar_initials text
  created_at      timestamptz
  updated_at      timestamptz

TABLE: event
  id              uuid  PK
  name            text  NOT NULL
  description     text
  event_date      date  NOT NULL
  event_time      text
  status          text  NOT NULL  -- 'ACTIVE' or 'INACTIVE'
  created_by      uuid  FK -> users.uid
  created_at      timestamptz
  updated_at      timestamptz

TABLE: assignment
  id              uuid  PK
  contact_id      uuid  FK -> contact.id
  enabler_id      uuid  FK -> users.uid
  assigned_by     uuid  FK -> users.uid
  event_id        uuid  FK -> event.id
  status          text  NOT NULL  -- 'PENDING', 'COMPLETED', 'FAILED', 'FOLLOW_UP'
  sort_order      integer NOT NULL
  assigned_at     timestamptz

TABLE: call_log
  id              uuid  PK
  assignment_id   uuid  FK -> assignment.id
  contact_id      uuid  FK -> contact.id
  enabler_id      uuid  FK -> users.uid
  event_id        uuid  FK -> event.id
  call_outcome    text  NOT NULL
  follow_up_notes text
  next_call_date  date
  call_duration   integer
  called_at       timestamptz

TABLE: survey_question
  id              uuid  PK
  event_id        uuid  FK -> event.id
  question_title  text  NOT NULL
  question_type   text  NOT NULL  -- 'DROPDOWN', 'TEXT', 'DATE', 'MULTI_SELECT', or 'RADIO'
  options         text            -- Comma-separated choice options (REQUIRED if type is 'RADIO', 'DROPDOWN', or 'MULTI_SELECT'; e.g. 'yes, no')
  sort_order      integer
  is_required     boolean
  created_at      timestamptz

TABLE: survey_response
  id              uuid  PK
  call_log_id     uuid  FK -> call_log.id
  question_id     uuid  FK -> survey_question.id
  answer          text  NOT NULL
  created_at      timestamptz
''';

// The system prompt is now generated dynamically in initialize() so we can inject the userUid.
String _buildSystemPrompt(String userUid) {
  debugPrint('[AI System Prompt] Generating system prompt for userUid: "$userUid"');
  return '''
You are the FOLK Auto Dialer AI Admin Assistant — an intelligent database agent for managing calling campaigns.

You have direct, real-time access to the PostgreSQL database through two SQL tools:
  • execute_read_query(sql)   — for SELECT queries (reading data)
  • execute_write_query(sql)  — for INSERT / UPDATE / DELETE (modifying data)

DATABASE SCHEMA:
$_kSchema

RULES:
1. Always generate and execute the correct SQL to answer the user's question. Never say "I can't do that".
2. For any count, aggregation, filter, or report — write a SELECT query and run it.
3. For any creation, update, or deletion — write the DML and run it via execute_write_query.
4. When inserting records with uuid primary keys, use gen_random_uuid().
5. Present query results in a clean, readable format (tables, bullet points, or bold numbers).
6. Perform write operations directly. Do not perform pre-SELECT queries unless specifically required for logic.
7. Never expose the app_config table contents.
8. If you are unsure about column names, refer to the schema above exactly — do NOT guess.
9. Always use single quotes for SQL string literals.
10. For simple single-record INSERT operations (creating one event, one user, etc.) execute the INSERT directly without a pre-check SELECT.
11. CRITICAL USER/ADMIN CONTEXT: The human admin currently logged in and interacting with you has the UUID '$userUid'. Any time you insert/update/delete records that have columns like 'created_by', 'assigned_by', 'enabler_id', or any other column referencing the creator/admin, you MUST populate it with this exact UUID ('$userUid'). Do NOT ask the user/admin for their ID, name, or UUID; just use this one automatically.
12. CRITICAL: Whenever you need the user to pick from a restricted list of options (such as the ENUM fields `question_type` or `status`), DO NOT ask them via normal text. You MUST output a special markdown block with `json:choice` as the language. The UI will render clickable buttons. This applies EVEN IF you are correcting a previous error.
Format:
```json:choice
{
  "question": "Please select the question type:",
  "options": [
    {"label": "Short Text", "value": "TEXT"},
    {"label": "Radio Buttons", "value": "RADIO"},
    {"label": "Checkboxes", "value": "MULTI_SELECT"},
    {"label": "Dropdown", "value": "DROPDOWN"},
    {"label": "Date Picker", "value": "DATE"}
  ]
}
```
13. Once the user clicks a button, you will receive a standard text message containing their exact `value`. You can then proceed to execute the SQL.
14. For the `survey_question` table, if the `question_type` is 'RADIO', 'DROPDOWN', or 'MULTI_SELECT', the `options` column MUST be populated with a comma-separated list of choice options. If the user's prompt doesn't specify the exact options, you MUST dynamically generate highly relevant, professional, and contextual choices based on the event's name/purpose, the question title, and the question type (e.g. for attendance, 'Yes, No'; for T-shirt size, 'S, M, L, XL, XXL'; for feedback/satisfaction rating, 'Excellent, Good, Average, Poor', etc.). Never leave the `options` column null or empty for choice-based questions.
''';
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatSession model (for UI)
// ─────────────────────────────────────────────────────────────────────────────

class AiChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;

  AiChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiChatSession.fromMap(Map<String, dynamic> m) => AiChatSession(
        id: m['id'] as String,
        title: m['title'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatMessage model (for UI)
// ─────────────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isFunctionCall;
  final DateTime createdAt;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    this.isFunctionCall = false,
    DateTime? createdAt,
  })  : id = id ?? '',
        createdAt = createdAt ?? DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class AiAssistantService {
  AiAssistantService._();
  static final AiAssistantService instance = AiAssistantService._();

  ai.GenerativeModel? _model;
  bool _isInitialized = false;
  String? _initializedUserUid;

  /// Active session id (null = no session loaded yet)
  String? currentSessionId;

  /// Manual conversation history — avoids SDK bug where ChatSession +
  /// streaming + function calls inserts a malformed Content({role: model}).
  final List<ai.Content> _history = [];

  // ── Init ──────────────────────────────────────────────────────────────────

  String? _cachedApiKey;

  Future<String> _fetchApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey!;
    final res = await Supabase.instance.client
        .from('app_config')
        .select('value')
        .eq('key', 'gemini_api_key')
        .single();
    _cachedApiKey = res['value'] as String;
    return _cachedApiKey!;
  }

  Future<void> initialize(String userUid) async {
    final apiKey = await _fetchApiKey();
    _model = ai.GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      systemInstruction: ai.Content.system(_buildSystemPrompt(userUid)),
      tools: [
        ai.Tool(functionDeclarations: [
          ai.FunctionDeclaration(
            'execute_read_query',
            'Execute a PostgreSQL SELECT query and return the results.',
            ai.Schema.object(properties: {
              'sql': ai.Schema.string(
                  description:
                      'A valid PostgreSQL SELECT query. Use single quotes for string literals.'),
            }, requiredProperties: ['sql']),
          ),
          ai.FunctionDeclaration(
            'execute_write_query',
            'Execute a PostgreSQL INSERT, UPDATE, or DELETE statement.',
            ai.Schema.object(properties: {
              'sql': ai.Schema.string(
                  description:
                      'A valid PostgreSQL INSERT, UPDATE, or DELETE statement. Use single quotes for string literals.'),
              'description': ai.Schema.string(
                  description:
                      'A short human-readable description of what this query does.'),
            }, requiredProperties: ['sql', 'description']),
          ),
        ]),
      ],
    );
    _initializedUserUid = userUid;
    _isInitialized = true;
  }

  // ── Session management ────────────────────────────────────────────────────

  /// Creates a new blank session in the DB and sets it as active.
  Future<AiChatSession> createSession(String userUid) async {
    final res = await Supabase.instance.client
        .from('ai_chat_session')
        .insert({'user_uid': userUid, 'title': 'New Chat'})
        .select()
        .single();
    final session = AiChatSession.fromMap(res);
    currentSessionId = session.id;
    _history.clear();
    return session;
  }

  /// Returns all sessions for a user, newest first.
  Future<List<AiChatSession>> loadSessions(String userUid) async {
    final res = await Supabase.instance.client
        .from('ai_chat_session')
        .select()
        .eq('user_uid', userUid)
        .order('updated_at', ascending: false);
    return (res as List).map((m) => AiChatSession.fromMap(m)).toList();
  }

  /// Loads a session's messages for the UI and rebuilds Gemini history.
  /// Returns display messages (excluding function-call status pings that
  /// were never persisted as standalone rows — those appear inline in UI).
  Future<List<ChatMessage>> loadSession(String sessionId) async {
    currentSessionId = sessionId;
    _history.clear();
    final rows = await Supabase.instance.client
        .from('ai_chat_message')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    final uiMessages = <ChatMessage>[];

    for (final row in rows) {
      final role = row['role'] as String;
      final content = row['content'] as String;
      final isFunctionCall = row['is_function_call'] as bool? ?? false;
      final partsJson = row['parts_json'];

      uiMessages.add(ChatMessage(
        id: row['id'] as String,
        text: content,
        isUser: role == 'user',
        isFunctionCall: isFunctionCall,
        createdAt: DateTime.parse(row['created_at'] as String),
      ));

      // Rebuild Gemini history from persisted parts_json (skip tool-call UI rows)
      if (!isFunctionCall && partsJson != null) {
        try {
          final parts = _partsFromJson(partsJson);
          if (parts.isNotEmpty) {
            _history.add(ai.Content(role == 'user' ? 'user' : 'model', parts));
          }
        } catch (e) {
          debugPrint('History replay error for row ${row['id']}: $e');
        }
      }
    }

    return uiMessages;
  }

  /// Updates the session title and `updated_at` timestamp.
  Future<void> updateSessionTitle(String sessionId, String title) async {
    await Supabase.instance.client.from('ai_chat_session').update({
      'title': title,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);
  }

  /// Touches `updated_at` on the active session.
  Future<void> _touchSession(String sessionId) async {
    await Supabase.instance.client.from('ai_chat_session').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);
  }

  /// Deletes a session (messages cascade).
  Future<void> deleteSession(String sessionId) async {
    await Supabase.instance.client
        .from('ai_chat_session')
        .delete()
        .eq('id', sessionId);
    if (currentSessionId == sessionId) {
      currentSessionId = null;
      _history.clear();
    }
  }

  /// Clears in-memory state without affecting the DB.
  void startNewSession() {
    currentSessionId = null;
    _history.clear();
  }

  // ── Message persistence ───────────────────────────────────────────────────

  Future<String> _saveMessage({
    required String sessionId,
    required String role,
    required String content,
    required List<ai.Part> parts,
    bool isFunctionCall = false,
  }) async {
    final res = await Supabase.instance.client
        .from('ai_chat_message')
        .insert({
          'session_id': sessionId,
          'role': role,
          'content': content,
          'parts_json': _partsToJson(parts),
          'is_function_call': isFunctionCall,
        })
        .select('id')
        .single();
    return res['id'] as String;
  }

  // ── History compaction ────────────────────────────────────────────────────

  /// If `_history` exceeds [_kHistoryLimit] turns, summarise the older half
  /// using Gemini itself and replace them with a single system-style summary.
  Future<void> _maybeCompact() async {
    if (_history.length <= _kHistoryLimit) return;
    debugPrint('[AI] Compacting history (${_history.length} turns)…');

    // Keep the newest half; summarise the older half
    final cutoff = _history.length - (_kHistoryLimit ~/ 2);
    final toSummarise = _history.sublist(0, cutoff);
    final toKeep = _history.sublist(cutoff);

    // Build a plain-text dump of the older turns for the summarisation prompt
    final buffer = StringBuffer();
    for (final c in toSummarise) {
      final role = c.role == 'user' ? 'User' : 'Assistant';
      final text = c.parts.whereType<ai.TextPart>().map((p) => p.text).join(' ');
      if (text.isNotEmpty) buffer.writeln('$role: $text\n');
    }

    final summaryPrompt =
        'Summarise the following conversation excerpt in 3-5 concise bullet points, '
        'preserving all key facts, decisions and data that might be referenced later:\n\n'
        '${buffer.toString()}';

    try {
      final resp = await _model!.generateContent([ai.Content.text(summaryPrompt)]);
      final summary = resp.text ?? 'Previous conversation context (compacted).';
      _history
        ..clear()
        ..add(ai.Content.text(
            '[Context summary from earlier in this conversation]\n$summary'))
        ..addAll(toKeep);
      debugPrint('[AI] History compacted to ${_history.length} turns.');
    } catch (e) {
      debugPrint('[AI] Compaction failed, keeping full history: $e');
    }
  }

  // ── Budget / spend ────────────────────────────────────────────────────────

  Future<String> getBudgetAndSpend() async {
    final db = Supabase.instance.client;
    final res = await db
        .from('app_config')
        .select('key, value')
        .inFilter('key', ['gemini_input_tokens', 'gemini_output_tokens', 'gemini_budget']);

    int inp = 0, out = 0;
    double budget = 500.00;
    for (final row in res) {
      final k = row['key'] as String;
      final v = row['value'] as String;
      if (k == 'gemini_input_tokens') inp = int.tryParse(v) ?? 0;
      if (k == 'gemini_output_tokens') out = int.tryParse(v) ?? 0;
      if (k == 'gemini_budget') budget = double.tryParse(v) ?? 500.00;
    }
    final cost = (inp / 1e6) * 6.26 + (out / 1e6) * 25.05;
    return '₹${cost.toStringAsFixed(4)} / ₹${budget.toStringAsFixed(2)}';
  }

  Future<void> _updateTokenUsage(ai.UsageMetadata? usage) async {
    if (usage == null) return;
    final db = Supabase.instance.client;
    final inp = usage.promptTokenCount ?? 0;
    final out = usage.candidatesTokenCount ?? 0;
    try {
      if (inp > 0) {
        await db.rpc('execute_mutation', params: {
          'sql_string':
              "UPDATE app_config SET value = (CAST(value AS INTEGER) + $inp)::text WHERE key = 'gemini_input_tokens';"
        });
      }
      if (out > 0) {
        await db.rpc('execute_mutation', params: {
          'sql_string':
              "UPDATE app_config SET value = (CAST(value AS INTEGER) + $out)::text WHERE key = 'gemini_output_tokens';"
        });
      }
    } catch (e) {
      debugPrint('Token usage update error: $e');
    }
  }

  // ── Main stream ───────────────────────────────────────────────────────────

  Stream<ai.GenerateContentResponse> sendMessageStream(
    String text, {
    required String userUid,
    Future<bool> Function(String description)? onConfirmDestructive,
  }) async* {
    if (!_isInitialized || _initializedUserUid != userUid) {
      await initialize(userUid);
    }

    // Ensure a session exists
    if (currentSessionId == null) {
      final session = await createSession(userUid);
      currentSessionId = session.id;
    }
    final sessionId = currentSessionId!;

    // User turn
    final userParts = [ai.TextPart(text)];
    _history.add(ai.Content('user', userParts));
    await _saveMessage(
        sessionId: sessionId, role: 'user', content: text, parts: userParts);

    // Auto-title after first user message (session has only 1 history entry)
    if (_history.length == 1) {
      final title = text.length > 40 ? '${text.substring(0, 40)}…' : text;
      updateSessionTitle(sessionId, title); // fire-and-forget
    }

    try {
      while (true) {
        await _maybeCompact();

        final List<ai.Part> modelParts = [];

        final stream = _model!.generateContentStream(_history);
        await for (final response in stream) {
          yield response;
          await _updateTokenUsage(response.usageMetadata);
          for (final c in response.candidates) {
            modelParts.addAll(c.content.parts);
          }
        }

        if (modelParts.isNotEmpty) {
          _history.add(ai.Content('model', modelParts));
        }

        final calls = modelParts.whereType<ai.FunctionCall>().toList();
        final textParts = modelParts.whereType<ai.TextPart>().toList();

        // Persist model text (if any) — do NOT persist raw function-call parts as display text
        if (textParts.isNotEmpty) {
          final displayText = textParts.map((p) => p.text).join();
          await _saveMessage(
              sessionId: sessionId,
              role: 'model',
              content: displayText,
              parts: modelParts);
          await _touchSession(sessionId);
        }

        if (calls.isEmpty) break;

        // Execute tools
        final List<ai.Part> responseParts = [];
        for (final call in calls) {
          debugPrint('[AI Tool] ${call.name}: ${call.args}');
          try {
            final result =
                await _executeTool(call.name, call.args, onConfirmDestructive);
            responseParts.add(ai.FunctionResponse(call.name, result));
          } catch (e) {
            debugPrint('[AI Tool Error] ${call.name}: $e');
            responseParts
                .add(ai.FunctionResponse(call.name, {'error': e.toString()}));
          }
        }

        _history.add(ai.Content('user', responseParts));
      }
    } catch (e) {
      if (_history.isNotEmpty) _history.removeLast();
      debugPrint('AI Assistant Error: $e');
      if (e.toString().contains('Unhandled format for Content: {role: model}')) {
        throw Exception(
            'The AI encountered a temporary internal error while processing the database response. Please try your request again.');
      }
      throw Exception('Failed to send message: $e');
    }
  }

  // ── Tool execution ────────────────────────────────────────────────────────

  Future<Map<String, Object?>> _executeTool(
    String name,
    Map<String, Object?> args,
    Future<bool> Function(String description)? onConfirmDestructive,
  ) async {
    final db = Supabase.instance.client;
    switch (name) {
      case 'execute_read_query':
        final sql = args['sql'] as String;
        final upper = sql.trim().toUpperCase();
        if (!upper.startsWith('SELECT') && !upper.startsWith('WITH')) {
          return {'error': 'Only SELECT queries allowed in execute_read_query.'};
        }
        final res =
            await db.rpc('run_dynamic_sql', params: {'query_string': sql});
        return {
          'status': 'success',
          'rows': res,
          'count': (res as List?)?.length ?? 0
        };

      case 'execute_write_query':
        final sql = args['sql'] as String;
        final description = args['description'] as String? ?? '';
        final upper = sql.trim().toUpperCase();
        if (upper.startsWith('DROP') ||
            upper.startsWith('ALTER') ||
            upper.startsWith('CREATE') ||
            upper.startsWith('TRUNCATE') ||
            upper.startsWith('GRANT') ||
            upper.startsWith('REVOKE')) {
          return {'error': 'DDL statements are not permitted.'};
        }
        if (upper.startsWith('DELETE') || upper.startsWith('UPDATE')) {
          if (onConfirmDestructive != null) {
            final confirmed = await onConfirmDestructive(description);
            if (!confirmed) return {'error': 'Operation cancelled by user.'};
          }
        }
        final res =
            await db.rpc('execute_mutation', params: {'sql_string': sql});
        return {'status': 'success', 'description': description, 'result': res};

      default:
        return {'error': 'Unknown tool: $name'};
    }
  }

  // ── Parts JSON serialization ──────────────────────────────────────────────

  static List<Map<String, dynamic>> _partsToJson(List<ai.Part> parts) {
    return parts.map((p) {
      if (p is ai.TextPart) return {'type': 'text', 'text': p.text};
      if (p is ai.FunctionCall) {
        return {'type': 'functionCall', 'name': p.name, 'args': p.args};
      }
      if (p is ai.FunctionResponse) {
        return {'type': 'functionResponse', 'name': p.name, 'response': p.response};
      }
      return {'type': 'unknown'};
    }).toList();
  }

  static List<ai.Part> _partsFromJson(dynamic json) {
    final list = json is List ? json : (jsonDecode(json.toString()) as List);
    return list.map<ai.Part?>((item) {
      final type = item['type'] as String? ?? '';
      switch (type) {
        case 'text':
          return ai.TextPart(item['text'] as String? ?? '');
        case 'functionCall':
          return ai.FunctionCall(
              item['name'] as String,
              Map<String, Object?>.from(item['args'] as Map? ?? {}));
        case 'functionResponse':
          return ai.FunctionResponse(
              item['name'] as String,
              Map<String, Object?>.from(item['response'] as Map? ?? {}));
        default:
          return null;
      }
    }).whereType<ai.Part>().toList();
  }
}
