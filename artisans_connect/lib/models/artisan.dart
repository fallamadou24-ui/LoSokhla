import 'realisation.dart';

class Artisan {
  const Artisan({
    required this.id,
    required this.fullName,
    required this.metier,
    required this.ville,
    this.note,
    this.presentation,
    this.avatarUrl,
    this.realisationList = const [],
    this.yearsOfExperience,
  });

  final String id;
  final String fullName;
  final String metier;
  final String ville;
  final double? note;
  final String? presentation;
  final String? avatarUrl;
  final List<Realisation> realisationList;
  final int? yearsOfExperience;

  Artisan copyWith({
    String? id,
    String? fullName,
    String? metier,
    String? ville,
    double? note,
    String? presentation,
    String? avatarUrl,
    List<Realisation>? realisationList,
    int? yearsOfExperience,
  }) {
    return Artisan(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      metier: metier ?? this.metier,
      ville: ville ?? this.ville,
      note: note ?? this.note,
      presentation: presentation ?? this.presentation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      realisationList: realisationList ?? this.realisationList,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
    );
  }

  factory Artisan.fromJson(Map<String, dynamic> json) {
    final realisations = (json['realisations'] as List<dynamic>?)
            ?.map((item) => Realisation.fromJson(item as Map<String, dynamic>))
            .toList() ??
        const <Realisation>[];

    return Artisan(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      metier: json['metier'] as String,
      ville: json['ville'] as String,
      note: (json['note'] as num?)?.toDouble(),
      presentation: json['presentation'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      realisationList: realisations,
      yearsOfExperience: json['yearsOfExperience'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'metier': metier,
      'ville': ville,
      'note': note,
      'presentation': presentation,
      'avatarUrl': avatarUrl,
      'yearsOfExperience': yearsOfExperience,
      'realisations': realisationList.map((item) => item.toJson()).toList(),
    };
  }
}
