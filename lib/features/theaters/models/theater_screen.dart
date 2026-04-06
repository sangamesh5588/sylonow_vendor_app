import 'package:freezed_annotation/freezed_annotation.dart';

part 'theater_screen.freezed.dart';
part 'theater_screen.g.dart';

@freezed
class TheaterScreen with _$TheaterScreen {
  const factory TheaterScreen({
    required String id,
    @JsonKey(name: 'theater_id') required String theaterId,
    @JsonKey(name: 'screen_name') required String screenName,
    @JsonKey(name: 'screen_number') required int screenNumber,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'total_capacity') @Default(0) int totalCapacity,
    @JsonKey(name: 'allowed_capacity') @Default(0) int allowedCapacity,
    @JsonKey(name: 'charges_extra_per_person') @Default(0.0) double chargesExtraPerPerson,
    @JsonKey(name: 'video_url') String? videoUrl,
    @Default([]) List<String> images,
    @Default([]) List<String> amenities,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'what_included') @Default([]) List<String> whatIncluded,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'activation_status') @Default('not_requested') String activationStatus,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _TheaterScreen;

  factory TheaterScreen.fromJson(Map<String, dynamic> json) => _$TheaterScreenFromJson(json);
}