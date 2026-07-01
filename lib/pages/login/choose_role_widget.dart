import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';

class ChooseRoleWidget extends StatefulWidget {
  const ChooseRoleWidget({super.key});

  static String routeName = 'ChooseRole';
  static String routePath = '/chooseRole';

  @override
  State<ChooseRoleWidget> createState() => _ChooseRoleWidgetState();
}

class _ChooseRoleWidgetState extends State<ChooseRoleWidget> {
  Future<void> _selectRole(UserRole role) async {
    AuthService.instance.setEffectiveRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.swap_horiz_rounded,
                      size: 32, color: theme.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome!',
                  style: theme.headlineMedium.override(
                    font: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                    color: theme.primaryText,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have admin privileges. How would you like to log in?',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),
                _RoleCard(
                  theme: theme,
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Login as Admin',
                  subtitle:
                      'Full access to manage contacts, enablers, events, and settings',
                  color: theme.primary,
                  onTap: () => _selectRole(UserRole.ADMIN),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  theme: theme,
                  icon: Icons.phone_in_talk_rounded,
                  title: 'Login as Enabler',
                  subtitle:
                      'Make calls, manage assigned contacts, and track follow-ups',
                  color: const Color(0xFF25D366),
                  onTap: () => _selectRole(UserRole.ENABLER),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final FlutterFlowTheme theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.alternate),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: theme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
