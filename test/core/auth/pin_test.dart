import 'package:bechakena/core/auth/pin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PIN hashing', () {
    test('hash then verify succeeds', () {
      final hash = hashPin('1234');
      expect(verifyPin('1234', hash), isTrue);
    });

    test('wrong PIN fails', () {
      final hash = hashPin('1234');
      expect(verifyPin('0000', hash), isFalse);
    });

    test('same PIN hashes differently each time (random salt)', () {
      expect(hashPin('1234'), isNot(hashPin('1234')));
    });

    test('stored form carries algorithm, iterations, salt and digest', () {
      final hash = hashPin('1234');
      final parts = hash.split(r'$');
      expect(parts.length, 4);
      expect(parts[0], 'pbkdf2sha256');
      expect(int.parse(parts[1]), greaterThanOrEqualTo(10000));
      expect(parts[2], isNotEmpty); // salt
      expect(parts[3], isNotEmpty); // digest
    });

    test('verify is robust to a malformed stored hash', () {
      expect(verifyPin('1234', ''), isFalse);
      expect(verifyPin('1234', 'garbage'), isFalse);
      expect(verifyPin('1234', r'pbkdf2sha256$abc'), isFalse);
    });

    test('empty PIN is rejected at hash time', () {
      expect(() => hashPin(''), throwsArgumentError);
    });
  });
}
