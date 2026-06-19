import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String formatTime(DateTime dt) {
  final now = DateTime.now();
  final local = dt.toLocal();
  final isToday = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final isYesterday = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day - 1;

  final timeStr = DateFormat('h:mm a').format(local);
  if (isToday) return 'Today, $timeStr';
  if (isYesterday) return 'Yesterday, $timeStr';
  return DateFormat('d MMM, h:mm a').format(local);
}


class RecentActivityWidget extends StatefulWidget {
  const RecentActivityWidget({Key? key}) : super(key: key);

  static const String routeName = 'RecentActivity';
  static const String routePath = '/recentActivity';

  @override
  State<RecentActivityWidget> createState() => _RecentActivityWidgetState();
}

class _RecentActivityWidgetState extends State<RecentActivityWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>>? _activities;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    setState(() => _loading = true);
    try {
      final activityRes = await Supabase.instance.client
          .from('call_log')
          .select('*, contact(*), enabler:users(*), event(*)')
          .order('called_at', ascending: false)
          .limit(100);
      setState(() {
        _activities = activityRes;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading recent activity: $e");
      setState(() => _loading = false);
    }
  }

  // ── Outcome helpers ───────────────────────────────────────────────────────
  String _outcomeName(String outcome) => outcome;

  Color _outcomeColor(String outcome) {
    switch (outcome) {
      case 'ANSWERED':
        return const Color(0xFF2E7D32); // deep green
      case 'BUSY':
        return const Color(0xFFE65100); // deep orange
      case 'NO_RESPONSE':
        return const Color(0xFF6A1B9A); // purple
      default:
        return const Color(0xFFC62828); // deep red
    }
  }

  Color _outcomeBg(String outcome) {
    switch (outcome) {
      case 'ANSWERED':
        return const Color(0xFFE8F5E9);
      case 'BUSY':
        return const Color(0xFFFFF3E0);
      case 'NO_RESPONSE':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFFFEBEE);
    }
  }

  IconData _outcomeIcon(String outcome) {
    switch (outcome) {
      case 'ANSWERED':
        return Icons.call_received_rounded;
      case 'BUSY':
        return Icons.phone_missed_rounded;
      case 'NO_RESPONSE':
        return Icons.phone_disabled_rounded;
      default:
        return Icons.phone_rounded;
    }
  }

  String _followUpLabel(String? followUp) {
    if (followUp == null) return '';
    return followUp.replaceAll('_', ' ');
  }

  // ── Initials avatar ───────────────────────────────────────────────────────
  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.alternate, height: 1),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: theme.primaryText, size: 24),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity',
                style: GoogleFonts.outfit(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                )),
            if (_activities != null)
              Text('${_activities!.length} calls',
                  style: GoogleFonts.inter(
                    color: theme.accent3,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  )),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.primary, size: 22),
            onPressed: _loadActivityData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading(theme)
            : (_activities == null || _activities!.isEmpty)
                ? _buildEmpty(theme)
                : RefreshIndicator(
                    onRefresh: _loadActivityData,
                    color: theme.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: _activities!.length,
                      itemBuilder: (context, index) =>
                          _ActivityCard(
                            item: _activities![index],
                            outcomeName: _outcomeName,
                            outcomeColor: _outcomeColor,
                            outcomeBg: _outcomeBg,
                            outcomeIcon: _outcomeIcon,
                            followUpLabel: _followUpLabel,
                            initials: _initials,
                            theme: theme,
                          ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildLoading(FlutterFlowTheme theme) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: 6,
        itemBuilder: (_, __) => _SkeletonCard(theme: theme),
      );

  Widget _buildEmpty(FlutterFlowTheme theme) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_rounded,
                  color: theme.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text('No Activity Yet',
                style: GoogleFonts.outfit(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                )),
            const SizedBox(height: 8),
            Text('Call logs will appear here once\nenablers start making calls.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: theme.accent3,
                  fontSize: 13,
                )),
          ],
        ),
      );
}

// ── Individual Card ───────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.item,
    required this.outcomeName,
    required this.outcomeColor,
    required this.outcomeBg,
    required this.outcomeIcon,
    required this.followUpLabel,
    required this.initials,
    required this.theme,
  });

  final Map<String, dynamic> item;
  final String Function(String) outcomeName;
  final Color Function(String) outcomeColor;
  final Color Function(String) outcomeBg;
  final IconData Function(String) outcomeIcon;
  final String Function(String?) followUpLabel;
  final String Function(String) initials;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    final outcome = item['call_outcome'] as String;
    final color = outcomeColor(outcome);
    final bgColor = outcomeBg(outcome);
    final icon = outcomeIcon(outcome);
    final outcomeStr = outcomeName(outcome);
    final followUp = followUpLabel(item['follow_up_status'] as String?);
    final timeStr = formatTime(DateTime.parse(item['called_at']));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: theme.alternate,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: outcome icon circle ────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // ── Center: main info ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact name + outcome badge in a row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item['contact']['name'],
                            style: GoogleFonts.outfit(
                              color: theme.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Outcome pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            outcomeStr,
                            style: GoogleFonts.inter(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Enabler row
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 13, color: theme.accent3),
                        const SizedBox(width: 4),
                        Text(
                          item['enabler']['name'],
                          style: GoogleFonts.inter(
                            color: theme.accent3,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.accent3,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.campaign_outlined,
                                  size: 13, color: theme.accent3),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item['event'] != null ? item['event']['name'] : '',
                                  style: GoogleFonts.inter(
                                    color: theme.accent3,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Follow-up status (if present)
                    if (followUp.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.label_outline_rounded,
                              size: 12,
                              color: theme.primary),
                          const SizedBox(width: 4),
                          Text(
                            followUp,
                            style: GoogleFonts.inter(
                              color: theme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Divider + timestamp row
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11, color: theme.accent3.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: GoogleFonts.inter(
                            color: theme.accent3.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (item['contact']['folk_id'] != null &&
                            item['contact']['folk_id']!.isNotEmpty) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ID ${item['contact']['folk_id']}',
                              style: GoogleFonts.inter(
                                color: theme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton loading card ─────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.theme});
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.alternate),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        height: 13,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: theme.alternate,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(
                        height: 11,
                        width: 160,
                        decoration: BoxDecoration(
                            color: theme.alternate,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(
                        height: 10,
                        width: 90,
                        decoration: BoxDecoration(
                            color: theme.alternate,
                            borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
