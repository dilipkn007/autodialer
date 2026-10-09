import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';

enum AdminTab {
  calling,
  events,
  tokens,
}

class AdminNavBar extends StatelessWidget {
  final AdminTab currentTab;

  const AdminNavBar({
    super.key,
    required this.currentTab,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.role == UserRole.ADMIN;

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        boxShadow: [
          BoxShadow(
            blurRadius: 8.0,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0.0, -2.0),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 1.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).alternate,
            ),
          ),
          Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(16.0, 10.0, 16.0, 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Calling Tab
                _buildTabItem(
                  context: context,
                  tab: AdminTab.calling,
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Calling',
                  onTap: () {
                    if (currentTab != AdminTab.calling) {
                      context.go('/assignedContacts');
                    }
                  },
                ),
                // Events Tab
                _buildTabItem(
                  context: context,
                  tab: AdminTab.events,
                  icon: Icons.event_note_rounded,
                  label: 'Events',
                  onTap: () {
                    if (currentTab != AdminTab.events) {
                      context.go('/events');
                    }
                  },
                ),
                // Tokens Tab (Admin Only)
                if (isAdmin)
                  _buildTabItem(
                    context: context,
                    tab: AdminTab.tokens,
                    icon: Icons.key_rounded,
                    label: 'Tokens',
                    onTap: () {
                      if (currentTab != AdminTab.tokens) {
                        context.go('/access');
                      }
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
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24.0,
            ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                    color: color,
                    letterSpacing: 0.0,
                    fontSize: 11.0,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
