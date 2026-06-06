import '/components/button_widget.dart';
import '/components/local_contact_card_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'assigned_contacts_widget.dart' show AssignedContactsWidget;
import 'package:flutter/material.dart';

class AssignedContactsModel extends FlutterFlowModel<AssignedContactsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TextField.
  late TextFieldModel textFieldModel;
  // Model for LocalContactCard.
  late LocalContactCardModel localContactCardModel;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    textFieldModel = createModel(context, () => TextFieldModel());
    localContactCardModel = createModel(context, () => LocalContactCardModel());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    textFieldModel.dispose();
    localContactCardModel.dispose();
    buttonModel.dispose();
  }
}
