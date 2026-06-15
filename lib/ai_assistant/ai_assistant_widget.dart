import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:f_o_l_k_auto_dialer/services/ai_assistant_service.dart';
import 'package:f_o_l_k_auto_dialer/components/admin_nav_bar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'ai_assistant_model.dart';
export 'ai_assistant_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isFunctionCall;
  
  ChatMessage({required this.text, required this.isUser, this.isFunctionCall = false});
}

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
        debugPrint('onSpeechStatus: $val');
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
          _sendVoiceMessage();
        }
      },
    );
    setState(() {});
  }

  void _initService() async {
    await AiAssistantService.instance.initialize();
    _updateQuota();
    
    setState(() {
      _messages.add(ChatMessage(
        text: "Hello! I'm your FOLK Auto Dialer AI assistant. How can I help you manage campaigns today?",
        isUser: false,
      ));
    });
  }

  void _updateQuota() async {
    final spendString = await AiAssistantService.instance.getBudgetAndSpend();
    setState(() {
      _budgetSpendString = spendString;
    });
  }

  void _startListening() async {
    if (_speechEnabled && !_isListening) {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _model.textController?.text = result.recognizedWords;
    });
  }

  void _sendVoiceMessage() {
    if (_model.textController?.text.isNotEmpty == true) {
      _sendMessage();
    }
  }

  Future<void> _sendMessage() async {
    final text = _model.textController?.text.trim() ?? '';
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _model.textController?.clear();
      _isProcessing = true;
    });
    
    _scrollToBottom();

    try {
      final stream = AiAssistantService.instance.sendMessageStream(
        text,
        onConfirmDestructive: (description) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Action'),
              content: Text('The assistant wants to perform a potentially destructive operation:\n\n$description\n\nAre you sure you want to proceed?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: FlutterFlowTheme.of(context).error,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Proceed'),
                ),
              ],
            ),
          ) ?? false;
        },
      );
      int? currentAiMsgIndex;

      await for (final response in stream) {
        if (response.functionCalls.isNotEmpty) {
          setState(() {
            _messages.add(ChatMessage(text: "⚡ Executing operation...", isUser: false, isFunctionCall: true));
          });
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
                isUser: false
              );
            });
          }
        }
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "⚠️ Error: ${e.toString()}", isUser: false));
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _scrollToBottom();
      _updateQuota();
    }
  }

  void _scrollToBottom() {
    if (_model.listScrollController != null && _model.listScrollController!.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _model.listScrollController!.animateTo(
          _model.listScrollController!.position.maxScrollExtent,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: Text(
            'AI Admin Assistant',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 16, 0),
              child: Center(
                child: Text(
                  _budgetSpendString,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Readex Pro',
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        fontSize: 12.0,
                      ),
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
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _model.listScrollController,
                  padding: EdgeInsets.all(16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    if (msg.isFunctionCall) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: msg.isUser 
                              ? FlutterFlowTheme.of(context).primary 
                              : FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(12.0).copyWith(
                            bottomRight: msg.isUser ? Radius.zero : Radius.circular(12.0),
                            bottomLeft: msg.isUser ? Radius.circular(12.0) : Radius.zero,
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 3.0,
                              color: Color(0x1A000000),
                              offset: Offset(0.0, 1.0),
                            )
                          ],
                        ),
                        child: MarkdownBody(
                          data: msg.text,
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
                  },
                ),
              ),
              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4.0,
                      color: Color(0x0F000000),
                      offset: Offset(0.0, -2.0),
                    )
                  ],
                ),
                padding: EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_speechEnabled)
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                        child: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening 
                                ? FlutterFlowTheme.of(context).error 
                                : FlutterFlowTheme.of(context).secondaryText,
                            size: 28.0,
                          ),
                          onPressed: _isListening ? _stopListening : _startListening,
                        ),
                      ),
                    Expanded(
                      child: TextFormField(
                        controller: _model.textController,
                        focusNode: _model.textFieldFocusNode,
                        obscureText: false,
                        decoration: InputDecoration(
                          hintText: _isListening ? 'Listening...' : 'Ask the assistant...',
                          hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Readex Pro',
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          contentPadding: EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Readex Pro',
                            ),
                        maxLines: 4,
                        minLines: 1,
                        onFieldSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
                      child: IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 28.0,
                        ),
                        onPressed: _isProcessing ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                const AdminNavBar(currentTab: AdminTab.assistant),
            ],
          ),
        ),
      ),
    );
  }
}
