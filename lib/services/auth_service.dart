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
  bool _loading = true;
  bool _initialized = false;

  User? get currentUser => _supabase.auth.currentUser;
  UserRole? get role => _role;
  String? get userName => _userName;
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
          .from('users')
          .select('role, name')
          .eq('uid', currentUser!.id)
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
      } else {
        _role = null;
        _userName = null;
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      _role = null;
      _userName = null;
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

    await _supabase.from('users').upsert({
      'uid': user.id,
      'phone': phone,
      'name': name,
      if (email.isNotEmpty) 'email': email,
      if (initials.isNotEmpty) 'avatar_initials': initials,
    });

    await refreshProfile();
  }

  Future<bool> autoMigrateDummyProfile() async {
    final user = currentUser;
    if (user == null) return false;

    final phone = user.phone ?? '';
    if (phone.isEmpty) return false;

    final phoneWithoutPlus = phone.replaceFirst('+', '');
    final phoneWithPlus = '+$phoneWithoutPlus';

    try {
      final existingUsers = await _supabase
          .from('users')
          .select()
          .or('phone.eq.$phoneWithoutPlus,phone.eq.$phoneWithPlus');
          
      // Find a dummy profile (a row where the UID doesn't match the new Auth UID)
      final dummyProfiles = existingUsers.where((u) => u['uid'] != user.id).toList();
          
      if (dummyProfiles.isNotEmpty) {
        final oldUser = dummyProfiles.first;
        final oldUid = oldUser['uid'] as String;
        
        // Call the atomic Supabase RPC to migrate the profile and relational data
        await _supabase.rpc('migrate_dummy_profile', params: {
          'p_old_uid': oldUid,
          'p_new_uid': user.id,
          'p_phone': phone,
          'p_name': oldUser['name'],
          'p_email': oldUser['email'],
          'p_avatar_initials': oldUser['avatar_initials'],
          'p_role': oldUser['role'],
          'p_is_active': oldUser['is_active'],
        });
        
        debugPrint("Migration successful!");
        await refreshProfile();
        return true;
      }
      
      // If we reach here, there was no dummy profile to migrate.
      // (Either the user already has a real profile, or it's a brand new organic signup).
      return false;
    } catch (e) {
      debugPrint("Error during auto-migration: $e");
      rethrow;
    }
    return false;
  }

  Future<void> verifyPhone({
    required String phoneNumber,
  }) async {
    // Note: Supabase formatting requires e.g. +91... 
    await _supabase.auth.signInWithOtp(
      phone: phoneNumber,
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
    await _supabase.auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
