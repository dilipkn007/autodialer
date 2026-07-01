import '/components/button_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_model.dart';
export 'login_model.dart';

// Which login mode is selected
enum _LoginMode { otp, token }

class LoginWidget extends StatefulWidget {
  final String? initialMode;
  const LoginWidget({super.key, this.initialMode});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Mode ──────────────────────────────────────────────────────────────────
  _LoginMode _loginMode = _LoginMode.otp;

  // ── OTP flow state ────────────────────────────────────────────────────────
  bool _otpSent = false;
  bool _loading = false;
  String? _errorMessage;

  // ── Token flow state ──────────────────────────────────────────────────────
  // Token is the sole auth credential — no OTP step required.

  // ── Registration state ────────────────────────────────────────────────────
  bool _needsRegistration = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
    if (widget.initialMode == 'token') {
      _loginMode = _LoginMode.token;
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FlutterFlowTheme.of(context).error,
      ),
    );
  }

  void _switchMode(_LoginMode mode) {
    if (_loading) return;
    setState(() {
      _loginMode = mode;
      _otpSent = false;
      _needsRegistration = false;
      _errorMessage = null;
      _loading = false;
      _model.textFieldModel1.inputTextController?.clear();
      _model.textFieldModel2.inputTextController?.clear();
      _model.textFieldModel3.inputTextController?.clear();
    });
  }

  // ── OTP flow handlers ─────────────────────────────────────────────────────

  Future<void> _handleOtpAction() async {
    if (_needsRegistration) {
      await _registerProfile();
      return;
    }
    if (!_otpSent) {
      await _sendOtp();
    } else {
      await _verifyOtp();
    }
  }

  Future<void> _sendOtp() async {
    final phoneText = _model.textFieldModel1.inputTextController?.text ?? '';
    if (phoneText.isEmpty || phoneText.length < 10) {
      _showError('Please enter a valid 10-digit mobile number');
      return;
    }

    String formattedPhone = phoneText.trim();
    if (!formattedPhone.startsWith('+')) {
      if (formattedPhone.length == 12 && formattedPhone.startsWith('91')) {
        formattedPhone = '+$formattedPhone';
      } else if (formattedPhone.startsWith('0')) {
        formattedPhone = '+91${formattedPhone.substring(1)}';
      } else {
        formattedPhone = '+91$formattedPhone';
      }
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.verifyPhone(phoneNumber: formattedPhone);
      setState(() {
        _otpSent = true;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully')),
      );
    } catch (e) {
      _showError('Failed to send OTP: $e');
    }
  }

  Future<void> _verifyOtp() async {
    final otpText = _model.textFieldModel2.inputTextController?.text ?? '';
    if (otpText.isEmpty || otpText.length < 6) {
      _showError('Please enter the 6-digit OTP');
      return;
    }

    String formattedPhone =
        _model.textFieldModel1.inputTextController?.text.trim() ?? '';
    if (!formattedPhone.startsWith('+')) {
      if (formattedPhone.length == 12 && formattedPhone.startsWith('91')) {
        formattedPhone = '+$formattedPhone';
      } else if (formattedPhone.startsWith('0')) {
        formattedPhone = '+91${formattedPhone.substring(1)}';
      } else {
        formattedPhone = '+91$formattedPhone';
      }
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInWithOtp(formattedPhone, otpText.trim());
      await _checkProfileAndNavigate();
    } catch (e) {
      _showError('Invalid OTP. Please try again.');
    }
  }

  // ── Token flow handler ─────────────────────────────────────────────────────

  Future<void> _handleTokenAction() async {
    final token = _model.textFieldModel1.inputTextController?.text.trim() ?? '';
    if (token.isEmpty) {
      _showError('Please paste or enter your access token');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInWithToken(token);
      await _checkProfileAndNavigate();
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Shared post-auth ──────────────────────────────────────────────────────

  Future<void> _checkProfileAndNavigate() async {
    try {
      await AuthService.instance.autoMigrateDummyProfile();
    } catch (e) {
      debugPrint('Auto-migration failed: $e');
    }

    await AuthService.instance.refreshProfile();
    if (!mounted) return;

    final role = AuthService.instance.role;
    if (role == null) {
      setState(() {
        _needsRegistration = true;
        _loading = false;
      });
    } else {
      // Router redirect handles routing to dashboard or chooseRole
      setState(() => _loading = false);
    }
  }

  void _routeToDashboard(UserRole role) {
    setState(() => _loading = false);
    if (role == UserRole.ADMIN) {
      context.goNamed(FolkGuideDashboardWidget.routeName);
    } else {
      context.goNamed(AssignedContactsWidget.routeName);
    }
  }

  Future<void> _registerProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      _showError('Name is required');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.registerUserProfile(name: name, email: email);
      final role = AuthService.instance.role;
      if (role != null) {
        _routeToDashboard(role);
      } else {
        _showError('Failed to verify profile creation.');
      }
    } catch (e) {
      _showError('Registration failed: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header / branding ────────────────────────────────────
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    24.0, 64.0, 24.0, 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'FOLK Auto Dialer',
                      style: theme.headlineMedium.override(
                        font: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                        color: theme.primaryText,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w800,
                        lineHeight: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _needsRegistration
                          ? 'Complete Your Registration Profile'
                          : 'Follow-up Management & Smart Calling',
                      textAlign: TextAlign.center,
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                        lineHeight: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form area ────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error banner
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: theme.error10,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: theme.error),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: theme.bodySmall.override(
                                font: GoogleFonts.inter(),
                                color: theme.error,
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Mode selector (only show before OTP is sent / token validated,
                        // and only when not in registration)
                        if (!_needsRegistration && !_otpSent) ...[
                          _buildModeSelector(theme),
                          const SizedBox(height: 24),
                        ],

                        // ── OTP mode ─────────────────────────────────
                        if (_loginMode == _LoginMode.otp &&
                            !_needsRegistration) ...[
                          wrapWithModel(
                            model: _model.textFieldModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: TextFieldWidget(
                              label: 'Mobile Number',
                              labelPresent: true,
                              helper: '',
                              helperPresent: false,
                              leadingIcon: Icon(
                                Icons.phone_android_rounded,
                                color: theme.primaryText,
                                size: 24.0,
                              ),
                              leadingIconPresent: true,
                              trailingIconPresent: false,
                              hint: 'Enter 10 digit number',
                              value: '',
                              onChange: '',
                              onSubmit: '',
                              variant: 'outlined',
                              error: false,
                            ),
                          ),
                          if (_otpSent) ...[
                            const SizedBox(height: 16),
                            wrapWithModel(
                              model: _model.textFieldModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: TextFieldWidget(
                                label: 'Verification Code',
                                labelPresent: true,
                                helper: '',
                                helperPresent: false,
                                leadingIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: theme.primaryText,
                                  size: 24.0,
                                ),
                                leadingIconPresent: true,
                                trailingIconPresent: false,
                                hint: 'Enter 6-digit OTP',
                                value: '',
                                onChange: '',
                                onSubmit: '',
                                variant: 'outlined',
                                error: false,
                              ),
                            ),
                          ],
                        ],

                        // ── Token mode ───────────────────────────────
                        if (_loginMode == _LoginMode.token &&
                            !_needsRegistration) ...[
                            // Info chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.primary.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                    size: 16, color: theme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                    'Enter the access token provided by your admin to login.',
                                      style: theme.labelSmall.override(
                                        font: GoogleFonts.inter(),
                                        color: theme.primary,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            wrapWithModel(
                              model: _model.textFieldModel1,
                              updateCallback: () => safeSetState(() {}),
                              child: TextFieldWidget(
                                label: 'Access Token',
                                labelPresent: true,
                                helper: '',
                                helperPresent: false,
                                leadingIcon: Icon(
                                  Icons.key_rounded,
                                  color: theme.primaryText,
                                  size: 24.0,
                                ),
                                leadingIconPresent: true,
                                trailingIconPresent: false,
                                hint: 'Paste your access token here',
                                value: '',
                                onChange: '',
                                onSubmit: '',
                                variant: 'outlined',
                                error: false,
                              ),
                            ),
                          const SizedBox(height: 20),
                          // ── Divider with label ──────────────────
                          Row(
                                children: [
                                  Expanded(
                                  child: Divider(
                                      color: theme.alternate, thickness: 1)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text("Don't have a token?",
                                    style: theme.labelSmall),
                                  ),
                              Expanded(
                                  child: Divider(
                                      color: theme.alternate, thickness: 1)),
                                ],
                              ),
                            const SizedBox(height: 16),
                          // ── WhatsApp CTA card ───────────────────
                          _WhatsAppRequestCard(theme: theme),
                        ],

                        // ── Registration form ────────────────────────
                        if (_needsRegistration) ...[
                          Text('Full Name', style: theme.labelMedium),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.alternate),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.primary),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: theme.primaryText,
                              ),
                            ),
                            style: theme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Text('Email Address (Optional)',
                              style: theme.labelMedium),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Enter your email address',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.alternate),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: theme.primary),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: theme.primaryText,
                              ),
                            ),
                            style: theme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'New accounts are registered as enablers. Admin access is provisioned separately.',
                            style: theme.bodySmall.override(
                              font: GoogleFonts.inter(),
                              color: theme.secondaryText,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ── Primary CTA button ───────────────────────
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            if (_loginMode == _LoginMode.otp ||
                                _needsRegistration) {
                              await _handleOtpAction();
                            } else {
                              await _handleTokenAction();
                            }
                          },
                          child: wrapWithModel(
                            model: _model.buttonModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: ButtonWidget(
                              iconPresent: false,
                              iconEndPresent: false,
                              content: _needsRegistration
                                  ? 'COMPLETE REGISTRATION'
                                  : _loginMode == _LoginMode.otp
                                      ? (_otpSent
                                          ? 'VERIFY & LOGIN'
                                          : 'SEND OTP')
                                      : 'LOGIN',
                              variant: 'primary',
                              size: 'large',
                              fullWidth: true,
                              loading: _loading,
                              disabled: _loading,
                            ),
                          ),
                        ),

                        // Resend OTP row (OTP mode)
                        if (_loginMode == _LoginMode.otp &&
                            _otpSent &&
                            !_needsRegistration) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Didn\'t receive code?',
                                style: theme.bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: theme.secondaryText,
                                  letterSpacing: 0.0,
                                  lineHeight: 1.4,
                                ),
                              ),
                              InkWell(
                                onTap: () async => await _sendOtp(),
                                child: wrapWithModel(
                                  model: _model.buttonModel2,
                                  updateCallback: () => safeSetState(() {}),
                                  child: ButtonWidget(
                                    iconPresent: false,
                                    iconEndPresent: false,
                                    content: 'Resend OTP',
                                    variant: 'ghost',
                                    size: 'small',
                                    fullWidth: false,
                                    loading: _loading,
                                    disabled: _loading,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'By continuing, you agree to our',
                      style: theme.bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                        lineHeight: 1.4,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Terms of Service',
                          style: theme.bodySmall.override(
                            font:
                                GoogleFonts.inter(fontWeight: FontWeight.bold),
                            color: theme.primary,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            lineHeight: 1.4,
                          ),
                        ),
                        Text(
                          '&',
                          style: theme.bodySmall.override(
                            font: GoogleFonts.inter(),
                            color: theme.secondaryText,
                            letterSpacing: 0.0,
                            lineHeight: 1.4,
                          ),
                        ),
                        Text(
                          'Privacy Policy',
                          style: theme.bodySmall.override(
                            font:
                                GoogleFonts.inter(fontWeight: FontWeight.bold),
                            color: theme.primary,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            lineHeight: 1.4,
                          ),
                        ),
                      ].divide(const SizedBox(width: 4.0)),
                    ),
                  ].divide(const SizedBox(height: 4.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mode selector widget ───────────────────────────────────────────────────

  Widget _buildModeSelector(FlutterFlowTheme theme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'OTP Login',
              icon: Icons.sms_rounded,
              isActive: _loginMode == _LoginMode.otp,
              theme: theme,
              onTap: () => _switchMode(_LoginMode.otp),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                bottomLeft: Radius.circular(11),
              ),
            ),
          ),
          Container(width: 1, color: theme.alternate),
          Expanded(
            child: _ModeTab(
              label: 'Access Token',
              icon: Icons.key_rounded,
              isActive: _loginMode == _LoginMode.token,
              theme: theme,
              onTap: () => _switchMode(_LoginMode.token),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode tab button ────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final FlutterFlowTheme theme;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.theme,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? theme.primary : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: isActive ? Colors.white : theme.secondaryText),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : theme.secondaryText,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── WhatsApp Request Card ──────────────────────────────────────────────────

class _WhatsAppRequestCard extends StatelessWidget {
  final FlutterFlowTheme theme;

  const _WhatsAppRequestCard({required this.theme});

  Future<void> _openAdminList(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('contact')
          .select('name, mobile')
          .eq('role', 'ADMIN')
          .neq('mobile', '')
          .order('name');

      if (!context.mounted) return;

      final admins = List<Map<String, dynamic>>.from(data);

      if (admins.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No admins available. Please try again later.')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _AdminListSheet(theme: theme, admins: admins),
      );
    } catch (e) {
      debugPrint('Failed to fetch admins: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load admin list.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openAdminList(context),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                _WhatsAppIcon(),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RequestAccessText(),
                      SizedBox(height: 4),
                      _RequestAccessSubtitle(),
                    ],
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

class _WhatsAppIcon extends StatelessWidget {
  const _WhatsAppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF25D366),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _RequestAccessText extends StatelessWidget {
  const _RequestAccessText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Request Access',
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: FlutterFlowTheme.of(context).primaryText,
      ),
    );
  }
}

class _RequestAccessSubtitle extends StatelessWidget {
  const _RequestAccessSubtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Choose an admin to message on WhatsApp for an access token.',
      style: GoogleFonts.inter(
        fontSize: 13,
        color: FlutterFlowTheme.of(context).secondaryText,
      ),
    );
  }
}

// ── Admin List Bottom Sheet ────────────────────────────────────────────────

class _AdminListSheet extends StatelessWidget {
  final FlutterFlowTheme theme;
  final List<Map<String, dynamic>> admins;

  const _AdminListSheet({required this.theme, required this.admins});

  Future<void> _openWhatsApp(
      BuildContext context, String mobile, String name) async {
    String phone = mobile.trim();
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }
    if (!phone.startsWith('91')) {
      phone = '91$phone';
    }

    final message = Uri.encodeComponent(
      'Hare Krishna Prabhu, Please provide the access token for AutoDialer APP.\nThanks!',
    );

    final Uri waUri = Uri.parse('whatsapp://send?phone=$phone&text=$message');
    final Uri webUri = Uri.parse('https://wa.me/$phone?text=$message');

    try {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        debugPrint('Could not launch WhatsApp');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_rounded, size: 20, color: theme.primaryText),
                const SizedBox(width: 8),
                Text(
                  'Select Admin',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Choose an admin to request an access token via WhatsApp.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            ...admins.map((admin) {
              final name = admin['name'] as String? ?? 'Admin';
              final mobile = admin['mobile'] as String? ?? '';
              final initials = name
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .take(2)
                  .map((w) => w[0].toUpperCase())
                  .join();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _openWhatsApp(context, mobile, name),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.alternate),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                const Color(0xFF25D366).withValues(alpha: 0.15),
                            child: Text(
                              initials,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF25D366),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: theme.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatMobile(mobile),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Message',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatMobile(String mobile) {
    if (mobile.startsWith('+')) {
      mobile = mobile.substring(1);
    }
    if (mobile.length == 12 && mobile.startsWith('91')) {
      return '+91 ${mobile.substring(2, 7)} ${mobile.substring(7)}';
    }
    return mobile;
  }
}
