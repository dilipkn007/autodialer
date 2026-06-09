import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:f_o_l_k_auto_dialer/dataconnect/default.dart';
import 'package:f_o_l_k_auto_dialer/flutter_flow/nav/nav.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserRole? _role;
  String? _userName;
  bool _loading = true;
  bool _initialized = false;

  User? get currentUser => _auth.currentUser;
  UserRole? get role => _role;
  String? get userName => _userName;
  bool get loading => _loading;
  bool get initialized => _initialized;

  StreamSubscription<User?>? _authSubscription;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _authSubscription = _auth.userChanges().listen((user) async {
      _loading = true;
      notifyListeners();
      if (user == null) {
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
      final response = await DefaultConnector.instance.getCurrentUser().execute();
      final userProfile = response.data.user;
      if (userProfile != null) {
        final roleVal = userProfile.role;
        if (roleVal is Known<UserRole>) {
          _role = roleVal.value;
        }
        _userName = userProfile.name;
      } else {
        // No profile in Data Connect yet
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

    final phone = user.phoneNumber ?? '';
    if (phone.isNotEmpty) {
      try {
        final existingRes = await DefaultConnector.instance.getUserByPhone(phone: phone).execute();
        final existingUsers = existingRes.data.users;
        if (existingUsers.isNotEmpty) {
          final oldUser = existingUsers.first;
          if (oldUser.uid != user.uid) {
            // Delete the old dummy user record created by the admin
            await DefaultConnector.instance.deleteUserByPhone(uid: oldUser.uid, phone: phone).execute();
          }
        }
      } catch (e) {
        debugPrint("Error cleaning up dummy profile: $e");
      }
    }

    var builder = DefaultConnector.instance.upsertUser(
      uid: user.uid,
      phone: phone,
      name: name,
    );

    if (email.isNotEmpty) {
      builder = builder.email(email);
    }
    if (initials.isNotEmpty) {
      builder = builder.avatarInitials(initials);
    }

    await builder.execute();

    await refreshProfile();
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithOtp(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
