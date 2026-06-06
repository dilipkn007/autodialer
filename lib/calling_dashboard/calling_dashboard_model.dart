import '/components/accordion_item_widget.dart';
import '/components/button_widget.dart';
import '/components/stat_item_d940b1b0_d940b1b0_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'calling_dashboard_widget.dart' show CallingDashboardWidget;
import 'package:flutter/material.dart';

class CallingDashboardModel extends FlutterFlowModel<CallingDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for AccordionItem.
  late AccordionItemModel accordionItemModel;
  // Model for StatItemD940b1b0D940b1b0.
  late StatItemD940b1b0D940b1b0Model statItemD940b1b0D940b1b0Model1;
  // Model for StatItemD940b1b0D940b1b0.
  late StatItemD940b1b0D940b1b0Model statItemD940b1b0D940b1b0Model2;
  // Model for StatItemD940b1b0D940b1b0.
  late StatItemD940b1b0D940b1b0Model statItemD940b1b0D940b1b0Model3;
  // Model for TextField.
  late TextFieldModel textFieldModel1;
  // Model for TextField.
  late TextFieldModel textFieldModel2;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    accordionItemModel = createModel(context, () => AccordionItemModel());
    statItemD940b1b0D940b1b0Model1 =
        createModel(context, () => StatItemD940b1b0D940b1b0Model());
    statItemD940b1b0D940b1b0Model2 =
        createModel(context, () => StatItemD940b1b0D940b1b0Model());
    statItemD940b1b0D940b1b0Model3 =
        createModel(context, () => StatItemD940b1b0D940b1b0Model());
    textFieldModel1 = createModel(context, () => TextFieldModel());
    textFieldModel2 = createModel(context, () => TextFieldModel());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    accordionItemModel.dispose();
    statItemD940b1b0D940b1b0Model1.dispose();
    statItemD940b1b0D940b1b0Model2.dispose();
    statItemD940b1b0D940b1b0Model3.dispose();
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    buttonModel.dispose();
  }
}
