import 'package:freezed_annotation/freezed_annotation.dart';

part 'venue.freezed.dart';
part 'venue.g.dart';

@freezed
class Venue with _$Venue {
  const factory Venue({
    required String id,
    required String name,
    @JsonKey(name: 'icon_name') required String iconName,
    @JsonKey(name: 'display_order') required int displayOrder,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);
}
