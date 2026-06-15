import '/components/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:f_o_l_k_auto_dialer/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_model.dart';

export 'profile_model.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static String routeName = 'Profile';
  static String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late ProfileModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileModel());
    _initializeControllers();
    AuthService.instance.refreshProfile();
  }

  void _initializeControllers() {
    final auth = AuthService.instance;
    _nameController.text = auth.userName ?? 'User';
    _emailController.text = auth.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        final user = auth.currentUser;
        final name = auth.userName ?? 'User';
        final phone = user?.phone ?? 'No Phone';
        final email = user?.email ?? '';
        final role = auth.role?.name ?? 'ENABLER';

        final initials = name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          appBar: AppBar(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: FlutterFlowTheme.of(context).primaryText),
              onPressed: () {
                context.safePop();
              },
            ),
            title: Text(
              'My Profile',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: FlutterFlowTheme.of(context).primaryText),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _initializeControllers();
                    });
                  },
                ),
            ],
            elevation: 1.0,
          ),
          body: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  const SizedBox(height: 24.0),
                  Center(
                    child: Container(
                      width: 96.0,
                      height: 96.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: const AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        initials.isNotEmpty ? initials : 'U',
                        style: FlutterFlowTheme.of(context).headlineLarge.override(
                          font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          color: FlutterFlowTheme.of(context).onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: _isEditing
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48.0),
                            child: TextFormField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context).headlineMedium.override(
                                font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 2.0),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 2.0),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            name,
                            style: FlutterFlowTheme.of(context).headlineMedium.override(
                              font: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                          ),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary10,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        role,
                        style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48.0),
                  Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInfoRow(
                            context,
                            icon: Icons.phone_rounded,
                            label: 'Phone Number',
                            value: phone,
                          ),
                          const Divider(),
                          _isEditing
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.email_outlined, color: FlutterFlowTheme.of(context).secondaryText, size: 20),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _emailController,
                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                                color: FlutterFlowTheme.of(context).primaryText,
                                              ),
                                          decoration: InputDecoration(
                                            labelText: 'Email Address',
                                            labelStyle: FlutterFlowTheme.of(context).labelSmall,
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 1.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildInfoRow(
                                  context,
                                  icon: Icons.email_outlined,
                                  label: 'Email Address',
                                  value: email.isNotEmpty ? email : 'Not provided',
                                ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () {
                              setState(() {
                                _isEditing = false;
                                _initializeControllers();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: FlutterFlowTheme.of(context).primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            child: Text('Cancel', style: TextStyle(color: FlutterFlowTheme.of(context).primary)),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : () async {
                              setState(() { _isSaving = true; });
                              try {
                                final initials = _nameController.text.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
                                await Supabase.instance.client.from('users').update({
                                  'name': _nameController.text.trim(),
                                  'email': _emailController.text.trim(),
                                  'avatar_initials': initials.isNotEmpty ? initials : 'U',
                                }).eq('uid', user!.id);
                                await AuthService.instance.refreshProfile();
                                setState(() {
                                  _isEditing = false;
                                  _isSaving = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                setState(() { _isSaving = false; });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FlutterFlowTheme.of(context).primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            child: _isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                  ] else ...[
                    InkWell(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out', style: const TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await AuthService.instance.signOut();
                      }
                    },
                    child: wrapWithModel(
                      model: _model.buttonModel,
                      updateCallback: () => safeSetState(() {}),
                      child: ButtonWidget(
                        iconPresent: true,
                        icon: Icon(
                          Icons.logout_rounded,
                          color: FlutterFlowTheme.of(context).onPrimary,
                          size: 20,
                        ),
                        iconEndPresent: false,
                        content: 'SIGN OUT',
                        variant: 'primary',
                        size: 'large',
                        fullWidth: true,
                        loading: false,
                        disabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
},
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: FlutterFlowTheme.of(context).secondaryText, size: 20),
          const SizedBox(width: 12.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: FlutterFlowTheme.of(context).labelSmall.override(
                  font: GoogleFonts.inter(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
