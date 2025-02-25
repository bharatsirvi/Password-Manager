import 'package:local_auth/local_auth.dart';

class BiometricAuthUtil {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return false;
      }

      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your passwords',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      return authenticated;
    } catch (e) {
      print('Error using biometric authentication: $e');
      return false;
    }
  }
}
