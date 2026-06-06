import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'form_label_c3deb8f0_model.dart';
export 'form_label_c3deb8f0_model.dart';

class FormLabelC3deb8f0Widget extends StatefulWidget {
  const FormLabelC3deb8f0Widget({
    super.key,
    String? label,
  }) : this.label = label ?? 'Call Outcome';

  final String label;

  @override
  State<FormLabelC3deb8f0Widget> createState() =>
      _FormLabelC3deb8f0WidgetState();
}

class _FormLabelC3deb8f0WidgetState extends State<FormLabelC3deb8f0Widget> {
  late FormLabelC3deb8f0Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FormLabelC3deb8f0Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 4.0),
      child: Container(
        child: Text(
          'Call Outcome',
          style: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.inter(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                lineHeight: 1.3,
              ),
        ),
      ),
    );
  }
}
