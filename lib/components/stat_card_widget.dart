import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stat_card_model.dart';
export 'stat_card_model.dart';

class StatCardWidget extends StatefulWidget {
  const StatCardWidget({
    super.key,
    String? label,
    String? value,
    this.icon,
    this.iconColor,
    this.iconBgColor,
  })  : this.label = label ?? 'Total Members',
        this.value = value ?? '1,284';

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;

  @override
  State<StatCardWidget> createState() => _StatCardWidgetState();
}

class _StatCardWidgetState extends State<StatCardWidget> {
  late StatCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StatCardModel());
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
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate.withOpacity(0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valueOrDefault<String>(
                      widget.label,
                      'Total Members',
                    ),
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          lineHeight: 1.2,
                        ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    valueOrDefault<String>(
                      widget.value,
                      '1,284',
                    ),
                    style: FlutterFlowTheme.of(context).titleLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          lineHeight: 1.2,
                          fontSize: 24.0,
                        ),
                  ),
                ],
              ),
            ),
            if (widget.icon != null) ...[
              const SizedBox(width: 8.0),
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: widget.iconBgColor ??
                      FlutterFlowTheme.of(context).accent1,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  widget.icon,
                  color:
                      widget.iconColor ?? FlutterFlowTheme.of(context).primary,
                  size: 22.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
