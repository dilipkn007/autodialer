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

  bool _otpSent = false;
  bool _loading = false;
  String? _errorMessage;

  // Registration state
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

  void _showError(String message) {
    safeSetState(() {
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

  Future<void> _handlePrimaryAction() async {
    if (_loading) return;

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
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+91${formattedPhone.substring(1)}';
      } else {
        formattedPhone = '+91$formattedPhone';
      }
    }

    safeSetState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.verifyPhone(
        phoneNumber: formattedPhone,
      );
      safeSetState(() {
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

    String formattedPhone = _model.textFieldModel1.inputTextController?.text.trim() ?? '';
    if (!formattedPhone.startsWith('+')) {
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+91${formattedPhone.substring(1)}';
      } else {
        formattedPhone = '+91$formattedPhone';
      }
    }

    try {
      await AuthService.instance
          .signInWithOtp(formattedPhone, otpText.trim());
      await _checkProfileAndNavigate();
    } catch (e) {
      _showError('Invalid OTP. Please try again.');
    }
  }

  Future<void> _checkProfileAndNavigate() async {
    await AuthService.instance.refreshProfile();
    final role = AuthService.instance.role;
    if (role == null) {
      // No fully registered profile found. Check if an admin pre-created a dummy profile.
      try {
        final autoMigrated =
            await AuthService.instance.autoMigrateDummyProfile();
        if (autoMigrated) {
          // Auto-migration successful! Route to dashboard immediately.
          final newRole = AuthService.instance.role;
          if (newRole != null) {
            _routeToDashboard(newRole);
            return;
          }
        }
      } catch (e) {
        debugPrint("Migration failed, will show registration form: $e");
        // Migration failed but a dummy profile exists — show error
        _showError(
            'Profile migration failed. Please contact your admin. Error: $e');
        return;
      }

      // If we reach here, it's a completely organic sign-up (no dummy profile). Show registration form.
      safeSetState(() {
        _needsRegistration = true;
        _loading = false;
      });
    } else {
      _routeToDashboard(role);
    }
  }

  void _routeToDashboard(UserRole role) {
    safeSetState(() {
      _loading = false;
    });
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

    safeSetState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.registerUserProfile(
        name: name,
        email: email,
      );
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 64.0, 24.0, 24.0),
                  child: Container(
                    child: Container(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'FOLK Auto Dialer',
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .fontStyle,
                                      lineHeight: 1.2,
                                    ),
                              ),
                              Text(
                                _needsRegistration
                                    ? 'Complete Your Registration Profile'
                                    : 'Follow-up Management & Smart Calling',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.5,
                                    ),
                              ),
                            ].divide(SizedBox(height: 4.0)),
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).error10,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).error,
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(),
                                    color: FlutterFlowTheme.of(context).error,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        if (!_needsRegistration) ...[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
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
                            ].divide(SizedBox(height: 24.0)),
                          ),
                          if (_otpSent)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
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
                              ].divide(SizedBox(height: 24.0)),
                            ),
                        ],
                        if (_needsRegistration) ...[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Full Name',
                                style: FlutterFlowTheme.of(context).labelMedium,
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your full name',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                ),
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Email Address (Optional)',
                                style: FlutterFlowTheme.of(context).labelMedium,
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Enter your email address',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                ),
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'New accounts are registered as enablers. Admin access is provisioned separately.',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            await _handlePrimaryAction();
                          },
                          child: wrapWithModel(
                            model: _model.buttonModel1,
                            updateCallback: () => safeSetState(() {}),
                            child: ButtonWidget(
                              iconPresent: false,
                              iconEndPresent: false,
                              content: _needsRegistration
                                  ? 'COMPLETE REGISTRATION'
                                  : (_otpSent ? 'VERIFY & LOGIN' : 'SEND OTP'),
                              variant: 'primary',
                              size: 'large',
                              fullWidth: true,
                              loading: _loading,
                              disabled: _loading,
                            ),
                          ),
                        ),
                        if (_otpSent && !_needsRegistration)
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Didn\'t receive code?',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              InkWell(
                                onTap: () async {
                                  await _sendOtp();
                                },
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
                    ),
                  ),
                ),
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Container(
                    child: Container(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'By continuing, you agree to our',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Terms of Service',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                      decoration: TextDecoration.underline,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              Text(
                                '&',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              Text(
                                'Privacy Policy',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                      decoration: TextDecoration.underline,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ].divide(SizedBox(width: 4.0)),
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
