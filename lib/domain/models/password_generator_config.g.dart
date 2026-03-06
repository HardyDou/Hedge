// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_generator_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PasswordGeneratorConfigImpl _$$PasswordGeneratorConfigImplFromJson(
  Map<String, dynamic> json,
) => _$PasswordGeneratorConfigImpl(
  length: (json['length'] as num).toInt(),
  numbersCount: (json['numbersCount'] as num?)?.toInt() ?? 0,
  symbolsCount: (json['symbolsCount'] as num?)?.toInt() ?? 0,
  excludeAmbiguous: json['excludeAmbiguous'] as bool? ?? false,
);

Map<String, dynamic> _$$PasswordGeneratorConfigImplToJson(
  _$PasswordGeneratorConfigImpl instance,
) => <String, dynamic>{
  'length': instance.length,
  'numbersCount': instance.numbersCount,
  'symbolsCount': instance.symbolsCount,
  'excludeAmbiguous': instance.excludeAmbiguous,
};
