import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:f_o_l_k_auto_dialer/flutter_flow/nav/nav.dart';

enum UserRole { ADMIN, ENABLER, FOLK, FOLK_GUIDE }

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  UserRole? _role;
  UserRole? _effectiveRole;
  String? _userName;
  String? _userEmail;
  String? _folkGuideId;
  bool _loading = true;
  bool _initialized = false;

  User? get currentUser => _supabase.auth.currentUser;
  UserRole? get role => _role;
  UserRole? get effectiveRole => _effectiveRole ?? _role;
  bool get isEffectiveRoleSet => _effectiveRole != null;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get folkGuideId => _folkGuideId;
  bool get isFolkGuide => effectiveRole == UserRole.FOLK_GUIDE;
  bool get loading => _loading;
  bool get initialized => _initialized;

  void setEffectiveRole(UserRole role, {String? folkGuideId}) {
    _effectiveRole = role;
    if (role == UserRole.FOLK_GUIDE) {
      _folkGuideId = folkGuideId;
    }
    notifyListeners();
    AppStateNotifier.instance.notifyListeners();
  }

  void clearEffectiveRole() {
    _effectiveRole = null;
    _folkGuideId = null;
    notifyListeners();
    AppStateNotifier.instance.notifyListeners();
  }

  StreamSubscription<AuthState>? _authSubscription;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      _loading = true;
      notifyListeners();
      final session = data.session;
      if (session == null) {
        _role = null;
        _userName = null;
        _loading = false;
        notifyListeners();
        AppStateNotifier.instance.notifyListeners();
      } else {
        await refreshProfile();
      }
    });
  }

  Future<void> refreshProfile() async {
    if (currentUser == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      var response = await _supabase
          .from('contact')
          .select('role, name, email')
          .eq('id', currentUser!.id)
          .maybeSingle();

      // If no contact matches auth UID (e.g. token-login without duplicate),
      // fall back to matching by phone number.
      if (response == null) {
        final phone = currentUser!.phone;
        if (phone != null && phone.isNotEmpty) {
          final raw10 = phone.length >= 10
              ? phone.substring(phone.length - 10)
              : phone;
          final formats = <String>{
            phone,
            raw10,
            '91$raw10',
            '+91$raw10',
          };
          formats.remove('');
          final contacts = await _supabase
              .from('contact')
              .select('role, name, email')
              .inFilter('mobile', formats.toList())
              .limit(1);
          if (contacts.isNotEmpty) {
            response = contacts.first as Map<String, dynamic>?;
          }
        }
      }

      if (response != null) {
        String? roleStr = response['role'] as String?;

        // If the contact's role is FOLK (default OTP role), check if
        // their phone is mapped in folk_guide_id → promote to FOLK_GUIDE.
        if (roleStr == 'FOLK' || roleStr == 'FOLK_GUIDE') {
          final phone = currentUser!.phone;
          if (phone != null && phone.isNotEmpty) {
            final raw10 = phone.length >= 10
                ? phone.substring(phone.length - 10)
                : phone;
            final formats = <String>{
              phone,
              raw10,
              '91$raw10',
              '+91$raw10',
            };
            formats.remove('');
            final guideRow = await _supabase
                .from('folk_guide_id')
                .select('folk_guide_id')
                .inFilter('phone', formats.toList())
                .maybeSingle();
            if (guideRow != null) {
              _folkGuideId = guideRow['folk_guide_id'] as String?;
              roleStr = 'FOLK_GUIDE';
            }
          }
        }
        if (_folkGuideId == null) {
          _folkGuideId = response['folk_guide_id'] as String?;
        }

        switch (roleStr) {
          case 'ADMIN':
            _role = UserRole.ADMIN;
            break;
          case 'ENABLER':
            _role = UserRole.ENABLER;
            break;
          case 'FOLK':
            _role = UserRole.FOLK;
            break;
          case 'FOLK_GUIDE':
            _role = UserRole.FOLK_GUIDE;
            break;
          default:
            _role = null;
        }
        _userName = response['name'] as String?;
        _userEmail = response['email'] as String?;
      } else {
        _role = null;
        _userName = null;
        _userEmail = null;
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      _role = null;
      _userName = null;
      _userEmail = null;
    } finally {
      _loading = false;
      notifyListeners();
      AppStateNotifier.instance.notifyListeners();
    }
  }

  Future<void> registerUserProfile({
    required String name,
    required String email,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("No authenticated user");

    final initials = name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    final phone = user.phone ?? '';
    final base10 =
        phone.length >= 10 ? phone.substring(phone.length - 10) : phone;

    // Check if phone already exists for a different contact
    final existingContact = await _supabase
        .from('contact')
        .select()
        .or('mobile.eq.$phone,mobile.eq.$base10,mobile.eq.91$base10,mobile.eq.+91$base10')
        .neq('id', user.id)
        .maybeSingle();
        
    if (existingContact != null) {
      throw Exception("A contact with this phone number already exists.");
    }

    await _supabase.from('contact').upsert({
      'id': user.id,
      'mobile': phone,
      'name': name,
      if (email.isNotEmpty) 'email': email,
      if (initials.isNotEmpty) 'avatar_initials': initials,
      'role': 'FOLK',
    });

    await refreshProfile();
  }

  Future<bool> autoMigrateDummyProfile() async {
    final user = currentUser;
    if (user == null) return false;

    final phone = user.phone ?? '';
    if (phone.isEmpty) return false;

    // Extract the base 10 digits to match various formats (e.g., 7019958110, 917019958110, +917019958110)
    final base10 =
        phone.length >= 10 ? phone.substring(phone.length - 10) : phone;

    try {
      final existingContacts = await _supabase.from('contact').select().or(
          'mobile.eq.$phone,mobile.eq.$base10,mobile.eq.91$base10,mobile.eq.+91$base10');
          
      // Find a dummy profile (a row where the ID doesn't match the new Auth ID)
      final dummyProfiles =
          existingContacts.where((u) => u['id'] != user.id).toList();
          
      if (dummyProfiles.isNotEmpty) {
        final oldContact = dummyProfiles.first;
        final oldId = oldContact['id'] as String;
        
        // Call the atomic Supabase RPC to migrate the profile and relational data
        await _supabase.rpc('migrate_contact_identity', params: {
          'p_old_id': oldId,
          'p_new_id': user.id,
          'p_mobile': phone,
          'p_name': oldContact['name'],
          'p_role': oldContact['role'],
        });
        
        debugPrint("Migration successful!");
        await refreshProfile();
        return true;
      }
      
      // If we reach here, there was no dummy profile to migrate.
      // (Either the contact already has a real profile, or it's a brand new organic signup).
      return false;
    } catch (e) {
      debugPrint("Error during auto-migration: $e");
      rethrow;
    }
  }

  Future<void> verifyPhone({
    required String phoneNumber,
  }) async {
    // Note: Supabase formatting requires e.g. +91... 
    await _supabase.auth.signInWithOtp(
      phone: phoneNumber,
    );
  }

  /// --- Token-based login (no OTP) ---
  ///
  /// Validates the token via an Edge Function, then signs in with phone + password.
  /// The token itself is the sole authentication credential.
  Future<void> signInWithToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) throw Exception('Token cannot be empty.');

    final FunctionResponse result;
    try {
      result = await _supabase.functions.invoke(
        'login-with-token',
        body: {'token': trimmed},
      );
    } on FunctionException catch (e) {
      if (e.status == 401) {
        final msg = e.details is Map ? (e.details as Map)['error'] : null;
        throw Exception(msg ?? 'Invalid or expired access token.');
    }
      throw Exception('Failed to login with token.');
    }

    final data = result.data as Map<String, dynamic>;
    final phone = data['phone'] as String;
    final password = data['password'] as String;

    await _supabase.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  Future<AuthResponse> signInWithOtp(String phoneNumber, String smsCode) async {
    final response = await _supabase.auth.verifyOTP(
      phone: phoneNumber,
      token: smsCode,
      type: OtpType.sms,
    );
    return response;
  }

  Future<void> signOut() async {
    _effectiveRole = null;
    await _supabase.auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
