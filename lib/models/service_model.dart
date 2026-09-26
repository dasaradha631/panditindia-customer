/// Vedic service offered by PanditIndia (PDF section 7 - models).
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.icon,
    this.priceFrom,
    this.duration,
    this.category,
    this.rating = 4.8,
    this.reviewCount = 0,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? icon;
  final double? priceFrom;
  final String? duration;
  final String? category;
  final double rating;
  final int reviewCount;
  final String? imageAsset;

  String get priceLabel => priceFrom == null
      ? 'On request'
      : 'From ₹${priceFrom!.toStringAsFixed(0)}';

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        subtitle: '${json['subtitle'] ?? json['description'] ?? ''}',
        icon: json['icon'] as String?,
        priceFrom: (json['price_from'] as num?)?.toDouble(),
        duration: json['duration'] as String?,
        category: json['category'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        imageAsset: json['image_asset'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
        'price_from': priceFrom,
        'duration': duration,
        'category': category,
        'rating': rating,
        'review_count': reviewCount,
        'image_asset': imageAsset,
      };
}
