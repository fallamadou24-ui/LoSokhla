enum RealisationMediaType { photo, video }

class Realisation {
  const Realisation({
    required this.id,
    required this.title,
    this.description,
    required this.mediaUrl,
    this.mediaType = RealisationMediaType.photo,
    this.completedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String mediaUrl;
  final RealisationMediaType mediaType;
  final DateTime? completedAt;

  Realisation copyWith({
    String? id,
    String? title,
    String? description,
    String? mediaUrl,
    RealisationMediaType? mediaType,
    DateTime? completedAt,
  }) {
    return Realisation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory Realisation.fromJson(Map<String, dynamic> json) {
    return Realisation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      mediaUrl: json['mediaUrl'] as String,
      mediaType: RealisationMediaType.values.firstWhere(
        (type) => type.name == (json['mediaType'] as String?)?.toLowerCase(),
        orElse: () => RealisationMediaType.photo,
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.name,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
