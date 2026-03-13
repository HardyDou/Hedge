// Unit tests for CLI core modules
// Run with: cd cli && dart test

import 'dart:convert';
import 'package:test/test.dart';
import 'package:hedge_cli/vault/vault_models.dart';

void main() {
  group('VaultItem', () {
    test('should parse from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'title': 'GitHub Account',
        'username': 'user@example.com',
        'password': 'secret123',
        'url': 'https://github.com',
        'notes': 'Test notes',
        'category': 'work',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final item = VaultItem.fromJson(json);

      expect(item.id, equals('test-id'));
      expect(item.title, equals('GitHub Account'));
      expect(item.username, equals('user@example.com'));
      expect(item.password, equals('secret123'));
      expect(item.url, equals('https://github.com'));
      expect(item.notes, equals('Test notes'));
      expect(item.category, equals('work'));
    });

    test('should serialize to JSON correctly', () {
      final item = VaultItem(
        id: 'test-id',
        title: 'Test Item',
        username: 'user',
        password: 'pass',
        url: 'https://example.com',
        notes: 'notes',
        category: 'personal',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = item.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['title'], equals('Test Item'));
      expect(json['username'], equals('user'));
      expect(json['password'], equals('pass'));
    });

    test('should match query in title (case insensitive)', () {
      final item = VaultItem(
        id: '1',
        title: 'GitHub Personal',
        username: 'user',
        password: 'pass',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(item.matches('github'), isTrue);
      expect(item.matches('GITHUB'), isTrue);
      expect(item.matches('GitHub'), isTrue);
      expect(item.matches('notfound'), isFalse);
    });

    test('should match query in username', () {
      final item = VaultItem(
        id: '1',
        title: 'GitHub',
        username: 'user@example.com',
        password: 'pass',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(item.matches('user@'), isTrue);
      expect(item.matches('example'), isTrue);
      expect(item.matches('notfound'), isFalse);
    });

    test('should match query in url', () {
      final item = VaultItem(
        id: '1',
        title: 'GitHub',
        username: 'user',
        password: 'pass',
        url: 'https://github.com/login',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(item.matches('github.com'), isTrue);
      expect(item.matches('login'), isTrue);
    });

    test('should match query in notes', () {
      final item = VaultItem(
        id: '1',
        title: 'GitHub',
        username: 'user',
        password: 'pass',
        notes: 'Work account for coding',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(item.matches('work'), isTrue);
      expect(item.matches('coding'), isTrue);
    });

    test('should handle null fields gracefully', () {
      final item = VaultItem(
        id: '1',
        title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(item.matches('anything'), isFalse);
      expect(item.url, isNull);
      expect(item.username, isNull);
      expect(item.password, isNull);
    });
  });

  group('Vault', () {
    test('should parse from JSON correctly', () {
      final json = {
        'items': [
          {
            'id': '1',
            'title': 'Item 1',
            'createdAt': '2024-01-01T00:00:00.000Z',
            'updatedAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': '2',
            'title': 'Item 2',
            'createdAt': '2024-01-01T00:00:00.000Z',
            'updatedAt': '2024-01-01T00:00:00.000Z',
          },
        ],
      };

      final vault = Vault.fromJson(json);

      expect(vault.items.length, equals(2));
      expect(vault.items[0].title, equals('Item 1'));
      expect(vault.items[1].title, equals('Item 2'));
    });

    test('should handle empty items', () {
      final json = {'items': <Map<String, dynamic>>[]};

      final vault = Vault.fromJson(json);

      expect(vault.items, isEmpty);
    });
  });
}
