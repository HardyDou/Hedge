import 'package:flutter_test/flutter_test.dart';
import 'package:hedge/domain/services/sort_service.dart';
import 'package:hedge/src/dart/vault.dart';

void main() {
  group('SortService', () {
    VaultItem createItem(String title) {
      return VaultItem(title: title);
    }

    group('分类排序', () {
      test('数字开头排在字母前面', () {
        final items = [
          createItem('Apple'),
          createItem('12306'),
        ];

        final sorted = SortService.sort(items);

        expect(sorted[0].title, '12306');
        expect(sorted[1].title, 'Apple');
      });

      test('字母开头排在中文前面', () {
        final items = [
          createItem('测试'),
          createItem('Apple'),
        ];

        final sorted = SortService.sort(items);

        expect(sorted[0].title, 'Apple');
        expect(sorted[1].title, '测试');
      });

      test('数字→字母→中文顺序', () {
        final items = [
          createItem('测试'),
          createItem('Apple'),
          createItem('12306'),
        ];

        final sorted = SortService.sort(items);

        expect(sorted[0].title, '12306');
        expect(sorted[1].title, 'Apple');
        expect(sorted[2].title, '测试');
      });
    });

    group('字母排序', () {
      test('英文字母按 A-Z 排序', () {
        final items = [
          createItem('Banana'),
          createItem('Apple'),
          createItem('Cherry'),
        ];

        final sorted = SortService.sort(items);

        expect(sorted[0].title, 'Apple');
        expect(sorted[1].title, 'Banana');
        expect(sorted[2].title, 'Cherry');
      });

      test('忽略大小写排序', () {
        final items = [
          createItem('banana'),
          createItem('Apple'),
          createItem('CHERRY'),
        ];

        final sorted = SortService.sort(items);

        expect(sorted[0].title, 'Apple');
        expect(sorted[1].title, 'banana');
        expect(sorted[2].title, 'CHERRY');
      });
    });

    group('拼音排序', () {
      test('中文按拼音排序', () {
        final items = [
          createItem('测试'),  // ceshi
          createItem('银行'),  // yinhang
          createItem('阿里'),  // ali
        ];

        final sorted = SortService.sort(items);

        expect(sorted[0].title, '阿里');   // ali
        expect(sorted[1].title, '测试');   // ceshi
        expect(sorted[2].title, '银行');   // yinhang
      });

      test('混合排序完整测试', () {
        final items = [
          createItem('测试'),
          createItem('12306'),
          createItem('Apple'),
          createItem('银行'),
          createItem('163邮箱'),
          createItem('Zoom'),
        ];

        final sorted = SortService.sort(items);

        // 数字开头
        expect(sorted[0].title, '12306');
        expect(sorted[1].title, '163邮箱');
        // 字母开头
        expect(sorted[2].title, 'Apple');
        expect(sorted[3].title, 'Zoom');
        // 中文（按拼音）
        expect(sorted[4].title, '测试');
        expect(sorted[5].title, '银行');
      });
    });

    group('边界情况', () {
      test('空列表', () {
        final sorted = SortService.sort([]);
        expect(sorted, isEmpty);
      });

      test('单个元素', () {
        final items = [createItem('Test')];
        final sorted = SortService.sort(items);
        expect(sorted.length, 1);
        expect(sorted[0].title, 'Test');
      });
    });
  });
}
