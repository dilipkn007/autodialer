import '/components/button_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'login_model.dart';
export 'login_model.dart';

// Which login mode is selected
enum _LoginMode { otp, token }

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

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
  // Step 1: user enters token  → we validate + send OTP to linked mobile
  // Step 2: user enters OTP    → we verify + mark token used
  bool _tokenValidated = false;   // true once token is validated & OTP dispatched
  String _linkedPhone = '';        // the phone we sent OTP to (hidden from user)
  String _enteredToken = '';       // saved for marking as used in step 2

  // ── Registration state ────────────────────────────────────────────────────
  bool _needsRegistration = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
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
      _tokenValidated = false;
      _linkedPhone = '';
      _enteredToken = '';
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
    final phoneText =
        _model.textFieldModel1.inputTextController?.text ?? '';
    if (phoneText.isEmpty || phoneText.length < 10) {
      _showError('Please enter a valid 10-digit mobile number');
      return;
    }

    String formattedPhone = phoneText.trim();
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = formattedPhone.startsWith('0')
          ? '+91${formattedPhone.substring(1)}'
          : '+91$formattedPhone';
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
    final otpText =
        _model.textFieldModel2.inputTextController?.text ?? '';
    if (otpText.isEmpty || otpText.length < 6) {
      _showError('Please enter the 6-digit OTP');
      return;
    }

    String formattedPhone =
        _model.textFieldModel1.inputTextController?.text.trim() ?? '';
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = formattedPhone.startsWith('0')
          ? '+91${formattedPhone.substring(1)}'
          : '+91$formattedPhone';
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance
          .signInWithOtp(formattedPhone, otpText.trim());
      await _checkProfileAndNavigate();
    } catch (e) {
      _showError('Invalid OTP. Please try again.');
    }
  }

  // ── Token flow handlers ───────────────────────────────────────────────────

  Future<void> _handleTokenAction() async {
    if (!_tokenValidated) {
      await _validateToken();
    } else {
      await _verifyTokenOtp();
    }
  }

  Future<void> _validateToken() async {
    final token =
        _model.textFieldModel1.inputTextController?.text.trim() ?? '';
    if (token.isEmpty) {
      _showError('Please paste or enter your access token');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final phone =
          await AuthService.instance.signInWithAccessToken(token);
      setState(() {
        _tokenValidated = true;
        _linkedPhone = phone;
        _enteredToken = token;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Token verified ✓ — OTP sent to your registered number'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _verifyTokenOtp() async {
    final otpText =
        _model.textFieldModel2.inputTextController?.text.trim() ?? '';
    if (otpText.isEmpty || otpText.length < 6) {
      _showError('Please enter the 6-digit OTP sent to your number');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.confirmAccessTokenOtp(
          _enteredToken, _linkedPhone, otpText);
      await _checkProfileAndNavigate();
    } catch (e) {
      _showError('Invalid OTP. Please try again.');
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
    final role = AuthService.instance.role;
    if (role == null) {
      setState(() {
        _needsRegistration = true;
        _loading = false;
      });
    } else {
      _routeToDashboard(role);
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
      await AuthService.instance
          .registerUserProfile(name: name, email: email);
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
                        if (!_needsRegistration &&
                            !_otpSent &&
                            !_tokenValidated) ...[
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
                          if (!_tokenValidated) ...[
                            // Info chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: theme.primary
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 16,
                                      color: theme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Enter the access token provided by your admin. An OTP will be sent to your registered mobile number.',
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
                          ],
                          if (_tokenValidated) ...[
                            // Success banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        theme.success.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 16, color: theme.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Token verified! An OTP has been sent to your registered mobile number.',
                                      style: theme.labelSmall.override(
                                        font: GoogleFonts.inter(),
                                        color: theme.success,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            wrapWithModel(
                              model: _model.textFieldModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: TextFieldWidget(
                                label: 'OTP Code',
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

                        // ── Registration form ────────────────────────
                        if (_needsRegistration) ...[
                          Text('Full Name',
                              style: theme.labelMedium),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: theme.alternate),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: theme.primary),
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
                                borderSide:
                                    BorderSide(color: theme.alternate),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: theme.primary),
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
                                      : (_tokenValidated
                                          ? 'VERIFY OTP & LOGIN'
                                          : 'VERIFY TOKEN'),
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

                        // Back link when token was already validated
                        if (_loginMode == _LoginMode.token &&
                            _tokenValidated &&
                            !_needsRegistration) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => setState(() {
                                        _tokenValidated = false;
                                        _linkedPhone = '';
                                        _enteredToken = '';
                                        _errorMessage = null;
                                        _model.textFieldModel1
                                            .inputTextController
                                            ?.clear();
                                        _model.textFieldModel2
                                            .inputTextController
                                            ?.clear();
                                      }),
                              child: Text(
                                'Use a different token',
                                style: theme.labelSmall.override(
                                  font: GoogleFonts.inter(),
                                  color: theme.primary,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
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
                            font: GoogleFonts.inter(
                                fontWeight: FontWeight.bold),
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
                            font: GoogleFonts.inter(
                                fontWeight: FontWeight.bold),
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
                size: 16,
                color: isActive ? Colors.white : theme.secondaryText),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : theme.secondaryText,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
