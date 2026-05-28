import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class TotpService {
  static const String _base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const int _period = 30;
  static const int _digits = 6;

  /// Generates a random Base32 secret (16 chars = 80 bits of entropy).
  static String generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(10, (_) => random.nextInt(256));
    return _base32Encode(bytes);
  }

  /// Builds the otpauth URI used to generate the QR code for authenticator apps.
  static String buildOtpAuthUri(String secret, String username) {
    final label = Uri.encodeComponent(
        'SkyTrip:${username.isEmpty ? 'user' : username}');
    return 'otpauth://totp/$label'
        '?secret=$secret'
        '&issuer=SkyTrip'
        '&algorithm=SHA1'
        '&digits=$_digits'
        '&period=$_period';
  }

  /// Verifies a 6-digit TOTP code against the secret.
  /// Accepts codes from the previous, current, and next 30-second windows
  /// to account for slight clock skew.
  static bool verifyCode(String secret, String code) {
    final trimmed = code.trim();
    if (trimmed.length != _digits) return false;
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return false;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (int delta = -1; delta <= 1; delta++) {
      final counter = (nowSeconds + delta * _period) ~/ _period;
      if (_generateCode(secret, counter) == parsed) return true;
    }
    return false;
  }

  static int _generateCode(String secret, int counter) {
    final key = _base32Decode(secret);
    final msg = _int64ToBytes(counter);
    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(msg).bytes;
    final offset = digest.last & 0x0F;
    final truncated = ((digest[offset] & 0x7F) << 24) |
        ((digest[offset + 1] & 0xFF) << 16) |
        ((digest[offset + 2] & 0xFF) << 8) |
        (digest[offset + 3] & 0xFF);
    return truncated % _pow10(_digits);
  }

  static int _pow10(int n) {
    int result = 1;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  static Uint8List _int64ToBytes(int value) {
    final bytes = Uint8List(8);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = value & 0xFF;
      value >>= 8;
    }
    return bytes;
  }

  static String _base32Encode(List<int> bytes) {
    final result = StringBuffer();
    var buffer = 0;
    var bitsLeft = 0;
    for (final byte in bytes) {
      buffer = (buffer << 8) | (byte & 0xFF);
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        result.write(_base32Chars[(buffer >> bitsLeft) & 0x1F]);
      }
    }
    if (bitsLeft > 0) {
      result.write(_base32Chars[(buffer << (5 - bitsLeft)) & 0x1F]);
    }
    return result.toString();
  }

  static List<int> _base32Decode(String input) {
    final upper = input.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
    var buffer = 0;
    var bitsLeft = 0;
    final result = <int>[];
    for (final char in upper.split('')) {
      final val = _base32Chars.indexOf(char);
      if (val < 0) continue;
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        result.add((buffer >> bitsLeft) & 0xFF);
      }
    }
    return result;
  }
}
