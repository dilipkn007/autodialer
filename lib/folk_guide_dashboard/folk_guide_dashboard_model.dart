import '/components/activity_item_widget.dart';
import '/components/stat_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'folk_guide_dashboard_widget.dart' show FolkGuideDashboardWidget;
import 'package:flutter/material.dart';

class FolkGuideDashboardModel
    extends FlutterFlowModel<FolkGuideDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for StatCard.
  late StatCardModel statCardModel1;
  // Model for StatCard.
  late StatCardModel statCardModel2;
  // Model for StatCard.
  late StatCardModel statCardModel3;
  // Model for StatCard.
  late StatCardModel statCardModel4;
  // Model for ActivityItem.
  late ActivityItemModel activityItemModel1;
  // Model for ActivityItem.
  late ActivityItemModel activityItemModel2;
  // Model for ActivityItem.
  late ActivityItemModel activityItemModel3;
  // Model for ActivityItem.
  late ActivityItemModel activityItemModel4;

  @override
  void initState(BuildContext context) {
    statCardModel1 = createModel(context, () => StatCardModel());
    statCardModel2 = createModel(context, () => StatCardModel());
    statCardModel3 = createModel(context, () => StatCardModel());
    statCardModel4 = createModel(context, () => StatCardModel());
    activityItemModel1 = createModel(context, () => ActivityItemModel());
    activityItemModel2 = createModel(context, () => ActivityItemModel());
    activityItemModel3 = createModel(context, () => ActivityItemModel());
    activityItemModel4 = createModel(context, () => ActivityItemModel());
  }

  @override
  void dispose() {
    statCardModel1.dispose();
    statCardModel2.dispose();
    statCardModel3.dispose();
    statCardModel4.dispose();
    activityItemModel1.dispose();
    activityItemModel2.dispose();
    activityItemModel3.dispose();
    activityItemModel4.dispose();
  }
}
