import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    if (role == UserRole.FOLK_GUIDE) {
      await _pickFolkGuide();
      return;
    }
    AuthService.instance.setEffectiveRole(role);
  }

  Future<void> _pickFolkGuide() async {
    try {
      final folkGuides = await Supabase.instance.client
          .from('folk_guide_id')
          .select('folk_guide_id, name, phone')
          .order('name');

      if (!mounted) return;

      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          title: Text(
            'Select Folk Guide',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                color: FlutterFlowTheme.of(context).primaryText),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: folkGuides.isEmpty
                ? Text('No folk guides found. Add them in the database first.',
                    style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: folkGuides.length,
                    itemBuilder: (ctx, i) {
                      final fg = folkGuides[i];
                      return ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              (fg['folk_guide_id'] as String).substring(0, 2).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                          ),
                        ),
                        title: Text(fg['name'] ?? '',
                            style: TextStyle(
                                color: FlutterFlowTheme.of(context).primaryText)),
                        subtitle: Text('ID: ${fg['folk_guide_id']}',
                            style: TextStyle(
                                color: FlutterFlowTheme.of(context).secondaryText)),
                        onTap: () => Navigator.pop(ctx, fg),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText)),
            ),
          ],
        ),
      );

      if (selected != null && mounted) {
        AuthService.instance.setEffectiveRole(
          UserRole.FOLK_GUIDE,
          folkGuideId: selected['folk_guide_id'] as String?,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load folk guides: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final rawRole = AuthService.instance.role;
    final isAdmin = rawRole == UserRole.ADMIN;

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
                  isAdmin
                      ? 'You have admin privileges. How would you like to log in?'
                      : 'You are a folk guide. How would you like to log in?',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),
                if (isAdmin)
                  _RoleCard(
                    theme: theme,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Login as Admin',
                    subtitle:
                        'Full access to manage contacts, enablers, events, and settings',
                    color: theme.primary,
                    onTap: () => _selectRole(UserRole.ADMIN),
                  ),
                if (isAdmin)
                  const SizedBox(height: 12),
                _RoleCard(
                  theme: theme,
                  icon: Icons.people_alt_rounded,
                  title: 'Login as Folk Guide',
                  subtitle:
                      'Manage your folk-specific contacts, enablers, and campaigns',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _selectRole(UserRole.FOLK_GUIDE),
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
                const SizedBox(height: 12),
                _RoleCard(
                  theme: theme,
                  icon: Icons.event_note_rounded,
                  title: 'Login as Folk',
                  subtitle:
                      'View events and manage your RSVP',
                  color: const Color(0xFFEC4899),
                  onTap: () => _selectRole(UserRole.FOLK),
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
