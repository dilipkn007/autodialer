import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:f_o_l_k_auto_dialer/services/ai_assistant_service.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'package:f_o_l_k_auto_dialer/components/admin_nav_bar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'ai_assistant_model.dart';
export 'ai_assistant_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class AiAssistantWidget extends StatefulWidget {
  static const String routeName = 'AiAssistant';
  static const String routePath = '/aiAssistant';

  const AiAssistantWidget({Key? key}) : super(key: key);

  @override
  _AiAssistantWidgetState createState() => _AiAssistantWidgetState();
}

class _AiAssistantWidgetState extends State<AiAssistantWidget> {
  late AiAssistantModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  String _budgetSpendString = '₹0.0000 / ₹500.00';

  // Session sidebar state
  List<AiChatSession> _sessions = [];
  bool _sessionsLoading = false;

  String? get _userUid => AuthService.instance.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiAssistantModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    _initSpeech();
    _initService();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => debugPrint('onSpeechError: $val'),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
          _sendVoiceMessage();
        }
      },
    );
    setState(() {});
  }

  void _initService() async {
    if (_userUid != null) {
      await AiAssistantService.instance.initialize(_userUid!);
    }
    _updateQuota();
    _loadSessions();

    if (_userUid != null) {
      final activeSessionId = AiAssistantService.instance.currentSessionId;
      if (activeSessionId == null) {
        await _startNewSession(addWelcome: true);
      } else {
        // Load messages for the existing session after state recreation (e.g. hot reload)
        final msgs =
            await AiAssistantService.instance.loadSession(activeSessionId);
        if (mounted) {
          setState(() {
            _messages = msgs;
          });
          _scrollToBottom();
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _updateQuota() async {
    final s = await AiAssistantService.instance.getBudgetAndSpend();
    if (mounted) setState(() => _budgetSpendString = s);
  }

  // ── Session management ──────────────────────────────────────────────────

  Future<void> _loadSessions() async {
    if (_userUid == null) return;
    setState(() => _sessionsLoading = true);
    try {
      final sessions =
          await AiAssistantService.instance.loadSessions(_userUid!);
      if (mounted) setState(() => _sessions = sessions);
    } finally {
      if (mounted) setState(() => _sessionsLoading = false);
    }
  }

  Future<void> _startNewSession({bool addWelcome = false}) async {
    if (_userUid == null) return;
    AiAssistantService.instance.startNewSession();
    setState(() {
      _messages = [];
      if (addWelcome) {
        _messages.add(ChatMessage(
          text:
              "Hare Krishna Prabhu! I'm your FOLK Auto Dialer AI assistant. How can I serve you in managing the campaigns today?",
          isUser: false,
        ));
      }
    });
    if (scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openSession(AiChatSession session) async {
    if (session.id == AiAssistantService.instance.currentSessionId &&
        _messages.isNotEmpty) {
      Navigator.of(context).pop(); // just close drawer
      return;
    }
    setState(() {
      _messages = [];
      _isProcessing = false;
    });
    final msgs = await AiAssistantService.instance.loadSession(session.id);
    setState(() => _messages = msgs);
    _scrollToBottom();
    if (scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteSession(AiChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat?'),
        content: Text('Delete "${session.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: FlutterFlowTheme.of(context).error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AiAssistantService.instance.deleteSession(session.id);
    setState(() => _sessions.removeWhere((s) => s.id == session.id));
    // If we deleted the active session, start fresh
    if (AiAssistantService.instance.currentSessionId == null) {
      await _startNewSession(addWelcome: true);
    }
  }

  Future<void> _renameSession(AiChatSession session) async {
    final ctrl = TextEditingController(text: session.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Session name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (newTitle == null || newTitle.isEmpty) return;
    await AiAssistantService.instance.updateSessionTitle(session.id, newTitle);
    setState(() {
      final idx = _sessions.indexWhere((s) => s.id == session.id);
      if (idx != -1) _sessions[idx].title = newTitle;
    });
  }

  // ── Speech ─────────────────────────────────────────────────────────────

  void _startListening() async {
    if (_speechEnabled && !_isListening) {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      setState(() => _isListening = true);
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() => _model.textController?.text = result.recognizedWords);
  }

  void _sendVoiceMessage() {
    if (_model.textController?.text.isNotEmpty == true) _sendMessage();
  }

  // ── Messaging ──────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _model.textController?.text.trim() ?? '';
    if (text.isEmpty || _userUid == null) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _model.textController?.clear();
      _isProcessing = true;
    });
    _scrollToBottom();

    try {
      final stream = AiAssistantService.instance.sendMessageStream(
        text,
        userUid: _userUid!,
        onConfirmDestructive: (description) async {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Action'),
                  content: Text(
                      'The assistant wants to perform a potentially destructive operation:\n\n$description\n\nAre you sure?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: FlutterFlowTheme.of(context).error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Proceed'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
      );

      int? currentAiMsgIndex;

      await for (final response in stream) {
        if (response.functionCalls.isNotEmpty) {
          if (_messages.isEmpty || !_messages.last.isFunctionCall) {
            setState(() {
              _messages.add(ChatMessage(
                  text: '⚡ Executing operation…',
                  isUser: false,
                  isFunctionCall: true));
            });
          }
          currentAiMsgIndex = null;
        } else if (response.text != null && response.text!.isNotEmpty) {
          if (currentAiMsgIndex == null) {
            setState(() {
              _messages.add(ChatMessage(text: response.text!, isUser: false));
              currentAiMsgIndex = _messages.length - 1;
            });
          } else {
            setState(() {
              _messages[currentAiMsgIndex!] = ChatMessage(
                  text: _messages[currentAiMsgIndex!].text + response.text!,
                  isUser: false);
            });
          }
        }
        _scrollToBottom();
      }

      // Refresh session list so title/timestamp update in the drawer
      _loadSessions();
    } catch (e) {
      String errMsg = e.toString();
      if (errMsg.contains('429') ||
          errMsg.contains('RESOURCE_EXHAUSTED') ||
          errMsg.contains('exceeded your current quota') ||
          errMsg.contains('rate limit')) {
        errMsg = 'Rate limit exceeded. Please wait a few seconds before trying again.';
      }
      setState(() {
        _messages
            .add(ChatMessage(text: '⚠️ Error: $errMsg', isUser: false));
      });
    } finally {
      setState(() => _isProcessing = false);
      _scrollToBottom();
      _updateQuota();
    }
  }

  void _scrollToBottom() {
    if (_model.listScrollController?.hasClients == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // With reverse: true on the ListView, 0.0 is the bottom
        _model.listScrollController!.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        drawer: _buildDrawer(context),
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Chat History',
          ),
          title: Text(
            'AI Assistant',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 20.0,
                  letterSpacing: 0.0,
                ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.add_comment_rounded,
                    color: Colors.white, size: 22),
                onPressed: _isProcessing
                    ? null
                    : () => _startNewSession(addWelcome: true),
                tooltip: 'New Chat',
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (modelId) async {
                setState(() {
                  AiAssistantService.instance.setActiveModel(modelId);
                });
                _updateQuota();
              },
              itemBuilder: (context) => AiAssistantService.instance.freeModels.map((m) {
                return PopupMenuItem<String>(
                  value: m['id'],
                  child: Text(m['name'] ?? m['id'] ?? ''),
                );
              }).toList(),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 12, 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AiAssistantService.instance.activeModelName,
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Readex Pro',
                                color: Colors.white,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AiAssistantService.instance.isActiveModelFree
                          ? 'Free Model'
                          : _budgetSpendString,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Readex Pro',
                            color: Colors.white70,
                            fontSize: 11.0,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // ── Message list ────────────────────────────────────────────
              Expanded(
                child: _messages.isEmpty && !_isProcessing
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _model.listScrollController,
                        reverse: true, // Native chat behavior: starts from the bottom
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          // With reverse: true, index 0 is at the bottom, so we reverse the list access
                          final msg = _messages[_messages.length - 1 - i];
                          return _buildMessageTile(msg);
                        },
                      ),
              ),

              // ── Typing indicator ────────────────────────────────────────
              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Thinking…',
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                  fontFamily: 'Readex Pro',
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),

              // ── Input bar ───────────────────────────────────────────────
              _buildInputBar(),

              if (MediaQuery.of(context).viewInsets.bottom == 0)
                const AdminNavBar(currentTab: AdminTab.assistant),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: FlutterFlowTheme.of(context).primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Chat History',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // New Chat button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New Chat'),
                onPressed: () => _startNewSession(addWelcome: true),
              ),
            ),

            const Divider(height: 16),

            // Session list
            Expanded(
              child: _sessionsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                      ? Center(
                          child: Text('No previous chats',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                      fontFamily: 'Readex Pro',
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _sessions.length,
                          itemBuilder: (ctx, i) =>
                              _buildSessionTile(_sessions[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(AiChatSession session) {
    final isActive = session.id == AiAssistantService.instance.currentSessionId;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 18,
          color: isActive
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryText,
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Readex Pro',
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).primaryText,
              ),
        ),
        subtitle: Text(
          timeago.format(session.updatedAt),
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Readex Pro',
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 11,
              ),
        ),
        onTap: () => _openSession(session),
        onLongPress: () => _showSessionActions(session),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, size: 18),
          color: FlutterFlowTheme.of(context).secondaryText,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _showSessionActions(session),
        ),
      ),
    );
  }

  void _showSessionActions(AiChatSession session) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _renameSession(session);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: FlutterFlowTheme.of(context).error),
              title: Text('Delete',
                  style: TextStyle(color: FlutterFlowTheme.of(context).error)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteSession(session);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Message tiles ───────────────────────────────────────────────────────

  Widget _buildMessageTile(ChatMessage msg) {
    if (msg.isFunctionCall) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FlutterFlowTheme.of(context).alternate),
            ),
            child: Text(
              msg.text,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Readex Pro',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.0,
          left: msg.isUser ? 48.0 : 0.0,
          right: msg.isUser ? 0.0 : 48.0,
        ),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: msg.isUser
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12.0).copyWith(
            bottomRight: msg.isUser ? Radius.zero : const Radius.circular(12.0),
            bottomLeft: msg.isUser ? const Radius.circular(12.0) : Radius.zero,
          ),
          boxShadow: const [
            BoxShadow(
                blurRadius: 3.0,
                color: Color(0x1A000000),
                offset: Offset(0.0, 1.0))
          ],
        ),
        child: MarkdownBody(
          data: msg.text,
          builders: {
            'code': ChoiceMarkdownBuilder(context, (selectedValue) {
              if (msg.isUser)
                return; // Prevent user bubbles from triggering actions again
              // Inject the selected value into the chat input and send it automatically
              _model.textController?.text = selectedValue;
              _sendMessage();
            }),
          },
          styleSheet: MarkdownStyleSheet(
            p: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Readex Pro',
                  color: msg.isUser
                      ? FlutterFlowTheme.of(context).primaryBackground
                      : FlutterFlowTheme.of(context).primaryText,
                  letterSpacing: 0.0,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 48,
              color:
                  FlutterFlowTheme.of(context).primary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('How can I help you today?',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Readex Pro',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  )),
        ],
      ),
    );
  }

  // ── Input bar ───────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        boxShadow: const [
          BoxShadow(
              blurRadius: 4.0,
              color: Color(0x0F000000),
              offset: Offset(0.0, -2.0))
        ],
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_speechEnabled)
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening
                    ? FlutterFlowTheme.of(context).error
                    : FlutterFlowTheme.of(context).secondaryText,
                size: 26,
              ),
              onPressed: _isListening ? _stopListening : _startListening,
            ),
          Expanded(
            child: TextFormField(
              controller: _model.textController,
              focusNode: _model.textFieldFocusNode,
              obscureText: false,
              decoration: InputDecoration(
                hintText: _isListening ? 'Listening…' : 'Ask the assistant…',
                hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Readex Pro',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).primary, width: 1.0),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                contentPadding:
                    const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
              ),
              style: FlutterFlowTheme.of(context)
                  .bodyMedium
                  .override(fontFamily: 'Readex Pro'),
              maxLines: 4,
              minLines: 1,
              onFieldSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send_rounded,
                color: FlutterFlowTheme.of(context).primary, size: 26),
            onPressed: _isProcessing ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

class ChoiceMarkdownBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  final Function(String) onOptionSelected;

  ChoiceMarkdownBuilder(this.context, this.onOptionSelected);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final language = element.attributes['class'];
    if (language == 'language-json:choice') {
      final textContent = element.textContent;
      try {
        final data = jsonDecode(textContent);
        final question = data['question'] as String? ?? 'Choose an option:';
        final options = data['options'] as List? ?? [];

        return Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Readex Pro',
                      fontWeight: FontWeight.w600,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map<Widget>((opt) {
                  final label = opt['label'] as String? ?? '';
                  final value = opt['value'] as String? ?? '';
                  return ActionChip(
                    label: Text(label),
                    backgroundColor:
                        FlutterFlowTheme.of(context).secondaryBackground,
                    labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Readex Pro',
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 1),
                    ),
                    onPressed: () => onOptionSelected(value),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      } catch (e) {
        return Text('Error parsing choice block: $e',
            style: TextStyle(color: Colors.red));
      }
    }

    // Return null to fallback to default code block rendering for normal code
    return null;
  }
}
