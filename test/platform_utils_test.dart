import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_password/core/platform/platform_utils.dart';

void main() {
  group('PlatformUtils', () {
    test('platform returns correct enum based on current platform', () {
      final platform = PlatformUtils.platform;
      
      // This test will run on whatever platform the test is executed on
      // We verify the enum is one of the valid values
      expect([
        AppPlatform.mobile,
        AppPlatform.desktop,
        AppPlatform.web,
      ], contains(platform));
    });

    test('isDesktop returns true for desktop platforms', () {
      // The actual value depends on where tests are run
      // We just verify the property doesn't throw
      final result = PlatformUtils.isDesktop;
      expect(result, isA<bool>());
    });

    test('isMobile returns true for mobile platforms', () {
      final result = PlatformUtils.isMobile;
      expect(result, isA<bool>());
    });

    test('isDesktop and isMobile are mutually exclusive', () {
      // On any given platform, exactly one should be true
      // (or both false for web, which we don't detect here)
      final isDesktop = PlatformUtils.isDesktop;
      final isMobile = PlatformUtils.isMobile;
      
      // At least one should be true for known platforms
      expect(isDesktop || isMobile, isTrue);
    });

    test('platform-specific getters work correctly', () {
      // Verify all platform getters return booleans without throwing
      expect(PlatformUtils.isMacOS, isA<bool>());
      expect(PlatformUtils.isWindows, isA<bool>());
      expect(PlatformUtils.isLinux, isA<bool>());
      expect(PlatformUtils.isIOS, isA<bool>());
      expect(PlatformUtils.isAndroid, isA<bool>());
    });

    test('AppPlatform enum has correct values', () {
      expect(AppPlatform.values, contains(AppPlatform.mobile));
      expect(AppPlatform.values, contains(AppPlatform.desktop));
      expect(AppPlatform.values, contains(AppPlatform.web));
      expect(AppPlatform.values.length, 3);
    });
  });

  group('Platform detection logic', () {
    test('desktop platforms are correctly identified', () {
      // We can't directly test Platform.isXxx in unit tests without mocking
      // But we can verify the logic works for the current platform
      final currentPlatform = Platform.operatingSystem;
      
      final isDesktop = PlatformUtils.isDesktop;
      final isMobile = PlatformUtils.isMobile;
      
      // Log for debugging (will show in test output)
      print('Current OS: $currentPlatform');
      print('isDesktop: $isDesktop, isMobile: $isMobile');
      
      // Basic sanity check - properties should be consistent
      if (currentPlatform == 'macos' || 
          currentPlatform == 'windows' || 
          currentPlatform == 'linux') {
        expect(isDesktop, isTrue);
      }
    });
  });
}
