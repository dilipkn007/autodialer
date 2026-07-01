import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'local_contact_card_model.dart';
export 'local_contact_card_model.dart';

class LocalContactCardWidget extends StatefulWidget {
  const LocalContactCardWidget({
    super.key,
    String? city,
    String? date,
    String? folkId,
    String? initials,
    String? name,
  })  : this.city = city ?? 'Bangalore',
        this.date = date ?? 'Oct 28',
        this.folkId = folkId ?? 'YV25W30045S',
        this.initials = initials ?? 'AR',
        this.name = name ?? 'Arjun Raghav';

  final String city;
  final String date;
  final String folkId;
  final String initials;
  final String name;

  @override
  State<LocalContactCardWidget> createState() => _LocalContactCardWidgetState();
}

class _LocalContactCardWidgetState extends State<LocalContactCardWidget> {
  late LocalContactCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalContactCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
      child: Container(
        child: Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            shape: BoxShape.rectangle,
            border: Border.all(
              color: FlutterFlowTheme.of(context).alternate,
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Text(
                                valueOrDefault<String>(
                                  widget.initials,
                                  'AR',
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .onPrimaryContainer,
                                      fontSize: 18.24,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                      lineHeight: 1.3,
                                    ),
                                overflow: TextOverflow.clip,
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
                                      'Arjun Raghav',
                                    ),
                                    maxLines: 1,
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                          lineHeight: 1.4,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                    Builder(builder: (context) {
                                    final isCompleted =
                                        widget.date == 'COMPLETED';
                                    final isPending =
                                        widget.date == 'PENDING' ||
                                            widget.date == 'NEW';
                                      
                                      Color badgeColor;
                                      Color textColor;
                                      if (isCompleted) {
                                      badgeColor = FlutterFlowTheme.of(context)
                                          .success
                                          .withValues(alpha: 0.2);
                                      textColor =
                                          FlutterFlowTheme.of(context).success;
                                      } else if (isPending) {
                                      badgeColor = FlutterFlowTheme.of(context)
                                          .warning
                                          .withValues(alpha: 0.2);
                                      textColor =
                                          FlutterFlowTheme.of(context).warning;
                                      } else {
                                      badgeColor = FlutterFlowTheme.of(context)
                                          .alternate;
                                      textColor = FlutterFlowTheme.of(context)
                                          .primaryText;
                                      }

                                      return Row(
                                      mainAxisSize: MainAxisSize.max,
                                        children: [
                                        Expanded(
                                          child: Text(
                                            valueOrDefault<String>(
                                              'ID: ${widget.folkId}',
                                              'ID: YV25W30045S',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .override(
                                                  font: GoogleFonts.inter(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontStyle,
                                                  lineHeight: 1.2,
                                                ),
                                          ),
                                        ),
                                          const SizedBox(width: 8.0),
                                          Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              widget.date,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(width: 16.0)),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).success,
                          borderRadius: BorderRadius.circular(9999.0),
                          shape: BoxShape.rectangle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Container(
                            child: Icon(
                              Icons.phone,
                              color: FlutterFlowTheme.of(context).onSuccess,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
