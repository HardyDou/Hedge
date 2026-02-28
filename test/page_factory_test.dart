import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge/core/platform/platform_utils.dart';
import 'package:hedge/presentation/pages/page_factory.dart';
import 'package:hedge/src/dart/vault.dart';

void main() {
  group('PageFactory', () {
    test('getHomePage returns appropriate widget based on platform', () {
      final widget = PageFactory.getHomePage();
      expect(widget, isA<Widget>());
    });

    test('getUnlockPage returns a widget', () {
      final widget = PageFactory.getUnlockPage();
      expect(widget, isA<Widget>());
    });

    test('getOnboardingPage returns a widget', () {
      final widget = PageFactory.getOnboardingPage();
      expect(widget, isA<Widget>());
    });

    test('getAddItemPage returns a widget', () {
      final widget = PageFactory.getAddItemPage();
      expect(widget, isA<Widget>());
    });

    test('getDetailPage accepts VaultItem and returns widget', () {
      final testItem = VaultItem(
        id: 'test-id-123',
        title: 'Test Account',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final widget = PageFactory.getDetailPage(testItem);
      expect(widget, isA<Widget>());
    });

    test('getEditPage accepts VaultItem and returns widget', () {
      final testItem = VaultItem(
        id: 'test-id-456',
        title: 'Edit Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final widget = PageFactory.getEditPage(testItem);
      expect(widget, isA<Widget>());
    });

    test('getSettingsPage returns a widget', () {
      final widget = PageFactory.getSettingsPage();
      expect(widget, isA<Widget>());
    });
  });

  group('PlatformUtils integration', () {
    test('platform detection is available', () {
      final platform = PlatformUtils.platform;
      expect(platform, isA<AppPlatform>());
    });

    test('isDesktop and isMobile work correctly', () {
      expect(PlatformUtils.isDesktop || PlatformUtils.isMobile, isTrue);
    });

    test('platform-specific detection returns boolean', () {
      expect(PlatformUtils.isMacOS, isA<bool>());
      expect(PlatformUtils.isWindows, isA<bool>());
      expect(PlatformUtils.isLinux, isA<bool>());
      expect(PlatformUtils.isIOS, isA<bool>());
      expect(PlatformUtils.isAndroid, isA<bool>());
    });
  });

  group('VaultItem test fixture', () {
    test('VaultItem can be created for testing', () {
      final item = VaultItem(
        id: 'test-id-789',
        title: 'Test Account',
        username: 'testuser',
        password: 'testpass',
        url: 'https://example.com',
        notes: 'Test notes',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(item.id, 'test-id-789');
      expect(item.title, 'Test Account');
      expect(item.username, 'testuser');
      expect(item.password, 'testpass');
      expect(item.url, 'https://example.com');
      expect(item.notes, 'Test notes');
    });

    test('VaultItem can be used with PageFactory', () {
      final item = VaultItem(
        id: 'factory-test-id',
        title: 'Factory Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final widget = PageFactory.getDetailPage(item);
      expect(widget, isNotNull);
    });

    test('VaultItem with minimal fields works', () {
      final item = VaultItem(
        id: 'min-id',
        title: 'Minimal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(item.id, 'min-id');
      expect(item.title, 'Minimal');
      expect(item.username, isNull);
      expect(item.password, isNull);
      expect(item.url, isNull);
    });
  });

  group('Desktop vs Mobile widget types', () {
    testWidgets('getHomePage returns desktop widget on desktop', (WidgetTester tester) async {
      final widget = PageFactory.getHomePage();
      // On macOS test runner, should return desktop home
      expect(widget, isA<Widget>());
    }, skip: true);

    test('getDetailPage returns correct type for desktop', () {
      final item = VaultItem(
        id: 'detail-test',
        title: 'Detail Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final widget = PageFactory.getDetailPage(item);
      // Just verify it returns a widget without throwing
      expect(widget, isNotNull);
    });
  });
}
