// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'password_strength.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PasswordStrength {
  /// 强度分数 (0-100)
  int get score => throw _privateConstructorUsedError;

  /// 强度等级
  StrengthLevel get level => throw _privateConstructorUsedError;

  /// 改进建议
  String get suggestion => throw _privateConstructorUsedError;

  /// Create a copy of PasswordStrength
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PasswordStrengthCopyWith<PasswordStrength> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PasswordStrengthCopyWith<$Res> {
  factory $PasswordStrengthCopyWith(
    PasswordStrength value,
    $Res Function(PasswordStrength) then,
  ) = _$PasswordStrengthCopyWithImpl<$Res, PasswordStrength>;
  @useResult
  $Res call({int score, StrengthLevel level, String suggestion});
}

/// @nodoc
class _$PasswordStrengthCopyWithImpl<$Res, $Val extends PasswordStrength>
    implements $PasswordStrengthCopyWith<$Res> {
  _$PasswordStrengthCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PasswordStrength
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? score = null,
    Object? level = null,
    Object? suggestion = null,
  }) {
    return _then(
      _value.copyWith(
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as StrengthLevel,
            suggestion: null == suggestion
                ? _value.suggestion
                : suggestion // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PasswordStrengthImplCopyWith<$Res>
    implements $PasswordStrengthCopyWith<$Res> {
  factory _$$PasswordStrengthImplCopyWith(
    _$PasswordStrengthImpl value,
    $Res Function(_$PasswordStrengthImpl) then,
  ) = __$$PasswordStrengthImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int score, StrengthLevel level, String suggestion});
}

/// @nodoc
class __$$PasswordStrengthImplCopyWithImpl<$Res>
    extends _$PasswordStrengthCopyWithImpl<$Res, _$PasswordStrengthImpl>
    implements _$$PasswordStrengthImplCopyWith<$Res> {
  __$$PasswordStrengthImplCopyWithImpl(
    _$PasswordStrengthImpl _value,
    $Res Function(_$PasswordStrengthImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PasswordStrength
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? score = null,
    Object? level = null,
    Object? suggestion = null,
  }) {
    return _then(
      _$PasswordStrengthImpl(
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as StrengthLevel,
        suggestion: null == suggestion
            ? _value.suggestion
            : suggestion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PasswordStrengthImpl extends _PasswordStrength {
  const _$PasswordStrengthImpl({
    required this.score,
    required this.level,
    required this.suggestion,
  }) : super._();

  /// 强度分数 (0-100)
  @override
  final int score;

  /// 强度等级
  @override
  final StrengthLevel level;

  /// 改进建议
  @override
  final String suggestion;

  @override
  String toString() {
    return 'PasswordStrength(score: $score, level: $level, suggestion: $suggestion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PasswordStrengthImpl &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.suggestion, suggestion) ||
                other.suggestion == suggestion));
  }

  @override
  int get hashCode => Object.hash(runtimeType, score, level, suggestion);

  /// Create a copy of PasswordStrength
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PasswordStrengthImplCopyWith<_$PasswordStrengthImpl> get copyWith =>
      __$$PasswordStrengthImplCopyWithImpl<_$PasswordStrengthImpl>(
        this,
        _$identity,
      );
}

abstract class _PasswordStrength extends PasswordStrength {
  const factory _PasswordStrength({
    required final int score,
    required final StrengthLevel level,
    required final String suggestion,
  }) = _$PasswordStrengthImpl;
  const _PasswordStrength._() : super._();

  /// 强度分数 (0-100)
  @override
  int get score;

  /// 强度等级
  @override
  StrengthLevel get level;

  /// 改进建议
  @override
  String get suggestion;

  /// Create a copy of PasswordStrength
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PasswordStrengthImplCopyWith<_$PasswordStrengthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
