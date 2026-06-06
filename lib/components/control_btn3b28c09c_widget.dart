import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'control_btn3b28c09c_model.dart';
export 'control_btn3b28c09c_model.dart';

class ControlBtn3b28c09cWidget extends StatefulWidget {
  const ControlBtn3b28c09cWidget({
    super.key,
    String? bg,
    Color? borderColor,
    String? color,
    String? icon,
    String? label,
  })  : this.bg = bg ?? 'surface_variant',
        this.borderColor = borderColor ?? const Color(0x00000000),
        this.color = color ?? 'primary_text',
        this.icon = icon ?? 'pause_rounded',
        this.label = label ?? 'Pause';

  final String bg;
  final Color borderColor;
  final String color;
  final String icon;
  final String label;

  @override
  State<ControlBtn3b28c09cWidget> createState() =>
      _ControlBtn3b28c09cWidgetState();
}

class _ControlBtn3b28c09cWidgetState extends State<ControlBtn3b28c09cWidget> {
  late ControlBtn3b28c09cModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ControlBtn3b28c09cModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).surfaceVariant,
        borderRadius: BorderRadius.circular(8.0),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Container(
          child: Container(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.pause_rounded,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 24.0,
                ),
                Text(
                  'Pause',
                  style: FlutterFlowTheme.of(context).labelSmall.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primaryText,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).labelSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelSmall.fontStyle,
                        lineHeight: 1.2,
                      ),
                ),
              ].divide(SizedBox(height: 4.0)),
            ),
          ),
        ),
      ),
    );
  }
}
