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

  Color _getColor(String colorName) {
    final theme = FlutterFlowTheme.of(context);
    switch (colorName) {
      case 'primary': return theme.primary;
      case 'surface_variant': return theme.surfaceVariant;
      case 'on_primary': return theme.onPrimary;
      case 'primary_text': return theme.primaryText;
      default: return theme.primaryText;
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'pause_rounded': return Icons.pause_rounded;
      case 'play_arrow_rounded': return Icons.play_arrow_rounded;
      case 'call_rounded': return Icons.call_rounded;
      default: return Icons.circle;
    }
  }

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
        color: _getColor(widget.bg),
        borderRadius: BorderRadius.circular(8.0),
        shape: BoxShape.rectangle,
        border: widget.borderColor != const Color(0x00000000)
            ? Border.all(color: widget.borderColor, width: 1.0)
            : null,
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
                  _getIcon(widget.icon),
                  color: _getColor(widget.color),
                  size: 24.0,
                ),
                Text(
                  widget.label,
                  style: FlutterFlowTheme.of(context).labelSmall.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                        ),
                        color: _getColor(widget.color),
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
