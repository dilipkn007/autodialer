import '/flutter_flow/flutter_flow_model.dart';
import 'package:flutter/material.dart';

class AiAssistantModel extends FlutterFlowModel {
  // State fields for stateful widgets in this page.
  final unfocusNode = FocusNode();
  
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  
  // ScrollController for the chat list
  ScrollController? listScrollController;

  /// Initialization and disposal methods.
  @override
  void initState(BuildContext context) {
    listScrollController = ScrollController();
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
    listScrollController?.dispose();
  }
}
