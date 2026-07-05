import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

enum AdminTab {
  contacts,
  dashboard,
  enablers,
  events,
  assistant,
  access,
}

class AdminNavBar extends StatelessWidget {
  final AdminTab currentTab;

  const AdminNavBar({
    super.key,
    required this.currentTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        shape: BoxShape.rectangle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 1.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).alternate,
              shape: BoxShape.rectangle,
            ),
          ),
          Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Contacts Tab
                _buildTabItem(
                  context: context,
                  tab: AdminTab.contacts,
                  icon: Icons.group_rounded,
                  label: 'Contacts',
                  onTap: () {
                    context.go('/contactAssignment');
                  },
                ),
                // Dashboard Tab
                _buildTabItem(
                  context: context,
                  tab: AdminTab.dashboard,
                  icon: Icons.analytics_rounded,
                  label: 'Dashboard',
                  onTap: () {
                    context.go('/folkGuideDashboard');
                  },
                ),
                // Assistant Tab
                _buildTabItem(
                  context: context,
                  tab: AdminTab.assistant,
                  icon: Icons.auto_awesome,
                  label: 'Assistant',
                  onTap: () {
                    context.go('/aiAssistant');
                  },
                ),
                // Enablers Tab
                _buildTabItem(
                  context: context,
                  tab: AdminTab.enablers,
                  icon: Icons.people_alt_rounded,
                  label: 'Enablers',
                  onTap: () {
                    context.go('/enablers');
                  },
                ),
                // Events Tab
                _buildTabItem(
                  context: context,
                  tab: AdminTab.events,
                  icon: Icons.event_note_rounded,
                  label: 'Events',
                  onTap: () {
                    context.go('/events');
                  },
                ),
                // Access Management Tab
                _buildTabItem(
                  context: context,
                  tab: AdminTab.access,
                  icon: Icons.key_rounded,
                  label: 'Access',
                  onTap: () {
                    context.go('/access');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required AdminTab tab,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isActive = currentTab == tab;
    final color = isActive
        ? FlutterFlowTheme.of(context).primary
        : FlutterFlowTheme.of(context).secondaryText;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 22.0,
          ),
          Text(
            label,
            style: FlutterFlowTheme.of(context).labelSmall.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  ),
                  color: color,
                  letterSpacing: 0.0,
                  lineHeight: 1.2,
                ),
          ),
        ].divide(const SizedBox(height: 2.0)),
      ),
    );
  }
}
