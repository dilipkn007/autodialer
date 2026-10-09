import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:f_o_l_k_auto_dialer/flutter_flow/nav/nav.dart';
import 'package:f_o_l_k_auto_dialer/models/enums.dart';

export 'package:f_o_l_k_auto_dialer/models/enums.dart' show UserRole;

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  UserRole? _role;
  UserRole? _effectiveRole;
  String? _userName;
  String? _userEmail;
  String? _contactId;
  String? _folkGuideId;
  bool _loading = true;
  bool _initialized = false;

  User? get currentUser => _supabase.auth.currentUser;
  UserRole? get role => _role;
  UserRole? get effectiveRole => _effectiveRole ?? _role;
  bool get isEffectiveRoleSet => _effectiveRole != null;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get contactId => _contactId ?? currentUser?.id;
  String? get folkGuideId => _folkGuideId;
  bool get isFolkGuide => effectiveRole == UserRole.FOLK_GUIDE;
  bool get loading => _loading;
  bool get initialized => _initialized;

  void setEffectiveRole(UserRole role, {String? folkGuideId}) {
    _effectiveRole = role;
    _folkGuideId = folkGuideId;
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
        _contactId = null;
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
      _contactId = null;
      notifyListeners();
      return;
    }
    try {
      var response = await _supabase
          .from('contact')
          .select('id, role, name, email')
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
              .select('id, role, name, email')
              .inFilter('mobile', formats.toList())
              .limit(1);
          if (contacts.isNotEmpty) {
            response = contacts.first as Map<String, dynamic>?;
          }
        }
      }

      if (response != null) {
        _contactId = response['id'] as String?;
        final String? roleStr = response['role'] as String?;
        if (roleStr == 'ADMIN') {
          _role = UserRole.ADMIN;
        } else {
          _role = UserRole.ENABLER;
        }
        _userName = response['name'] as String?;
        _userEmail = response['email'] as String?;
      } else {
        _contactId = currentUser!.id;
        _role = UserRole.ENABLER;
        _userName = currentUser!.email ?? currentUser!.phone ?? 'User';
        _userEmail = currentUser!.email;
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      _role = null;
      _userName = null;
      _userEmail = null;
      _contactId = currentUser?.id;
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
      'role': 'ENABLER',
    });

    await refreshProfile();
  }

  Future<bool> autoMigrateDummyProfile() async {
    final user = currentUser;
    if (user == null) return false;

    final phone = user.phone ?? '';
    if (phone.isEmpty) return false;

    final base10 =
        phone.length >= 10 ? phone.substring(phone.length - 10) : phone;

    try {
      final existingContacts = await _supabase.from('contact').select().or(
          'mobile.eq.$phone,mobile.eq.$base10,mobile.eq.91$base10,mobile.eq.+91$base10');
          
      final dummyProfiles =
          existingContacts.where((u) => u['id'] != user.id).toList();
          
      if (dummyProfiles.isNotEmpty) {
        final oldContact = dummyProfiles.first;
        final oldId = oldContact['id'] as String;
        
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
      
      return false;
    } catch (e) {
      debugPrint("Error during auto-migration: $e");
      rethrow;
    }
  }

  Future<void> verifyPhone({
    required String phoneNumber,
  }) async {
    await _supabase.auth.signInWithOtp(
      phone: phoneNumber,
    );
  }

  /// --- Token-based login (no OTP) ---
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
    _contactId = null;
    await _supabase.auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
