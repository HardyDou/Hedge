// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_generator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$passwordGeneratorHash() => r'6d79a6c310bb2f2c22c72afc6bad088f70ca8689';

/// 密码生成器 Provider
///
/// Copied from [PasswordGenerator].
@ProviderFor(PasswordGenerator)
final passwordGeneratorProvider =
    AutoDisposeAsyncNotifierProvider<
      PasswordGenerator,
      PasswordGeneratorState
    >.internal(
      PasswordGenerator.new,
      name: r'passwordGeneratorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$passwordGeneratorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PasswordGenerator = AutoDisposeAsyncNotifier<PasswordGeneratorState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
