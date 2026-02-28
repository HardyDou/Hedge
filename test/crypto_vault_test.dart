import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge/src/dart/crypto.dart';
import 'package:hedge/src/dart/vault.dart';

void main() {
  group('CryptoService', () {
    test('generateSalt creates 16-byte salt', () {
      final salt = CryptoService.generateSalt();
      expect(salt.length, 16);
    });

    test('encrypt and decrypt data correctly', () async {
      final salt = CryptoService.generateSalt();
      final password = 'test_password_123';
      final data = {'username': 'testuser', 'password': 'secret123'};

      final encrypted = await CryptoService.encryptJson(data, password, salt);
      expect(encrypted.length, greaterThan(16));

      final decrypted = await CryptoService.decryptJson(encrypted, password);
      expect(decrypted!['username'], 'testuser');
      expect(decrypted['password'], 'secret123');
    });

    test('decrypt with wrong password returns null', () async {
      final salt = CryptoService.generateSalt();
      final password = 'correct_password';
      final data = {'test': 'value'};

      final encrypted = await CryptoService.encryptJson(data, password, salt);
      final decrypted = await CryptoService.decryptJson(encrypted, 'wrong_password');
      
      expect(decrypted, isNull);
    });

    test('same data with same password produces different ciphertext (due to random IV)', () async {
      final salt = CryptoService.generateSalt();
      final password = 'my_password';
      final data = {'item': 'test'};

      final encrypted1 = await CryptoService.encryptJson(data, password, salt);
      final encrypted2 = await CryptoService.encryptJson(data, password, salt);

      expect(encrypted1, isNot(equals(encrypted2)));
    });
  });

  group('VaultItem', () {
    test('create VaultItem with required fields', () {
      final item = VaultItem(title: 'Test Item');
      expect(item.title, 'Test Item');
      expect(item.id, isNotEmpty);
      expect(item.username, isNull);
      expect(item.password, isNull);
      expect(item.notes, isNull);
    });

    test('create VaultItem with all fields', () {
      final now = DateTime.now();
      final item = VaultItem(
        title: 'Test Item',
        username: 'user@test.com',
        password: 'secret123',
        url: 'https://example.com',
        notes: 'Some notes',
        category: 'Personal',
        createdAt: now,
        updatedAt: now,
      );
      expect(item.title, 'Test Item');
      expect(item.username, 'user@test.com');
      expect(item.password, 'secret123');
      expect(item.url, 'https://example.com');
      expect(item.notes, 'Some notes');
      expect(item.category, 'Personal');
    });

    test('copyWith creates new instance with updated fields', () {
      final item = VaultItem(title: 'Original');
      final updated = item.copyWith(title: 'Updated', username: 'newuser');
      
      expect(updated.title, 'Updated');
      expect(updated.username, 'newuser');
      expect(updated.id, item.id);
    });

    test('toJson and fromJson work correctly', () {
      final item = VaultItem(
        title: 'Test',
        username: 'user',
        password: 'pass',
      );
      
      final json = item.toJson();
      final restored = VaultItem.fromJson(json);
      
      expect(restored.title, item.title);
      expect(restored.username, item.username);
      expect(restored.password, item.password);
      expect(restored.id, item.id);
    });
  });

  group('Vault', () {
    test('createEmptyVault creates empty vault', () {
      final vault = VaultService.createEmptyVault();
      expect(vault.items, isEmpty);
    });

    test('addItem adds item to vault', () {
      final vault = VaultService.createEmptyVault();
      final updated = VaultService.addItem(vault, 'New Item');
      
      expect(updated.items.length, 1);
      expect(updated.items.first.title, 'New Item');
    });

    test('addItemWithDetails adds complete item', () {
      final vault = VaultService.createEmptyVault();
      final item = VaultItem(
        title: 'Complete Item',
        username: 'user',
        password: 'pass',
      );
      final updated = VaultService.addItemWithDetails(vault, item);
      
      expect(updated.items.length, 1);
      expect(updated.items.first.username, 'user');
    });

    test('updateItem updates existing item', () {
      final vault = VaultService.createEmptyVault();
      final withItem = VaultService.addItem(vault, 'Item');
      final item = withItem.items.first;
      
      final updated = VaultService.updateItem(
        withItem,
        item.copyWith(username: 'updated_user'),
      );
      
      expect(updated.items.first.username, 'updated_user');
    });

    test('updateItem does nothing for non-existent id', () {
      final vault = VaultService.createEmptyVault();
      final withItem = VaultService.addItem(vault, 'Item');
      
      final updated = VaultService.updateItem(
        withItem,
        VaultItem(id: 'non-existent', title: 'Test'),
      );
      
      expect(updated.items.length, 1);
    });

    test('deleteItem removes item by id', () {
      final vault = VaultService.createEmptyVault();
      final withItem = VaultService.addItem(vault, 'Item1');
      final item = withItem.items.first;
      
      final updated = VaultService.deleteItem(withItem, item.id);
      
      expect(updated.items, isEmpty);
    });

    test('deleteItem does nothing for non-existent id', () {
      final vault = VaultService.createEmptyVault();
      final withItem = VaultService.addItem(vault, 'Item');
      
      final updated = VaultService.deleteItem(withItem, 'non-existent');
      
      expect(updated.items.length, 1);
    });

    test('toJson and fromJson work correctly', () {
      final vault = VaultService.createEmptyVault();
      final withItem = VaultService.addItem(vault, 'Item1');
      final item2 = VaultItem(title: 'Item2', username: 'user');
      final withMultiple = VaultService.addItemWithDetails(withItem, item2);
      
      final json = withMultiple.toJson();
      final restored = Vault.fromJson(json);
      
      expect(restored.items.length, 2);
      expect(restored.items[0].title, 'Item1');
      expect(restored.items[1].title, 'Item2');
      expect(restored.items[1].username, 'user');
    });
  });

  group('Attachment', () {
    test('create attachment', () {
      final attachment = Attachment(
        name: 'test.pdf',
        data: Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      expect(attachment.name, 'test.pdf');
      expect(attachment.data.length, 5);
    });

    test('toJson and fromJson work correctly', () {
      final attachment = Attachment(
        name: 'test.pdf',
        data: Uint8List.fromList([1, 2, 3, 4, 5]),
      );
      
      final json = attachment.toJson();
      final restored = Attachment.fromJson(json);
      
      expect(restored.name, attachment.name);
      expect(restored.data, attachment.data);
    });
  });
}
