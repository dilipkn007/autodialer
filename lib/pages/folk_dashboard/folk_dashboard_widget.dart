import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import '/components/app_drawer.dart';
import 'folk_dashboard_model.dart';

export 'folk_dashboard_model.dart';

class FolkDashboardWidget extends StatefulWidget {
  const FolkDashboardWidget({super.key});

  static String routeName = 'FolkDashboard';
  static String routePath = '/folkDashboard';

  @override
  State<FolkDashboardWidget> createState() => _FolkDashboardWidgetState();
}

class _FolkDashboardWidgetState extends State<FolkDashboardWidget> {
  late FolkDashboardModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _events = [];
  Map<String, String> _myRsvps = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FolkDashboardModel());
    _loadData();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<String?> _findContactId() async {
    final uid = AuthService.instance.currentUser?.id ?? '';
    if (uid.isEmpty) return null;

    var contactRes = await Supabase.instance.client
        .from('contact')
        .select('id')
        .eq('id', uid)
        .maybeSingle();

    if (contactRes != null) return contactRes['id'] as String;

    final authPhone = AuthService.instance.currentUser?.phone ?? '';
    if (authPhone.isEmpty) return null;

    final raw10 = authPhone.length >= 10
        ? authPhone.substring(authPhone.length - 10)
        : authPhone;
    final formatVariants = <String>{authPhone, raw10, '91$raw10', '+91$raw10'};
    formatVariants.remove('');

    final phoneContacts = await Supabase.instance.client
        .from('contact')
        .select('id')
        .inFilter('mobile', formatVariants.toList())
        .limit(1);

    if (phoneContacts.isNotEmpty) {
      return phoneContacts.first['id'] as String;
    }

    return null;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final contactId = await _findContactId();
      if (contactId == null) return;

      final events = await Supabase.instance.client
          .from('event')
          .select()
          .order('event_date', ascending: true);

      final rsvps = await Supabase.instance.client
          .from('event_rsvp')
          .select()
          .eq('contact_id', contactId);

      final rsvpMap = <String, String>{};
      for (final r in rsvps) {
        rsvpMap[r['event_id'] as String] = r['status'] as String;
      }

      setState(() {
        _events = List<Map<String, dynamic>>.from(events);
        _myRsvps = rsvpMap;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading folk dashboard: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _updateRsvp(String eventId, String status) async {
    try {
      final contactId = await _findContactId();
      if (contactId == null) return;

      await Supabase.instance.client.from('event_rsvp').upsert({
        'event_id': eventId,
        'contact_id': contactId,
        'status': status,
      }, onConflict: 'event_id,contact_id');

      setState(() => _myRsvps[eventId] = status);
    } catch (e) {
      debugPrint("Error updating RSVP: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update RSVP: $e')),
        );
      }
    }
  }

  Color _rsvpColor(String? status) {
    switch (status) {
      case 'GOING':
        return const Color(0xFF22C55E);
      case 'NOT_GOING':
        return const Color(0xFFEF4444);
      case 'MAYBE':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _rsvpLabel(String? status) {
    switch (status) {
      case 'GOING':
        return 'Going';
      case 'NOT_GOING':
        return 'Not Going';
      case 'MAYBE':
        return 'Maybe';
      default:
        return 'No RSVP';
    }
  }

  IconData _rsvpIcon(String? status) {
    switch (status) {
      case 'GOING':
        return Icons.check_circle_rounded;
      case 'NOT_GOING':
        return Icons.cancel_rounded;
      case 'MAYBE':
        return Icons.help_rounded;
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final auth = AuthService.instance;
        if (auth.role != null && auth.effectiveRole != auth.role) {
          auth.setEffectiveRole(auth.role!);
          final target = switch (auth.role) {
            UserRole.ADMIN => '/folkGuideDashboard',
            UserRole.FOLK_GUIDE => '/folkGuideDashboard',
            UserRole.FOLK => '/folkDashboard',
            _ => '/assignedContacts',
          };
          Future.microtask(() {
            if (context.mounted) context.go(target);
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: theme.primaryBackground,
          endDrawer: const AppDrawer(),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.primaryBackground,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Events',
                                  style: theme.headlineMedium.override(
                                    font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                    color: theme.primaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    lineHeight: 1.2,
                                  ),
                                ),
                                Text(
                                  'View events and manage your RSVP',
                                  style: theme.bodySmall.override(
                                    font: GoogleFonts.inter(),
                                    color: theme.secondaryText,
                                    letterSpacing: 0.0,
                                    lineHeight: 1.4,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.menu_rounded,
                                color: theme.primaryText,
                                size: 28.0,
                              ),
                              onPressed: () {
                                scaffoldKey.currentState?.openEndDrawer();
                              },
                              tooltip: 'Menu',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _events.isEmpty
                          ? ListView(
                              children: const [
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(48),
                                    child: Text('No events available.'),
                                  ),
                                ),
                              ],
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: _events.length,
                                itemBuilder: (context, index) {
                                  final event = _events[index];
                                  final eventId = event['id'] as String;
                                  final rsvpStatus = _myRsvps[eventId];
                                  return _EventCard(
                                    theme: theme,
                                    event: event,
                                    rsvpStatus: rsvpStatus,
                                    rsvpColor: _rsvpColor(rsvpStatus),
                                    rsvpLabel: _rsvpLabel(rsvpStatus),
                                    rsvpIcon: _rsvpIcon(rsvpStatus),
                                    onRsvp: (status) =>
                                        _updateRsvp(eventId, status),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final FlutterFlowTheme theme;
  final Map<String, dynamic> event;
  final String? rsvpStatus;
  final Color rsvpColor;
  final String rsvpLabel;
  final IconData rsvpIcon;
  final void Function(String) onRsvp;

  const _EventCard({
    required this.theme,
    required this.event,
    required this.rsvpStatus,
    required this.rsvpColor,
    required this.rsvpLabel,
    required this.rsvpIcon,
    required this.onRsvp,
  });

  String _formatDate(String dateStr) {
    try {
      return DateFormat('EEEE, MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.alternate, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['name'] as String? ?? 'Unnamed Event',
                          style: theme.titleMedium.override(
                            font: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                            color: theme.primaryText,
                            letterSpacing: 0.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(event['event_date'] as String? ?? ''),
                          style: theme.bodySmall.override(
                            font: GoogleFonts.inter(),
                            color: theme.secondaryText,
                            letterSpacing: 0.0,
                          ),
                        ),
                        if (event['description'] != null &&
                            (event['description'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            event['description'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall.override(
                              font: GoogleFonts.inter(),
                              color: theme.secondaryText,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (rsvpStatus != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: rsvpColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(rsvpIcon, size: 14, color: rsvpColor),
                          const SizedBox(width: 4),
                          Text(
                            rsvpLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: rsvpColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _RsvpChip(
                    label: 'Going',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF22C55E),
                    isSelected: rsvpStatus == 'GOING',
                    onTap: () => onRsvp('GOING'),
                  ),
                  const SizedBox(width: 8),
                  _RsvpChip(
                    label: 'Maybe',
                    icon: Icons.help_rounded,
                    color: const Color(0xFFF59E0B),
                    isSelected: rsvpStatus == 'MAYBE',
                    onTap: () => onRsvp('MAYBE'),
                  ),
                  const SizedBox(width: 8),
                  _RsvpChip(
                    label: 'Not Going',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFEF4444),
                    isSelected: rsvpStatus == 'NOT_GOING',
                    onTap: () => onRsvp('NOT_GOING'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RsvpChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RsvpChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : const Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
