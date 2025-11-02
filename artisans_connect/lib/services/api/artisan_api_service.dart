import '../../models/artisan.dart';

class ArtisanApiService {
  const ArtisanApiService();

  Future<List<Artisan>> fetchArtisans({
    String? metier,
    String? ville,
  }) async {
    // TODO: Impl?menter l'appel API pour r?cup?rer la liste des artisans.
    throw UnimplementedError('fetchArtisans() n\'est pas encore impl?ment?.');
  }

  Future<Artisan> fetchArtisanById(String artisanId) async {
    // TODO: Impl?menter l'appel API pour r?cup?rer le d?tail d'un artisan.
    throw UnimplementedError('fetchArtisanById() n\'est pas encore impl?ment?.');
  }
}
