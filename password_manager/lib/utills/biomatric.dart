import 'package:local_auth/local_auth.dart';

class BiometricAuthUtil {
  final LocalAuthentication _localAuth = LocalAuthentication();
  Future<bool> isDeviceSupported() async {
    try {
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      print(
          'isDeviceSupported checking biometric availability: .....................$isDeviceSupported');
      return isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: .....................$e');
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print(
          'canCheckBiometrics checking biometric availability: .....................$canCheckBiometrics');
      return canCheckBiometrics;
    } catch (e) {
      print('Error checking biometric availability: ..................$e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your passwords',
        options: const AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
            sensitiveTransaction: true),
      );

      return authenticated;
    } catch (e) {
      print('Error using biometric authentication: $e');
      return false;
    }
  }
}
