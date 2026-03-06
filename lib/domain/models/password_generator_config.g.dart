// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_generator_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PasswordGeneratorConfigImpl _$$PasswordGeneratorConfigImplFromJson(
  Map<String, dynamic> json,
) => _$PasswordGeneratorConfigImpl(
  length: (json['length'] as num).toInt(),
  includeUppercase: json['includeUppercase'] as bool,
  includeLowercase: json['includeLowercase'] as bool,
  includeNumbers: json['includeNumbers'] as bool,
  includeSymbols: json['includeSymbols'] as bool,
  excludeAmbiguous: json['excludeAmbiguous'] as bool? ?? false,
);

Map<String, dynamic> _$$PasswordGeneratorConfigImplToJson(
  _$PasswordGeneratorConfigImpl instance,
) => <String, dynamic>{
  'length': instance.length,
  'includeUppercase': instance.includeUppercase,
  'includeLowercase': instance.includeLowercase,
  'includeNumbers': instance.includeNumbers,
  'includeSymbols': instance.includeSymbols,
  'excludeAmbiguous': instance.excludeAmbiguous,
};
