import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stat_item_d940b1b0_d940b1b0_model.dart';
export 'stat_item_d940b1b0_d940b1b0_model.dart';

class StatItemD940b1b0D940b1b0Widget extends StatefulWidget {
  const StatItemD940b1b0D940b1b0Widget({
    super.key,
    String? label,
    String? value,
  })  : this.label = label ?? 'Status',
        this.value = value ?? 'Active';

  final String label;
  final String value;

  @override
  State<StatItemD940b1b0D940b1b0Widget> createState() =>
      _StatItemD940b1b0D940b1b0WidgetState();
}

class _StatItemD940b1b0D940b1b0WidgetState
    extends State<StatItemD940b1b0D940b1b0Widget> {
  late StatItemD940b1b0D940b1b0Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StatItemD940b1b0D940b1b0Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          valueOrDefault<String>(
            widget.label,
            'Status',
          ),
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.inter(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                lineHeight: 1.2,
              ),
        ),
        Text(
          valueOrDefault<String>(
            widget.value,
            'Active',
          ),
          maxLines: 1,
          style: FlutterFlowTheme.of(context).titleSmall.override(
                font: GoogleFonts.outfit(
                  fontWeight:
                      FlutterFlowTheme.of(context).titleSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                lineHeight: 1.4,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ].divide(SizedBox(height: 4.0)),
    );
  }
}
