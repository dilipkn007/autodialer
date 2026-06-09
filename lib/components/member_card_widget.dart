import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'member_card_model.dart';
export 'member_card_model.dart';

class MemberCardWidget extends StatefulWidget {
  const MemberCardWidget({
    super.key,
    String? currentEnabler,
    String? folkId,
    String? name,
    bool? selected,
    this.assignmentStatus,
  })  : this.currentEnabler = currentEnabler ?? 'Unassigned',
        this.folkId = folkId ?? 'YV25W30045S',
        this.name = name ?? 'Rahul Vardhan',
        this.selected = selected ?? true;

  final String currentEnabler;
  final String folkId;
  final String name;
  final bool selected;
  final String? assignmentStatus;

  @override
  State<MemberCardWidget> createState() => _MemberCardWidgetState();
}

class _MemberCardWidgetState extends State<MemberCardWidget> {
  late MemberCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MemberCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
      child: Container(
        child: Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            shape: BoxShape.rectangle,
            border: Border.all(
              color: valueOrDefault<Color>(
                valueOrDefault<bool>(
                  widget.selected,
                  true,
                )
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).alternate,
                FlutterFlowTheme.of(context).primary,
              ),
              width: valueOrDefault<double>(
                valueOrDefault<bool>(
                  widget.selected,
                  true,
                )
                    ? 1.0
                    : 1.0,
                1.0,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Container(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: BoxDecoration(
                      color: valueOrDefault<Color>(
                        valueOrDefault<bool>(
                          widget.selected,
                          true,
                        )
                            ? FlutterFlowTheme.of(context).primary
                            : Colors.transparent,
                        FlutterFlowTheme.of(context).primary,
                      ),
                      borderRadius: BorderRadius.circular(9999.0),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: valueOrDefault<Color>(
                          valueOrDefault<bool>(
                            widget.selected,
                            true,
                          )
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).alternate,
                          FlutterFlowTheme.of(context).primary,
                        ),
                        width: valueOrDefault<double>(
                          valueOrDefault<bool>(
                            widget.selected,
                            true,
                          )
                              ? 2.0
                              : 2.0,
                          2.0,
                        ),
                      ),
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Visibility(
                      visible: valueOrDefault<bool>(
                        widget.selected,
                        true,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: FlutterFlowTheme.of(context).onPrimary,
                        size: 16.0,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          valueOrDefault<String>(
                            widget.name,
                            'Rahul Vardhan',
                          ),
                          maxLines: 1,
                          style: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                font: GoogleFonts.outfit(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                                lineHeight: 1.4,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              valueOrDefault<String>(
                                widget.folkId,
                                'YV25W30045S',
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            Text(
                              '•',
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).accent3,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            Text(
                              valueOrDefault<String>(
                                widget.currentEnabler,
                                'Unassigned',
                              ),
                              maxLines: 1,
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.2,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ].divide(SizedBox(width: 4.0)),
                        ),
                      ].divide(SizedBox(height: 4.0)),
                    ),
                  ),
                  if (widget.assignmentStatus != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: widget.assignmentStatus == 'COMPLETED' 
                            ? Colors.green.withValues(alpha: 0.1) 
                            : FlutterFlowTheme.of(context).alternate.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        widget.assignmentStatus!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.assignmentStatus == 'COMPLETED' 
                              ? Colors.green 
                              : FlutterFlowTheme.of(context).secondaryText,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: FlutterFlowTheme.of(context).accent3,
                      size: 20.0,
                    ),
                ].divide(SizedBox(width: 16.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
