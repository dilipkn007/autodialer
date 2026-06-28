import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:f_o_l_k_auto_dialer/flutter_flow/nav/nav.dart';

enum UserRole { ADMIN, ENABLER }

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  UserRole? _role;
  String? _userName;
  String? _userEmail;
  bool _loading = true;
  bool _initialized = false;

  User? get currentUser => _supabase.auth.currentUser;
  UserRole? get role => _role;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get loading => _loading;
  bool get initialized => _initialized;

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
      final response = await _supabase
          .from('contact')
          .select('role, name, email')
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (response != null) {
        final roleStr = response['role'] as String?;
        if (roleStr == 'ADMIN') {
          _role = UserRole.ADMIN;
        } else if (roleStr == 'ENABLER') {
          _role = UserRole.ENABLER;
        } else {
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

    final initials = name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    final phone = user.phone ?? '';
    final base10 = phone.length >= 10 ? phone.substring(phone.length - 10) : phone;

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

    // Extract the base 10 digits to match various formats (e.g., 7019958110, 917019958110, +917019958110)
    final base10 = phone.length >= 10 ? phone.substring(phone.length - 10) : phone;

    try {
      final existingContacts = await _supabase
          .from('contact')
          .select()
          .or('mobile.eq.$phone,mobile.eq.$base10,mobile.eq.91$base10,mobile.eq.+91$base10');
          
      // Find a dummy profile (a row where the ID doesn't match the new Auth ID)
      final dummyProfiles = existingContacts.where((u) => u['id'] != user.id).toList();
          
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

  /// --- Token-based login (for enablers) ---
  ///
  /// Step 1: Validate the token, retrieve the mobile, and send OTP.
  /// Returns the normalised phone number to use in step 2.
  Future<String> signInWithAccessToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) throw Exception('Token cannot be empty.');

    // Look up a valid (not revoked, not used, not expired) token
    final rows = await _supabase
        .from('access_token')
        .select('id, mobile_number, is_used, revoked, expires_at')
        .eq('token', trimmed)
        .limit(1);

    if (rows.isEmpty) throw Exception('Invalid access token.');

    final row = rows.first;

    if (row['revoked'] == true) {
      throw Exception('This token has been revoked.');
    }
    if (row['is_used'] == true) {
      throw Exception('This token has already been used.');
    }
    final expiresAt = row['expires_at'] != null
        ? DateTime.tryParse(row['expires_at'].toString())
        : null;
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw Exception('This token has expired.');
    }

    final mobile = row['mobile_number'] as String? ?? '';
    if (mobile.isEmpty) throw Exception('No mobile number linked to this token.');

    // Normalise phone
    String phone = mobile.trim();
    if (!phone.startsWith('+')) {
      phone = phone.startsWith('0')
          ? '+91${phone.substring(1)}'
          : '+91$phone';
    }

    // Send OTP to the linked mobile number
    await _supabase.auth.signInWithOtp(phone: phone);

    return phone; // caller uses this in step 2
  }

  /// Step 2: Verify OTP obtained after signInWithAccessToken, and mark the token as used.
  Future<AuthResponse> confirmAccessTokenOtp(
      String token, String phone, String otp) async {
    final response = await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );

    // Mark token as used
    try {
      await _supabase.from('access_token').update({
        'is_used': true,
        'used_at': DateTime.now().toIso8601String(),
      }).eq('token', token.trim());
    } catch (e) {
      debugPrint('Warning: could not mark token as used: $e');
    }

    return response;
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
    await _supabase.auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
