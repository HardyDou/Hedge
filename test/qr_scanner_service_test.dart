import 'package:flutter_test/flutter_test.dart';
import 'package:hedge/domain/services/qr_scanner_service.dart';

void main() {
  group('QrScannerService', () {
    test('parseTotpUri should parse valid TOTP URI', () {
      const uri = 'otpauth://totp/Example:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example';
      final result = QrScannerService.parseTotpUri(uri);
      
      expect(result, isNotNull);
      expect(result!['secret'], 'JBSWY3DPEHPK3PXP');
      expect(result['issuer'], 'Example');
      expect(result['account'], 'user@example.com');
    });

    test('parseTotpUri should return null for invalid URI', () {
      const uri = 'https://example.com';
      final result = QrScannerService.parseTotpUri(uri);
      
      expect(result, isNull);
    });

    test('isValidSecret should validate correct secret format', () {
      expect(QrScannerService.isValidSecret('JBSWY3DPEHPK3PXP'), isTrue);
      expect(QrScannerService.isValidSecret('ABCDEFGHIJKLMNOP'), isTrue);
    });

    test('isValidSecret should reject invalid secret format', () {
      expect(QrScannerService.isValidSecret(''), isFalse);
      expect(QrScannerService.isValidSecret('123'), isFalse);
      expect(QrScannerService.isValidSecret('invalid!@#'), isFalse);
    });
  });
}
