import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/auth_service.dart';
import 'access_model.dart';

export 'access_model.dart';

class AccessWidget extends StatefulWidget {
  const AccessWidget({super.key});

  static String routeName = 'Access';
  static String routePath = '/access';

  @override
  State<AccessWidget> createState() => _AccessWidgetState();
}

class _AccessWidgetState extends State<AccessWidget>
    with SingleTickerProviderStateMixin {
  late AccessModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _supabase = Supabase.instance.client;

  // ── Tabs: All Contacts  /  Active Tokens ──────────────────────────────────
  late TabController _tabController;

  // ── Contacts tab state ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _contacts = [];
  bool _contactsLoading = true;
  String _searchQuery = '';
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _generatingIds = {};

  // ── Tokens tab state ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _tokens = [];
  bool _tokensLoading = true;
  bool _showRevoked = false;
  final Set<String> _revokingIds = {};
  String _tokenSearchQuery = '';
  final TextEditingController _tokenSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccessModel());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _searchController.addListener(() {
      _searchQuery = _searchController.text;
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        _loadContacts();
      });
      setState(() {});
    });

    _tokenSearchController.addListener(() {
      setState(() {
        _tokenSearchQuery = _tokenSearchController.text;
      });
    });

    _loadContacts();
    _loadTokens();
    AuthService.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tokenSearchController.dispose();
    _tabController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    _loadContacts();
    _loadTokens();
  }

  // ── Data loaders ───────────────────────────────────────────────────────────

  Future<void> _loadContacts() async {
    setState(() => _contactsLoading = true);
    try {
      final auth = AuthService.instance;
      final q = _searchQuery.trim();
      dynamic baseQuery = _supabase
          .from('contact')
          .select(
              'id, name, mobile, whatsapp, email, role, avatar_initials');
      if (auth.isFolkGuide && auth.folkGuideId != null) {
        baseQuery = baseQuery.eq('folk_guide', auth.folkGuideId!);
      }
      final data = q.isEmpty
          ? await baseQuery
              .order('name', ascending: true)
              .limit(60)
          : await baseQuery
              .or('name.ilike.%$q%,mobile.ilike.%$q%,email.ilike.%$q%')
              .order('name', ascending: true)
              .limit(60);

      if (mounted) {
        setState(() {
          _contacts = List<Map<String, dynamic>>.from(data);
          _contactsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _contactsLoading = false);
        _showError('Failed to load contacts: $e');
      }
    }
  }

  Future<void> _loadTokens() async {
    setState(() => _tokensLoading = true);
    try {
      // Join with contact to get name + mobile for display
      final data = await _supabase
          .from('access_token')
          .select(
              'id, token, is_used, expires_at, created_at, used_at, revoked, revoked_at, login_count, last_login_at, contact_id, mobile_number, contact:contact_id(name, role, avatar_initials)')
          .order('created_at', ascending: false)
          .limit(200);

      if (mounted) {
        setState(() {
          _tokens = List<Map<String, dynamic>>.from(data);
          _tokensLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _tokensLoading = false);
        _showError('Failed to load tokens: $e');
      }
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _generateToken(Map<String, dynamic> contact) async {
    final contactId = contact['id'] as String;
    final mobile = contact['mobile'] as String? ?? '';
    final whatsapp = contact['whatsapp'] as String? ?? '';
    if (mobile.isEmpty) {
      _showError('This contact has no mobile number.');
      return;
    }

    // Show date picker for expiration
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select token expiry date',
    );
    if (picked == null) return;

    final expiresAt =
        DateTime(picked.year, picked.month, picked.day, 23, 59, 59);

    setState(() => _generatingIds.add(contactId));
    try {
      const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final _rng = Random.secure();
      final token = List.generate(8, (_) => _chars[_rng.nextInt(_chars.length)]).join();
      final adminId = AuthService.instance.currentUser?.id;

      await _supabase.from('access_token').insert({
        'contact_id': contactId,
        'mobile_number': mobile,
        'token': token,
        'expires_at': expiresAt.toUtc().toIso8601String(),
        if (adminId != null) 'created_by': adminId,
        'is_used': false,
      });

      if (mounted) {
        setState(() => _generatingIds.remove(contactId));
        _showTokenDialog(
          contactName: contact['name'] as String? ?? 'Contact',
          mobile: mobile,
          whatsapp: whatsapp,
          token: token,
          expiresAt: expiresAt,
        );
        _loadTokens();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generatingIds.remove(contactId));
        _showError('Failed to generate token: $e');
      }
    }
  }

  Future<void> _revokeToken(String tokenId) async {
    setState(() => _revokingIds.add(tokenId));
    try {
      await _supabase.from('access_token').update({
        'revoked': true,
        'revoked_at': DateTime.now().toIso8601String(),
      }).eq('id', tokenId);

      if (mounted) {
        setState(() {
          _revokingIds.remove(tokenId);
          final idx = _tokens.indexWhere((t) => t['id'] == tokenId);
          if (idx != -1) {
            _tokens[idx] = {
              ..._tokens[idx],
              'revoked': true,
              'revoked_at': DateTime.now().toIso8601String(),
            };
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _revokingIds.remove(tokenId));
        _showError('Failed to revoke token: $e');
      }
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showTokenDialog({
    required String contactName,
    required String mobile,
    required String whatsapp,
    required String token,
    DateTime? expiresAt,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final targetPhone = (whatsapp.isNotEmpty ? whatsapp : mobile);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.key_rounded, color: theme.success, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Token Generated', style: theme.titleMedium),
                  Text(
                    contactName,
                    style: theme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Valid until ${expiresAt != null ? '${expiresAt.day}/${expiresAt.month}/${expiresAt.year}' : '1 year'} — can be used multiple times before expiry.',
              style: theme.labelMedium,
            ),
            const SizedBox(height: 14),
            _CopyableBox(label: 'Access Token', value: token, theme: theme),
            const SizedBox(height: 10),
            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _shareTokenOnWhatsApp(
                  phone: targetPhone,
                  token: token,
                  expiresAt: expiresAt,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text('Share Token via WhatsApp',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Done',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareTokenOnWhatsApp({
    required String phone,
    required String token,
    DateTime? expiresAt,
  }) async {
    String raw = phone.trim();
    if (raw.startsWith('+')) raw = raw.substring(1);
    if (!raw.startsWith('91')) raw = '91$raw';

    final expiryText = expiresAt != null
        ? '${expiresAt.day}/${expiresAt.month}/${expiresAt.year}'
        : '1 year from issue';
    final message = Uri.encodeComponent(
      'Your access token for FOLK Auto Dialer is:\n$token\n\n'
      'Valid until: $expiryText\n'
      'Use this token to login to the app.',
    );

    final waUri = Uri.parse('whatsapp://send?phone=$raw&text=$message');
    final webUri = Uri.parse('https://wa.me/$raw?text=$message');

    try {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        debugPrint('Could not launch WhatsApp');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed.')),
          );
        }
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: FlutterFlowTheme.of(context).error,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color: theme.primaryText),
                      onPressed: () {
                        context.safePop();
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Access Control',
                            style: theme.headlineMedium.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700),
                              letterSpacing: 0,
                              fontSize: 22.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Generate & manage login tokens',
                            style: theme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      icon: Icon(Icons.refresh_rounded,
                          color: theme.secondaryText),
                      onPressed: () {
                        _loadContacts();
                        _loadTokens();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Tab bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.alternate),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: theme.secondaryText,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Contacts'),
                      Tab(text: 'Tokens'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Tab views ─────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContactsTab(theme),
                    _buildTokensTab(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contacts tab ───────────────────────────────────────────────────────────

  Widget _buildContactsTab(FlutterFlowTheme theme) {
    return Column(
      children: [
        // Search
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

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              Text(
                _contactsLoading ? '' : '${_contacts.length} contacts',
                style: theme.labelSmall,
              ),
            ],
          ),
        ),

        Expanded(
          child: _contactsLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : _contacts.isEmpty
                  ? _emptyState(
                      Icons.person_search_rounded, 'No contacts found')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: _contacts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return _ContactCard(
                          contact: contact,
                          isGenerating: _generatingIds.contains(contact['id']),
                          onGenerate: () => _generateToken(contact),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ── Tokens tab ─────────────────────────────────────────────────────────────

  Widget _buildTokensTab(FlutterFlowTheme theme) {
    final visibleTokens = _showRevoked
        ? _tokens
        : _tokens.where((t) => t['revoked'] != true).toList();

    final q = _tokenSearchQuery.trim().toLowerCase();
    final searchedTokens = q.isEmpty
        ? visibleTokens
        : visibleTokens.where((t) {
            final contactInfo = t['contact'] as Map<String, dynamic>? ?? {};
            final name = (contactInfo['name'] as String? ?? '').toLowerCase();
            final mobile = (t['mobile_number'] as String? ?? '').toLowerCase();
            final tokenVal = (t['token'] as String? ?? '').toLowerCase();
            return name.contains(q) || mobile.contains(q) || tokenVal.contains(q);
          }).toList();

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: TextField(
              controller: _tokenSearchController,
              style: theme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search tokens by name, mobile or token…',
                hintStyle: theme.labelMedium,
                prefixIcon:
                    Icon(Icons.search_rounded, color: theme.secondaryText),
                suffixIcon: _tokenSearchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _tokenSearchController.clear();
                          setState(() {
                            _tokenSearchQuery = '';
                          });
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

        const SizedBox(height: 6),

        // Filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Row(
            children: [
              Text(
                _tokensLoading
                    ? ''
                    : '${searchedTokens.length} token${searchedTokens.length == 1 ? '' : 's'}',
                style: theme.labelSmall,
              ),
              const Spacer(),
              Row(
                children: [
                  Text('Show revoked', style: theme.labelSmall),
                  Switch(
                    value: _showRevoked,
                    onChanged: (v) => setState(() => _showRevoked = v),
                    activeThumbColor: theme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: _tokensLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : searchedTokens.isEmpty
                  ? _emptyState(
                      Icons.key_off_rounded,
                      _showRevoked ? 'No tokens yet' : 'No active tokens',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: searchedTokens.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final token = searchedTokens[index];
                        return _TokenCard(
                          token: token,
                          isRevoking: _revokingIds.contains(token['id']),
                          onRevoke: () => _revokeToken(token['id'] as String),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String label) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.secondaryText),
          const SizedBox(height: 12),
          Text(label, style: theme.labelLarge),
        ],
      ),
    );
  }
}

// ── Contact Card ──────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _ContactCard({
    required this.contact,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final name = contact['name'] as String? ?? '—';
    final mobile = contact['mobile'] as String? ?? '—';
    final email = contact['email'] as String? ?? '';
    final role = contact['role'] as String? ?? 'ENABLER';
    final initials = contact['avatar_initials'] as String? ??
        name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

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
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.primary.withValues(alpha: 0.12),
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
                        color: roleColor.withValues(alpha: 0.12),
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
                Text(mobile, style: theme.labelSmall),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(email,
                      style: theme.labelSmall, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          isGenerating
              ? SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: theme.primary),
                )
              : GestureDetector(
                  onTap: onGenerate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Token',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Token Card ────────────────────────────────────────────────────────────────

class _TokenCard extends StatelessWidget {
  final Map<String, dynamic> token;
  final bool isRevoking;
  final VoidCallback onRevoke;

  const _TokenCard({
    required this.token,
    required this.isRevoking,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final contactInfo = token['contact'] as Map<String, dynamic>? ?? {};
    final name = contactInfo['name'] as String? ?? '—';
    final initials = contactInfo['avatar_initials'] as String? ??
        name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    final mobile = token['mobile_number'] as String? ?? '—';
    final tokenVal = token['token'] as String? ?? '';
    final isRevoked = token['revoked'] == true;
    final expiresAt = token['expires_at'] != null
        ? DateTime.tryParse(token['expires_at'].toString())
        : null;
    final createdAt = token['created_at'] != null
        ? DateTime.tryParse(token['created_at'].toString())
        : null;
    final loginCount = token['login_count'] as int? ?? 0;

    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    final isActive = !isRevoked && !isExpired;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (isRevoked) {
      statusColor = theme.error;
      statusLabel = 'Revoked';
      statusIcon = Icons.block_rounded;
    } else if (isExpired) {
      statusColor = theme.warning;
      statusLabel = 'Expired';
      statusIcon = Icons.timer_off_rounded;
    } else {
      statusColor = theme.primary;
      statusLabel = 'Active';
      statusIcon = Icons.key_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isRevoked ? theme.error.withValues(alpha: 0.3) : theme.alternate,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name + status badge
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isRevoked
                    ? theme.error.withValues(alpha: 0.1)
                    : theme.primary.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    color: isRevoked ? theme.error : theme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        letterSpacing: 0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(mobile, style: theme.labelSmall),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Token value (truncated) with copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.alternate),
            ),
            child: Row(
              children: [
                Icon(Icons.vpn_key_rounded,
                    size: 14, color: theme.secondaryText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tokenVal,
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      color: theme.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: tokenVal));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Token copied to clipboard')),
                    );
                  },
                  child:
                      Icon(Icons.copy_rounded, size: 14, color: theme.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Meta row: created date + expires + login count + revoke button
          Row(
            children: [
              if (createdAt != null) ...[
                Icon(Icons.calendar_today_rounded,
                    size: 12, color: theme.secondaryText),
                const SizedBox(width: 4),
                Text(
                  _formatDate(createdAt),
                  style: theme.labelSmall,
                ),
                const SizedBox(width: 10),
              ],
              if (expiresAt != null) ...[
                Icon(
                  isExpired ? Icons.timer_off_rounded : Icons.timer_outlined,
                  size: 12,
                  color: isExpired ? theme.error : theme.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  isExpired ? 'Expired' : 'Exp: ${_formatDate(expiresAt)}',
                  style: theme.labelSmall.override(
                    font: GoogleFonts.inter(),
                    color: isExpired ? theme.error : null,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (loginCount > 0) ...[
                Icon(Icons.login_rounded, size: 12, color: theme.secondaryText),
                const SizedBox(width: 4),
                Text(
                  '$loginCount login${loginCount == 1 ? '' : 's'}',
                  style: theme.labelSmall,
                ),
              ],
              const Spacer(),
              if (isActive)
                isRevoking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: theme.error),
                      )
                    : GestureDetector(
                        onTap: onRevoke,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.block_rounded,
                                  size: 12, color: theme.error),
                              const SizedBox(width: 4),
                              Text(
                                'Revoke',
                                style: GoogleFonts.inter(
                                  color: theme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

// ── Reusable copyable value box ───────────────────────────────────────────────

class _CopyableBox extends StatelessWidget {
  final String label;
  final String value;
  final FlutterFlowTheme theme;

  const _CopyableBox({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              letterSpacing: 0,
            )),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.alternate),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.robotoMono(
                    color: theme.primaryText,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied')),
                  );
                },
                child: Icon(Icons.copy_rounded, size: 16, color: theme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
