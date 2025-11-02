import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/user_role.dart';
import 'api_config.dart';
import 'api_exception.dart';

class AuthVerificationResult {
  const AuthVerificationResult({
    required this.token,
    required this.role,
  });

  final String token;
  final UserRole role;
}

class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  Future<void> requestOtp({required String phoneNumber}) async {
    final uri = _buildUri('auth/otp/request');
    final payload = {'phone': phoneNumber};
    final response = await _safePost(uri, payload);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForStatus(response.statusCode);
    }
  }

  Future<AuthVerificationResult> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    final uri = _buildUri('auth/otp/verify');
    final payload = {
      'phone': phoneNumber,
      'code': otpCode,
    };

    final response = await _safePost(uri, payload);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForStatus(response.statusCode);
    }

    final decoded = _decodeJson(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Reponse du serveur illisible.');
    }

    final token = decoded['token'] as String?;
    final roleValue = decoded['role'] as String?;
    if (token == null || roleValue == null) {
      throw const ApiException('Informations d\'authentification manquantes.');
    }

    final role = UserRoleParsing.fromString(roleValue);
    return AuthVerificationResult(token: token, role: role);
  }

  Uri _buildUri(String endpoint) {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final segments = <String>[
      ...baseUri.pathSegments,
      ...endpoint.split('/').where((segment) => segment.isNotEmpty),
    ];

    return baseUri.replace(pathSegments: segments, queryParameters: baseUri.queryParameters);
  }

  Future<http.Response> _safePost(Uri uri, Map<String, dynamic> payload) async {
    final body = jsonEncode(payload);
    try {
      return await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeout);
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

  dynamic _decodeJson(String source) {
    try {
      return jsonDecode(source);
    } on FormatException {
      throw const ApiException('Reponse du serveur illisible.');
    }
  }

  void _throwForStatus(int statusCode) {
    if (statusCode == 404) {
      throw const ApiException('Service d\'authentification indisponible.');
    }
    if (statusCode == 401 || statusCode == 403) {
      throw const ApiException('Code OTP invalide ou expire.');
    }
    if (statusCode >= 500) {
      throw const ApiException('Serveur indisponible. Reessayez plus tard.');
    }
    throw ApiException('Echec de la requete d\'authentification (code $statusCode).');
  }
}
