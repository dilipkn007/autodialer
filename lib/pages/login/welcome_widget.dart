import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({super.key});

  static String routeName = 'Welcome';
  static String routePath = '/welcome';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLoggedIn = AuthService.instance.currentUser != null;

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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone_in_talk_rounded,
                      size: 40, color: theme.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  'FOLK Auto Dialer',
                  style: theme.headlineMedium.override(
                    font: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                    color: theme.primaryText,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLoggedIn
                      ? 'Choose your session role'
                      : 'Select your login method',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                  ),
                ),
                const SizedBox(height: 40),
                _WelcomeCard(
                  theme: theme,
                  icon: Icons.admin_panel_settings_rounded,
                  title: isLoggedIn ? 'Admin Mode' : 'Admin Login',
                  subtitle: isLoggedIn
                      ? 'Manage contacts, events, enablers, and settings'
                      : 'Use your phone number and OTP to manage contacts, events, and settings',
                  color: theme.primary,
                  onTap: () {
                    if (isLoggedIn) {
                      if (AuthService.instance.role == UserRole.ADMIN) {
                        AuthService.instance
                            .setEffectiveRole(UserRole.ADMIN);
                        context.go('/folkGuideDashboard');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'You don\'t have admin access'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      context.go('/login');
                    }
                  },
                ),
                _WelcomeCard(
                  theme: theme,
                  icon: Icons.people_alt_rounded,
                  title: isLoggedIn ? 'Folk Guide Mode' : 'Folk Guide Login',
                  subtitle: isLoggedIn
                      ? 'Manage your folk-specific contacts and enablers'
                      : 'Use your phone number to manage your folk-specific data',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    if (isLoggedIn) {
                      if (AuthService.instance.role == UserRole.FOLK_GUIDE) {
                        AuthService.instance
                            .setEffectiveRole(UserRole.FOLK_GUIDE);
                        context.go('/folkGuideDashboard');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'You don\'t have folk guide access'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      context.go('/login');
                    }
                  },
                ),
                _WelcomeCard(
                  theme: theme,
                  icon: Icons.people_rounded,
                  title: isLoggedIn ? 'Folk Mode' : 'Folk Login',
                  subtitle: isLoggedIn
                      ? 'View events and manage your RSVP'
                      : 'Use your access token to view events and RSVP',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    if (isLoggedIn) {
                      AuthService.instance
                          .setEffectiveRole(UserRole.FOLK);
                      context.go('/folkDashboard');
                    } else {
                      context.go('/login?mode=token');
                    }
                  },
                ),
                const SizedBox(height: 16),
                _WelcomeCard(
                  theme: theme,
                  icon: Icons.phone_in_talk_rounded,
                  title: isLoggedIn ? 'Enabler Mode' : 'Enabler Login',
                  subtitle: isLoggedIn
                      ? 'Make calls and manage assigned contacts'
                      : 'Use your access token to make calls and manage assigned contacts',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    if (isLoggedIn) {
                      AuthService.instance.setEffectiveRole(UserRole.ENABLER);
                      context.go('/assignedContacts');
                    } else {
                      context.go('/login?mode=token');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final FlutterFlowTheme theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WelcomeCard({
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
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.alternate,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleMedium.override(
                        font: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
