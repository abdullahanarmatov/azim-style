/// Answers from the style quiz. Sent to the AI stylist as-is.
class StyleProfile {
  const StyleProfile({
    this.gender,
    this.occasions = const {},
    this.styles = const {},
    this.budget,
    this.topSize,
    this.colors = const {},
    this.notes = '',
  });

  final String? gender;
  final Set<String> occasions;
  final Set<String> styles;

  /// Upper limit for a full look, in currency units.
  final int? budget;
  final String? topSize;
  final Set<String> colors;
  final String notes;

  bool get isComplete =>
      gender != null && occasions.isNotEmpty && styles.isNotEmpty && budget != null;

  StyleProfile copyWith({
    String? gender,
    Set<String>? occasions,
    Set<String>? styles,
    int? budget,
    String? topSize,
    Set<String>? colors,
    String? notes,
  }) =>
      StyleProfile(
        gender: gender ?? this.gender,
        occasions: occasions ?? this.occasions,
        styles: styles ?? this.styles,
        budget: budget ?? this.budget,
        topSize: topSize ?? this.topSize,
        colors: colors ?? this.colors,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'occasions': occasions.toList(),
        'styles': styles.toList(),
        'budget': budget,
        'top_size': topSize,
        'colors': colors.toList(),
        'notes': notes,
      };
}

/// What the AI stylist (or the offline fallback) returns.
class Recommendation {
  const Recommendation({required this.summary, required this.looks});

  final String summary;
  final List<RecommendedLook> looks;
}

class RecommendedLook {
  const RecommendedLook({
    required this.title,
    required this.reason,
    required this.productIds,
  });

  final String title;
  final String reason;
  final List<String> productIds;

  factory RecommendedLook.fromJson(Map<String, dynamic> json) => RecommendedLook(
        title: json['title'] as String,
        reason: (json['reason'] as String?) ?? '',
        productIds: List<String>.from(json['product_ids'] as List),
      );
}
