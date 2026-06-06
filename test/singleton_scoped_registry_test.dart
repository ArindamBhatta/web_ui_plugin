import 'package:flutter_test/flutter_test.dart';
import 'package:web_ui_plugin/src/core/registry/singleton_scoped_registry.dart';

void main() {
  group('CrossModuleSingletonKey Tests', () {
    test('Identical keys should be equal and have matching hashCodes', () {
      const key1 = CrossModuleSingletonKey(
        moduleId: 'module_a',
        modelType: 'User',
        collection: 'users',
      );

      final key2 = CrossModuleSingletonKey(
        moduleId: 'module_a',
        modelType: 'User',
        collection: 'users',
      );

      expect(key1 == key2, isTrue);
      expect(key1.hashCode == key2.hashCode, isTrue);
    });

    test('Registry should retrieve instance with matching key values', () {
      final registry = SingletonScopedRegistry<String>();
      final key1 = CrossModuleSingletonKey(
        moduleId: 'module_a',
        modelType: 'User',
        collection: 'users',
      );

      final key2 = CrossModuleSingletonKey(
        moduleId: 'module_a',
        modelType: 'User',
        collection: 'users',
      );

      registry.register(key1, 'hello');

      expect(registry.get(key2), equals('hello'));
      expect(registry.contains(key2), isTrue);
    });
  });
}
