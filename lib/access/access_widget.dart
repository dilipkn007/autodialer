import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/components/admin_nav_bar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'access_model.dart';

export 'access_model.dart';

class AccessWidget extends StatefulWidget {
  const AccessWidget({super.key});

  static String routeName = 'Access';
  static String routePath = '/access';

  @override
  State<AccessWidget> createState() => _AccessWidgetState();
}

class _AccessWidgetState extends State<AccessWidget> {
  late AccessModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;
  String _searchQuery = '';
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  // Track which contacts are having their link generated/generated
  final Map<String, String?> _generatedLinks = {}; // contactId -> link or null while loading
  final Set<String> _generatingIds = {};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccessModel());
    _searchController.addListener(() {
      _searchQuery = _searchController.text;
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        _loadContacts();
      });
      setState(() {});
    });
    _loadContacts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      var query = _supabase
          .from('contact')
          .select('id, name, mobile, email, role, avatar_initials')
          .order('name', ascending: true)
          .limit(50);

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim();
        query = _supabase
            .from('contact')
            .select('id, name, mobile, email, role, avatar_initials')
            .or('name.ilike.%$q%,mobile.ilike.%$q%,email.ilike.%$q%')
            .order('name', ascending: true)
            .limit(50);
      }

      final data = await query;
      if (mounted) {
        setState(() {
          _contacts = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  Future<void> _generateLink(String contactId, String mobile) async {
    setState(() => _generatingIds.add(contactId));
    try {
      // Use Supabase admin generateLink or show OTP instructions
      // We generate a magic link / OTP send for the contact's mobile
      // Since Supabase OTP goes to the phone, we show the phone to admin
      // and also let them copy the phone so they can tell the user their OTP will arrive.
      // Alternatively, generate a shareable deep-link instructing the user to sign in via OTP.
      final normalised = mobile.startsWith('+') ? mobile : '+91$mobile';
      // We just call signInWithOtp on the admin side to trigger OTP to the enabler's phone
      await _supabase.auth.signInWithOtp(phone: normalised);
      if (mounted) {
        setState(() {
          _generatingIds.remove(contactId);
          _generatedLinks[contactId] = normalised;
        });
        _showSuccessDialog(contactId, normalised);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generatingIds.remove(contactId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String contactId, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: FlutterFlowTheme.of(context).success, size: 24),
            const SizedBox(width: 8),
            Text(
              'OTP Sent!',
              style: FlutterFlowTheme.of(context).titleMedium,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A one-time password has been sent to:',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: FlutterFlowTheme.of(context).alternate),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      phone,
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    child: Icon(Icons.copy_rounded,
                        size: 18,
                        color: FlutterFlowTheme.of(context).primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ask the user to enter the OTP they received via SMS to sign in.',
              style: FlutterFlowTheme.of(context).labelSmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Done',
              style: TextStyle(color: FlutterFlowTheme.of(context).primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        bottomNavigationBar: const AdminNavBar(currentTab: AdminTab.access),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access Control',
                      style: theme.headlineMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send OTP access to contacts & enablers',
                      style: theme.labelMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Search bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.alternate),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: theme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search by name, mobile or email…',
                      hintStyle: theme.labelMedium,
                      prefixIcon:
                          Icon(Icons.search_rounded, color: theme.secondaryText),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _loadContacts();
                              },
                              child: Icon(Icons.close_rounded,
                                  color: theme.secondaryText, size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Count label ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  _loading ? '' : '${_contacts.length} contacts',
                  style: theme.labelSmall,
                ),
              ),

              // ── Contact list ────────────────────────────────────────
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(color: theme.primary))
                    : _contacts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_search_rounded,
                                    size: 48, color: theme.secondaryText),
                                const SizedBox(height: 12),
                                Text('No contacts found',
                                    style: theme.labelLarge),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: _contacts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final contact = _contacts[index];
                              return _ContactAccessCard(
                                contact: contact,
                                isGenerating:
                                    _generatingIds.contains(contact['id']),
                                wasSent:
                                    _generatedLinks.containsKey(contact['id']),
                                onSendAccess: () => _generateLink(
                                  contact['id'] as String,
                                  contact['mobile'] as String? ?? '',
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contact Access Card ──────────────────────────────────────────────────────

class _ContactAccessCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final bool isGenerating;
  final bool wasSent;
  final VoidCallback onSendAccess;

  const _ContactAccessCard({
    required this.contact,
    required this.isGenerating,
    required this.wasSent,
    required this.onSendAccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final name = contact['name'] as String? ?? '—';
    final mobile = contact['mobile'] as String? ?? '—';
    final email = contact['email'] as String? ?? '';
    final role = contact['role'] as String? ?? 'ENABLER';
    final initials = contact['avatar_initials'] as String? ??
        name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    final isAdmin = role == 'ADMIN';
    final roleColor = isAdmin ? theme.primary : theme.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.primary.withOpacity(0.12),
            child: Text(
              initials,
              style: GoogleFonts.inter(
                color: theme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.bodyMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          letterSpacing: 0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role,
                        style: GoogleFonts.inter(
                          color: roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mobile,
                  style: theme.labelSmall.override(
                    font: GoogleFonts.inter(),
                    letterSpacing: 0,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    email,
                    style: theme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action button
          _buildActionButton(context, theme),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, FlutterFlowTheme theme) {
    if (isGenerating) {
      return SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: theme.primary,
        ),
      );
    }

    if (wasSent) {
      return GestureDetector(
        onTap: onSendAccess,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 14, color: theme.success),
              const SizedBox(width: 4),
              Text(
                'Sent',
                style: GoogleFonts.inter(
                  color: theme.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onSendAccess,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.send_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Send OTP',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
