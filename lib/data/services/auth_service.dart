import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Current signed-in user
  User? get currentUser => _supabase.auth.currentUser;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with Google (Native — using google_sign_in + Supabase ID token)
  ///
  /// Web Client ID'nizi Supabase Dashboard > Authentication > Providers > Google
  /// altından alabilirsiniz. iOS Client ID'yi ise Google Cloud Console'dan
  /// oluşturup Info.plist'e eklemeniz gerekir.
  Future<AuthResponse> signInWithGoogle() async {
    try {
      /// TODO: Kendi Google Cloud Console'dan aldığınız web client ID'yi buraya yazın.
      /// Supabase Dashboard > Authentication > Providers > Google bölümünde
      /// "Web Client ID" olarak gösterilen değerdir.
      const webClientId = '17232384502-b56b3p7kva8f0m2bb69p2u1dnue502eg.apps.googleusercontent.com';

      /// iOS için ayrıca bir iOS Client ID gerekir.
      /// Google Cloud Console > Credentials > iOS type OAuth 2.0 Client ID
      /// oluşturup burada ve Info.plist'te tanımlayın.
      /// Android'de null bırakabilirsiniz.
      const iosClientId = '17232384502-5gg7kreg242hgkpjc2sop8hd357e802b.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google girişi iptal edildi.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AuthException('Google ID token alınamadı.');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('Google Sign-In başarılı: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('Google Sign in error: $e');
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      // Google Sign-In'den de çıkış yap
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
}
