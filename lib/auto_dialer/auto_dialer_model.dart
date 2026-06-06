import '/components/accordion_item_widget.dart';
import '/components/control_btn3b28c09c_widget.dart';
import '/components/form_label_c3deb8f0_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'auto_dialer_widget.dart' show AutoDialerWidget;
import 'package:flutter/material.dart';

class AutoDialerModel extends FlutterFlowModel<AutoDialerWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for AccordionItem.
  late AccordionItemModel accordionItemModel;
  // Model for FormLabelC3deb8f0.
  late FormLabelC3deb8f0Model formLabelC3deb8f0Model1;
  // State field(s) for Dropdown widget.
  String? dropdownValue1;
  FormFieldController<String>? dropdownValueController1;
  // Model for FormLabelC3deb8f0.
  late FormLabelC3deb8f0Model formLabelC3deb8f0Model2;
  // State field(s) for Dropdown widget.
  String? dropdownValue2;
  FormFieldController<String>? dropdownValueController2;
  // Model for FormLabelC3deb8f0.
  late FormLabelC3deb8f0Model formLabelC3deb8f0Model3;
  // Model for TextField.
  late TextFieldModel textFieldModel;
  // Model for FormLabelC3deb8f0.
  late FormLabelC3deb8f0Model formLabelC3deb8f0Model4;
  // Model for ControlBtn3b28c09c.
  late ControlBtn3b28c09cModel controlBtn3b28c09cModel;

  @override
  void initState(BuildContext context) {
    accordionItemModel = createModel(context, () => AccordionItemModel());
    formLabelC3deb8f0Model1 =
        createModel(context, () => FormLabelC3deb8f0Model());
    formLabelC3deb8f0Model2 =
        createModel(context, () => FormLabelC3deb8f0Model());
    formLabelC3deb8f0Model3 =
        createModel(context, () => FormLabelC3deb8f0Model());
    textFieldModel = createModel(context, () => TextFieldModel());
    formLabelC3deb8f0Model4 =
        createModel(context, () => FormLabelC3deb8f0Model());
    controlBtn3b28c09cModel =
        createModel(context, () => ControlBtn3b28c09cModel());
  }

  @override
  void dispose() {
    accordionItemModel.dispose();
    formLabelC3deb8f0Model1.dispose();
    formLabelC3deb8f0Model2.dispose();
    formLabelC3deb8f0Model3.dispose();
    textFieldModel.dispose();
    formLabelC3deb8f0Model4.dispose();
    controlBtn3b28c09cModel.dispose();
  }
}
