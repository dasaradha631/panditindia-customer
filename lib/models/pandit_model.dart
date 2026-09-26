/// Verified pandit / acharya profile (PDF section 7 - models).
class PanditModel {
  const PanditModel({
    required this.id,
    required this.name,
    required this.speciality,
    this.experienceYears = 0,
    this.languages = const <String>[],
    this.rating = 4.9,
    this.reviewCount = 0,
    this.city,
    this.imageAsset,
    this.verified = true,
  });

  final String id;
  final String name;
  final String speciality;
  final int experienceYears;
  final List<String> languages;
  final double rating;
  final int reviewCount;
  final String? city;
  final String? imageAsset;
  final bool verified;

  String get initials {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory PanditModel.fromJson(Map<String, dynamic> json) => PanditModel(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        speciality: '${json['speciality'] ?? ''}',
        experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
        languages: (json['languages'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => '$e')
            .toList(),
        rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        city: json['city'] as String?,
        imageAsset: json['image_asset'] as String?,
        verified: json['verified'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'speciality': speciality,
        'experience_years': experienceYears,
        'languages': languages,
        'rating': rating,
        'review_count': reviewCount,
        'city': city,
        'image_asset': imageAsset,
        'verified': verified,
      };
}
