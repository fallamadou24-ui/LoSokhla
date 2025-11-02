import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/artisan.dart';
import '../../models/realisation.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ArtisanApiService {
  ArtisanApiService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  Future<List<Artisan>> fetchArtisans({
    String? metier,
    String? ville,
  }) async {
    final trimmedMetier = metier?.trim();
    final trimmedVille = ville?.trim();
    final uri = _buildUri('artisans', {
      if (trimmedMetier != null && trimmedMetier.isNotEmpty) 'metier': trimmedMetier,
      if (trimmedVille != null && trimmedVille.isNotEmpty) 'ville': trimmedVille,
    });

    final data = await _getJson(uri, returnEmptyListOnNotFound: true);
    if (data is! List) {
      throw const ApiException('Format de donnees inattendu recu du serveur.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Artisan.fromJson)
        .toList(growable: false);
  }

  Future<Artisan> fetchArtisanById(String artisanId) async {
    final uri = _buildUri('artisans/$artisanId');
    final data = await _getJson(uri);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Format de donnees inattendu recu du serveur.');
    }

    var artisan = Artisan.fromJson(data);

    final hasEmbeddedRealisations =
        (data['realisations'] as List<dynamic>?)?.isNotEmpty ?? false;
    if (!hasEmbeddedRealisations) {
      final realisations = await fetchRealisations(artisanId);
      artisan = artisan.copyWith(realisationList: realisations);
    }

    return artisan;
  }

  Future<List<Realisation>> fetchRealisations(String artisanId) async {
    final uri = _buildUri('artisans/$artisanId/realisations');
    final data = await _getJson(uri, returnEmptyListOnNotFound: true);
    if (data is! List) {
      throw const ApiException('Format de donnees inattendu recu du serveur.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Realisation.fromJson)
        .toList(growable: false);
  }

  Future<dynamic> _getJson(Uri uri, {bool returnEmptyListOnNotFound = false}) async {
    final response = await _safeGet(uri);
    if (returnEmptyListOnNotFound && response.statusCode == 404) {
      return const <dynamic>[];
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForStatus(response.statusCode);
    }

    if (returnEmptyListOnNotFound && response.statusCode == 204) {
      return const <dynamic>[];
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('Reponse du serveur illisible.');
    }
  }

  Future<http.Response> _safeGet(Uri uri) async {
    try {
      return await _client.get(uri).timeout(_timeout);
    } on SocketException {
      throw const ApiException('Connexion impossible. Verifiez votre connexion internet.');
    } on TimeoutException {
      throw const ApiException('Le serveur met trop de temps a repondre. Reessayez plus tard.');
    } on HttpException {
      throw const ApiException('Impossible de contacter le serveur distant.');
    } catch (_) {
      throw const ApiException('Une erreur inattendue est survenue.');
    }
  }

  void _throwForStatus(int statusCode) {
    if (statusCode == 404) {
      throw const ApiException('Ressource introuvable.');
    }
    if (statusCode == 401 || statusCode == 403) {
      throw const ApiException('Acces refuse. Authentification requise.');
    }
    if (statusCode >= 500) {
      throw const ApiException('Service indisponible. Reessayez plus tard.');
    }
    throw ApiException('Requete echouee (code $statusCode).');
  }

  Uri _buildUri(String endpoint, [Map<String, String>? additionalQuery]) {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final segments = <String>[
      ...baseUri.pathSegments,
      ...endpoint.split('/').where((segment) => segment.isNotEmpty),
    ];

    final mergedQuery = <String, String>{
      ...baseUri.queryParameters,
      if (additionalQuery != null) ...additionalQuery,
    }..removeWhere((key, value) => value.isEmpty);

    return baseUri.replace(
      pathSegments: segments,
      queryParameters: mergedQuery.isEmpty ? null : mergedQuery,
    );
  }
}
