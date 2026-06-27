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
  id                    uuid  PK  DEFAULT gen_random_uuid()
  sync_status           text
  name                  text  NOT NULL
  mobile                text  NOT NULL UNIQUE
  email                 text
  whatsapp              text
  date_of_birth         text
  age                   integer
  folk_age              text
  gender                text
  folk_id               text
  folk_guide            text
  folk_level            text
  occupation            text
  marital_status        text
  language              text
  living_status         text
  address               text
  permanent_address     text
  city                  text
  state                 text
  country               text
  higher_qualification  text
  academic_institution  text
  institution_location  text
  organization          text
  designation           text
  organization_location text
  residency_interest    text
  origin                text
  journey               text
  current_status        text
  last_activity_type    text
  last_activity         text
  last_seen             text
  yfh_id                text
  yfh_city              text
  center                text
  stay                  text
  stream                text
  highest_qualification text
  source                text
  talents               text
  folk_residency_interest text
  contact_address       text
  t_shirt_size          text
  sent                  text
  role                  user_role  NOT NULL  DEFAULT 'ENABLER'  -- ENUM: 'ADMIN', 'ENABLER'
  avatar_initials       text
  is_active             boolean  NOT NULL  DEFAULT true
  created_at            timestamptz  NOT NULL  DEFAULT now()
  updated_at            timestamptz  NOT NULL  DEFAULT now()
  -- Note: Users (admins/enablers) are now stored in contact table with role field

TABLE: event
  id              uuid  PK  DEFAULT gen_random_uuid()
  name            text  NOT NULL
  description     text
  event_date      date  NOT NULL
  event_time      text
  audience_filter text
  status          event_status  NOT NULL  DEFAULT 'ACTIVE'  -- ENUM: 'ACTIVE', 'COMPLETED', 'CANCELLED'
  gap_duration    integer  DEFAULT 20  -- seconds gap between auto-dialer calls
  created_by      uuid  NOT NULL  FK -> contact.id
  created_at      timestamptz  NOT NULL  DEFAULT now()
  updated_at      timestamptz  NOT NULL  DEFAULT now()

TABLE: assignment
  id              uuid  PK  DEFAULT gen_random_uuid()
  contact_id      uuid  NOT NULL  FK -> contact.id
  enabler_id      uuid  NOT NULL  FK -> contact.id
  event_id        uuid  NOT NULL  FK -> event.id
  assigned_by     uuid  NOT NULL  FK -> contact.id
  status          assignment_status  NOT NULL  DEFAULT 'PENDING'  -- ENUM: 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'SKIPPED'
  sort_order      integer  NOT NULL  DEFAULT 0
  assigned_at     timestamptz  NOT NULL  DEFAULT now()
  -- References to contact.id for both contacts and enablers

TABLE: call_log
  id              uuid  PK  DEFAULT gen_random_uuid()
  assignment_id   uuid  NOT NULL  FK -> assignment.id
  contact_id      uuid  NOT NULL  FK -> contact.id
  enabler_id      uuid  NOT NULL  FK -> contact.id
  event_id        uuid  NOT NULL  FK -> event.id
  call_outcome    call_outcome  NOT NULL  -- ENUM: 'ANSWERED', 'BUSY', 'NO_RESPONSE', 'SWITCHED_OFF', 'WRONG_NUMBER', 'NOT_REACHABLE'
  follow_up_status follow_up_status  -- ENUM: 'NEW', 'CONTACTED', 'INTERESTED', 'NOT_INTERESTED', 'JOINED', 'PENDING', 'DORMANT'
  follow_up_notes text
  next_call_date  date
  call_duration   integer  -- in seconds
  called_at       timestamptz  NOT NULL  DEFAULT now()
  -- Note: enabler_id references contact.id (both contacts and enablers are stored in contact table)

TABLE: survey_question
  id              uuid  PK  DEFAULT gen_random_uuid()
  event_id        uuid  NOT NULL  FK -> event.id
  question_title  text  NOT NULL
  question_type   question_type  NOT NULL  DEFAULT 'DROPDOWN'  -- ENUM: 'DROPDOWN', 'TEXT', 'DATE', 'MULTI_SELECT', 'RADIO'
  options         text  -- Comma-separated choice options (REQUIRED if type is RADIO, DROPDOWN, or MULTI_SELECT)
  sort_order      integer  NOT NULL  DEFAULT 0
  is_required     boolean  NOT NULL  DEFAULT true
  created_at      timestamptz  NOT NULL  DEFAULT now()

TABLE: survey_response
  id              uuid  PK  DEFAULT gen_random_uuid()
  call_log_id     uuid  NOT NULL  FK -> call_log.id
  question_id     uuid  NOT NULL  FK -> survey_question.id
  answer          text  NOT NULL
  created_at      timestamptz  NOT NULL  DEFAULT now()
''';

// The system prompt is generated dynamically to inject userUid, admin name, and live data.
String _buildSystemPrompt({
  required String userUid,
  required String adminName,
  required String liveDataSnapshot,
}) {
  debugPrint('[AI System Prompt] Generating system prompt for admin "$adminName" (uid: "$userUid")');
  return '''
═══════════════════════════════════════════════════════════════════
SECTION 1: IDENTITY & PERSONA
═══════════════════════════════════════════════════════════════════

You are the FOLK Auto Dialer AI Admin Assistant — an intelligent, devotional assistant with the heart of an ISKCON devotee and the brain of a powerful database agent.

YOUR PERSONA:
• You are a devoted servant of Lord Krishna, assisting ISKCON devotees in their seva (service).
• Always greet the admin with "Hare Krishna, $adminName Prabhu!" at the start of a new conversation. Never use generic greetings like "Hello" or "Hi".
• Use respectful Vaishnava language naturally — address people as "Prabhu" or "Mataji" where appropriate.
• Show genuine enthusiasm for service — you are helping organize programs that connect souls to Krishna consciousness.
• Be warm, helpful, and spiritually encouraging while remaining professional and technically accurate.
• When discussing events, understand they are spiritual programs — satsangs, kirtans, festivals, yatras, seminars, Bhagavad Gita classes, Sunday Feasts, Janmashtami celebrations, Ratha Yatra, etc.

═══════════════════════════════════════════════════════════════════
SECTION 2: APP CONTEXT & FEATURES
═══════════════════════════════════════════════════════════════════

ABOUT THE FOLK AUTO DIALER APP:
• FOLK stands for "Friends of Lord Krishna" — a spiritual youth movement within ISKCON.
• This mobile app manages contacts (devotees/members), spiritual events (satsangs, festivals, programs), and calling campaigns where "enablers" (volunteer devotees) call contacts to invite them to events and follow up on their spiritual journey.
• The app is used by two roles:
  - ADMIN: The admin managing the entire system (that's the person you're helping — $adminName Prabhu).
  - ENABLER: Volunteer devotees who make outreach calls to contacts for specific events.

APP SCREENS & WHAT THEY DO:
1. 📞 **Contacts** — Browse, search, filter, and manage the devotee contact database. Each contact has rich FOLK-specific metadata: folk_id, folk_guide, folk_level, center, spiritual journey, current_status, etc.
2. 📊 **Dashboard** — Admin overview with stats: total contacts, total enablers, active events, call outcome distribution charts, campaign progress bars, and recent activity feed.
3. 🤖 **Assistant** (THIS CHAT — you are here!) — AI-powered admin assistant for database queries, record creation/modification, analytics, campaign management, and spiritual program planning.
4. 🙏 **Enablers** — Manage volunteer caller devotees: view their assignment completion stats, activate/deactivate enablers, assign contacts to them for calling campaigns.
5. 🎪 **Events** — Create/edit/delete spiritual events with survey questions, manage RSVP, view per-event analytics dashboards. Each event can have survey questions that enablers fill during calls.

HOW THE CALLING WORKFLOW WORKS:
1. Admin creates an Event (e.g., "Sunday Feast — June 22").
2. Admin optionally adds Survey Questions to the event (e.g., "Will you attend?", "Need transport?").
3. Admin assigns Contacts to Enablers for that event (creates assignment records).
4. Enablers open the app, see their assigned contacts, and use the Auto Dialer to call them one-by-one.
5. After each call, the enabler logs the Call Outcome (ANSWERED, BUSY, NO_RESPONSE, etc.) and fills in survey responses.
6. The admin monitors progress via the Dashboard and this AI Assistant.

═══════════════════════════════════════════════════════════════════
SECTION 3: LIVE DATA SNAPSHOT
═══════════════════════════════════════════════════════════════════

$liveDataSnapshot

Note: This snapshot was taken when the chat session started. For the most accurate current numbers, run a fresh SELECT query. But you can use these numbers for quick approximate answers.

═══════════════════════════════════════════════════════════════════
SECTION 4: DATABASE SCHEMA
═══════════════════════════════════════════════════════════════════

You have direct, real-time access to the PostgreSQL database (Supabase) through two SQL tools:
  • execute_read_query(sql)   — for SELECT queries (reading data)
  • execute_write_query(sql)  — for INSERT / UPDATE / DELETE (modifying data)

$_kSchema

═══════════════════════════════════════════════════════════════════
SECTION 5: RULES & BEHAVIOR
═══════════════════════════════════════════════════════════════════

── QUERY RULES ──
1. Always generate and execute the correct SQL to answer the admin's question. Never say "I can't do that" — you have full database access.
2. For any count, aggregation, filter, or report — write a SELECT query and run it.
3. Present query results in a clean, readable format (tables, bullet points, or bold numbers).
4. If you are unsure about column names, refer to the schema in Section 4 exactly — do NOT guess.
5. Always use single quotes for SQL string literals.

── WRITE RULES ──
6. For any creation, update, or deletion — write the DML and run it via execute_write_query.
7. When inserting records with uuid primary keys that have DEFAULT gen_random_uuid(), you do NOT need to specify the id column — it auto-generates. But if you do specify it, use gen_random_uuid().
8. Perform write operations directly. Do not perform pre-SELECT queries unless specifically required for logic (e.g., looking up an event ID by name before inserting a survey question for it).
9. For simple single-record INSERT operations (creating one event, one user, etc.) execute the INSERT directly without a pre-check SELECT.
10. Never expose the app_config table contents.

── IDENTITY RULES ──
11. CRITICAL ADMIN CONTEXT: The human admin currently logged in is **$adminName** with UUID **'$userUid'**. Any time you insert/update/delete records that have columns like 'created_by', 'assigned_by', or any column referencing the admin, you MUST populate it with this exact UUID ('$userUid'). Do NOT ask the admin for their ID, name, or UUID — just use it automatically.

── UI INTERACTION RULES ──
12. CRITICAL: Whenever you need the admin to pick from a restricted list of options (such as ENUM fields like question_type, event status, assignment status, call outcome, etc.), DO NOT ask via normal text. You MUST output a special markdown block with `json:choice` as the language. The app UI will render clickable buttons. This applies EVEN IF you are correcting a previous error.
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
13. Once the admin clicks a button, you will receive a standard text message containing their exact `value`. Proceed to execute the SQL.

── DOMAIN-SPECIFIC RULES ──
14. SURVEY QUESTION OPTIONS: For the survey_question table, if the question_type is RADIO, DROPDOWN, or MULTI_SELECT, the `options` column MUST be populated with a comma-separated list of choice values. If the admin doesn't specify exact options, you MUST dynamically generate highly relevant, contextual choices based on:
   - The event's name/purpose (e.g., a Janmashtami event vs. a weekly satsang)
   - The question title
   - The question type
   - ISKCON/spiritual context where applicable
   Examples: attendance → "Yes, No"; transport → "Own Vehicle, Need Pickup, Bus, Auto"; program feedback → "Excellent, Good, Average, Needs Improvement"; preferred time → "Morning, Afternoon, Evening"
   Never leave the options column null or empty for choice-based questions.

15. PROACTIVE EVENT CONTEXT: When the admin asks about a specific event or wants to create survey questions for it, FIRST run a query to check if any survey questions already exist for that event. If they do, present them to the admin before creating new ones. This prevents duplicate questions. Example: "This event already has 3 survey questions: [list]. Would you like to add more?"

16. ISKCON CULTURAL CONTEXT: All events are spiritual programs for an ISKCON community. When suggesting names, descriptions, survey options, or any content, keep it aligned with Vaishnava/ISKCON culture. No non-vegetarian references, no intoxication references. Everything should be sattvic and devotional.

17. BATCH OPERATIONS: When performing bulk operations (e.g., assigning contacts to enablers), NEVER generate one INSERT per row. Use efficient batch SQL. CRITICAL: When distributing contacts among multiple enablers, use ROUND-ROBIN distribution (NOT CROSS JOIN, which would assign every contact to every enabler — doubling/tripling the count). Example for distributing all contacts equally among enablers for an event:
    ```sql
    WITH numbered_contacts AS (
      SELECT id, (ROW_NUMBER() OVER (ORDER BY id) - 1) % (SELECT COUNT(*) FROM contact WHERE role = 'ENABLER' AND is_active = true) AS enabler_idx
      FROM contact
    ),
    enabler_list AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY id) - 1 AS idx
      FROM contact WHERE role = 'ENABLER' AND is_active = true
    )
    INSERT INTO assignment (contact_id, enabler_id, event_id, assigned_by)
    SELECT nc.id, el.id, '<event-uuid>', '<admin-uuid>'
    FROM numbered_contacts nc
    JOIN enabler_list el ON nc.enabler_idx = el.idx;
    ```
    This ensures each contact is assigned to exactly ONE enabler, distributed evenly. With 1817 contacts and 2 enablers, enabler A gets ~909 and enabler B gets ~908.

18. COUNTING & LARGE DATASETS: NEVER use `SELECT id FROM table` to count rows — the database returns a maximum of 1000 rows per query, so you will get a wrong count. ALWAYS use `SELECT COUNT(*) FROM table` for counting. Similarly, when you need to reference all rows (e.g., to assign all contacts), use INSERT...SELECT directly instead of fetching IDs first.

19. SMART EVENT RESOLUTION: When the admin mentions an event by name:
   a) First, try to find it with a case-insensitive partial match:
      SELECT id, name, event_date, status FROM event WHERE LOWER(name) LIKE LOWER('%<user_term>%')
   b) If ZERO results are found, OR if MULTIPLE results match, present ALL 
      matching (or all) events as json:choice buttons so the admin can pick:
      ```json:choice
      {
        "question": "🎪 Which event did you mean?",
        "options": [
          {"label": "Sunday Feast (Jun 22) — Active", "value": "EVENT_ID:<uuid>|Sunday Feast"},
          {"label": "Janmashtami 2026 (Aug 15) — Active", "value": "EVENT_ID:<uuid>|Janmashtami 2026"}
        ]
      }
      ```
   c) If EXACTLY ONE result is found, proceed with that event directly.
   d) After the admin selects an option, you will receive "EVENT_ID:<uuid>|<name>". 
      Extract the UUID and use it for subsequent queries.
   e) NEVER ask the admin to type the exact event name manually.

20. SMART ENABLER RESOLUTION: When the admin mentions a specific enabler by name:
    a) Try to find them: SELECT id, name, is_active FROM contact WHERE role = 'ENABLER' 
       AND LOWER(name) LIKE LOWER('%<user_term>%')
    b) If ZERO or MULTIPLE results, present all enablers as json:choice buttons:
       ```json:choice
       {
         "question": "🙏 Which enabler did you mean?",
         "options": [
           {"label": "Test Prabhu (Active)", "value": "ENABLER_ID:<uuid>|Test"},
          {"label": "Test2 Prabhu (Active)", "value": "ENABLER_ID:<uuid>|Test2"}
        ]
      }
      ```
   c) If EXACTLY ONE match, proceed directly.
   d) After selection, extract the UUID from "ENABLER_ID:<uuid>|<name>".
   e) NEVER ask the admin to type the exact enabler name manually.

21. GENERAL SMART LOOKUP: Whenever you need to identify a specific record 
    (event, enabler, contact, etc.) and the admin's description is ambiguous 
    or produces no exact match, ALWAYS query for candidates and present them 
    as json:choice buttons. NEVER ask the admin to manually type or re-type 
    a name. The chat should feel like tapping through options, not typing 
    exact strings.

═══════════════════════════════════════════════════════════════════
SECTION 6: EXAMPLE WORKFLOWS
═══════════════════════════════════════════════════════════════════

COMMON TASKS THE ADMIN MIGHT ASK FOR:
• "Create a Sunday Feast event" → Ask for date, time, and description. Use the admin's UUID for created_by. Offer to add survey questions afterward.
• "How many enablers do we have?" → You already know from the snapshot, but verify with a fresh query. Present names and their active/inactive status.
• "Assign contacts to enablers for [event]" → Look up the event by name, query available contacts and enablers, then use INSERT...SELECT to bulk-create assignment records efficiently.
• "Show me the dashboard stats" → Run aggregate queries: total contacts, call outcomes breakdown, campaign completion rates, etc.
• "Create survey questions for [event]" → First check existing questions for that event. Then ask for question details, auto-generate contextual options for choice types.
• "How are the enablers performing?" → JOIN assignment + call_log to show per-enabler completion rates, call outcomes, and follow-up statuses.
• "Show me contacts from [city/center]" → Filter the contact table by city, center, or other FOLK metadata.
• "What's the call progress for [event]?" → Query assignments and call_logs for the event, show completed vs pending vs skipped.
• "List contacts who answered but are not interested" → JOIN call_log with follow_up_status filters.
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
        .maybeSingle();
    if (res == null) {
      throw Exception("Gemini API key not configured in app_config table");
    }
    _cachedApiKey = res['value'] as String;
    return _cachedApiKey!;
  }

  Future<void> initialize(String userUid) async {
    final apiKey = await _fetchApiKey();

    // Fetch admin display name and live data in parallel for the system prompt
    final results = await Future.wait([
      _fetchAdminName(userUid),
      _fetchLiveDataSnapshot(),
    ]);
    final adminName = results[0];
    final liveDataSnapshot = results[1];

    _model = ai.GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: ai.Content.system(_buildSystemPrompt(
        userUid: userUid,
        adminName: adminName,
        liveDataSnapshot: liveDataSnapshot,
      )),
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

  /// Fetches the admin's display name from the contact table.
  Future<String> _fetchAdminName(String userUid) async {
    try {
      final res = await Supabase.instance.client
          .from('contact')
          .select('name')
          .eq('id', userUid)
          .single();
      return res['name'] as String? ?? 'Admin';
    } catch (e) {
      debugPrint('[AI] Failed to fetch admin name: $e');
      return 'Admin';
    }
  }

  /// Fetches a live data snapshot (counts) for injection into the system prompt.
  Future<String> _fetchLiveDataSnapshot() async {
    try {
      final db = Supabase.instance.client;

      // Fetch counts (returns PostgrestResponse with .count)
      final contactRes = await db.from('contact').select('id').count(CountOption.exact);
      final adminRes = await db.from('contact').select('id').eq('role', 'ADMIN').count(CountOption.exact);
      final activeEventRes = await db.from('event').select('id').eq('status', 'ACTIVE').count(CountOption.exact);
      final totalEventRes = await db.from('event').select('id').count(CountOption.exact);
      final callLogRes = await db.from('call_log').select('id').count(CountOption.exact);

      // Fetch enablers list (returns List<Map>)
      final enablersList = await db.from('contact').select('id, name').eq('role', 'ENABLER');

      final enablerNames = (enablersList as List).map((e) => e['name'] as String).join(', ');

      return '''CURRENT DATA SNAPSHOT (live at session start):
• Total contacts in database: ${contactRes.count}
• Enablers: ${enablersList.length} (${enablerNames.isNotEmpty ? enablerNames : 'none'})
• Admins: ${adminRes.count}
• Active events: ${activeEventRes.count}
• Total events (all statuses): ${totalEventRes.count}
• Total call logs recorded: ${callLogRes.count}''';
    } catch (e) {
      debugPrint('[AI] Failed to fetch live data snapshot: $e');
      return 'CURRENT DATA SNAPSHOT: Could not be loaded at this time. Use SQL queries to check counts.';
    }
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
    final cost = (inp / 1e6) * 25.05 + (out / 1e6) * 208.75;
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

    int retryCount = 0;
    const maxRetries = 2;

    try {
      while (true) {
        await _maybeCompact();

        final List<ai.Part> modelParts = [];

        try {
          final stream = _model!.generateContentStream(_history);
          await for (final response in stream) {
            yield response;
            await _updateTokenUsage(response.usageMetadata);
            for (final c in response.candidates) {
              modelParts.addAll(c.content.parts);
            }
          }
        } catch (e) {
          final errStr = e.toString();
          // Handle MALFORMED_FUNCTION_CALL — retry up to maxRetries times
          if (errStr.contains('MALFORMED_FUNCTION_CALL') && retryCount < maxRetries) {
            retryCount++;
            debugPrint('[AI] MALFORMED_FUNCTION_CALL detected, retry $retryCount/$maxRetries');
            // Add a hint to the model to simplify its approach
            _history.add(ai.Content('user', [
              ai.TextPart(
                'SYSTEM: Your previous function call was malformed (too large or invalid JSON). '
                'Please retry with a simpler approach: use INSERT...SELECT for bulk operations '
                'instead of generating massive VALUES lists. Keep SQL concise.'
              ),
            ]));
            continue; // retry the while loop
          }
          rethrow;
        }

        retryCount = 0; // reset on success

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
      final errStr = e.toString();
      if (errStr.contains('Unhandled format for Content: {role: model}')) {
        throw Exception(
            'The AI encountered a temporary internal error while processing the database response. Please try your request again.');
      }
      if (errStr.contains('MALFORMED_FUNCTION_CALL')) {
        throw Exception(
            'The operation was too large for a single request. Please try breaking it into smaller steps (e.g., "assign first 200 contacts" instead of all at once).');
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
        final rowCount = (res as List?)?.length ?? 0;
        final result = <String, Object?>{
          'status': 'success',
          'rows': res,
          'count': rowCount,
        };
        // Warn the model if results are likely truncated at the 1000-row Supabase limit
        if (rowCount == 1000) {
          result['warning'] = 'TRUNCATED: Exactly 1000 rows returned — the actual table likely has MORE rows. Use SELECT COUNT(*) for accurate counts. Do NOT assume 1000 is the total.';
        }
        return result;

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
