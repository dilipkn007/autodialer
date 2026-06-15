import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Full PostgreSQL schema embedded so Gemini can write precise queries.
// ─────────────────────────────────────────────────────────────────────────────
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
  enabler_id      uuid  FK -> users.uid  (the enabler doing the calling)
  assigned_by     uuid  FK -> users.uid  (the admin who made the assignment)
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
  call_outcome    text  NOT NULL  -- 'ANSWERED', 'NOT_ANSWERED', 'BUSY', 'FOLLOW_UP', 'INTERESTED', 'NOT_INTERESTED'
  follow_up_notes text
  next_call_date  date
  call_duration   integer  -- seconds
  called_at       timestamptz

TABLE: survey_question
  id              uuid  PK
  event_id        uuid  FK -> event.id
  question_title  text  NOT NULL
  question_type   text  NOT NULL  -- 'TEXT', 'CHOICE', 'BOOLEAN'
  options         text  -- comma-separated for CHOICE type
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

// ─────────────────────────────────────────────────────────────────────────────
// System prompt
// ─────────────────────────────────────────────────────────────────────────────
const _kSystemPrompt = '''
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
11. The event table's created_by column is a uuid FK to users.uid. When creating an event, use a subquery: (SELECT uid FROM users WHERE role = 'ADMIN' LIMIT 1).
12. When creating ANY record (e.g., event, user, contact), DO NOT immediately execute the INSERT. First, review the schema and politely ask the user to provide any relevant optional and required fields that were not provided in the initial request. Only execute the INSERT once the user provides these details or explicitly tells you to skip the optional fields. Never invent or insert empty/dummy data without confirmation.
''';

class AiAssistantService {
  AiAssistantService._();
  static final AiAssistantService instance = AiAssistantService._();

  ai.GenerativeModel? _model;
  ai.ChatSession? _chat;
  bool _isInitialized = false;

  Future<String> _fetchApiKey() async {
    final res = await Supabase.instance.client
        .from('app_config')
        .select('value')
        .eq('key', 'gemini_api_key')
        .single();
    return res['value'] as String;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    final apiKey = await _fetchApiKey();

    _model = ai.GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      systemInstruction: ai.Content.system(_kSystemPrompt),
      tools: [
        ai.Tool(functionDeclarations: [
          ai.FunctionDeclaration(
            'execute_read_query',
            'Execute a PostgreSQL SELECT query and return the results. Use this for any read, count, filter, aggregation, or reporting query.',
            ai.Schema.object(properties: {
              'sql': ai.Schema.string(
                description: 'A valid PostgreSQL SELECT query. Use single quotes for string literals.',
              ),
            }, requiredProperties: ['sql']),
          ),
          ai.FunctionDeclaration(
            'execute_write_query',
            'Execute a PostgreSQL INSERT, UPDATE, or DELETE statement. Use this to create, modify, or remove records.',
            ai.Schema.object(properties: {
              'sql': ai.Schema.string(
                description: 'A valid PostgreSQL INSERT, UPDATE, or DELETE statement. Use single quotes for string literals.',
              ),
              'description': ai.Schema.string(
                description: 'A short human-readable description of what this query does, e.g. "Creating new enabler Rahul".',
              ),
            }, requiredProperties: ['sql', 'description']),
          ),
        ]),
      ],
    );

    _chat = _model!.startChat();

    _isInitialized = true;
  }

  void startNewSession() {
    if (_model == null) throw Exception('Service not initialized');
    _chat = _model!.startChat();
  }

  Future<String> getBudgetAndSpend() async {
    final db = Supabase.instance.client;
    final res = await db.from('app_config').select('key, value').inFilter('key', ['gemini_input_tokens', 'gemini_output_tokens', 'gemini_budget']);
    
    int inputTokens = 0;
    int outputTokens = 0;
    double budget = 500.00;

    for (final row in res) {
      final key = row['key'] as String;
      final val = row['value'] as String;
      if (key == 'gemini_input_tokens') inputTokens = int.tryParse(val) ?? 0;
      if (key == 'gemini_output_tokens') outputTokens = int.tryParse(val) ?? 0;
      if (key == 'gemini_budget') budget = double.tryParse(val) ?? 500.00;
    }

    // Gemini 2.5 Flash-Lite Pricing:
    // Input: $0.075 per 1M tokens -> ₹6.26 per 1M
    // Output: $0.30 per 1M tokens -> ₹25.05 per 1M
    // (using approx 1 USD = 83.5 INR)
    final double inputCost = (inputTokens / 1000000.0) * 6.26;
    final double outputCost = (outputTokens / 1000000.0) * 25.05;
    final double totalCost = inputCost + outputCost;

    return '₹${totalCost.toStringAsFixed(4)} / ₹${budget.toStringAsFixed(2)}';
  }

  Future<void> _updateTokenUsage(ai.UsageMetadata? usage) async {
    if (usage == null) return;
    
    final db = Supabase.instance.client;
    final int inputTokens = usage.promptTokenCount ?? 0;
    final int outputTokens = usage.candidatesTokenCount ?? 0;

    try {
      if (inputTokens > 0) {
        await db.rpc('execute_mutation', params: {
          'sql_string': "UPDATE app_config SET value = (CAST(value AS INTEGER) + $inputTokens)::text WHERE key = 'gemini_input_tokens';"
        });
      }
      if (outputTokens > 0) {
        await db.rpc('execute_mutation', params: {
          'sql_string': "UPDATE app_config SET value = (CAST(value AS INTEGER) + $outputTokens)::text WHERE key = 'gemini_output_tokens';"
        });
      }
    } catch (e) {
      debugPrint('Error updating token usage: \$e');
    }
  }

  Stream<ai.GenerateContentResponse> sendMessageStream(
    String text, {
    Future<bool> Function(String description)? onConfirmDestructive,
  }) async* {
    if (!_isInitialized) await initialize();
    if (_chat == null) startNewSession();

    try {
      final responseStream = _chat!.sendMessageStream(ai.Content.text(text));

      await for (final response in responseStream) {
        yield response;
        await _updateTokenUsage(response.usageMetadata);

        if (response.functionCalls.isNotEmpty) {
          final List<ai.FunctionResponse> functionResponses = [];

          for (final call in response.functionCalls) {
            debugPrint('[AI Tool] ${call.name}: ${call.args}');
            try {
              final result = await _executeTool(call.name, call.args, onConfirmDestructive);
              functionResponses.add(ai.FunctionResponse(call.name, result));
            } catch (e) {
              debugPrint('[AI Tool Error] ${call.name}: $e');
              functionResponses.add(
                ai.FunctionResponse(call.name, {'error': e.toString()}),
              );
            }
          }

          if (functionResponses.isNotEmpty) {
            final followUpStream = _chat!.sendMessageStream(
              ai.Content.functionResponses(functionResponses),
            );
            await for (final r in followUpStream) {
              yield r;
              await _updateTokenUsage(r.usageMetadata);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AI Assistant Error: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  Future<Map<String, Object?>> _executeTool(
    String name,
    Map<String, Object?> args,
    Future<bool> Function(String description)? onConfirmDestructive,
  ) async {
    final db = Supabase.instance.client;


    switch (name) {
      // ── Read ──────────────────────────────────────────────────────────────
      case 'execute_read_query':
        final sql = args['sql'] as String;
        // Safety: only allow SELECT / WITH (CTE)
        final upper = sql.trim().toUpperCase();
        if (!upper.startsWith('SELECT') && !upper.startsWith('WITH')) {
          return {
            'error': 'Only SELECT queries are allowed in execute_read_query. Use execute_write_query for mutations.',
          };
        }
        final res = await db.rpc('run_dynamic_sql', params: {'query_string': sql});
        return {'status': 'success', 'rows': res, 'count': (res as List?)?.length ?? 0};

      // ── Write ─────────────────────────────────────────────────────────────
      case 'execute_write_query':
        final sql = args['sql'] as String;
        final description = args['description'] as String? ?? '';
        // Safety: block DDL
        final upper = sql.trim().toUpperCase();
        if (upper.startsWith('DROP') ||
            upper.startsWith('ALTER') ||
            upper.startsWith('CREATE') ||
            upper.startsWith('TRUNCATE') ||
            upper.startsWith('GRANT') ||
            upper.startsWith('REVOKE')) {
          return {'error': 'DDL statements (DROP, ALTER, CREATE, etc.) are not permitted.'};
        }

        if (upper.startsWith('DELETE') || upper.startsWith('UPDATE')) {
          if (onConfirmDestructive != null) {
            final confirmed = await onConfirmDestructive(description);
            if (!confirmed) {
              return {'error': 'Operation cancelled by user.'};
            }
          }
        }

        final res = await db.rpc('execute_mutation', params: {'sql_string': sql});
        return {'status': 'success', 'description': description, 'result': res};

      default:
        return {'error': 'Unknown tool: $name'};
    }
  }
}
