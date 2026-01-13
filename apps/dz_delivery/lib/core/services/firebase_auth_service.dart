import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Service Firebase pour la vérification du numéro de téléphone
class FirebaseAuthService {
  static FirebaseAuth? _auth;
  static String? _verificationId;
  static int? _resendToken;

  static Future<void> init() async {
    await Firebase.initializeApp();
    _auth = FirebaseAuth.instance;
    // Configurer la langue pour les SMS
    await _auth!.setLanguageCode('fr');
  }

  static FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  /// Envoyer un code OTP au numéro de téléphone
  /// Le numéro doit être au format international: +213XXXXXXXXX
  static Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResendingToken ?? _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-vérification sur certains appareils Android
        completer.complete({
          'success': true,
          'autoVerified': true,
          'credential': credential,
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        String message;
        switch (e.code) {
          case 'invalid-phone-number':
            message = 'Numéro de téléphone invalide';
            break;
          case 'too-many-requests':
            message = 'Trop de tentatives. Réessayez plus tard';
            break;
          case 'quota-exceeded':
            message = 'Quota SMS dépassé. Réessayez demain';
            break;
          default:
            message = e.message ?? 'Erreur d\'envoi du SMS';
        }
        completer.complete({'success': false, 'error': message});
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        completer.complete({
          'success': true,
          'autoVerified': false,
          'verificationId': verificationId,
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  /// Vérifier le code OTP saisi par l'utilisateur
  static Future<Map<String, dynamic>> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      return {'success': false, 'error': 'Session expirée. Renvoyez le code'};
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // On ne fait pas de sign-in Firebase, juste vérifier le code
      // Pour vérifier sans créer de compte Firebase:
      await auth.signInWithCredential(credential);
      
      // Déconnecter immédiatement de Firebase (on utilise Supabase pour l'auth)
      await auth.signOut();
      
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Code incorrect';
          break;
        case 'session-expired':
          message = 'Session expirée. Renvoyez le code';
          break;
        default:
          message = e.message ?? 'Erreur de vérification';
      }
      return {'success': false, 'error': message};
    }
  }

  /// Renvoyer le code OTP
  static Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    return sendOTP(phoneNumber: phoneNumber, forceResendingToken: _resendToken);
  }

  /// Formater le numéro algérien au format international
  static String formatAlgerianPhone(String phone) {
    // Supprimer les espaces et caractères spéciaux
    phone = phone.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
    
    // Si commence par 0, remplacer par +213
    if (phone.startsWith('0')) {
      phone = '+213${phone.substring(1)}';
    }
    // Si ne commence pas par +, ajouter +213
    else if (!phone.startsWith('+')) {
      phone = '+213$phone';
    }
    
    return phone;
  }

  /// Valider le format du numéro algérien
  static bool isValidAlgerianPhone(String phone) {
    final formatted = formatAlgerianPhone(phone);
    // +213 suivi de 9 chiffres (5, 6, 7 pour mobile)
    return RegExp(r'^\+213[567]\d{8}$').hasMatch(formatted);
  }

  static void reset() {
    _verificationId = null;
    _resendToken = null;
  }
}
