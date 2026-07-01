import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'section_header_model.dart';
export 'section_header_model.dart';

class SectionHeaderWidget extends StatefulWidget {
  const SectionHeaderWidget({
    super.key,
    String? count,
    String? title,
  })  : this.count = count ?? '3',
        this.title = title ?? 'Selected Members';

  final String count;
  final String title;

  @override
  State<SectionHeaderWidget> createState() => _SectionHeaderWidgetState();
}

class _SectionHeaderWidgetState extends State<SectionHeaderWidget> {
  late SectionHeaderModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SectionHeaderModel());
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
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
            valueOrDefault<String>(
              widget.title,
              'Selected Members',
            ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleMedium.fontStyle,
                  lineHeight: 1.4,
                ),
          ),
          ),
          const SizedBox(width: 8.0),
          Text(
            valueOrDefault<String>(
              widget.count,
              '3',
            ),
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelLarge.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primary,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).labelLarge.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  lineHeight: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}
