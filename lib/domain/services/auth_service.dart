import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class AuthService {
  AuthService()
      : _googleSignIn = GoogleSignIn(
          scopes: [
            drive.DriveApi.driveFileScope,
            drive.DriveApi.driveAppdataScope,
          ],
        );

  final GoogleSignIn _googleSignIn;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (error) {
      debugPrint('Sign in failed: $error');
      return null;
    }
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<GoogleSignInAccount?> get currentUser async => _googleSignIn.currentUser;
  
  Stream<GoogleSignInAccount?> get onCurrentUserChanged => _googleSignIn.onCurrentUserChanged;
}
