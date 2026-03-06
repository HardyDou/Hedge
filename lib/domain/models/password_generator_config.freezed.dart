// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'password_generator_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PasswordGeneratorConfig _$PasswordGeneratorConfigFromJson(
  Map<String, dynamic> json,
) {
  return _PasswordGeneratorConfig.fromJson(json);
}

/// @nodoc
mixin _$PasswordGeneratorConfig {
  /// 密码长度 (8-64)
  int get length => throw _privateConstructorUsedError;

  /// 数字字符数量 (0-length)
  int get numbersCount => throw _privateConstructorUsedError;

  /// 符号字符数量 (0-length)
  int get symbolsCount => throw _privateConstructorUsedError;

  /// 排除易混淆字符 (0/O, 1/l/I)
  bool get excludeAmbiguous => throw _privateConstructorUsedError;

  /// Serializes this PasswordGeneratorConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PasswordGeneratorConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PasswordGeneratorConfigCopyWith<PasswordGeneratorConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PasswordGeneratorConfigCopyWith<$Res> {
  factory $PasswordGeneratorConfigCopyWith(
    PasswordGeneratorConfig value,
    $Res Function(PasswordGeneratorConfig) then,
  ) = _$PasswordGeneratorConfigCopyWithImpl<$Res, PasswordGeneratorConfig>;
  @useResult
  $Res call({
    int length,
    int numbersCount,
    int symbolsCount,
    bool excludeAmbiguous,
  });
}

/// @nodoc
class _$PasswordGeneratorConfigCopyWithImpl<
  $Res,
  $Val extends PasswordGeneratorConfig
>
    implements $PasswordGeneratorConfigCopyWith<$Res> {
  _$PasswordGeneratorConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PasswordGeneratorConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? length = null,
    Object? numbersCount = null,
    Object? symbolsCount = null,
    Object? excludeAmbiguous = null,
  }) {
    return _then(
      _value.copyWith(
            length: null == length
                ? _value.length
                : length // ignore: cast_nullable_to_non_nullable
                      as int,
            numbersCount: null == numbersCount
                ? _value.numbersCount
                : numbersCount // ignore: cast_nullable_to_non_nullable
                      as int,
            symbolsCount: null == symbolsCount
                ? _value.symbolsCount
                : symbolsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            excludeAmbiguous: null == excludeAmbiguous
                ? _value.excludeAmbiguous
                : excludeAmbiguous // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PasswordGeneratorConfigImplCopyWith<$Res>
    implements $PasswordGeneratorConfigCopyWith<$Res> {
  factory _$$PasswordGeneratorConfigImplCopyWith(
    _$PasswordGeneratorConfigImpl value,
    $Res Function(_$PasswordGeneratorConfigImpl) then,
  ) = __$$PasswordGeneratorConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int length,
    int numbersCount,
    int symbolsCount,
    bool excludeAmbiguous,
  });
}

/// @nodoc
class __$$PasswordGeneratorConfigImplCopyWithImpl<$Res>
    extends
        _$PasswordGeneratorConfigCopyWithImpl<
          $Res,
          _$PasswordGeneratorConfigImpl
        >
    implements _$$PasswordGeneratorConfigImplCopyWith<$Res> {
  __$$PasswordGeneratorConfigImplCopyWithImpl(
    _$PasswordGeneratorConfigImpl _value,
    $Res Function(_$PasswordGeneratorConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PasswordGeneratorConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? length = null,
    Object? numbersCount = null,
    Object? symbolsCount = null,
    Object? excludeAmbiguous = null,
  }) {
    return _then(
      _$PasswordGeneratorConfigImpl(
        length: null == length
            ? _value.length
            : length // ignore: cast_nullable_to_non_nullable
                  as int,
        numbersCount: null == numbersCount
            ? _value.numbersCount
            : numbersCount // ignore: cast_nullable_to_non_nullable
                  as int,
        symbolsCount: null == symbolsCount
            ? _value.symbolsCount
            : symbolsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        excludeAmbiguous: null == excludeAmbiguous
            ? _value.excludeAmbiguous
            : excludeAmbiguous // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PasswordGeneratorConfigImpl implements _PasswordGeneratorConfig {
  const _$PasswordGeneratorConfigImpl({
    required this.length,
    this.numbersCount = 0,
    this.symbolsCount = 0,
    this.excludeAmbiguous = false,
  });

  factory _$PasswordGeneratorConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$PasswordGeneratorConfigImplFromJson(json);

  /// 密码长度 (8-64)
  @override
  final int length;

  /// 数字字符数量 (0-length)
  @override
  @JsonKey()
  final int numbersCount;

  /// 符号字符数量 (0-length)
  @override
  @JsonKey()
  final int symbolsCount;

  /// 排除易混淆字符 (0/O, 1/l/I)
  @override
  @JsonKey()
  final bool excludeAmbiguous;

  @override
  String toString() {
    return 'PasswordGeneratorConfig(length: $length, numbersCount: $numbersCount, symbolsCount: $symbolsCount, excludeAmbiguous: $excludeAmbiguous)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PasswordGeneratorConfigImpl &&
            (identical(other.length, length) || other.length == length) &&
            (identical(other.numbersCount, numbersCount) ||
                other.numbersCount == numbersCount) &&
            (identical(other.symbolsCount, symbolsCount) ||
                other.symbolsCount == symbolsCount) &&
            (identical(other.excludeAmbiguous, excludeAmbiguous) ||
                other.excludeAmbiguous == excludeAmbiguous));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    length,
    numbersCount,
    symbolsCount,
    excludeAmbiguous,
  );

  /// Create a copy of PasswordGeneratorConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PasswordGeneratorConfigImplCopyWith<_$PasswordGeneratorConfigImpl>
  get copyWith =>
      __$$PasswordGeneratorConfigImplCopyWithImpl<
        _$PasswordGeneratorConfigImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PasswordGeneratorConfigImplToJson(this);
  }
}

abstract class _PasswordGeneratorConfig implements PasswordGeneratorConfig {
  const factory _PasswordGeneratorConfig({
    required final int length,
    final int numbersCount,
    final int symbolsCount,
    final bool excludeAmbiguous,
  }) = _$PasswordGeneratorConfigImpl;

  factory _PasswordGeneratorConfig.fromJson(Map<String, dynamic> json) =
      _$PasswordGeneratorConfigImpl.fromJson;

  /// 密码长度 (8-64)
  @override
  int get length;

  /// 数字字符数量 (0-length)
  @override
  int get numbersCount;

  /// 符号字符数量 (0-length)
  @override
  int get symbolsCount;

  /// 排除易混淆字符 (0/O, 1/l/I)
  @override
  bool get excludeAmbiguous;

  /// Create a copy of PasswordGeneratorConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PasswordGeneratorConfigImplCopyWith<_$PasswordGeneratorConfigImpl>
  get copyWith => throw _privateConstructorUsedError;
}
