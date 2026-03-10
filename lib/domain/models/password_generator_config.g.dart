// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_generator_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PasswordGeneratorConfigImpl _$$PasswordGeneratorConfigImplFromJson(
  Map<String, dynamic> json,
) => _$PasswordGeneratorConfigImpl(
  length: (json['length'] as num).toInt(),
  includeNumbers: json['includeNumbers'] as bool? ?? true,
  includeSymbols: json['includeSymbols'] as bool? ?? true,
  excludeAmbiguous: json['excludeAmbiguous'] as bool? ?? false,
);

Map<String, dynamic> _$$PasswordGeneratorConfigImplToJson(
  _$PasswordGeneratorConfigImpl instance,
) => <String, dynamic>{
  'length': instance.length,
  'includeNumbers': instance.includeNumbers,
  'includeSymbols': instance.includeSymbols,
  'excludeAmbiguous': instance.excludeAmbiguous,
};
