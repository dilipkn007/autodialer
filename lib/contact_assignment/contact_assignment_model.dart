import '/components/button_widget.dart';
import '/components/member_card_widget.dart';
import '/components/section_header_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'contact_assignment_widget.dart' show ContactAssignmentWidget;
import 'package:flutter/material.dart';

class ContactAssignmentModel extends FlutterFlowModel<ContactAssignmentWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TextField.
  late TextFieldModel textFieldModel;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Model for SectionHeader.
  late SectionHeaderModel sectionHeaderModel1;
  // Model for MemberCard.
  late MemberCardModel memberCardModel1;
  // Model for MemberCard.
  late MemberCardModel memberCardModel2;
  // Model for MemberCard.
  late MemberCardModel memberCardModel3;
  // Model for SectionHeader.
  late SectionHeaderModel sectionHeaderModel2;
  // Model for MemberCard.
  late MemberCardModel memberCardModel4;
  // Model for MemberCard.
  late MemberCardModel memberCardModel5;
  // Model for Button.
  late ButtonModel buttonModel3;

  @override
  void initState(BuildContext context) {
    textFieldModel = createModel(context, () => TextFieldModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    sectionHeaderModel1 = createModel(context, () => SectionHeaderModel());
    memberCardModel1 = createModel(context, () => MemberCardModel());
    memberCardModel2 = createModel(context, () => MemberCardModel());
    memberCardModel3 = createModel(context, () => MemberCardModel());
    sectionHeaderModel2 = createModel(context, () => SectionHeaderModel());
    memberCardModel4 = createModel(context, () => MemberCardModel());
    memberCardModel5 = createModel(context, () => MemberCardModel());
    buttonModel3 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    textFieldModel.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    sectionHeaderModel1.dispose();
    memberCardModel1.dispose();
    memberCardModel2.dispose();
    memberCardModel3.dispose();
    sectionHeaderModel2.dispose();
    memberCardModel4.dispose();
    memberCardModel5.dispose();
    buttonModel3.dispose();
  }
}
