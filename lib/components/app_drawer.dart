import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        final name = auth.userName ?? 'User';
        final email = auth.userEmail ?? '';
        final roleName = auth.role?.name ?? 'ENABLER';

        final initials = name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

        return Drawer(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Profile Header Section
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  context.push('/profile');
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20.0, 60.0, 20.0, 24.0),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  child: Row(
                    children: [
                      Container(
                        width: 54.0,
                        height: 54.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: const AlignmentDirectional(0.0, 0.0),
                        child: Text(
                          initials.isNotEmpty ? initials : 'U',
                          style: FlutterFlowTheme.of(context)
                              .titleMedium
                              .override(
                                font: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold),
                                color: FlutterFlowTheme.of(context).onPrimary,
                              ),
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 2.0),
                              Text(
                                email,
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(
                                          fontWeight: FontWeight.normal),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontSize: 12.0,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary10,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                roleName,
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold),
                                      color: FlutterFlowTheme.of(context).primary,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 1.0,
                color: FlutterFlowTheme.of(context).alternate,
              ),
              const SizedBox(height: 12.0),

              // Navigation Links
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  children: [
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.person_outline_rounded,
                      title: 'My Profile',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        context.push('/profile');
                      },
                    ),
                    const SizedBox(height: 4.0),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.key_outlined,
                      title: 'Access Control',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        context.push('/access');
                      },
                    ),
                    const SizedBox(height: 12.0),
                    Divider(color: FlutterFlowTheme.of(context).alternate, height: 1.0),
                    const SizedBox(height: 12.0),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      isDestructive: true,
                      onTap: () async {
                        Navigator.pop(context); // Close drawer
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            title: Text(
                              'Sign Out',
                              style: FlutterFlowTheme.of(context).titleLarge.override(
                                    font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                    color: FlutterFlowTheme.of(context).primaryText,
                                  ),
                            ),
                            content: Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Sign Out',
                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await AuthService.instance.signOut();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : FlutterFlowTheme.of(context).primaryText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22.0),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                title,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
