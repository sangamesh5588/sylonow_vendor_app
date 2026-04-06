// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VenueImpl _$$VenueImplFromJson(Map<String, dynamic> json) => _$VenueImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String,
      displayOrder: (json['display_order'] as num).toInt(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$VenueImplToJson(_$VenueImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon_name': instance.iconName,
      'display_order': instance.displayOrder,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
